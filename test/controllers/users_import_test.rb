# frozen_string_literal: true

require 'test_helper'
require 'spreadsheet'

# Import XLS des agents — `users#import` (formulaire) et `users#import_do` (traitement).
class UsersImportTest < ActionDispatch::IntegrationTest
  # En-têtes du modèle officiel téléchargeable (= User.xls_headers, épinglé plus bas).
  ENTETES = %w[Nom Prénom Email Téléphone Service Mémo].freeze

  setup do
    Spreadsheet.client_encoding = 'UTF-8'
    @tempfiles = []
    @admin = users(:administrateur_paris)
    sign_in @admin
  end

  teardown do
    @tempfiles.each(&:close!)
  end

  # --- A. Accès et autorisation -------------------------------------------

  test 'un manager accède au formulaire d’import' do
    sign_in users(:hidalgo)

    get import_users_url

    assert_response :success
  end

  test 'un agent ne peut pas accéder au formulaire d’import' do
    sign_in users(:bond)

    get import_users_url

    assert_redirected_to root_path
    assert_equal "Vous n'êtes pas autorisé à effectuer cette action.", flash[:alert]
  end

  test 'un adhérent ne peut pas lancer un import' do
    sign_in users(:weil)

    assert_no_difference 'User.count' do
      importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test')], save: 'true')
    end

    assert_redirected_to root_path
  end

  test 'un visiteur non connecté ne peut pas lancer un import' do
    sign_out @admin

    assert_no_difference 'User.count' do
      importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test')], save: 'true')
    end

    assert_redirected_to new_user_session_path
  end

  # --- B. Garde upload et structure du fichier ----------------------------

  # Sentinelle : les tests ci-dessous fabriquent leurs fichiers dans cet ordre de
  # colonnes ; si le modèle proposé aux utilisateurs change, ils doivent suivre.
  test 'les en-têtes attendues du modèle XLS n’ont pas changé' do
    assert_equal ENTETES, User.xls_headers
  end

  test 'sans fichier joint, l’import redirige vers le formulaire avec une alerte' do
    post import_do_users_url

    assert_redirected_to import_users_url
    assert_equal 'Manque le fichier source pour pouvoir lancer l\'importation !', flash[:alert]
  end

  test 'une colonne obligatoire manquante interrompt l’import avant toute écriture' do
    entetes_sans_service = %w[Nom Prénom Email]

    assert_no_difference 'User.count' do
      importer([entetes_sans_service, ['Durand', 'Marie', 'marie.durand@example.test']], save: 'true')
    end

    assert_response :success
    assert_match(/Structure du fichier invalide/, flash[:alert])
  end

  test 'l’ordre des colonnes est libre grâce au mapping dynamique' do
    entetes_inversées = %w[Mémo Service Téléphone Email Prénom Nom]
    ligne_inversée    = ['Note', 'Informatique', '0102030405', 'marie.durand@example.test', 'Marie', 'Durand']

    assert_difference 'User.count', 1 do
      importer([entetes_inversées, ligne_inversée], save: 'true')
    end

    créé = User.find_by(email: 'marie.durand@example.test')
    assert_equal 'DURAND', créé.nom
    assert_includes créé.services, services(:informatique)
  end

  test 'les en-têtes sont reconnues sans accents ni casse' do
    entetes_brutes = %w[NOM PRENOM EMAIL TELEPHONE SERVICE MEMO]

    assert_difference 'User.count', 1 do
      importer([entetes_brutes, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test')],
               save: 'true')
    end
  end

  test 'un fichier réduit aux en-têtes ne fait rien et annonce un succès' do
    assert_no_difference 'User.count' do
      importer([ENTETES], save: 'true')
    end

    assert_response :success
    assert_equal "L'importation a bien été exécutée.", flash[:notice]
    assert_match(/Lignes importées: 0 \| Lignes ignorées: 0/, response.body)
  end

  test 'un fichier qui n’est pas un XLS est refusé proprement' do
    skip 'BUG (comportement à définir) : aucune protection serveur, Spreadsheet.open lève ' \
         'et l’utilisateur reçoit une 500 — cf. users_controller.rb:216'

    fichier = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/exemple.png'), 'image/png')

    post import_do_users_url, params: { upload: fichier, save: 'false' }

    assert_response :success
    assert flash[:alert].present?, 'un fichier illisible doit produire une alerte, pas une erreur serveur'
  end

  # --- C. Création d'utilisateurs (chemin nominal) ------------------------

  test 'une ligne valide crée un agent rattaché à son service' do
    assert_difference 'User.count', 1 do
      importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test',
                               service: 'Informatique')],
               save: 'true')
    end

    créé = User.find_by(email: 'marie.durand@example.test')
    assert créé.agent?, 'un utilisateur importé est toujours créé avec le rôle agent'
    assert_includes créé.services, services(:informatique)
  end

  test 'le nom, le prénom et l’email sont normalisés à l’import' do
    importer([ENTETES, ligne(nom: '  durand ', prénom: 'MARIE', email: '  Marie.Durand@EXAMPLE.test  ')],
             save: 'true')

    créé = User.find_by(email: 'marie.durand@example.test')
    assert_not_nil créé, 'l’email doit être normalisé en minuscules et sans espaces'
    assert_equal 'DURAND', créé.nom
    assert_equal 'Marie', créé.prénom
  end

  test 'le téléphone et le mémo des colonnes optionnelles sont importés' do
    importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test',
                             téléphone: '0102030405', mémo: 'Import du 27/07')],
             save: 'true')

    créé = User.find_by(email: 'marie.durand@example.test')
    assert_equal '0102030405', créé.téléphone
    assert_equal 'Import du 27/07', créé.memo
  end

  test 'un utilisateur créé reçoit une invitation de la part de l’importateur' do
    assert_emails 1 do
      importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test')],
               save: 'true')
    end

    créé = User.find_by(email: 'marie.durand@example.test')
    assert_equal ['marie.durand@example.test'], ActionMailer::Base.deliveries.last.to
    assert_equal @admin.id, créé.invited_by_id
  end

  test 'le mot de passe généré pour un utilisateur importé satisfait la politique de complexité' do
    mot_de_passe = User.generate_random_password

    candidat = User.new(nom: 'DURAND', prénom: 'Marie', email: 'marie.durand@example.test',
                        rôle: 'agent', password: mot_de_passe)
    candidat.user_services.build(service: services(:informatique))

    assert_equal 12, mot_de_passe.length
    assert candidat.valid?, candidat.errors.full_messages.join(', ')
  end

  test 'plusieurs lignes valides sont toutes importées et comptées' do
    lignes = [
      ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test'),
      ligne(nom: 'Dupuis', prénom: 'Paul', email: 'paul.dupuis@example.test')
    ]

    assert_difference 'User.count', 2 do
      importer([ENTETES] + lignes, save: 'true')
    end

    assert_match(/Lignes importées: 2 \| Lignes ignorées: 0/, response.body)
  end

  # --- D. Mise à jour d'un utilisateur existant ---------------------------

  test 'un email déjà connu met à jour l’utilisateur sans créer de doublon' do
    martin = users(:martin_technique_paris)

    assert_no_difference 'User.count' do
      importer([ENTETES, ligne(nom: 'Martin-Durand', prénom: 'Michel', email: martin.email.upcase,
                               service: 'Technique', mémo: 'Mis à jour par import')],
               save: 'true')
    end

    martin.reload
    assert_equal 'MARTIN-DURAND', martin.nom
    assert_equal 'Mis à jour par import', martin.memo
  end

  test 'une mise à jour ne déclenche aucune nouvelle invitation' do
    martin = users(:martin_technique_paris)

    assert_no_emails do
      importer([ENTETES, ligne(nom: 'Martin', prénom: 'Michel', email: martin.email, service: 'Technique')],
               save: 'true')
    end
  end

  test 'un service déjà rattaché n’est pas rattaché une seconde fois' do
    martin = users(:martin_technique_paris)

    assert_no_difference 'UserService.count' do
      importer([ENTETES, ligne(nom: 'Martin', prénom: 'Michel', email: martin.email, service: 'Technique')],
               save: 'true')
    end
  end

  test 'un service supplémentaire s’ajoute sans retirer les précédents' do
    martin = users(:martin_technique_paris)

    assert_difference 'UserService.count', 1 do
      importer([ENTETES, ligne(nom: 'Martin', prénom: 'Michel', email: martin.email, service: 'Informatique')],
               save: 'true')
    end

    martin.reload
    assert_includes martin.services, services(:informatique)
    assert_includes martin.services, services(:technique)
  end

  test 'un fichier sans colonne Téléphone conserve le téléphone existant' do
    skip 'BUG : les colonnes optionnelles absentes écrasent les valeurs en base ' \
         '(users_controller.rb:248-249) — perte de données silencieuse'

    martin = users(:martin_technique_paris)
    martin.update_columns(téléphone: '0102030405')
    entetes_sans_telephone = %w[Nom Prénom Email Service]

    importer([entetes_sans_telephone, ['Martin', 'Michel', martin.email, 'Technique']], save: 'true')

    assert_equal '0102030405', martin.reload.téléphone
  end

  test 'un email appartenant à un utilisateur désactivé est signalé en erreur' do
    # ÉPINGLAGE : `User.where(...)` subit le `default_scope :kept`, l'utilisateur
    # soft-deleté n'est donc pas retrouvé → tentative de création → unicité en défaut.
    désactivé = users(:agent_discarded_paris)

    assert_no_difference 'User.count' do
      importer([ENTETES, ligne(nom: 'Spectre', prénom: 'Ancien', email: désactivé.email, service: 'Technique')],
               save: 'true')
    end

    assert_match(/ERREURS: email .*est déjà utilisé/, response.body,
                 'l’erreur remontée est une collision d’unicité, sans mention de la désactivation')
    assert_match(/Lignes importées: 0 \| Lignes ignorées: 1/, response.body)
  end

  # --- E. Mode simulation vs enregistrement -------------------------------

  test 'sans paramètre save, l’import ne fait que simuler' do
    assert_no_difference 'User.count' do
      importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test')])
    end

    assert_match(/Les modifications n'ont pas été enregistrées/, response.body)
  end

  test 'avec save à false, aucun utilisateur n’est créé ni invité' do
    assert_no_emails do
      assert_no_difference 'User.count' do
        importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test')],
                 save: 'false')
      end
    end
  end

  test 'la simulation signale les erreurs sans rien enregistrer' do
    assert_no_difference 'User.count' do
      importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test',
                               service: 'Zorglub')],
               save: 'false')
    end

    assert_match(/Zorglub/, response.body)
    assert_equal "L'importation a échouée.", flash[:alert]
  end

  test 'la simulation ne modifie pas un utilisateur existant' do
    martin = users(:martin_technique_paris)
    nom_initial = martin.nom

    importer([ENTETES, ligne(nom: 'Martin-Durand', prénom: 'Michel', email: martin.email, service: 'Technique')],
             save: 'false')

    assert_equal nom_initial, martin.reload.nom
  end

  # --- F. Lignes en erreur et cas limites de données ----------------------

  test 'un service introuvable met la ligne en erreur en citant la valeur lue' do
    assert_no_difference 'User.count' do
      importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test',
                               service: 'Zorglub')],
               save: 'true')
    end

    assert_equal "L'importation a échouée.", flash[:alert]
    assert_match(/Zorglub/, response.body)
  end

  test 'une ligne en erreur n’empêche pas l’import des lignes valides' do
    lignes = [
      ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test', service: 'Informatique'),
      ligne(nom: 'Dupuis', prénom: 'Paul', email: 'paul.dupuis@example.test', service: 'Zorglub')
    ]

    assert_difference 'User.count', 1 do
      importer([ENTETES] + lignes, save: 'true')
    end

    assert_equal "L'importation a partiellement échouée.", flash[:alert]
    assert_match(/Lignes importées: 1 \| Lignes ignorées: 1/, response.body)
  end

  test 'un email invalide met la ligne en erreur' do
    assert_no_difference 'User.count' do
      importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'pas-un-email')], save: 'true')
    end

    assert_match(/Lignes importées: 0 \| Lignes ignorées: 1/, response.body)
  end

  test 'une ligne sans nom est ignorée sans être comptée' do
    # ÉPINGLAGE : `next` silencieux (users_controller.rb:237) — la ligne n'apparaît
    # ni dans les importées ni dans les ignorées, et le bilan annonce un succès.
    assert_no_difference 'User.count' do
      importer([ENTETES, ligne(nom: '', prénom: 'Marie', email: 'marie.durand@example.test')], save: 'true')
    end

    assert_match(/Lignes importées: 0 \| Lignes ignorées: 0/, response.body)
    assert_equal "L'importation a bien été exécutée.", flash[:notice]
  end

  test 'une ligne sans email est ignorée sans être comptée' do
    # ÉPINGLAGE : idem, `next` silencieux (users_controller.rb:240).
    assert_no_difference 'User.count' do
      importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: '')], save: 'true')
    end

    assert_match(/Lignes importées: 0 \| Lignes ignorées: 0/, response.body)
  end

  test 'les noms accentués et non ASCII sont importés et normalisés' do
    importer([ENTETES, ligne(nom: 'Ångström', prénom: 'józef', email: 'jozef.angstrom@example.test')],
             save: 'true')

    créé = User.find_by(email: 'jozef.angstrom@example.test')
    assert_equal 'ÅNGSTRÖM', créé.nom
    assert_equal 'Józef', créé.prénom
  end

  test 'un même email répété dans le fichier ne crée qu’un utilisateur' do
    lignes = [
      ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test'),
      ligne(nom: 'Durand-Dupuis', prénom: 'Marie', email: 'marie.durand@example.test')
    ]

    assert_difference 'User.count', 1 do
      importer([ENTETES] + lignes, save: 'true')
    end

    # ÉPINGLAGE : les deux lignes sont comptées comme importées, la seconde étant
    # traitée comme une mise à jour de la première.
    assert_match(/Lignes importées: 2 \| Lignes ignorées: 0/, response.body)
    assert_equal 'DURAND-DUPUIS', User.find_by(email: 'marie.durand@example.test').nom
  end

  # --- G. Cloisonnement multi-organisations (défauts épinglés) ------------

  test 'un service d’une autre organisation est accepté par l’import' do
    # ÉPINGLAGE B20 : `Service.find_by(nom:)` (users_controller.rb:259) n'est pas borné à
    # l'organisation courante, alors que l'unicité du nom l'est (service.rb:21).
    service_marseille = Service.create!(nom: 'Voirie', organisation: organisations(:mairie_marseille))

    importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test',
                             service: 'Voirie')],
             save: 'true')

    créé = User.find_by(email: 'marie.durand@example.test')
    assert_includes créé.services, service_marseille
    assert_equal organisations(:mairie_marseille), créé.organisation
  end

  test 'l’import peut rétrograder un manager d’une autre organisation en agent' do
    # ÉPINGLAGE B21 : la recherche par email (users_controller.rb:242) est globale et
    # aucun `authorize` ne porte sur l'enregistrement retrouvé ; `rôle = 'agent'`.
    manager_marseille = users(:manager_marseille)

    importer([ENTETES, ligne(nom: 'Payan', prénom: 'Benoit', email: manager_marseille.email,
                             service: 'Informatique')],
             save: 'true')

    manager_marseille.reload
    assert manager_marseille.agent?, 'le rôle est écrasé sans contrôle'
    assert_includes manager_marseille.services, services(:informatique)
  end

  test 'l’import rétrograde un manager de sa propre organisation en agent' do
    # ÉPINGLAGE B21 (variante intra-organisation) : perte de privilèges silencieuse
    # dès qu'un manager figure par mégarde dans le fichier d'agents.
    hidalgo = users(:hidalgo)

    importer([ENTETES, ligne(nom: 'Hidalgo', prénom: 'Anne', email: hidalgo.email, service: 'Informatique')],
             save: 'true')

    assert hidalgo.reload.agent?
  end

  # --- H. Effets de bord --------------------------------------------------

  test 'la création par import est tracée dans l’audit trail' do
    importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test')],
             save: 'true')

    créé = User.find_by(email: 'marie.durand@example.test')
    assert_equal 1, créé.audits.where(action: 'create').count
  end

  test 'l’invitation envoyée est tracée dans les MailLog' do
    assert_difference 'MailLog.count', 1 do
      importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test')],
               save: 'true')
    end

    assert_equal 'marie.durand@example.test', MailLog.last.to
  end

  test 'l’import n’enfile aucun job de fond' do
    assert_no_enqueued_jobs do
      importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie.durand@example.test')],
               save: 'true')
    end
  end

  private

  # Construit une ligne du fichier dans l'ordre d'ENTETES.
  def ligne(nom:, prénom:, email:, service: 'Informatique', téléphone: nil, mémo: nil)
    [nom, prénom, email, téléphone, service, mémo]
  end

  # Fabrique un vrai fichier XLS 97-2003 (format attendu par la gem Spreadsheet).
  def fichier_xls(lignes)
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet(name: 'Import')
    lignes.each_with_index { |ligne, index| sheet.row(index).replace(ligne) }

    tempfile = Tempfile.new(['import', '.xls'])
    book.write(tempfile.path)
    @tempfiles << tempfile

    Rack::Test::UploadedFile.new(tempfile.path, 'application/vnd.ms-excel')
  end

  def importer(lignes, save: nil)
    params = { upload: fichier_xls(lignes) }
    params[:save] = save unless save.nil?

    post import_do_users_url, params: params
  end
end
