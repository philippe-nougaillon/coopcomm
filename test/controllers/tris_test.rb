# frozen_string_literal: true

require 'test_helper'

# Sentinelle des tris : chaque colonne déclarée par un contrôleur est exercée sur
# la page qui l'affiche, dans les deux sens. Une colonne ajoutée plus tard entre
# automatiquement dans le test.
class TrisTest < ActionDispatch::IntegrationTest
  # `super_admin?` lit une variable d'environnement, absente de la CI : sans ça
  # l'index des newsletters y répond une redirection Pundit.
  setup do
    @super_admin_initial = ENV.fetch('SUPER_ADMIN', nil)
    ENV['SUPER_ADMIN'] = users(:philippe_super_admin).email
  end

  teardown do
    ENV['SUPER_ADMIN'] = @super_admin_initial
    ENV.delete('SUPER_ADMIN') if @super_admin_initial.nil?
  end

  # [libellé, contrôleur, modèle trié, utilisateur, chemin]
  def tableaux
    [
      ['interventions (vue compacte)', InterventionsController, 'Intervention', users(:hidalgo),
       interventions_path(vue: 'compact')],
      ['pointages d\'un modèle', InterventionsController, 'Intervention', users(:hidalgo),
       intervention_path(interventions(:intervention_repete))],
      ['activité d\'une intervention', InterventionsController, 'Audited::Audit', users(:hidalgo),
       intervention_path(interventions(:tonte_locaux))],
      ['utilisateurs', UsersController, 'User', users(:hidalgo), users_path],
      ['agents (planning)', UsersController, 'User', users(:hidalgo), agent_calendrier_users_path],
      ['absences d\'un utilisateur', UsersController, 'Absence', users(:hidalgo), user_path(users(:bond))],
      ['activité d\'un utilisateur', UsersController, 'Audited::Audit', users(:hidalgo), user_path(users(:bond))],
      ['matériel', ToolsController, 'Tool', users(:hidalgo), tools_path],
      ['interventions d\'un outil', ToolsController, 'Intervention', users(:hidalgo),
       tool_path(tools(:tondeuse), vue: 'liste')],
      ['mouvements d\'un outil', ToolsController, 'Mouvement', users(:hidalgo), tool_path(tools(:tondeuse))],
      ['activité d\'un outil', ToolsController, 'Audited::Audit', users(:hidalgo), tool_path(tools(:tondeuse))],
      ['mouvements', MouvementsController, 'Mouvement', users(:hidalgo), mouvements_path],
      ['audits', AdminController, 'Audited::Audit', users(:hidalgo), admin_audits_path],
      ['paramètres : services', AdminController, 'Service', users(:administrateur_paris), admin_parametres_path],
      ['paramètres : sites', AdminController, 'Warehouse', users(:administrateur_paris),
       admin_parametres_path(tab: 'sites')],
      ['paramètres : prestations', AdminController, 'Prestation', users(:administrateur_paris),
       admin_parametres_path(tab: 'prestations')],
      ['devis', CotationsController, 'Cotation', users(:hidalgo), cotations_path],
      ['envois d\'un devis', CotationsController, 'MailLog', users(:hidalgo),
       cotation_path(cotations(:cotation_paris))],
      ['activité d\'un devis', CotationsController, 'Audited::Audit', users(:hidalgo), cotation_path(cotations(:cotation_paris))],
      ['commandes', CommandesController, 'Commande', users(:hidalgo), commandes_path],
      ['activité d\'une commande', CommandesController, 'Audited::Audit', users(:hidalgo),
       commande_path(commandes(:commande_paris))],
      ['factures', FacturesController, 'Facture', users(:hidalgo), factures_path],
      ['activité d\'une facture', FacturesController, 'Audited::Audit', users(:hidalgo), facture_path(factures(:facture_paris))],
      ['conventions', ConventionsController, 'Convention', users(:hidalgo), conventions_path],
      ['activité d\'une convention', ConventionsController, 'Audited::Audit', users(:hidalgo),
       convention_path(conventions(:convention_paris))],
      ['notifications', MailLogsController, 'MailLog', users(:hidalgo), mail_logs_path],
      ['newsletters', NewslettersController, 'Newsletter', users(:philippe_super_admin), newsletters_path],
      ['CRM adhérent : devis', AdherentCrmController, 'Cotation', users(:weil), adherent_crm_path],
      ['CRM adhérent : commandes', AdherentCrmController, 'Commande', users(:weil),
       adherent_crm_path(tab: 'commandes')],
      ['CRM adhérent : factures', AdherentCrmController, 'Facture', users(:weil), adherent_crm_path(tab: 'factures')],
      ['historique des exports', PagesController, 'ExportLog', users(:hidalgo), dashboard_path]
    ]
  end

  test 'chaque colonne déclarée répond dans les deux sens sur la page qui l\'affiche' do
    tableaux.each do |libellé, controleur, modèle, utilisateur, chemin|
      colonnes = controleur.tris.fetch(modèle)[:colonnes].keys

      assert_predicate colonnes, :any?, "#{libellé} : aucune colonne déclarée"

      sign_in utilisateur
      colonnes.each do |colonne|
        %w[asc desc].each do |sens|
          get chemin, params: { column: colonne, direction: sens }

          assert_response :success, "#{libellé} : le tri #{colonne} #{sens} ne répond pas"
        end
      end
      sign_out utilisateur
    end
  end

  test 'une colonne inconnue retombe sur le tri par défaut au lieu de planter' do
    sign_in users(:hidalgo)

    get interventions_path(vue: 'compact', column: 'interventions.colonne_inexistante', direction: 'asc')

    assert_response :success
  end

  test 'un sens de tri inconnu ne casse pas la page' do
    sign_in users(:hidalgo)

    get users_path(column: 'users.nom', direction: 'DROP TABLE users')

    assert_response :success
    assert_predicate User, :any?
  end

  test 'toute colonne posée dans une vue est déclarée par un contrôleur' do
    Rails.application.eager_load!
    declarees = ApplicationController.descendants.flat_map do |controleur|
      controleur.tris.values.flat_map { |tri| tri[:colonnes].keys }
    end.uniq

    inconnues = Dir[Rails.root.join('app/views/**/*.erb')].flat_map do |vue|
      colonnes = File.read(vue).scan(/(?:colonne:|sort_link)\s+'([^']+)'/).flatten
      (colonnes - declarees).map { |colonne| "#{colonne} (#{vue.delete_prefix(Rails.root.to_s)})" }
    end

    assert_empty inconnues, "colonnes triables posées dans une vue mais jamais déclarées : #{inconnues.join(', ')}"
  end

  test 'trier change réellement l\'ordre affiché' do
    sign_in users(:hidalgo)

    get users_path(column: 'users.nom', direction: 'asc')
    croissant = noms_normalisés(assigns(:users))

    get users_path(column: 'users.nom', direction: 'desc')
    décroissant = noms_normalisés(assigns(:users))

    assert_operator croissant.size, :>, 1
    assert_equal croissant.sort, croissant
    assert_equal décroissant.sort.reverse, décroissant
    assert_not_equal croissant.first, décroissant.first
  end

  test 'une expression devenue fausse retombe sur le tri par défaut sans casser la page' do
    avec_colonne_cassée('users.email') do
      sign_in users(:hidalgo)

      get users_path(column: 'users.email', direction: 'asc')

      assert_response :success
      assert_equal noms_normalisés(assigns(:users)).sort, noms_normalisés(assigns(:users))
    end
  end

  test 'un tri par défaut devenu faux retombe sur la clé primaire' do
    avec_colonne_cassée('users.nom') do
      sign_in users(:hidalgo)

      get users_path

      assert_response :success
      assert_equal assigns(:users).map(&:id).sort, assigns(:users).map(&:id)
    end
  end

  def avec_colonne_cassée(colonne)
    déclaré = UsersController.tris
    cassé = déclaré['User'][:colonnes].merge(colonne => '(SELECT colonne_disparue FROM table_disparue)')
    UsersController.tris = déclaré.merge('User' => déclaré['User'].merge(colonnes: cassé))
    Triable::ORDRES_ÉPROUVÉS.clear

    yield
  ensure
    UsersController.tris = déclaré
    Triable::ORDRES_ÉPROUVÉS.clear
  end

  test 'filtrer après avoir trié conserve le tri' do
    sign_in users(:hidalgo)

    get users_path(column: 'users.email', direction: 'desc')

    assert_select 'form input[name=column][value=?]', 'users.email'
    assert_select 'form input[name=direction][value=?]', 'desc'
  end

  test 'trier repart de la première page' do
    sign_in users(:hidalgo)

    get users_path(page: 2, column: 'users.nom', direction: 'asc')

    assert_select 'th a[href*=?]', 'column=users.email' do |liens|
      assert_no_match(/page=/, liens.first[:href])
    end
  end

  def noms_normalisés(utilisateurs)
    utilisateurs.map { |utilisateur| I18n.transliterate(utilisateur.nom.to_s).downcase }
  end

  test 'le tri par une donnée liée passe par une sous-requête, sans dupliquer de ligne' do
    sign_in users(:hidalgo)

    get users_path
    total_sans_tri = assigns(:pagy).count

    get users_path(column: 'users.service', direction: 'asc')
    ids = assigns(:users).map(&:id)

    assert_equal total_sans_tri, assigns(:pagy).count
    assert_equal ids.uniq, ids
  end
end
