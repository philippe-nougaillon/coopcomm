# frozen_string_literal: true

require 'test_helper'

class ServiceTest < ActiveSupport::TestCase
  # ==================== TESTS CRITIQUES ====================
  # Le service est la racine du système : l'organisation d'un utilisateur, son périmètre
  # de visibilité et le cloisonnement entre communes en dérivent tous. Un service en
  # double, sans nom ou supprimé alors qu'il porte encore des données casse cette chaîne.

  # Sentinelle : `schema.rb` est régénéré depuis la base de dev de celui qui migre. Si sa
  # base a perdu cette contrainte, le dump la retire sans bruit, et toute la suite tourne
  # alors sur un schéma plus permissif que la prod (c'est déjà arrivé). Sans elle, un
  # service sans organisation redevient possible, et tout le cloisonnement en dérive.
  test 'organisation_id : schéma de la base → NOT NULL (critique)' do
    assert_not Service.columns_hash['organisation_id'].null,
               'services.organisation_id doit être NOT NULL : schema.rb a sans doute été régénéré ' \
               'depuis une base de dev qui a perdu la contrainte'
  end

  test 'unicité du nom : doublon dans la même organisation → refusé (critique)' do
    doublon = Service.new(nom: services(:technique).nom, organisation: organisations(:mairie_paris))

    assert_not doublon.valid?
    assert_includes doublon.errors[:nom], 'est déjà utilisé(e)'
  end

  test 'unicité du nom : même nom dans une autre organisation → accepté (critique)' do
    assert Service.new(nom: services(:technique).nom, organisation: organisations(:mairie_marseille)).valid?
  end

  test 'normalisation du nom : espaces et casse → humanisé et détouré (critique)' do
    service = Service.create!(nom: '  espaces verts  ', organisation: organisations(:mairie_paris))

    assert_equal 'Espaces verts', service.nom
  end

  # Un service sans nom apparaît comme une entrée VIDE dans le sélecteur du formulaire
  # utilisateur : impossible de distinguer un vrai service d'une ligne accidentelle, et
  # les utilisateurs qu'on y rattache semblent « sans service ». La normalisation vide
  # un nom fait d'espaces, c'est elle qui déclenche alors le refus.
  test 'normalisation du nom : nom fait uniquement d\'espaces → refusé (critique)' do
    service = Service.new(nom: '   ', organisation: organisations(:mairie_paris))

    assert_not service.valid?
    assert_includes service.errors[:nom], 'doit être rempli(e)'
  end

  test 'scope ordered : plusieurs services → triés sans tenir compte des accents ni de la casse (critique)' do
    organisation = organisations(:mairie_marseille)
    %w[Élagage aiguillage Zonage].each { |nom| Service.create!(nom: nom, organisation: organisation) }

    noms = organisation.services.ordered.pluck(:nom)

    assert_operator noms.index('Aiguillage'), :<, noms.index('Élagage')
    assert_operator noms.index('Élagage'), :<, noms.index('Zonage')
  end

  test 'managers_and_admin : service peuplé → ses managers et administrateurs seulement (critique)' do
    encadrants = services(:technique).managers_and_admin

    assert_includes encadrants, users(:hidalgo)
    assert_includes encadrants, users(:administrateur_paris)
    assert_not_includes encadrants, users(:martin_technique_paris)
  end

  test 'can_be_destroyed? : service sans aucun rattachement → vrai (critique)' do
    assert services(:menage).can_be_destroyed?
  end

  test 'can_be_destroyed? : service porteur d\'une intervention → faux (critique)' do
    service = service_vide_avec_administrateur
    creer_intervention(service)

    assert_not service.reload.can_be_destroyed?
    assert_includes service.text_for_unauthorized_destroy, 'des interventions'
  end

  test 'can_be_destroyed? : service porteur d\'une convention → faux (critique)' do
    service = service_vide_avec_administrateur
    creer_convention(service)

    assert_not service.reload.can_be_destroyed?
    assert_includes service.text_for_unauthorized_destroy, 'des conventions'
  end

  test 'can_be_destroyed? : service porteur d\'une cotation → faux (critique)' do
    service = service_vide_avec_administrateur
    Cotation.create!(adherent: @administrateur, service: service, intitulé: 'Devis')

    assert_not service.reload.can_be_destroyed?
    assert_includes service.text_for_unauthorized_destroy, 'des cotations'
  end

  test 'can_be_destroyed? : service porteur d\'une commande → faux (critique)' do
    service = service_vide_avec_administrateur
    Commande.create!(adherent: @administrateur, service: service, intitulé: 'Commande')

    assert_not service.reload.can_be_destroyed?
    assert_includes service.text_for_unauthorized_destroy, 'des commandes'
  end

  test 'can_be_destroyed? : service porteur d\'une facture → faux (critique)' do
    service = service_vide_avec_administrateur
    Facture.create!(adherent: @administrateur, service: service, intitulé: 'Facture')

    assert_not service.reload.can_be_destroyed?
    assert_includes service.text_for_unauthorized_destroy, 'des factures'
  end

  test 'can_be_destroyed? : service rattaché à un utilisateur non administrateur → faux (critique)' do
    service = services(:menage)
    service.users << users(:weil)

    assert_not service.reload.can_be_destroyed?
    assert_includes service.text_for_unauthorized_destroy, 'des utilisateurs non administrateurs'
  end

  # Un administrateur ne compte pas : il peut être rattaché à tous les services de son
  # organisation sans pour autant les rendre indestructibles.
  test 'can_be_destroyed? : service rattaché à un seul administrateur → vrai (critique)' do
    assert service_vide_avec_administrateur.reload.can_be_destroyed?
  end

  test 'text_for_unauthorized_destroy : service supprimable → texte vide (critique)' do
    assert_equal '', services(:menage).text_for_unauthorized_destroy
  end

  test 'text_for_unauthorized_destroy : motif unique → une phrase qui le nomme (critique)' do
    texte = services(:service_paris).text_for_unauthorized_destroy

    assert_includes texte, 'Impossible de supprimer ce service'
    assert_includes texte, 'des utilisateurs non administrateurs'
    assert_not_includes texte, 'des interventions'
  end

  test 'text_for_unauthorized_destroy : tous les rattachements → tous énumérés (critique)' do
    service = service_vide_avec_administrateur
    creer_intervention(service)
    creer_convention(service)
    Cotation.create!(adherent: @administrateur, service: service, intitulé: 'Devis')
    Commande.create!(adherent: @administrateur, service: service, intitulé: 'Commande')
    Facture.create!(adherent: @administrateur, service: service, intitulé: 'Facture')
    service.users << users(:weil)

    texte = service.reload.text_for_unauthorized_destroy

    assert_includes texte, 'des interventions'
    assert_includes texte, 'des conventions'
    assert_includes texte, 'des cotations'
    assert_includes texte, 'des commandes'
    assert_includes texte, 'des factures'
    assert_includes texte, 'des utilisateurs non administrateurs'
  end

  # ==================== /TESTS CRITIQUES ====================

  private

  # `menage` n'a aucun rattachement en fixture. L'administrateur y est ajouté parce que
  # l'intervention et la convention exigent un adhérent membre du service, et qu'un
  # administrateur n'entre pas dans le décompte des utilisateurs bloquants.
  def service_vide_avec_administrateur
    @administrateur = users(:administrateur_paris)
    services(:menage).tap { |service| service.users << @administrateur }
  end

  def creer_intervention(service)
    Intervention.create!(description: 'Contrôle', adherent: @administrateur, service: service)
  end

  def creer_convention(service)
    Convention.create!(user: @administrateur, service: service, heures_conventionnees: 100,
                       date_début: Date.new(2026, 1, 1), date_fin_prévue: Date.new(2026, 12, 31))
  end
end
