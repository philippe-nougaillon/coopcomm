# frozen_string_literal: true

require 'test_helper'

class CotationTest < ActiveSupport::TestCase
  setup do
    @adherent = users(:weil)
    @service = services(:informatique)
  end

  def build_cotation(attrs = {})
    Cotation.new({ adherent: @adherent, service: @service, intitulé: 'Devis' }.merge(attrs))
  end

  test 'valide avec un intitulé' do
    assert build_cotation.valid?
  end

  test 'invalide sans intitulé' do
    cotation = build_cotation(intitulé: nil)
    refute cotation.valid?
    assert cotation.errors[:intitulé].any?
  end

  # --- Workflow (gem workflow) ---

  test 'état initial : créé' do
    assert_equal 'créé', build_cotation.workflow_state
    assert build_cotation.créé?
  end

  test 'envoyer : créé -> envoyé' do
    cotation = build_cotation
    cotation.save!
    assert cotation.can_envoyer?
    cotation.envoyer!
    assert cotation.envoyé?
  end

  test 'depuis envoyé, on peut valider et refuser' do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!
    assert cotation.can_valider?
    assert cotation.can_refuser?
  end

  test 'valider : envoyé -> validé' do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!
    cotation.valider!
    assert cotation.validé?
  end

  test 'refuser : envoyé -> refusé' do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!
    cotation.refuser!
    assert cotation.refusé?
  end

  test 'on ne peut pas valider directement depuis créé' do
    cotation = build_cotation
    cotation.save!
    refute cotation.can_valider?
  end

  test 'renvoyer : refusé -> envoyé (corriger puis renvoyer)' do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!
    cotation.refuser!
    assert cotation.can_envoyer?
    cotation.envoyer!
    assert cotation.envoyé?
  end

  # --- modifiable? (verrou d'édition après envoi) ---

  test "modifiable? vrai à l'état créé" do
    assert build_cotation.modifiable?
  end

  test "modifiable? vrai à l'état refusé" do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!
    cotation.refuser!
    assert cotation.modifiable?
  end

  test "modifiable? faux à l'état envoyé" do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!
    refute cotation.modifiable?
  end

  test "modifiable? faux à l'état validé" do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!
    cotation.valider!
    refute cotation.modifiable?
  end

  test "modifiable? faux à l'état archivé" do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!
    cotation.valider!
    cotation.archiver!
    refute cotation.modifiable?
  end

  # --- Référence / périmètre / discard ---

  test 'ref générée à la création au format AAAA-N' do
    cotation = build_cotation
    cotation.save!
    assert_match(/\A#{Date.current.year}-\d+\z/, cotation.ref)
  end

  test "la ref n'est pas modifiée lors d'une mise à jour" do
    cotation = build_cotation
    cotation.save!
    ref = cotation.ref
    cotation.update!(intitulé: 'Nouveau titre')
    assert_equal ref, cotation.ref
  end

  test "la ref est incrémentée au sein de l'organisation" do
    premiere = build_cotation
    premiere.save!
    seconde = build_cotation
    seconde.save!
    n1 = premiere.ref.split('-').last.to_i
    n2 = seconde.ref.split('-').last.to_i
    assert_equal n1 + 1, n2
  end

  test 'organisation dérivée du service' do
    cotation = build_cotation
    cotation.save!
    assert_equal @service.organisation, cotation.organisation
  end

  test 'visible_to un administrateur de la même organisation' do
    cotation = build_cotation
    cotation.save!
    assert_includes Cotation.visible_to(users(:administrateur_paris)), cotation
  end

  test 'visible_to un manager possédant le service' do
    cotation = build_cotation
    cotation.save!
    # hidalgo gère le service informatique
    assert_includes Cotation.visible_to(users(:hidalgo)), cotation
  end

  test "non visible pour un manager d'une autre organisation" do
    cotation = build_cotation
    cotation.save!
    refute_includes Cotation.visible_to(users(:manager_marseille)), cotation
  end

  test 'aucune cotation visible pour un adhérent' do
    build_cotation.save!
    assert_empty Cotation.visible_to(@adherent)
  end

  test 'discard (soft delete)' do
    cotation = build_cotation
    cotation.save!
    cotation.discard
    assert cotation.discarded?
    refute_includes Cotation.kept, cotation
  end

  # --- Workflow : archivage (états terminaux) ---

  test 'archiver : validé -> archivé' do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!
    cotation.valider!
    assert cotation.can_archiver?
    cotation.archiver!
    assert cotation.archivé?
  end

  test 'archiver : refusé -> archivé' do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!
    cotation.refuser!
    assert cotation.can_archiver?
    cotation.archiver!
    assert cotation.archivé?
  end

  test "l'état archivé est terminal (aucune transition sortante)" do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!
    cotation.valider!
    cotation.archiver!
    refute cotation.can_envoyer?
    refute cotation.can_valider?
    refute cotation.can_refuser?
    refute cotation.can_archiver?
  end

  # --- Attributs imbriqués (cotation_lignes) ---

  test 'une ligne sans prestation_id est ignorée (reject_if)' do
    cotation = build_cotation(cotation_lignes_attributes: { '0' => { qté: 5 } })
    cotation.save!
    assert_equal 0, cotation.cotation_lignes.count
  end

  test 'une ligne avec prestation_id est créée via les attributs imbriqués' do
    cotation = build_cotation(cotation_lignes_attributes: {
                                '0' => { prestation_id: prestations(:nettoyage_bureaux).id, qté: 2 }
                              })
    cotation.save!
    assert_equal 1, cotation.cotation_lignes.count
  end

  test 'allow_destroy : _destroy supprime une ligne existante' do
    cotation = build_cotation
    cotation.save!
    ligne = cotation.cotation_lignes.create!(prestation: prestations(:nettoyage_bureaux), qté: 1)
    cotation.update!(cotation_lignes_attributes: { '0' => { id: ligne.id, _destroy: '1' } })
    assert_equal 0, cotation.cotation_lignes.count
  end

  # --- Présentation ---

  test "style renvoie la classe CSS du badge de l'état courant" do
    cotation = build_cotation
    assert_equal 'badge-ghost', cotation.style # créé
    cotation.save!
    cotation.envoyer!
    assert_equal 'badge-info text-white', cotation.style # envoyé
  end

  test "workflow_state_humanized liste les états humanisés dans l'ordre du workflow" do
    assert_equal %w[Créé Envoyé Validé Refusé Archivé], Cotation.workflow_state_humanized
  end

  test 'pdf_filename est basé sur la référence' do
    cotation = build_cotation
    cotation.save!
    assert_equal "Cotation-#{cotation.ref}.pdf", cotation.pdf_filename
  end

  # --- Persistance d'état & audit trail ---

  test "persist_workflow_state met à jour et persiste l'état" do
    cotation = build_cotation
    cotation.save!
    cotation.persist_workflow_state('envoyé')
    assert_equal 'envoyé', cotation.reload.workflow_state
  end

  test 'auditée : la création est tracée' do
    cotation = build_cotation
    cotation.save!
    assert_equal 1, cotation.audits.count
    assert_equal 'create', cotation.audits.last.action
  end

  test "auditée : un changement d'état du workflow est tracé" do
    cotation = build_cotation
    cotation.save!
    assert_difference -> { cotation.audits.count }, 1 do
      cotation.envoyer!
    end
    assert_equal 'update', cotation.audits.last.action
    assert_includes cotation.audits.last.audited_changes.keys, 'workflow_state'
  end

  test "auditée : les audits sont associés à l'adhérent" do
    cotation = build_cotation
    cotation.save!
    assert_equal cotation.adherent, cotation.audits.last.associated
  end
end
