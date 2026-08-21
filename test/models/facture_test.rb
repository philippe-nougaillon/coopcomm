# frozen_string_literal: true

require 'test_helper'

# Miroir de test/models/commande_test.rb (modèles symétriques).
class FactureTest < ActiveSupport::TestCase
  setup do
    @adherent = users(:weil)
    @service = services(:informatique)
  end

  test 'assign_ref : première facture d\'une organisation → FA-AAAA-1' do
    org = Organisation.create!(nom: 'Org neuve E')
    service = Service.create!(nom: 'Service E', organisation: org)
    facture = build_facture(service: service)

    facture.save!

    assert_equal "FA-#{Date.current.year}-1", facture.ref
  end

  test 'assign_ref : seconde facture de la même organisation → numéro incrémenté' do
    org = Organisation.create!(nom: 'Org neuve F')
    service = Service.create!(nom: 'Service F', organisation: org)
    build_facture(service: service).save!
    deuxième = build_facture(service: service)

    deuxième.save!

    assert_equal "FA-#{Date.current.year}-2", deuxième.ref
  end

  test 'assign_ref : deux organisations → numérotations indépendantes' do
    org1 = Organisation.create!(nom: 'Org neuve G')
    org2 = Organisation.create!(nom: 'Org neuve H')
    facture1 = build_facture(service: Service.create!(nom: 'Service G', organisation: org1))
    facture2 = build_facture(service: Service.create!(nom: 'Service H', organisation: org2))

    facture1.save!
    facture2.save!

    assert_equal "FA-#{Date.current.year}-1", facture1.ref
    assert_equal "FA-#{Date.current.year}-1", facture2.ref
  end

  test 'assign_ref : référence fournie explicitement → conservée' do
    facture = build_facture(ref: 'REF-MANUELLE')

    facture.save!

    assert_equal 'REF-MANUELLE', facture.ref
  end

  test 'style : chaque état → la classe du badge qui le distingue à l\'écran' do
    facture = build_facture

    assert_equal 'badge badge-secondary', facture.style

    facture.save!
    facture.envoyer!

    assert_equal 'badge badge-primary ', facture.style
  end

  test 'workflow_state_humanized : appel → les états humanisés du workflow' do
    humanized = Facture.workflow_state_humanized

    assert_includes humanized, 'Créé'
    assert_includes humanized, 'Archivé'
  end

  test 'modifiable? : état créé → vrai' do
    assert build_facture.modifiable?
  end

  test 'modifiable? : états envoyé, validé et archivé → faux' do
    facture = build_facture
    facture.save!

    facture.envoyer!

    assert_not facture.modifiable?

    facture.valider!

    assert_not facture.modifiable?

    facture.archiver!

    assert_not facture.modifiable?
  end

  test 'modifiable? : état refusé → vrai, pour corriger avant de renvoyer' do
    facture = build_facture
    facture.save!
    facture.envoyer!
    facture.refuser!

    assert facture.modifiable?
  end

  test 'pdf_filename : facture référencée → nom de fichier bâti sur la référence' do
    assert_equal 'Facture-2026-9.pdf', build_facture(ref: '2026-9').pdf_filename
  end

  test 'visible_to : administrateur → les factures de son organisation' do
    document = build_facture
    document.save!

    assert_includes Facture.visible_to(users(:administrateur_paris)), document
  end

  test 'visible_to : manager → celles des services qu\'il gère' do
    document = build_facture
    document.save!

    assert_includes Facture.visible_to(users(:hidalgo)), document
  end

  test 'visible_to : manager d\'une autre organisation → aucune' do
    document = build_facture
    document.save!

    assert_not_includes Facture.visible_to(users(:manager_marseille)), document
  end

  test 'visible_to : adhérent → les siennes envoyées, jamais un brouillon' do
    sienne = build_facture
    sienne.save!

    assert_not_includes Facture.visible_to(@adherent), sienne

    sienne.envoyer!

    assert_includes Facture.visible_to(@adherent), sienne
  end

  test 'visible_to : agent → aucune facture' do
    assert_empty Facture.visible_to(users(:bond))
  end

  private

  def build_facture(attrs = {})
    Facture.new({ adherent: @adherent, service: @service, intitulé: 'Facture test' }.merge(attrs))
  end
end
