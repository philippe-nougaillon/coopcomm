# frozen_string_literal: true

require 'test_helper'

class CotationTest < ActiveSupport::TestCase
  setup do
    @adherent = users(:weil)
    @service = services(:informatique)
  end

  test 'lignes imbriquées : ligne sans prestation → ignorée' do
    cotation = build_cotation(cotation_lignes_attributes: { '0' => { qté: 5 } })

    cotation.save!

    assert_equal 0, cotation.cotation_lignes.count
  end

  test 'lignes imbriquées : ligne avec prestation → créée avec la cotation' do
    cotation = build_cotation(cotation_lignes_attributes: {
                                '0' => { prestation_id: prestations(:nettoyage_bureaux).id, qté: 2 }
                              })

    cotation.save!

    assert_equal 1, cotation.cotation_lignes.count
  end

  test 'lignes imbriquées : _destroy sur une ligne existante → ligne supprimée' do
    cotation = build_cotation
    cotation.save!
    ligne = cotation.cotation_lignes.create!(prestation: prestations(:nettoyage_bureaux), qté: 1)

    cotation.update!(cotation_lignes_attributes: { '0' => { id: ligne.id, _destroy: '1' } })

    assert_equal 0, cotation.cotation_lignes.count
  end

  test 'assign_ref : création → référence au format CO-AAAA-N' do
    cotation = build_cotation

    cotation.save!

    assert_match(/\ACO-#{Date.current.year}-\d+\z/, cotation.ref)
  end

  test 'assign_ref : mise à jour → référence inchangée' do
    cotation = build_cotation
    cotation.save!
    ref = cotation.ref

    cotation.update!(intitulé: 'Nouveau titre')

    assert_equal ref, cotation.ref
  end

  test 'assign_ref : seconde cotation de l\'organisation → numéro incrémenté' do
    première = build_cotation
    première.save!
    seconde = build_cotation
    seconde.save!

    assert_equal première.ref.split('-').last.to_i + 1, seconde.ref.split('-').last.to_i
  end

  test 'style : chaque état → la classe du badge qui le distingue à l\'écran' do
    cotation = build_cotation

    assert_equal 'badge badge-secondary rounded-full', cotation.style

    cotation.save!
    cotation.envoyer!

    assert_equal 'badge badge-primary rounded-full', cotation.style

    cotation.signer!

    assert_equal 'badge badge-outline badge-info rounded-full ', cotation.style
  end

  test 'workflow_state_humanized : appel → les états humanisés dans l\'ordre du workflow' do
    assert_equal %w[Créé Envoyé Signé Validé Refusé Archivé], Cotation.workflow_state_humanized
  end

  test 'modifiable? : état créé → vrai' do
    assert build_cotation.modifiable?
  end

  test 'modifiable? : état envoyé → faux' do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!

    assert_not cotation.modifiable?
  end

  test 'modifiable? : état signé → faux' do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!
    cotation.signer!

    assert_not cotation.modifiable?
  end

  test 'modifiable? : état validé → faux' do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!
    cotation.signer!
    cotation.valider!

    assert_not cotation.modifiable?
  end

  test 'modifiable? : état refusé → vrai, pour corriger avant de renvoyer' do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!
    cotation.refuser!

    assert cotation.modifiable?
  end

  test 'modifiable? : état archivé → faux' do
    cotation = build_cotation
    cotation.save!
    cotation.envoyer!
    cotation.signer!
    cotation.valider!
    cotation.archiver!

    assert_not cotation.modifiable?
  end

  test 'pdf_filename : cotation référencée → nom de fichier bâti sur la référence' do
    cotation = build_cotation
    cotation.save!

    assert_equal "Cotation-#{cotation.ref}.pdf", cotation.pdf_filename
  end

  test 'visible_to : administrateur → les cotations de son organisation' do
    cotation = build_cotation
    cotation.save!

    assert_includes Cotation.visible_to(users(:administrateur_paris)), cotation
  end

  test 'visible_to : manager → les cotations des services qu\'il gère' do
    cotation = build_cotation
    cotation.save!

    assert_includes Cotation.visible_to(users(:hidalgo)), cotation
  end

  test 'visible_to : manager d\'une autre organisation → aucune' do
    cotation = build_cotation
    cotation.save!

    assert_not_includes Cotation.visible_to(users(:manager_marseille)), cotation
  end

  test 'visible_to : adhérent → ses cotations envoyées, jamais un brouillon ni celle d\'un autre' do
    sienne = build_cotation
    sienne.save!

    visibles = Cotation.visible_to(@adherent)

    assert_not_includes visibles, sienne

    sienne.envoyer!

    assert_includes Cotation.visible_to(@adherent), sienne
    assert_not_includes visibles, cotations(:cotation_marseille)
  end

  private

  def build_cotation(attrs = {})
    Cotation.new({ adherent: @adherent, service: @service, intitulé: 'Devis' }.merge(attrs))
  end
end
