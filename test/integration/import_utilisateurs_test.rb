# frozen_string_literal: true

require 'test_helper'
require_relative '../support/fabrique_xls'

# Import XLS des agents, de bout en bout : ce que l'utilisateur téléverse, ce
# qu'on lui répond et ce que la page de bilan lui montre. La logique ligne à
# ligne est couverte par `test/services/import_utilisateurs_xls_test.rb`.
class ImportUtilisateursTest < ActionDispatch::IntegrationTest
  include FabriqueXls

  setup do
    @admin = users(:administrateur_paris)
    sign_in @admin
  end

  teardown { fermer_fichiers }

  # ==================== TESTS CRITIQUES ====================
  # L'organisation et l'importateur viennent de la session : c'est le contrôleur
  # qui les transmet, et rien d'autre ne le vérifie.

  test 'un manager n’importe que dans le périmètre de son organisation (critique)' do
    sign_in users(:hidalgo)
    Service.create!(nom: 'Voirie', organisation: organisations(:mairie_marseille))

    assert_no_difference 'User.count' do
      importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test',
                               service: 'Voirie')], save: 'true')
    end

    assert_bilan importés: 0, erreurs: 1
    assert_match(/introuvable dans votre organisation/, tableau_erreurs)
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'un fichier qui n’est pas un classeur affiche une alerte et aucun bilan' do
    fichier = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/exemple.png'), 'image/png')

    assert_no_difference 'User.count' do
      post import_do_users_url, params: { upload: fichier, save: 'true' }
    end

    assert_response :success
    assert_match(/format attendu est Excel 97-2003/, flash[:alert])
    assert_nil bilan, 'un import interrompu n’affiche aucun compteur de lignes'
  end

  test 'une colonne obligatoire manquante affiche une alerte et aucun bilan' do
    assert_no_difference 'User.count' do
      importer([%w[Nom Prénom Email], ['Durand', 'Marie', 'marie.durand@example.test']], save: 'true')
    end

    assert_response :success
    assert_match(/Structure du fichier invalide/, flash[:alert])
    assert_nil bilan, 'un import interrompu n’affiche aucun compteur de lignes'
  end

  test 'un import réussi annonce son succès et compte les lignes importées' do
    assert_difference 'User.count', 1 do
      importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test',
                               service: 'Informatique')], save: 'true')
    end

    créé = User.find_by(email: 'marie.durand@example.test')
    assert créé.agent?
    assert_includes créé.services, services(:informatique)
    assert_equal "L'importation a bien été exécutée.", flash[:notice]
    assert_bilan importés: 1, erreurs: 0
  end

  test 'le bilan détaille chaque ligne importée' do
    importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test',
                             téléphone: '0102030405')], save: 'true')

    assert_match(/Nouveau/, tableau_succès)
    assert_match(/DURAND Marie/, tableau_succès)
    assert_match(/marie\.durand@example\.test/, tableau_succès)
    assert_match(/Informatique/, tableau_succès)
    assert_match(/Téléphone : 0102030405/, tableau_succès)
  end

  test 'le bilan d’un remplacement de service nomme l’ancien et le nouveau' do
    importer([ENTETES, ligne(nom: 'Martin', prénom: 'Michel',
                             email: users(:martin_technique_paris).email, service: 'Informatique')],
             save: 'true')

    assert_match(/Mise à jour/, tableau_succès)
    assert_match(/Service : Technique → Informatique/, tableau_succès)
  end

  test 'un import partiellement en échec annonce l’échec partiel et compte les deux' do
    lignes = [
      ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test', service: 'Informatique'),
      ligne(nom: 'Dupuis', prénom: 'Paul', email: 'paul.dupuis@example.test', service: 'Zorglub')
    ]

    assert_difference 'User.count', 1 do
      importer([ENTETES] + lignes, save: 'true')
    end

    assert_equal "L'importation a partiellement échouée.", flash[:alert]
    assert_bilan importés: 1, erreurs: 1
    assert_match(/Zorglub/, tableau_erreurs)
  end

  test 'un import entièrement en échec annonce l’échec' do
    importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: '')], save: 'true')

    assert_equal "L'importation a échouée.", flash[:alert]
    assert_bilan importés: 0, erreurs: 1
    assert_match(/Email manquant/, tableau_erreurs)
  end

  test 'le tableau d’erreurs nomme le numéro de la ligne fautive du classeur' do
    assert_difference 'User.count', 1 do
      importer([ENTETES,
                ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test'),
                ligne(nom: '', prénom: 'Paul', email: 'paul.dupuis@example.test')],
               save: 'true')
    end

    assert_bilan importés: 1, erreurs: 1
    assert_match(/Nom manquant/, tableau_erreurs)
    assert_equal '3', premiere_ligne_en_erreur.at_css('td').text.strip
  end

  test 'sans paramètre save, l’import est simulé et annoncé comme tel' do
    assert_no_difference 'User.count' do
      importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test')])
    end

    assert_match(/les modifications n'ont pas été enregistrées/i, response.body)
    assert_bilan importés: 1, erreurs: 0
  end

  test 'save à false ne crée ni n’invite personne' do
    assert_no_emails do
      assert_no_difference 'User.count' do
        importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test')],
                 save: 'false')
      end
    end
  end

  test 'un import appliqué n’affiche pas l’avertissement de simulation' do
    importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test')],
             save: 'true')

    assert_no_match(/n'ont pas été enregistrées/i, response.body)
  end

  test 'aucun mot de passe en clair dans la page de bilan' do
    importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test')],
             save: 'true')

    assert_no_match(/mot de passe/i, response.body)
    assert_no_match(/encrypted_password/, response.body)
  end

  private

  def importer(lignes, save: nil)
    params = { upload: televersement(lignes) }
    params[:save] = save unless save.nil?

    post import_do_users_url, params: params
  end

  def assert_bilan(importés:, erreurs:)
    assert_not_nil bilan, 'le bilan de l’import doit être affiché'

    compteurs = bilan.text.squish
    assert_match(/(?:^|\s)#{importés} Ligne\(s\) importées/, compteurs)
    assert_match(/(?:^|\s)#{erreurs} Ligne\(s\) en erreur/, compteurs)
  end

  def page = Nokogiri::HTML(response.body)
  def bilan = page.at_css('[data-testid=bilan_import]')
  def tableau_succès = page.at_css('[data-testid=tableau_succes]')&.text.to_s.squish
  def tableau_erreurs = page.at_css('[data-testid=tableau_erreurs]')&.text.to_s.squish
  def premiere_ligne_en_erreur = page.at_css('[data-testid=tableau_erreurs] tbody tr')
end
