# frozen_string_literal: true

require 'test_helper'

# Miroir de test/models/facture_test.rb (modèles symétriques).
class CommandeTest < ActiveSupport::TestCase
  setup do
    @adherent = users(:weil)
    @service = services(:informatique)
  end

  test 'assign_ref : première commande d\'une organisation → CM-AAAA-1' do
    org = Organisation.create!(nom: 'Org neuve A')
    service = Service.create!(nom: 'Service A', organisation: org)
    commande = build_commande(service: service)

    commande.save!

    assert_equal "CM-#{Date.current.year}-1", commande.ref
  end

  test 'assign_ref : seconde commande de la même organisation → numéro incrémenté' do
    org = Organisation.create!(nom: 'Org neuve B')
    service = Service.create!(nom: 'Service B', organisation: org)
    build_commande(service: service).save!
    deuxième = build_commande(service: service)

    deuxième.save!

    assert_equal "CM-#{Date.current.year}-2", deuxième.ref
  end

  test 'assign_ref : deux organisations → numérotations indépendantes' do
    org1 = Organisation.create!(nom: 'Org neuve C')
    org2 = Organisation.create!(nom: 'Org neuve D')
    commande1 = build_commande(service: Service.create!(nom: 'Service C', organisation: org1))
    commande2 = build_commande(service: Service.create!(nom: 'Service D', organisation: org2))

    commande1.save!
    commande2.save!

    assert_equal "CM-#{Date.current.year}-1", commande1.ref
    assert_equal "CM-#{Date.current.year}-1", commande2.ref
  end

  test 'assign_ref : référence fournie explicitement → conservée' do
    commande = build_commande(ref: 'REF-MANUELLE')

    commande.save!

    assert_equal 'REF-MANUELLE', commande.ref
  end

  test 'style : chaque état → la classe du badge qui le distingue à l\'écran' do
    commande = build_commande

    assert_equal 'badge badge-secondary ', commande.style

    commande.save!
    commande.envoyer!

    assert_equal 'badge badge-primary ', commande.style
  end

  test 'workflow_state_humanized : appel → les états humanisés du workflow' do
    humanized = Commande.workflow_state_humanized

    assert_includes humanized, 'Créé'
    assert_includes humanized, 'Archivé'
  end

  test 'modifiable? : état créé → vrai' do
    assert build_commande.modifiable?
  end

  test 'modifiable? : états envoyé, validé et archivé → faux' do
    commande = build_commande
    commande.save!

    commande.envoyer!

    assert_not commande.modifiable?

    commande.valider!

    assert_not commande.modifiable?

    commande.archiver!

    assert_not commande.modifiable?
  end

  test 'modifiable? : état refusé → vrai, pour corriger avant de renvoyer' do
    commande = build_commande
    commande.save!
    commande.envoyer!
    commande.refuser!

    assert commande.modifiable?
  end

  test 'pdf_filename : commande référencée → nom de fichier bâti sur la référence' do
    assert_equal 'Commande-2026-9.pdf', build_commande(ref: '2026-9').pdf_filename
  end

  test 'visible_to : administrateur → les commandes de son organisation' do
    document = build_commande
    document.save!

    assert_includes Commande.visible_to(users(:administrateur_paris)), document
  end

  test 'visible_to : manager → celles des services qu\'il gère' do
    document = build_commande
    document.save!

    assert_includes Commande.visible_to(users(:hidalgo)), document
  end

  test 'visible_to : manager d\'une autre organisation → aucune' do
    document = build_commande
    document.save!

    assert_not_includes Commande.visible_to(users(:manager_marseille)), document
  end

  test 'visible_to : adhérent → les siennes envoyées, jamais un brouillon' do
    sienne = build_commande
    sienne.save!

    assert_not_includes Commande.visible_to(@adherent), sienne

    sienne.envoyer!

    assert_includes Commande.visible_to(@adherent), sienne
  end

  test 'visible_to : agent → aucune commande' do
    assert_empty Commande.visible_to(users(:bond))
  end

  private

  def build_commande(attrs = {})
    Commande.new({ adherent: @adherent, service: @service, intitulé: 'Commande test' }.merge(attrs))
  end
end
