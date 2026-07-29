# frozen_string_literal: true

require 'test_helper'

# Tests de non-régression des failles corrigées.
# Chaque test matérialise une attaque qui était possible avant correctif.
class SecuriteRegressionsTest < ActionDispatch::IntegrationTest
  # ==================== TESTS CRITIQUES — isolation inter-organisations ====================
  # Menace réaliste : un curieux qui suit une URL vers les
  # données d'une autre commune (lien recopié, historique partagé, essai d'ID).

  # Test critique — la fiche d'une intervention d'une autre organisation est inaccessible.
  test "critique : un manager ne peut pas ouvrir l'intervention d'une autre organisation" do
    sign_in users(:hidalgo) # manager mairie_paris

    get intervention_url(interventions(:nettoyage_port)) # mairie_marseille

    assert_response :redirect, "la fiche d'une autre organisation ne doit pas se rendre"
  end

  # Test critique — la commande d'une autre organisation est inaccessible (argent).
  test "critique : un manager ne peut pas ouvrir la commande d'une autre organisation" do
    sign_in users(:hidalgo)

    get commande_url(commandes(:commande_marseille))

    assert_response :redirect
  end

  # Test critique — la facture d'une autre organisation est inaccessible (argent).
  test "critique : un manager ne peut pas ouvrir la facture d'une autre organisation" do
    sign_in users(:hidalgo)

    get facture_url(factures(:facture_marseille))

    assert_response :redirect
  end

  # Test critique — l'export XLS des interventions est borné à l'organisation :
  # aucune ligne d'une autre commune ne doit partir dans le fichier.
  test "critique : l'export XLS d'un manager ne contient aucune intervention d'une autre organisation" do
    sign_in users(:hidalgo)

    get interventions_url(format: :xls)

    assert_response :success
    sheet = Spreadsheet.open(StringIO.new(response.body)).worksheet(0)
    contenu = sheet.rows.map { |r| r.to_a.join(' ') }.join(' ')
    assert_includes contenu, interventions(:tonte_locaux).description,
                    'garde anti-faux-positif : les interventions de sa propre organisation sont exportées'
    assert_not_includes contenu, interventions(:nettoyage_port).description
  end

  # ==================== /TESTS CRITIQUES ====================

  # --- Mass assignment : rôle ---

  test "un agent ne peut pas s'auto-promouvoir administrateur via update" do
    bond = users(:bond)
    sign_in bond

    patch user_url(bond), params: { user: { nom: bond.nom, rôle: 'administrateur' } }

    assert bond.reload.agent?, 'le rôle ne doit pas être modifiable par son propriétaire'
  end

  test 'un manager ne peut pas changer le rôle d’un agent via update' do
    sign_in users(:hidalgo)
    bond = users(:bond)

    patch user_url(bond), params: { user: { nom: bond.nom, rôle: 'manager' } }

    assert bond.reload.agent?
  end

  test 'un manager ne peut pas créer un administrateur via admin/create_new_user_do' do
    sign_in users(:hidalgo)

    post admin_create_new_user_do_url, params: {
      user: { nom: 'Forgé', prénom: 'Compte', email: 'forge@example.com',
              password: 'Px9!aZk2#mQ7', rôle: 'administrateur',
              address: 'Mairie', latitude: 1.0, longitude: 1.0 }
    }

    créé = User.find_by(email: 'forge@example.com')
    assert_not_nil créé
    assert_not créé.administrateur?, 'un manager ne doit jamais pouvoir créer un administrateur'
  end

  # --- Mass assignment : service_ids inter-organisations ---

  test "les service_ids d'une autre organisation sont ignorés" do
    sign_in users(:hidalgo)
    bond = users(:bond)
    services_avant = bond.services.to_a

    patch user_url(bond), params: { user: { nom: bond.nom, service_ids: [services(:service_marseille).id] } }

    assert_not_includes bond.reload.services, services(:service_marseille)
    assert_equal services_avant.sort_by(&:id), bond.services.sort_by(&:id)
  end

  # --- Mass assignment : workflow_state / note / avis sur Intervention ---

  test 'workflow_state ne passe pas par le mass assignment' do
    sign_in users(:hidalgo)
    intervention = interventions(:nouvelle_intervention)
    état_avant = intervention.workflow_state

    patch intervention_url(intervention), params: { intervention: { description: intervention.description, workflow_state: 'validé' } }

    assert_equal état_avant, intervention.reload.workflow_state
  end

  test "un agent ne peut pas modifier la note et l'avis de satisfaction" do
    sign_in users(:bond)
    intervention = interventions(:nouvelle_intervention)
    note_avant = intervention.note

    patch intervention_url(intervention), params: { intervention: { description: intervention.description, note: 5, avis: 'Excellent travail' } }

    intervention.reload
    assert_equal note_avant, intervention.note
    assert_not_equal 'Excellent travail', intervention.avis
  end

  # --- IDOR : absences ---

  test "un manager d'une autre organisation ne peut pas supprimer une absence" do
    sign_in users(:manager_marseille)
    absence = absences(:one)

    delete absence_url(absence)

    assert Absence.exists?(absence.id), "l'absence d'une autre organisation ne doit pas être supprimable"
  end

  test 'un manager de la même équipe peut supprimer une absence' do
    sign_in users(:hidalgo)
    absence = absences(:one)

    delete absence_url(absence)

    assert_not Absence.exists?(absence.id)
  end

  # --- IDOR : mouvements (matériel) inter-organisations ---

  test "réserver l'outil d'une autre organisation est impossible" do
    sign_in users(:bond)
    outil_marseille = Tool.create!(name: 'Karcher Marseille', organisation: organisations(:mairie_marseille))

    assert_no_difference 'Mouvement.count' do
      post reserve_tool_mouvements_url(tool_id: outil_marseille.id, date: Date.tomorrow.to_s)
      assert_response :not_found
    end
  end

  test "un agent ne peut pas libérer la réservation d'un autre utilisateur" do
    bond = users(:bond)
    réservation = tools(:tondeuse).mouvements.create!(état: :réservé, date: Date.tomorrow, user: users(:hidalgo))
    sign_in bond

    post libere_tool_mouvements_url(tool_id: tools(:tondeuse).id, date: Date.tomorrow.to_s, user_id: users(:hidalgo).id)

    assert Mouvement.exists?(réservation.id), 'seul un manager/admin peut libérer la réservation d’autrui'
  end

  # --- IDOR : messagerie inter-organisations ---

  test 'impossible d’envoyer un message à un utilisateur d’une autre organisation' do
    sign_in users(:hidalgo)

    assert_no_difference 'Message.count' do
      post messagerie_send_message_url, params: { message: 'fuite ?', to_id: users(:manager_marseille).id }
    end
  end

  test 'impossible de lire une conversation avec un utilisateur d’une autre organisation' do
    sign_in users(:hidalgo)

    get messagerie_conversation_url(to_id: users(:manager_marseille).id)

    assert_redirected_to messagerie_path
  end

  test 'le modèle Message refuse un destinataire d’une autre organisation (défense en profondeur)' do
    message = Message.new(from_user: users(:hidalgo), to_user: users(:manager_marseille), message: 'x')

    assert_not message.valid?
    assert_includes message.errors[:base], 'Destinataire injoignable'
  end

  # --- Import : plus aucune écriture dans public/ ---

  test "l'import XLS n'écrit plus de fichier dans public/" do
    sign_in users(:hidalgo)
    fichiers_avant = Dir[Rails.root.join('public', '*')].sort

    fixture = Rails.root.join('test', 'fixtures', 'files', 'import_users.xls')
    skip 'pas de fichier XLS de fixture' unless File.exist?(fixture)

    post import_do_users_url, params: { upload: fixture_file_upload(fixture, 'application/vnd.ms-excel') }

    assert_equal fichiers_avant, Dir[Rails.root.join('public', '*')].sort
  end
end
