# frozen_string_literal: true

require 'test_helper'

# Miroir de test/models/facture_test.rb (les deux models sont symétriques, #330/#333).
class CommandeTest < ActiveSupport::TestCase
  setup do
    @adherent = users(:weil)
    @service = services(:informatique) # mairie_paris
  end

  def build_commande(attrs = {})
    Commande.new({ adherent: @adherent, service: @service, intitulé: 'Commande test' }.merge(attrs))
  end

  # --- Validations ---

  test 'valide avec un intitulé' do
    assert build_commande.valid?
  end

  test 'invalide sans intitulé' do
    commande = build_commande(intitulé: nil)
    refute commande.valid?
    assert commande.errors[:intitulé].any?
  end

  test 'invalide sans adhérent' do
    commande = build_commande(adherent: nil)
    refute commande.valid?
    assert commande.errors[:adherent].any?
  end

  test 'invalide sans service' do
    commande = build_commande(service: nil)
    refute commande.valid?
    assert commande.errors[:service].any?
  end

  test "l'organisation est dérivée du service" do
    assert_equal @service.organisation, build_commande.organisation
  end

  # --- Workflow (gem workflow) ---

  test 'état initial : créé' do
    commande = build_commande
    assert_equal Commande::CREE, commande.workflow_state
    assert commande.créé?
  end

  test 'envoyer : créé -> envoyé' do
    commande = build_commande
    commande.save!
    assert commande.can_envoyer?
    commande.envoyer!
    assert commande.envoyé?
  end

  test 'depuis envoyé, on peut valider et refuser' do
    commande = build_commande
    commande.save!
    commande.envoyer!
    assert commande.can_valider?
    assert commande.can_refuser?
  end

  test 'valider : envoyé -> validé' do
    commande = build_commande
    commande.save!
    commande.envoyer!
    commande.valider!
    assert commande.validé?
  end

  test 'refuser : envoyé -> refusé' do
    commande = build_commande
    commande.save!
    commande.envoyer!
    commande.refuser!
    assert commande.refusé?
  end

  test 'archiver : validé -> archivé' do
    commande = build_commande
    commande.save!
    commande.envoyer!
    commande.valider!
    commande.archiver!
    assert commande.archivé?
  end

  test 'une commande refusée peut être renvoyée (refusé -> envoyé)' do
    commande = build_commande
    commande.save!
    commande.envoyer!
    commande.refuser!
    assert commande.can_envoyer?
    commande.envoyer!
    assert commande.envoyé?
  end

  test 'une commande refusée peut être archivée (refusé -> archivé)' do
    commande = build_commande
    commande.save!
    commande.envoyer!
    commande.refuser!
    commande.archiver!
    assert commande.archivé?
  end

  test 'garde de transition : impossible de valider depuis créé' do
    commande = build_commande
    commande.save!
    refute commande.can_valider?
    assert_raises(Workflow::NoTransitionAllowed) { commande.valider! }
  end

  test 'garde de transition : impossible de refuser depuis créé' do
    commande = build_commande
    commande.save!
    refute commande.can_refuser?
    assert_raises(Workflow::NoTransitionAllowed) { commande.refuser! }
  end

  # --- assign_ref (référence auto par année et par organisation) ---

  test "première commande d'une organisation : ref = année-1" do
    org = Organisation.create!(nom: 'Org neuve A')
    service = Service.create!(nom: 'Service A', organisation: org)
    commande = build_commande(service: service)
    commande.save!
    assert_equal "CM-#{Date.current.year}-1", commande.ref
  end

  test 'ref incrémentée au sein de la même organisation' do
    org = Organisation.create!(nom: 'Org neuve B')
    service = Service.create!(nom: 'Service B', organisation: org)
    build_commande(service: service).save!
    deuxième = build_commande(service: service)
    deuxième.save!
    assert_equal "CM-#{Date.current.year}-2", deuxième.ref
  end

  test 'ref réinitialisée indépendamment pour chaque organisation' do
    org1 = Organisation.create!(nom: 'Org neuve C')
    org2 = Organisation.create!(nom: 'Org neuve D')
    commande1 = build_commande(service: Service.create!(nom: 'Service C', organisation: org1))
    commande2 = build_commande(service: Service.create!(nom: 'Service D', organisation: org2))
    commande1.save!
    commande2.save!
    assert_equal "CM-#{Date.current.year}-1", commande1.ref
    assert_equal "CM-#{Date.current.year}-1", commande2.ref
  end

  test 'une ref fournie explicitement est respectée' do
    commande = build_commande(ref: 'REF-MANUELLE')
    commande.save!
    assert_equal 'REF-MANUELLE', commande.ref
  end

  # --- modifiable? ---

  test 'modifiable? vrai à létat créé' do
    assert build_commande.modifiable?
  end

  test 'modifiable? vrai à létat refusé' do
    commande = build_commande
    commande.save!
    commande.envoyer!
    commande.refuser!
    assert commande.modifiable?
  end

  test 'modifiable? faux aux états envoyé, validé, archivé' do
    commande = build_commande
    commande.save!
    commande.envoyer!
    refute commande.modifiable?
    commande.valider!
    refute commande.modifiable?
    commande.archiver!
    refute commande.modifiable?
  end

  # --- Helpers de présentation ---

  test 'pdf_filename utilise la référence' do
    assert_equal 'Commande-2026-9.pdf', build_commande(ref: '2026-9').pdf_filename
  end

  test 'style renvoie la classe CSS de létat courant' do
    commande = build_commande
    assert_equal 'badge badge-secondary rounded-full', commande.style
    commande.save!
    commande.envoyer!
    assert_equal 'badge-info text-white', commande.style
  end

  test 'workflow_state_humanized liste les états humanisés' do
    humanized = Commande.workflow_state_humanized
    assert_includes humanized, 'Créé'
    assert_includes humanized, 'Archivé'
  end

  test 'persist_workflow_state écrit létat et sauvegarde' do
    commande = build_commande
    commande.save!
    commande.persist_workflow_state(Commande::ENVOYE)
    assert_equal Commande::ENVOYE, commande.reload.workflow_state
  end

  # --- Transverses (friendly_id, discard, audited) ---

  test 'un slug est généré automatiquement' do
    commande = build_commande
    commande.save!
    assert commande.slug.present?
  end

  test 'deux commandes ont des slugs distincts' do
    c1 = build_commande
    c2 = build_commande
    c1.save!
    c2.save!
    refute_equal c1.slug, c2.slug
  end

  test 'discard exclut la commande du scope kept' do
    commande = build_commande
    commande.save!
    commande.discard
    assert commande.discarded?
    refute Commande.kept.exists?(commande.id)
  end

  test "persist_workflow_state est tracé dans l'audit trail" do
    commande = build_commande
    commande.save!
    assert_difference -> { commande.audits.count }, 1 do
      commande.persist_workflow_state(Commande::ENVOYE)
    end
    assert_includes commande.audits.last.audited_changes.keys, 'workflow_state'
  end
end
