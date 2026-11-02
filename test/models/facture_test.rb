# frozen_string_literal: true

require 'test_helper'

# Miroir de test/models/commande_test.rb (modèles symétriques).
class FactureTest < ActiveSupport::TestCase
  setup do
    @adherent = users(:weil)
    @service = services(:informatique)
  end

  test "la première facture d'une organisation reçoit la référence FA-AAAA-1" do
    org = Organisation.create!(nom: 'Org neuve E')
    service = Service.create!(nom: 'Service E', organisation: org)
    facture = build_facture(service: service)

    facture.save!

    assert_equal "FA-#{Date.current.year}-1", facture.ref
  end

  test 'la seconde facture de la même organisation reçoit le numéro suivant' do
    org = Organisation.create!(nom: 'Org neuve F')
    service = Service.create!(nom: 'Service F', organisation: org)
    build_facture(service: service).save!
    deuxième = build_facture(service: service)

    deuxième.save!

    assert_equal "FA-#{Date.current.year}-2", deuxième.ref
  end

  test 'les factures de deux organisations sont numérotées indépendamment' do
    org1 = Organisation.create!(nom: 'Org neuve G')
    org2 = Organisation.create!(nom: 'Org neuve H')
    facture1 = build_facture(service: Service.create!(nom: 'Service G', organisation: org1))
    facture2 = build_facture(service: Service.create!(nom: 'Service H', organisation: org2))

    facture1.save!
    facture2.save!

    assert_equal "FA-#{Date.current.year}-1", facture1.ref
    assert_equal "FA-#{Date.current.year}-1", facture2.ref
  end

  test 'une référence de facture fournie explicitement est conservée' do
    facture = build_facture(ref: 'REF-MANUELLE')

    facture.save!

    assert_equal 'REF-MANUELLE', facture.ref
  end

  test "chaque état d'une facture se distingue à l'écran par la classe de son badge" do
    facture = build_facture

    assert_equal 'badge badge-secondary ', facture.style

    facture.save!
    facture.envoyer!

    assert_equal 'badge badge-primary ', facture.style
  end

  test "les états du workflow d'une facture ont un libellé humanisé" do
    humanized = Facture.workflow_state_humanized

    assert_includes humanized, 'Créé'
    assert_includes humanized, 'Archivé'
  end

  test "une facture à l'état créé est modifiable" do
    assert build_facture.modifiable?
  end

  test "une facture à l'état envoyé, validé ou archivé n'est pas modifiable" do
    facture = build_facture
    facture.save!

    facture.envoyer!

    assert_not facture.modifiable?

    facture.valider!

    assert_not facture.modifiable?

    facture.archiver!

    assert_not facture.modifiable?
  end

  test "une facture à l'état refusé est modifiable, pour être corrigée avant renvoi" do
    facture = build_facture
    facture.save!
    facture.envoyer!
    facture.refuser!

    assert facture.modifiable?
  end

  test "le nom du fichier PDF d'une facture est bâti sur sa référence" do
    assert_equal 'Facture-2026-9.pdf', build_facture(ref: '2026-9').pdf_filename
  end

  test 'un administrateur voit les factures de son organisation' do
    document = build_facture
    document.save!

    assert_includes Facture.visible_to(users(:administrateur_paris)), document
  end

  test 'un manager voit les factures de ses services' do
    document = build_facture
    document.save!

    assert_includes Facture.visible_to(users(:hidalgo)), document
  end

  test "un manager ne voit pas les factures d'une autre organisation" do
    document = build_facture
    document.save!

    assert_not_includes Facture.visible_to(users(:manager_marseille)), document
  end

  test 'un adhérent voit ses factures envoyées, jamais un brouillon' do
    sienne = build_facture
    sienne.save!

    assert_not_includes Facture.visible_to(@adherent), sienne

    sienne.envoyer!

    assert_includes Facture.visible_to(@adherent), sienne
  end

  test "un adhérent ne voit jamais la facture envoyée d'un autre adhérent de son organisation (critique)" do
    assert_not_includes Facture.visible_to(@adherent), factures(:facture_autre_adherent)
  end

  test 'un agent ne voit aucune facture' do
    assert_empty Facture.visible_to(users(:bond))
  end

  private

  def build_facture(attrs = {})
    Facture.new({ adherent: @adherent, service: @service, intitulé: 'Facture test' }.merge(attrs))
  end
end
