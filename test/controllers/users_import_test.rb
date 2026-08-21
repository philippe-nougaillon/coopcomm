# frozen_string_literal: true

require 'test_helper'
require_relative '../support/fabrique_xls'

# Import XLS des agents — parcours HTTP (`users#import`, `users#import_do`) et
# bilan affiché. La logique ligne à ligne est couverte par
# `test/services/import_utilisateurs_xls_test.rb`.
class UsersImportTest < ActionDispatch::IntegrationTest
  include FabriqueXls

  setup do
    @admin = users(:administrateur_paris)
    sign_in @admin
  end

  teardown { fermer_fichiers }

  # ==================== TESTS CRITIQUES ====================

  test "import_do : un manager n'importe que dans le périmètre de son organisation (critique)" do
    sign_in users(:hidalgo)
    Service.create!(nom: 'Voirie', organisation: organisations(:mairie_marseille))

    assert_no_difference 'User.count' do
      importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test',
                               service: 'Voirie')], save: 'true')
    end

    assert_bilan importés: 0, erreurs: 1
    assert_match(/introuvable dans votre organisation/, tableau_erreurs)
  end

  test "import_do : un compte privilégié n'est jamais rétrogradé (critique)" do
    hidalgo = users(:hidalgo)

    importer([ENTETES, ligne(nom: 'Hidalgo', prénom: 'Anne', email: hidalgo.email)], save: 'true')

    assert hidalgo.reload.manager?
    assert_bilan importés: 0, erreurs: 1
    assert_match(/modifiez-le depuis sa fiche/, tableau_erreurs)
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'import : un manager accède au formulaire' do
    sign_in users(:hidalgo)

    get import_users_url

    assert_response :success
  end

  test 'import_do : en GET au lieu de POST → redirection sans planter' do
    get import_do_users_url

    assert_redirected_to root_path
  end

  test 'import_do : un champ upload vide → retour au formulaire' do
    post import_do_users_url(upload: '')

    assert_redirected_to import_users_url
  end

  test 'import_do : sans fichier joint → retour au formulaire avec une alerte' do
    post import_do_users_url

    assert_redirected_to import_users_url
    assert_equal 'Manque le fichier source pour pouvoir lancer l\'importation !', flash[:alert]
  end

  test "import_do : un fichier qui n'est pas un XLS → refus propre" do
    fichier = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/exemple.png'), 'image/png')

    assert_no_difference 'User.count' do
      post import_do_users_url, params: { upload: fichier, save: 'true' }
    end

    assert_response :success
    assert_match(/format attendu est Excel 97-2003/, flash[:alert])
    assert_no_selector_bilan
  end

  test 'import_do : une colonne obligatoire manquante → interruption avant toute écriture' do
    assert_no_difference 'User.count' do
      importer([%w[Nom Prénom Email], ['Durand', 'Marie', 'marie.durand@example.test']], save: 'true')
    end

    assert_response :success
    assert_match(/Structure du fichier invalide/, flash[:alert])
    assert_no_selector_bilan
  end

  test 'import_do : un fichier réduit aux en-têtes → rien à faire, succès annoncé' do
    assert_no_difference 'User.count' do
      importer([ENTETES], save: 'true')
    end

    assert_equal "L'importation a bien été exécutée.", flash[:notice]
    assert_bilan importés: 0, erreurs: 0
  end

  test 'import_do : une ligne valide → un agent créé et rattaché à son service' do
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

  test 'import_do : le bilan détaille chaque ligne traitée' do
    importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test',
                             téléphone: '0102030405')], save: 'true')

    succès = tableau_succès
    assert_match(/Nouveau/, succès)
    assert_match(/DURAND Marie/, succès)
    assert_match(/marie\.durand@example\.test/, succès)
    assert_match(/Informatique/, succès)
    assert_match(/Téléphone : 0102030405/, succès)
  end

  test "import_do : un remplacement de service nomme l'ancien et le nouveau" do
    importer([ENTETES, ligne(nom: 'Martin', prénom: 'Michel',
                             email: users(:martin_technique_paris).email, service: 'Informatique')],
             save: 'true')

    assert_match(/Mise à jour/, tableau_succès)
    assert_match(/Service : Technique → Informatique/, tableau_succès)
  end

  test 'import_do : plusieurs lignes valides → toutes importées et comptées' do
    lignes = [
      ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test'),
      ligne(nom: 'Dupuis', prénom: 'Paul', email: 'paul.dupuis@example.test')
    ]

    assert_difference 'User.count', 2 do
      importer([ENTETES] + lignes, save: 'true')
    end

    assert_bilan importés: 2, erreurs: 0
  end

  test "import_do : une ligne en erreur n'empêche pas l'import des lignes valides" do
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

  test 'import_do : une ligne sans nom → comptée en erreur, avec son numéro' do
    assert_difference 'User.count', 1 do
      importer([ENTETES,
                ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test'),
                ligne(nom: '', prénom: 'Paul', email: 'paul.dupuis@example.test')],
               save: 'true')
    end

    assert_bilan importés: 1, erreurs: 1
    assert_match(/Nom manquant/, tableau_erreurs)
    assert_equal '3', premiere_erreur.at_css('td').text.strip
  end

  test 'import_do : une ligne sans email → comptée en erreur' do
    importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: '')], save: 'true')

    assert_bilan importés: 0, erreurs: 1
    assert_match(/Email manquant/, tableau_erreurs)
    assert_equal "L'importation a échouée.", flash[:alert]
  end

  test 'import_do : un compte désactivé est nommé comme tel dans le bilan' do
    désactivé = users(:agent_discarded_paris)

    assert_no_difference 'User.unscoped.count' do
      importer([ENTETES, ligne(nom: 'Spectre', prénom: 'Ancien', email: désactivé.email)], save: 'true')
    end

    assert_match(/Ce compte est désactivé/, tableau_erreurs)
    assert désactivé.reload.discarded?
  end

  test 'import_do : sans paramètre save → simulation seulement' do
    assert_no_difference 'User.count' do
      importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test')])
    end

    assert_match(/les modifications n'ont pas été enregistrées/i, response.body)
    assert_bilan importés: 1, erreurs: 0
  end

  test 'import_do : save à false → aucun utilisateur créé ni invité' do
    assert_no_emails do
      assert_no_difference 'User.count' do
        importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test')],
                 save: 'false')
      end
    end
  end

  test "import_do : mode appliqué → pas d'avertissement de simulation" do
    importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test')],
             save: 'true')

    assert_no_match(/n'ont pas été enregistrées/i, response.body)
  end

  test "import_do : un utilisateur créé reçoit une invitation de l'importateur" do
    assert_emails 1 do
      importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test')],
               save: 'true')
    end

    créé = User.find_by(email: 'marie.durand@example.test')
    assert_equal ['marie.durand@example.test'], ActionMailer::Base.deliveries.last.to
    assert_equal @admin.id, créé.invited_by_id
  end

  test "import_do : l'invitation envoyée est tracée dans les MailLog" do
    assert_difference 'MailLog.count', 1 do
      importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test')],
               save: 'true')
    end

    assert_equal 'marie.durand@example.test', MailLog.last.to
  end

  test "import_do : aucun job de fond n'est enfilé" do
    assert_no_enqueued_jobs do
      importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test')],
               save: 'true')
    end
  end

  test 'import_do : aucun mot de passe en clair dans la page de bilan' do
    importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test')],
             save: 'true')

    assert_no_match(/mot de passe/i, response.body)
    assert_no_match(/encrypted_password/, response.body)
  end

  test "import_do : aucun fichier n'est écrit dans public/" do
    fichiers_avant = Dir[Rails.root.join('public', '*')].sort

    importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test')],
             save: 'true')

    assert_equal fichiers_avant, Dir[Rails.root.join('public', '*')].sort
  end

  # si le modèle proposé aux utilisateurs change, ils doivent suivre.
  test "sentinelle : les en-têtes attendues du modèle XLS n'ont pas changé" do
    assert_equal ENTETES, User.xls_headers
  end

  test 'sentinelle : le mot de passe généré satisfait la politique de complexité' do
    mot_de_passe = User.generate_random_password

    candidat = User.new(nom: 'DURAND', prénom: 'Marie', email: 'marie.durand@example.test',
                        rôle: 'agent', password: mot_de_passe)
    candidat.user_services.build(service: services(:informatique))

    assert_equal 12, mot_de_passe.length
    assert candidat.valid?, candidat.errors.full_messages.join(', ')
  end

  private

  def importer(lignes, save: nil)
    params = { upload: televersement(lignes) }
    params[:save] = save unless save.nil?

    post import_do_users_url, params: params
  end

  def assert_bilan(importés:, erreurs:)
    bilan = page.at_css('[data-testid=bilan_import]')
    assert_not_nil bilan, 'le bilan de l’import doit être affiché'

    compteurs = bilan.text.squish
    assert_match(/(?:^|\s)#{importés} Ligne\(s\) importées/, compteurs)
    assert_match(/(?:^|\s)#{erreurs} Ligne\(s\) en erreur/, compteurs)
  end

  def assert_no_selector_bilan
    assert_nil page.at_css('[data-testid=bilan_import]'),
               'un import interrompu n’affiche aucun compteur de lignes'
  end

  def page = Nokogiri::HTML(response.body)
  def tableau_succès = page.at_css('[data-testid=tableau_succes]')&.text.to_s.squish
  def tableau_erreurs = page.at_css('[data-testid=tableau_erreurs]')&.text.to_s.squish
  def premiere_erreur = page.at_css('[data-testid=tableau_erreurs] tbody tr')
end
