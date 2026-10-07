# frozen_string_literal: true

require 'test_helper'

# Miroir de test/models/facture_test.rb (modèles symétriques).
class CommandeTest < ActiveSupport::TestCase
  setup do
    @adherent = users(:weil)
    @service = services(:informatique)
  end

  test "la première commande d'une organisation reçoit la référence CM-AAAA-1" do
    org = Organisation.create!(nom: 'Org neuve A')
    service = Service.create!(nom: 'Service A', organisation: org)
    commande = build_commande(service: service)

    commande.save!

    assert_equal "CM-#{Date.current.year}-1", commande.ref
  end

  test 'la seconde commande de la même organisation reçoit le numéro suivant' do
    org = Organisation.create!(nom: 'Org neuve B')
    service = Service.create!(nom: 'Service B', organisation: org)
    build_commande(service: service).save!
    deuxième = build_commande(service: service)

    deuxième.save!

    assert_equal "CM-#{Date.current.year}-2", deuxième.ref
  end

  test 'les commandes de deux organisations sont numérotées indépendamment' do
    org1 = Organisation.create!(nom: 'Org neuve C')
    org2 = Organisation.create!(nom: 'Org neuve D')
    commande1 = build_commande(service: Service.create!(nom: 'Service C', organisation: org1))
    commande2 = build_commande(service: Service.create!(nom: 'Service D', organisation: org2))

    commande1.save!
    commande2.save!

    assert_equal "CM-#{Date.current.year}-1", commande1.ref
    assert_equal "CM-#{Date.current.year}-1", commande2.ref
  end

  test 'une référence de commande fournie explicitement est conservée' do
    commande = build_commande(ref: 'REF-MANUELLE')

    commande.save!

    assert_equal 'REF-MANUELLE', commande.ref
  end

  test "chaque état d'une commande se distingue à l'écran par la classe de son badge" do
    commande = build_commande

    assert_equal 'badge badge-secondary ', commande.style

    commande.save!
    commande.envoyer!

    assert_equal 'badge badge-primary ', commande.style
  end

  test "les états du workflow d'une commande ont un libellé humanisé" do
    humanized = Commande.workflow_state_humanized

    assert_includes humanized, 'Créé'
    assert_includes humanized, 'Archivé'
  end

  test "une commande à l'état créé est modifiable" do
    assert build_commande.modifiable?
  end

  test "une commande à l'état envoyé, validé ou archivé n'est pas modifiable" do
    commande = build_commande
    commande.save!

    commande.envoyer!

    assert_not commande.modifiable?

    commande.valider!

    assert_not commande.modifiable?

    commande.archiver!

    assert_not commande.modifiable?
  end

  test "une commande à l'état refusé est modifiable, pour être corrigée avant renvoi" do
    commande = build_commande
    commande.save!
    commande.envoyer!
    commande.refuser!

    assert commande.modifiable?
  end

  test "le nom du fichier PDF d'une commande est bâti sur sa référence" do
    assert_equal 'Commande-2026-9.pdf', build_commande(ref: '2026-9').pdf_filename
  end

  test 'un administrateur voit les commandes de son organisation' do
    document = build_commande
    document.save!

    assert_includes Commande.visible_to(users(:administrateur_paris)), document
  end

  test 'un manager voit les commandes de ses services' do
    document = build_commande
    document.save!

    assert_includes Commande.visible_to(users(:hidalgo)), document
  end

  test "un manager ne voit pas les commandes d'une autre organisation" do
    document = build_commande
    document.save!

    assert_not_includes Commande.visible_to(users(:manager_marseille)), document
  end

  test 'un adhérent voit ses commandes envoyées, jamais un brouillon' do
    sienne = build_commande
    sienne.save!

    assert_not_includes Commande.visible_to(@adherent), sienne

    sienne.envoyer!

    assert_includes Commande.visible_to(@adherent), sienne
  end

  test "un adhérent ne voit jamais la commande envoyée d'un autre adhérent de son organisation (critique)" do
    assert_not_includes Commande.visible_to(@adherent), commandes(:commande_autre_adherent)
  end

  test 'un agent ne voit aucune commande' do
    assert_empty Commande.visible_to(users(:bond))
  end

  private

  def build_commande(attrs = {})
    Commande.new({ adherent: @adherent, service: @service, intitulé: 'Commande test' }.merge(attrs))
  end
end
