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
  test 'la colonne organisation_id des services est NOT NULL (critique)' do
    assert_not Service.columns_hash['organisation_id'].null,
               'services.organisation_id doit être NOT NULL : schema.rb a sans doute été régénéré ' \
               'depuis une base de dev qui a perdu la contrainte'
  end

  test 'un service dont le nom existe déjà dans la même organisation est refusé (critique)' do
    doublon = Service.new(nom: services(:technique).nom, organisation: organisations(:mairie_paris))

    assert_not doublon.valid?
    assert_includes doublon.errors[:nom], 'est déjà utilisé(e)'
  end

  test 'un service dont le nom existe dans une autre organisation est accepté (critique)' do
    assert Service.new(nom: services(:technique).nom, organisation: organisations(:mairie_marseille)).valid?
  end

  test 'le nom de service saisi avec des espaces et en minuscules est humanisé et détouré (critique)' do
    service = Service.create!(nom: '  espaces verts  ', organisation: organisations(:mairie_paris))

    assert_equal 'Espaces verts', service.nom
  end

  # Un service sans nom apparaît comme une entrée VIDE dans le sélecteur du formulaire
  # utilisateur : impossible de distinguer un vrai service d'une ligne accidentelle, et
  # les utilisateurs qu'on y rattache semblent « sans service ». La normalisation vide
  # un nom fait d'espaces, c'est elle qui déclenche alors le refus.
  test "un service dont le nom n'est fait que d'espaces est refusé (critique)" do
    service = Service.new(nom: '   ', organisation: organisations(:mairie_paris))

    assert_not service.valid?
    assert_includes service.errors[:nom], 'doit être rempli(e)'
  end

  test 'les services sont triés sans tenir compte des accents ni de la casse (critique)' do
    organisation = organisations(:mairie_marseille)
    %w[Élagage aiguillage Zonage].each { |nom| Service.create!(nom: nom, organisation: organisation) }

    noms = organisation.services.ordered.pluck(:nom)

    assert_operator noms.index('Aiguillage'), :<, noms.index('Élagage')
    assert_operator noms.index('Élagage'), :<, noms.index('Zonage')
  end

  test "un service qui est le seul service d'un utilisateur n'est pas supprimé (critique)" do
    administrateur = users(:philippe_super_admin)
    service = service_unique_de(administrateur)

    assert_not service.destroy
    assert_equal [service], administrateur.reload.services
  end

  test 'un service dont les utilisateurs gardent un autre service est supprimé (critique)' do
    service = service_vide_avec_administrateur

    assert service.destroy
    assert_not Service.exists?(service.id)
  end

  test "la liste des managers et administrateurs d'un service exclut ses agents (critique)" do
    encadrants = services(:technique).managers_and_admin

    assert_includes encadrants, users(:hidalgo)
    assert_includes encadrants, users(:administrateur_paris)
    assert_not_includes encadrants, users(:martin_technique_paris)
  end

  test 'un service sans aucun rattachement peut être supprimé (critique)' do
    assert services(:menage).can_be_destroyed?
  end

  test "un service porteur d'une intervention ne peut pas être supprimé (critique)" do
    service = service_vide_avec_administrateur
    creer_intervention(service)

    assert_not service.reload.can_be_destroyed?
    assert_includes service.text_for_unauthorized_destroy, 'des interventions'
  end

  test "un service porteur d'une convention ne peut pas être supprimé (critique)" do
    service = service_vide_avec_administrateur
    creer_convention(service)

    assert_not service.reload.can_be_destroyed?
    assert_includes service.text_for_unauthorized_destroy, 'des conventions'
  end

  test "un service porteur d'une cotation ne peut pas être supprimé (critique)" do
    service = service_vide_avec_administrateur
    Cotation.create!(adherent: @administrateur, service: service, intitulé: 'Devis')

    assert_not service.reload.can_be_destroyed?
    assert_includes service.text_for_unauthorized_destroy, 'des cotations'
  end

  test "un service porteur d'une commande ne peut pas être supprimé (critique)" do
    service = service_vide_avec_administrateur
    Commande.create!(adherent: @administrateur, service: service, intitulé: 'Commande')

    assert_not service.reload.can_be_destroyed?
    assert_includes service.text_for_unauthorized_destroy, 'des commandes'
  end

  test "un service porteur d'une facture ne peut pas être supprimé (critique)" do
    service = service_vide_avec_administrateur
    Facture.create!(adherent: @administrateur, service: service, intitulé: 'Facture')

    assert_not service.reload.can_be_destroyed?
    assert_includes service.text_for_unauthorized_destroy, 'des factures'
  end

  test "un service qui est le seul service d'un utilisateur ne peut pas être supprimé (critique)" do
    service = service_unique_de(users(:agent_whatsapp))

    assert_not service.can_be_destroyed?
    assert_includes service.text_for_unauthorized_destroy, "des utilisateurs dont c'est le seul service"
  end

  test "un service qui est le seul service d'un administrateur ne peut pas être supprimé (critique)" do
    service = service_unique_de(users(:philippe_super_admin))

    assert_not service.can_be_destroyed?
    assert_includes service.text_for_unauthorized_destroy, "des utilisateurs dont c'est le seul service"
  end

  test "un service qui est le seul service d'un compte désactivé ne peut pas être supprimé (critique)" do
    service = service_unique_de(users(:agent_discarded_paris))

    assert_not service.can_be_destroyed?
    assert_includes service.text_for_unauthorized_destroy, "des comptes désactivés dont c'est le seul service"
  end

  test 'un service dont les utilisateurs gardent un autre service peut être supprimé (critique)' do
    service = service_vide_avec_administrateur
    service.users << users(:weil)

    assert service.reload.can_be_destroyed?
  end

  test 'le texte de refus de suppression est vide pour un service supprimable (critique)' do
    assert_equal '', services(:menage).text_for_unauthorized_destroy
  end

  test 'le texte de refus de suppression nomme le seul motif présent et aucun autre (critique)' do
    texte = service_unique_de(users(:agent_whatsapp)).text_for_unauthorized_destroy

    assert_includes texte, 'Impossible de supprimer ce service'
    assert_includes texte, "des utilisateurs dont c'est le seul service"
    assert_not_includes texte, 'des interventions'
    assert_not_includes texte, 'des comptes désactivés'
  end

  test 'le texte de refus de suppression énumère tous les rattachements du service (critique)' do
    service = service_vide_avec_administrateur
    creer_intervention(service)
    creer_convention(service)
    Cotation.create!(adherent: @administrateur, service: service, intitulé: 'Devis')
    Commande.create!(adherent: @administrateur, service: service, intitulé: 'Commande')
    Facture.create!(adherent: @administrateur, service: service, intitulé: 'Facture')
    service_unique_de(users(:agent_whatsapp))
    service_unique_de(users(:agent_discarded_paris))

    texte = service.reload.text_for_unauthorized_destroy

    assert_includes texte, 'des interventions'
    assert_includes texte, 'des conventions'
    assert_includes texte, 'des cotations'
    assert_includes texte, 'des commandes'
    assert_includes texte, 'des factures'
    assert_includes texte, "des utilisateurs dont c'est le seul service"
    assert_includes texte, "des comptes désactivés dont c'est le seul service"
  end

  # ==================== /TESTS CRITIQUES ====================

  private

  # `menage` n'a aucun rattachement en fixture. L'administrateur y est ajouté parce que
  # l'intervention et la convention exigent un adhérent membre du service, et que,
  # gardant ses autres services, il n'entre pas dans le décompte des utilisateurs bloquants.
  def service_vide_avec_administrateur
    @administrateur = users(:administrateur_paris)
    services(:menage).tap { |service| service.users << @administrateur }
  end

  # Déplace sur `menage` l'unique rattachement de l'utilisateur.
  def service_unique_de(user)
    services(:menage).tap { |service| user.user_services.sole.update!(service: service) }
  end

  def creer_intervention(service)
    Intervention.create!(description: 'Contrôle', adherent: @administrateur, service: service)
  end

  def creer_convention(service)
    Convention.create!(user: @administrateur, service: service, heures_conventionnees: 100,
                       date_début: Date.new(2026, 1, 1), date_fin_prévue: Date.new(2026, 12, 31))
  end
end
