# frozen_string_literal: true

require 'test_helper'

class CotationTest < ActiveSupport::TestCase
  setup do
    @adherent = users(:weil)
    @service = services(:informatique)
  end

  test 'une ligne sans prestation soumise avec la cotation est ignorée' do
    cotation = build_cotation(cotation_lignes_attributes: { '0' => { qté: 5 } })

    cotation.save!

    assert_equal 0, cotation.cotation_lignes.count
  end

  test 'une ligne avec prestation soumise avec la cotation est créée avec elle' do
    cotation = build_cotation(cotation_lignes_attributes: {
                                '0' => { prestation_id: prestations(:nettoyage_bureaux).id, qté: 2 }
                              })

    cotation.save!

    assert_equal 1, cotation.cotation_lignes.count
  end

  test 'une ligne existante marquée pour suppression est retirée de la cotation' do
    cotation = build_cotation
    cotation.save!
    ligne = cotation.cotation_lignes.create!(prestation: prestations(:nettoyage_bureaux), qté: 1)

    cotation.update!(cotation_lignes_attributes: { '0' => { id: ligne.id, _destroy: '1' } })

    assert_equal 0, cotation.cotation_lignes.count
  end

  test 'une cotation créée reçoit une référence au format CO-AAAA-N' do
    cotation = build_cotation

    cotation.save!

    assert_match(/\ACO-#{Date.current.year}-\d+\z/, cotation.ref)
  end

  test "la référence d'une cotation ne change pas à la mise à jour" do
    cotation = build_cotation
    cotation.save!
    ref = cotation.ref

    cotation.update!(intitulé: 'Nouveau titre')

    assert_equal ref, cotation.ref
  end

  test 'la seconde cotation de la même organisation reçoit le numéro suivant' do
    première = build_cotation
    première.save!
    seconde = build_cotation
    seconde.save!

    assert_equal première.ref.split('-').last.to_i + 1, seconde.ref.split('-').last.to_i
  end

  test 'la cotation la plus récemment mise à jour est listée en tête' do
    ancienne = build_cotation
    ancienne.save!
    récente = build_cotation
    récente.save!
    ancienne.update_columns(updated_at: 2.days.ago)

    ordonnées = Cotation.ordered.to_a

    assert_operator ordonnées.index(récente), :<, ordonnées.index(ancienne)
  end

  test "chaque état d'une cotation se distingue à l'écran par la classe de son badge" do
    cotation = build_cotation

    assert_equal 'badge badge-secondary ', cotation.style

    cotation.save!
    cotation.envoyer!

    assert_equal 'badge badge-primary ', cotation.style

    cotation.signer!

    assert_equal 'badge badge-outline badge-info ', cotation.style
  end

  test "les états du workflow d'une cotation ont un libellé humanisé, dans l'ordre du workflow" do
    assert_equal %w[Créé Envoyé Signé Validé Refusé Archivé], Cotation.workflow_state_humanized
  end

  test "une cotation à l'état créé est modifiable" do
    assert build_cotation.modifiable?
  end

  test "une cotation à l'état envoyé n'est pas modifiable" do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!

    assert_not cotation.modifiable?
  end

  test "une cotation à l'état signé n'est pas modifiable" do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!
    cotation.signer!

    assert_not cotation.modifiable?
  end

  test "une cotation à l'état validé n'est pas modifiable" do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!
    cotation.signer!
    cotation.valider!

    assert_not cotation.modifiable?
  end

  test "une cotation à l'état refusé est modifiable, pour être corrigée avant renvoi" do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!
    cotation.refuser!

    assert cotation.modifiable?
  end

  test "une cotation à l'état archivé n'est pas modifiable" do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!
    cotation.signer!
    cotation.valider!
    cotation.archiver!

    assert_not cotation.modifiable?
  end

  test "le nom du fichier PDF d'une cotation est bâti sur sa référence" do
    cotation = build_cotation
    cotation.save!

    assert_equal "Cotation-#{cotation.ref}.pdf", cotation.pdf_filename
  end

  test 'un administrateur voit les cotations de son organisation' do
    cotation = build_cotation
    cotation.save!

    assert_includes Cotation.visible_to(users(:administrateur_paris)), cotation
  end

  test 'un manager voit les cotations de ses services' do
    cotation = build_cotation
    cotation.save!

    assert_includes Cotation.visible_to(users(:hidalgo)), cotation
  end

  test "un manager ne voit pas les cotations d'une autre organisation" do
    cotation = build_cotation
    cotation.save!

    assert_not_includes Cotation.visible_to(users(:manager_marseille)), cotation
  end

  test 'un adhérent voit ses cotations envoyées, jamais un brouillon' do
    sienne = build_cotation
    sienne.save!

    assert_not_includes Cotation.visible_to(@adherent), sienne

    sienne.envoyer!

    assert_includes Cotation.visible_to(@adherent), sienne
  end

  test "un adhérent ne voit jamais la cotation envoyée d'un autre adhérent de son organisation (critique)" do
    assert_not_includes Cotation.visible_to(@adherent), cotations(:cotation_envoyée)
  end

  private

  def build_cotation(attrs = {})
    Cotation.new({ adherent: @adherent, service: @service, intitulé: 'Devis' }.merge(attrs))
  end
end
