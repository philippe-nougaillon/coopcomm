# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test 'absences imbriquées : ligne sans dates → ignorée' do
    agent = users(:bond)

    assert_no_difference('Absence.count') do
      agent.update(absences_attributes: { '0' => { du: '', au: '', motif: 'formation' } })
    end
  end

  # ==================== TESTS CRITIQUES ====================
  # Rattachement aux services :
  # L'organisation d'un utilisateur dérive de ses services : un compte sans service
  # n'appartient à aucune organisation, n'apparaît dans aucune liste (`by_service`
  # joint `user_services`) et fait échouer tout ce qui lit `current_organisation`.

  User.rôles.each_key do |rôle|
    test "must_have_at_least_one_service : un #{rôle} sans service → refusé" do
      user = nouveau(rôle: rôle)

      assert_not user.valid?
      assert_includes user.errors[:services], 'doit comporter au moins un service'
    end

    test "must_have_at_least_one_service : un #{rôle} avec un service → accepté" do
      assert nouveau(rôle: rôle, service_ids: [services(:informatique).id]).valid?
    end
  end

  test 'must_have_at_least_one_service : dernier service retiré → refusé' do
    agent = users(:martin_technique_paris)

    agent.user_services.each(&:mark_for_destruction)

    assert_not agent.valid?
    assert_includes agent.errors[:services], 'doit comporter au moins un service'
  end

  test 'must_have_at_least_one_service : service remplacé dans le même enregistrement → accepté' do
    agent = users(:martin_technique_paris)

    agent.user_services.load
    agent.user_services.first.mark_for_destruction
    agent.user_services.build(service: services(:informatique))

    assert agent.valid?, agent.errors.full_messages.to_s
  end

  test 'agent_must_have_exactly_one_service : agent créé avec deux services → refusé' do
    agent = nouveau(rôle: 'agent', service_ids: [services(:informatique).id, services(:technique).id])

    assert_not agent.valid?
    assert_includes agent.errors[:services], "ne doit comporter qu'un seul service pour un agent"
  end

  test 'agent_must_have_exactly_one_service : second service ajouté à un agent existant → refusé' do
    agent = users(:martin_technique_paris)

    agent.user_services.build(service: services(:informatique))

    assert_not agent.valid?
    assert_includes agent.errors[:services], "ne doit comporter qu'un seul service pour un agent"
  end

  test 'agent_must_have_exactly_one_service : multi-services basculé en agent → refusé' do
    utilisateur = users(:hidalgo)

    utilisateur.rôle = 'agent'

    assert_not utilisateur.valid?
    assert_includes utilisateur.errors[:services], "ne doit comporter qu'un seul service pour un agent"
  end

  test 'agent_must_have_exactly_one_service : adhérent, manager et administrateur → plusieurs services acceptés' do
    %w[adhérent manager administrateur].each do |rôle|
      user = nouveau(rôle: rôle, service_ids: [services(:informatique).id, services(:technique).id])

      assert user.valid?, "#{rôle} devrait pouvoir porter deux services : #{user.errors.full_messages}"
    end
  end

  # ==================== /TESTS CRITIQUES ====================

  # Liste PLATE (sans groupe) des intervenants d'un ou plusieurs services, au format
  # [["NOM Prénom", id], …], triée par nom puis prénom.

  test 'agents_for_services : service demandé → ses intervenants' do
    ids = User.agents_for_services([services(:technique)]).map(&:last)

    assert_includes ids, users(:martin_technique_paris).id, 'agent du service attendu'
    assert_includes ids, users(:hidalgo).id,                'manager du service attendu'
    assert_includes ids, users(:administrateur_paris).id,   'administrateur du service attendu'
    assert_includes ids, users(:nettoyage).id,              'agent du service attendu'
  end

  test 'agents_for_services : adhérent du service → exclu' do
    ids = User.agents_for_services([services(:informatique)]).map(&:last)

    assert_not_includes ids, users(:weil).id
  end

  test 'agents_for_services : intervenant d\'un autre service ou d\'une autre organisation → exclu' do
    ids = User.agents_for_services([services(:technique)]).map(&:last)

    assert_not_includes ids, users(:agent_whatsapp).id
    assert_not_includes ids, users(:agent_marseille).id
  end

  test 'agents_for_services : intervenant retenu → rendu au format [nom complet, id]' do
    cible = users(:martin_technique_paris)

    agent = User.agents_for_services([services(:technique)]).find { |_nom, id| id == cible.id }

    assert_not_nil agent
    nom, id = agent

    assert_equal "#{cible.nom} #{cible.prénom}", nom
    assert_kind_of Integer, id
  end

  test 'agents_for_services : intervenant de deux services demandés → rendu une seule fois' do
    ids = User.agents_for_services([services(:service_paris), services(:technique)]).map(&:last)

    assert_equal 1, ids.count(users(:hidalgo).id)
  end

  # Les noms (premier mot) sont distincts et purement ASCII ici : un tri
  # croissant stable est vérifiable sans dépendre de la collation SQL.
  test 'agents_for_services : plusieurs intervenants → triés par nom croissant' do
    noms = User.agents_for_services([services(:technique)]).map { |nom, _id| nom.split.first }

    assert_equal noms.sort, noms
  end

  test 'agents_for_services : administrateur hors du service demandé → proposé quand même' do
    admin = users(:philippe_super_admin)

    ids = User.agents_for_services([services(:technique)]).map(&:last)

    assert_not_includes admin.service_ids, services(:technique).id
    assert_includes ids, admin.id
  end

  test 'agents_for_services : administrateur d\'une autre organisation → exclu' do
    ids = User.agents_for_services([services(:service_marseille)]).map(&:last)

    assert_not_includes ids, users(:philippe_super_admin).id
    assert_not_includes ids, users(:administrateur_paris).id
  end

  test 'dispatch_email_to_nom_prénom : adresse avec séparateur → nom et prénom déduits' do
    utilisateur = User.new(email: 'dupont.jeanne@mairie.fr')

    utilisateur.dispatch_email_to_nom_prénom

    assert_equal 'DUPONT', utilisateur.nom
    assert_equal 'Jeanne', utilisateur.prénom
  end

  test 'dispatch_email_to_nom_prénom : adresse sans séparateur → prénom laissé vide' do
    utilisateur = User.new(email: 'accueil@mairie.fr')

    utilisateur.dispatch_email_to_nom_prénom

    assert_equal 'ACCUEIL', utilisateur.nom
    assert_nil utilisateur.prénom
  end

  test 'current_absence : sans période demandée → l\'absence du jour' do
    agent = users(:john_wick)
    absence = Absence.create!(user: agent, du: Date.new(2030, 9, 2), au: Date.new(2030, 9, 2), motif: :formation)

    assert_equal absence, agent.current_absence(Date.new(2030, 9, 2))
  end

  test 'current_absence : aucune absence à cette date → nil' do
    assert_nil users(:john_wick).current_absence(Date.new(2030, 9, 3))
  end

  test 'current_absence : absence journée entière → répond à n\'importe quelle période' do
    agent = users(:john_wick)
    absence = Absence.create!(user: agent, du: Date.new(2030, 9, 4), au: Date.new(2030, 9, 4), motif: :formation)

    assert_equal absence, agent.current_absence(Date.new(2030, 9, 4), :matin)
    assert_equal absence, agent.current_absence(Date.new(2030, 9, 4), :apres_midi)
  end

  test 'current_absence : absence du matin → répond au matin, pas à l\'après-midi' do
    agent = users(:john_wick)
    absence = Absence.create!(user: agent, du: Date.new(2030, 9, 5), au: Date.new(2030, 9, 5),
                              motif: :formation, matin: true, après_midi: false)

    assert_equal absence, agent.current_absence(Date.new(2030, 9, 5), :matin)
    assert_nil agent.current_absence(Date.new(2030, 9, 5), :apres_midi)
  end

  test 'current_absence : absence de l\'après-midi → répond à l\'après-midi, pas au matin' do
    agent = users(:john_wick)
    absence = Absence.create!(user: agent, du: Date.new(2030, 9, 6), au: Date.new(2030, 9, 6),
                              motif: :formation, matin: false, après_midi: true)

    assert_equal absence, agent.current_absence(Date.new(2030, 9, 6), :apres_midi)
    assert_nil agent.current_absence(Date.new(2030, 9, 6), :matin)
  end

  test 'absent? : absence du matin → absent le matin, présent l\'après-midi' do
    agent = users(:john_wick)
    Absence.create!(user: agent, du: Date.new(2030, 9, 7), au: Date.new(2030, 9, 7),
                    motif: :formation, matin: true, après_midi: false)

    assert agent.absent?(Date.new(2030, 9, 7), :matin)
    assert_not agent.absent?(Date.new(2030, 9, 7), :apres_midi)
  end

  test 'intervention_en_cours : pointage ouvert sur le créneau courant → l\'intervention' do
    agent = users(:martin_technique_paris)
    en_cours = Intervention.create!(
      description: 'Pointage ouvert', adherent: users(:weil), service: services(:technique),
      workflow_state: 'nouveau', début_prévue: 1.hour.ago, fin_prévue: 1.hour.from_now,
      agents: [agent], slug: SecureRandom.uuid
    )

    assert_equal en_cours, agent.intervention_en_cours
  end

  test 'intervention_en_cours : aucune intervention sur le créneau courant → nil' do
    assert_nil users(:john_wick).intervention_en_cours
  end

  test 'assignable_roles : manager → le rôle agent seulement' do
    assert_equal ['agent'], users(:hidalgo).assignable_roles
  end

  test 'assignable_roles : agent → le rôle agent seulement' do
    assert_equal ['agent'], users(:bond).assignable_roles
  end

  test 'assignable_roles : administrateur → tous les rôles' do
    assert_equal User.rôles.keys, users(:administrateur_paris).assignable_roles
  end

  # Cœur du « re-scan » du QRCode : retrouve l'intervention fille EN COURS (état
  # « nouveau ») de CET agent, datée d'AUJOURD'HUI, pour le modèle scanné.

  test 'find_current_intervention : fille du jour de l\'agent en état nouveau → trouvée' do
    mère = interventions(:intervention_repete)
    agent = users(:martin_technique_paris)
    fille = mère.create_next_intervention(mère, agent)

    assert_equal fille, agent.find_current_intervention(mère.slug)
  end

  test 'find_current_intervention : fille d\'un autre agent → nil' do
    mère = interventions(:intervention_repete)
    mère.create_next_intervention(mère, users(:bond))

    assert_nil users(:martin_technique_paris).find_current_intervention(mère.slug)
  end

  test 'find_current_intervention : fille datée d\'un autre jour → nil' do
    mère = interventions(:intervention_repete)
    agent = users(:martin_technique_paris)
    fille = mère.create_next_intervention(mère, agent)
    fille.update_columns(début: 1.day.ago)

    assert_nil agent.find_current_intervention(mère.slug)
  end

  test 'find_current_intervention : fille déjà terminée → nil' do
    mère = interventions(:intervention_repete)
    agent = users(:martin_technique_paris)
    fille = mère.create_next_intervention(mère, agent)
    fille.update_columns(workflow_state: 'terminé')

    assert_nil agent.find_current_intervention(mère.slug)
  end

  test 'find_current_intervention : plusieurs filles ouvertes → la plus récemment mise à jour' do
    mère = interventions(:intervention_repete)
    agent = users(:martin_technique_paris)
    récente = mère.create_next_intervention(mère, agent)
    mère.create_next_intervention(mère, agent)
    récente.touch

    assert_equal récente, agent.find_current_intervention(mère.slug)
  end

  private

  # ==================== TESTS CRITIQUES ====================
    # Rattachement aux services :
  # L'organisation d'un utilisateur dérive de ses services : un compte sans service
  # n'appartient à aucune organisation, n'apparaît dans aucune liste (`by_service`
  # joint `user_services`) et fait échouer tout ce qui lit `current_organisation`.

  def nouveau(rôle:, service_ids: [])
    User.new(nom: 'Essai', prénom: 'Service', email: "essai-#{SecureRandom.hex(4)}@example.test",
             rôle: rôle, password: 'qtDug$d843sqACz?V', service_ids: service_ids,
             address: 'Mairie de Paris', latitude: 48.85, longitude: 2.35)
  end

  User.rôles.each_key do |rôle|
    test "un #{rôle} sans service est invalide" do
      user = nouveau(rôle: rôle)

      assert_not user.valid?
      assert_includes user.errors[:services], 'doit comporter au moins un service'
    end

    test "un #{rôle} avec un service est valide" do
      assert nouveau(rôle: rôle, service_ids: [services(:informatique).id]).valid?
    end
  end

  test 'un agent avec deux services est invalide' do
    agent = nouveau(rôle: 'agent', service_ids: [services(:informatique).id, services(:technique).id])

    assert_not agent.valid?
    assert_includes agent.errors[:services], "ne doit comporter qu'un seul service pour un agent"
  end

  test 'un adhérent, un manager et un administrateur peuvent porter plusieurs services' do
    %w[adhérent manager administrateur].each do |rôle|
      user = nouveau(rôle: rôle, service_ids: [services(:informatique).id, services(:technique).id])

      assert user.valid?, "#{rôle} devrait pouvoir porter deux services : #{user.errors.full_messages}"
    end
  end

  test 'un agent existant ne peut pas recevoir un second service' do
    agent = users(:martin_technique_paris)

    agent.user_services.build(service: services(:informatique))

    assert_not agent.valid?
    assert_includes agent.errors[:services], "ne doit comporter qu'un seul service pour un agent"
  end

  test 'retirer le dernier service d’un utilisateur le rend invalide' do
    agent = users(:martin_technique_paris)

    agent.user_services.each { |us| us.mark_for_destruction }

    assert_not agent.valid?
    assert_includes agent.errors[:services], 'doit comporter au moins un service'
  end

  test 'un service marqué pour destruction ne compte pas dans le total de l’agent' do
    agent = users(:martin_technique_paris)

    agent.user_services.load # sinon `first` renvoie une instance hors du target
    agent.user_services.first.mark_for_destruction
    agent.user_services.build(service: services(:informatique))

    assert agent.valid?, agent.errors.full_messages.to_s
  end

  test 'changer un adhérent en agent avec deux services devient invalide' do
    adhérent = users(:hidalgo) # manager multi-services
    adhérent.rôle = 'agent'

    assert_not adhérent.valid?
    assert_includes adhérent.errors[:services], "ne doit comporter qu'un seul service pour un agent"
  end

  # Sans `dependent: :destroy` sur la through, Rails retire la ligne de liaison
  # par delete_all : aucun callback, donc aucune trace du service retiré.
  test 'retirer un service à un utilisateur laisse une trace dans l\'audit' do
    manager = users(:hidalgo)
    retiré = manager.services.first
    restants = manager.services.where.not(id: retiré.id)

    assert_difference -> { Audited::Audit.where(auditable_type: 'UserService', action: 'destroy').count }, 1 do
      manager.update!(service_ids: restants.ids)
    end

    audit = Audited::Audit.where(auditable_type: 'UserService', action: 'destroy').last

    assert_equal retiré.id, audit.audited_changes['service_id']
    assert_equal manager.id, audit.associated_id
  end

  # ==================== /TESTS CRITIQUES ====================
end
