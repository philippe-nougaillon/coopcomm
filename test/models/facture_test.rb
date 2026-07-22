# frozen_string_literal: true

require 'test_helper'

class FactureTest < ActiveSupport::TestCase
  setup do
    @adherent = users(:weil)
    @service = services(:informatique) # mairie_paris
  end

  def build_facture(attrs = {})
    Facture.new({ adherent: @adherent, service: @service, intitulé: 'Facture test' }.merge(attrs))
  end

  # --- Validations ---

  test 'valide avec un intitulé' do
    assert build_facture.valid?
  end

  test 'invalide sans intitulé' do
    facture = build_facture(intitulé: nil)
    refute facture.valid?
    assert facture.errors[:intitulé].any?
  end

  test 'invalide sans adhérent' do
    facture = build_facture(adherent: nil)
    refute facture.valid?
    assert facture.errors[:adherent].any?
  end

  test 'invalide sans service' do
    facture = build_facture(service: nil)
    refute facture.valid?
    assert facture.errors[:service].any?
  end

  test "l'organisation est dérivée du service" do
    assert_equal @service.organisation, build_facture.organisation
  end

  # --- Workflow (gem workflow) ---

  test 'état initial : créé' do
    facture = build_facture
    assert_equal Facture::CREE, facture.workflow_state
    assert facture.créé?
  end

  test 'envoyer : créé -> envoyé' do
    facture = build_facture
    facture.save!
    assert facture.can_envoyer?
    facture.envoyer!
    assert facture.envoyé?
  end

  test 'depuis envoyé, on peut valider et refuser' do
    facture = build_facture
    facture.save!
    facture.envoyer!
    assert facture.can_valider?
    assert facture.can_refuser?
  end

  test 'valider : envoyé -> validé' do
    facture = build_facture
    facture.save!
    facture.envoyer!
    facture.valider!
    assert facture.validé?
  end

  test 'refuser : envoyé -> refusé' do
    facture = build_facture
    facture.save!
    facture.envoyer!
    facture.refuser!
    assert facture.refusé?
  end

  test 'archiver : validé -> archivé' do
    facture = build_facture
    facture.save!
    facture.envoyer!
    facture.valider!
    facture.archiver!
    assert facture.archivé?
  end

  test 'une facture refusée peut être renvoyée (refusé -> envoyé)' do
    facture = build_facture
    facture.save!
    facture.envoyer!
    facture.refuser!
    assert facture.can_envoyer?
    facture.envoyer!
    assert facture.envoyé?
  end

  test 'une facture refusée peut être archivée (refusé -> archivé)' do
    facture = build_facture
    facture.save!
    facture.envoyer!
    facture.refuser!
    facture.archiver!
    assert facture.archivé?
  end

  test 'garde de transition : impossible de valider depuis créé' do
    facture = build_facture
    facture.save!
    refute facture.can_valider?
    assert_raises(Workflow::NoTransitionAllowed) { facture.valider! }
  end

  test 'garde de transition : impossible de refuser depuis créé' do
    facture = build_facture
    facture.save!
    refute facture.can_refuser?
    assert_raises(Workflow::NoTransitionAllowed) { facture.refuser! }
  end

  # --- assign_ref (référence auto par année et par organisation) ---

  test "première facture d'une organisation : ref = année-1" do
    org = Organisation.create!(nom: 'Org neuve A')
    service = Service.create!(nom: 'Service A', organisation: org)
    facture = build_facture(service: service)
    facture.save!
    assert_equal "FA-#{Date.current.year}-1", facture.ref
  end

  test 'ref incrémentée au sein de la même organisation' do
    org = Organisation.create!(nom: 'Org neuve B')
    service = Service.create!(nom: 'Service B', organisation: org)
    build_facture(service: service).save!
    deuxième = build_facture(service: service)
    deuxième.save!
    assert_equal "FA-#{Date.current.year}-2", deuxième.ref
  end

  test 'ref réinitialisée indépendamment pour chaque organisation' do
    org1 = Organisation.create!(nom: 'Org neuve C')
    org2 = Organisation.create!(nom: 'Org neuve D')
    facture1 = build_facture(service: Service.create!(nom: 'Service C', organisation: org1))
    facture2 = build_facture(service: Service.create!(nom: 'Service D', organisation: org2))
    facture1.save!
    facture2.save!
    assert_equal "FA-#{Date.current.year}-1", facture1.ref
    assert_equal "FA-#{Date.current.year}-1", facture2.ref
  end

  test 'une ref fournie explicitement est respectée' do
    facture = build_facture(ref: 'REF-MANUELLE')
    facture.save!
    assert_equal 'REF-MANUELLE', facture.ref
  end

  # --- modifiable? ---

  test 'modifiable? vrai à létat créé' do
    assert build_facture.modifiable?
  end

  test 'modifiable? vrai à létat refusé' do
    facture = build_facture
    facture.save!
    facture.envoyer!
    facture.refuser!
    assert facture.modifiable?
  end

  test 'modifiable? faux aux états envoyé, validé, archivé' do
    facture = build_facture
    facture.save!
    facture.envoyer!
    refute facture.modifiable?
    facture.valider!
    refute facture.modifiable?
    facture.archiver!
    refute facture.modifiable?
  end

  # --- Helpers de présentation ---

  test 'pdf_filename utilise la référence' do
    assert_equal 'Facture-2026-9.pdf', build_facture(ref: '2026-9').pdf_filename
  end

  test 'style renvoie la classe CSS de létat courant' do
    facture = build_facture
    assert_equal 'badge badge-secondary rounded-full', facture.style
    facture.save!
    facture.envoyer!
    assert_equal 'badge badge-primary rounded-full', facture.style
  end

  test 'workflow_state_humanized liste les états humanisés' do
    humanized = Facture.workflow_state_humanized
    assert_includes humanized, 'Créé'
    assert_includes humanized, 'Archivé'
  end

  test 'persist_workflow_state écrit létat et sauvegarde' do
    facture = build_facture
    facture.save!
    facture.persist_workflow_state(Facture::ENVOYE)
    assert_equal Facture::ENVOYE, facture.reload.workflow_state
  end

  # --- Transverses (friendly_id, discard, audited) ---

  test 'un slug est généré automatiquement' do
    facture = build_facture
    facture.save!
    assert facture.slug.present?
  end

  test 'deux factures ont des slugs distincts' do
    f1 = build_facture
    f2 = build_facture
    f1.save!
    f2.save!
    refute_equal f1.slug, f2.slug
  end

  test 'discard exclut la facture du scope kept' do
    facture = build_facture
    facture.save!
    facture.discard
    assert facture.discarded?
    refute Facture.kept.exists?(facture.id)
  end

  test "persist_workflow_state est tracé dans l'audit trail" do
    facture = build_facture
    facture.save!
    assert_difference -> { facture.audits.count }, 1 do
      facture.persist_workflow_state(Facture::ENVOYE)
    end
    assert_includes facture.audits.last.audited_changes.keys, 'workflow_state'
  end
end
