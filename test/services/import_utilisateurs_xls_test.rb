# frozen_string_literal: true

require 'test_helper'
require_relative '../support/fabrique_xls'

# Import XLS des agents — logique ligne à ligne (`ImportUtilisateursXls`).
# Le parcours HTTP et le bilan affiché sont couverts par `users_import_test.rb`.
class ImportUtilisateursXlsTest < ActiveSupport::TestCase
  include FabriqueXls
  include ActionMailer::TestHelper

  setup do
    # Hors test d'intégration les routes ne sont pas chargées, donc `Devise.mappings`
    # est vide et l'envoi de l'invitation lève « Could not find a valid mapping ».
    Rails.application.reload_routes_unless_loaded

    @importateur = users(:administrateur_paris)
    @organisation = organisations(:mairie_paris)
  end

  teardown { fermer_fichiers }

  # ==================== TESTS CRITIQUES ====================
  # Cloisonnement multi-organisations et intégrité des comptes existants :
  # l'import écrit sans passer par un formulaire, il est le seul garde-fou.

  test 'un service homonyme d’une autre organisation n’est jamais retenu' do
    Service.create!(nom: 'Voirie', organisation: organisations(:mairie_marseille))

    rapport = importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie@example.test',
                                      service: 'Voirie')], appliquer: true)

    assert_equal 0, rapport.importés
    assert_nil User.find_by(email: 'marie@example.test')
    assert_match(/introuvable dans votre organisation/, rapport.erreurs.first.messages.join)
  end

  test 'un service de l’organisation courante est retenu même s’il existe un homonyme ailleurs' do
    voirie_paris = Service.create!(nom: 'Voirie', organisation: @organisation)
    Service.create!(nom: 'Voirie', organisation: organisations(:mairie_marseille))

    rapport = importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie@example.test',
                                      service: 'Voirie')], appliquer: true)

    assert_equal 1, rapport.importés
    assert_equal [voirie_paris], User.find_by(email: 'marie@example.test').services
  end

  test 'un agent d’une autre organisation n’est ni modifié ni aspiré' do
    agent = users(:agent_marseille)
    services_avant = agent.services.to_a

    rapport = importer([ENTETES, ligne(nom: 'Renommé', prénom: 'Par Import', email: agent.email)],
                       appliquer: true)

    agent.reload
    assert_equal 0, rapport.importés
    assert_not_equal 'RENOMMÉ', agent.nom
    assert_equal services_avant, agent.services.to_a
    assert_match(/une autre organisation/, rapport.erreurs.first.messages.join)
  end

  test 'un manager de l’organisation n’est pas rétrogradé en agent' do
    manager = users(:hidalgo)

    rapport = importer([ENTETES, ligne(nom: 'Hidalgo', prénom: 'Anne', email: manager.email)],
                       appliquer: true)

    assert manager.reload.manager?
    assert_equal 0, rapport.importés
    assert_match(/ce compte est un manager/, rapport.erreurs.first.messages.join)
  end

  test 'un manager mono-service n’est pas rétrogradé même quand son unique service est celui du fichier' do
    manager = User.create!(nom: 'Mono', prénom: 'Service', email: 'mono.service@example.test',
                           rôle: 'manager', password: 'qtDug$d843sqACz?V',
                           service_ids: [services(:informatique).id])

    importer([ENTETES, ligne(nom: 'Mono', prénom: 'Service', email: manager.email, service: 'Informatique')],
             appliquer: true)

    assert manager.reload.manager?, 'B21 : la recherche par email ne doit jamais changer le rôle'
  end

  test 'un administrateur n’est pas rétrogradé en agent' do
    admin = users(:administrateur_paris)

    rapport = importer([ENTETES, ligne(nom: 'Admin', prénom: 'Paris', email: admin.email)], appliquer: true)

    assert admin.reload.administrateur?
    assert_match(/ce compte est un administrateur/, rapport.erreurs.first.messages.join)
  end

  test 'un adhérent n’est pas transformé en agent' do
    adhérent = users(:weil)
    services_avant = adhérent.services.to_a

    rapport = importer([ENTETES, ligne(nom: 'Weil', prénom: 'Ariel', email: adhérent.email)], appliquer: true)

    adhérent.reload
    assert adhérent.adhérent?
    assert_equal services_avant, adhérent.services.to_a
    assert_match(/ce compte est un adhérent/, rapport.erreurs.first.messages.join)
  end

  test 'un compte désactivé est signalé comme tel, sans être réactivé ni dupliqué' do
    désactivé = users(:agent_discarded_paris)

    assert_no_difference 'User.unscoped.count' do
      @rapport = importer([ENTETES, ligne(nom: 'Spectre', prénom: 'Ancien', email: désactivé.email)],
                          appliquer: true)
    end

    assert désactivé.reload.discarded?, 'un import ne réactive jamais un compte'
    assert_match(/ce compte est désactivé/, @rapport.erreurs.first.messages.join)
    assert_no_match(/déjà utilisé/, @rapport.erreurs.first.messages.join,
                    'le motif doit nommer la désactivation, pas la collision d’unicité')
  end

  # ==================== /TESTS CRITIQUES ====================

  # --- A. Lecture du fichier ----------------------------------------------

  test 'un fichier qui n’est pas un classeur est refusé sans lever' do
    rapport = ImportUtilisateursXls.call(fichier: fichier_illisible.path, importateur: @importateur,
                                         organisation: @organisation, appliquer: true)

    assert rapport.illisible?
    assert rapport.interrompu?
    assert_equal ImportUtilisateursXls::FICHIER_ILLISIBLE, rapport.message_interruption
    assert_equal 0, rapport.total
  end

  test 'une image renommée en .xls est refusée sans lever' do
    image = Rails.root.join('test/fixtures/files/exemple.png')
    skip 'pas d’image de fixture' unless File.exist?(image)

    rapport = ImportUtilisateursXls.call(fichier: image.to_s, importateur: @importateur,
                                         organisation: @organisation, appliquer: true)

    assert rapport.illisible?
  end

  test 'un fichier inexistant est refusé sans lever' do
    rapport = ImportUtilisateursXls.call(fichier: '/tmp/aucun_fichier_ici.xls', importateur: @importateur,
                                         organisation: @organisation, appliquer: true)

    assert rapport.illisible?
  end

  test 'une colonne obligatoire manquante interrompt avant toute écriture' do
    assert_no_difference 'User.count' do
      @rapport = importer([%w[Nom Prénom Email], ['Durand', 'Marie', 'marie@example.test']], appliquer: true)
    end

    assert @rapport.structure_invalide?
    assert_equal 0, @rapport.total
  end

  test 'l’ordre des colonnes est libre' do
    rapport = importer([%w[Mémo Service Téléphone Email Prénom Nom],
                        ['Note', 'Informatique', '0102030405', 'marie@example.test', 'Marie', 'Durand']],
                       appliquer: true)

    assert_equal 1, rapport.importés
    créé = User.find_by(email: 'marie@example.test')
    assert_equal '0102030405', créé.téléphone
    assert_equal [services(:informatique)], créé.services
  end

  test 'les en-têtes sont reconnues sans accents ni casse' do
    rapport = importer([%w[NOM PRENOM EMAIL TELEPHONE SERVICE MEMO],
                        ligne(nom: 'Durand', prénom: 'Marie', email: 'marie@example.test')],
                       appliquer: true)

    assert_equal 1, rapport.importés
  end

  test 'une colonne inconnue est ignorée' do
    rapport = importer([ENTETES + ['Matricule'],
                        ligne(nom: 'Durand', prénom: 'Marie', email: 'marie@example.test') + ['A42']],
                       appliquer: true)

    assert_equal 1, rapport.importés
  end

  test 'un fichier réduit aux en-têtes ne traite aucune ligne' do
    rapport = importer([ENTETES], appliquer: true)

    assert_not rapport.interrompu?
    assert_equal 0, rapport.total
  end

  test 'une ligne entièrement vide est ignorée sans compter comme une erreur' do
    rapport = importer([ENTETES, [], ligne(nom: 'Durand', prénom: 'Marie', email: 'marie@example.test')],
                       appliquer: true)

    assert_equal 1, rapport.importés
    assert_equal 0, rapport.en_erreur
  end

  # --- B. Création ---------------------------------------------------------

  test 'une ligne valide crée un agent rattaché à son service' do
    rapport = importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie@example.test')],
                       appliquer: true)

    créé = User.find_by(email: 'marie@example.test')
    assert créé.agent?
    assert_equal [services(:informatique)], créé.services
    assert_equal 'Nouveau', rapport.succès.first.type
  end

  test 'le nom, le prénom et l’email sont normalisés' do
    importer([ENTETES, ligne(nom: '  durand ', prénom: 'MARIE', email: '  Marie.Durand@EXAMPLE.test  ')],
             appliquer: true)

    créé = User.find_by(email: 'marie.durand@example.test')
    assert_equal 'DURAND', créé.nom
    assert_equal 'Marie', créé.prénom
  end

  test 'le nom du service est reconnu quelle que soit la casse' do
    rapport = importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie@example.test',
                                      service: 'INFORMATIQUE')], appliquer: true)

    assert_equal 1, rapport.importés
    assert_equal [services(:informatique)], User.find_by(email: 'marie@example.test').services
  end

  test 'un utilisateur créé reçoit une invitation de l’importateur' do
    assert_emails 1 do
      importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie@example.test')], appliquer: true)
    end

    assert_equal @importateur.id, User.find_by(email: 'marie@example.test').invited_by_id
  end

  test 'la création est tracée dans l’audit trail' do
    importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie@example.test')], appliquer: true)

    assert_equal 1, User.find_by(email: 'marie@example.test').audits.where(action: 'create').count
  end

  test 'plusieurs lignes valides sont toutes importées' do
    rapport = importer([ENTETES,
                        ligne(nom: 'Durand', prénom: 'Marie', email: 'marie@example.test'),
                        ligne(nom: 'Dupuis', prénom: 'Paul', email: 'paul@example.test')],
                       appliquer: true)

    assert_equal 2, rapport.importés
    assert_equal [2, 3], rapport.succès.map(&:numéro)
  end

  test 'les noms non ASCII sont importés et normalisés' do
    importer([ENTETES, ligne(nom: 'Ångström', prénom: 'józef', email: 'jozef@example.test')], appliquer: true)

    créé = User.find_by(email: 'jozef@example.test')
    assert_equal 'ÅNGSTRÖM', créé.nom
    assert_equal 'Józef', créé.prénom
  end

  # --- C. Mise à jour d'un agent existant ---------------------------------

  test 'un email déjà connu met à jour sans créer de doublon' do
    martin = users(:martin_technique_paris)

    assert_no_difference 'User.count' do
      importer([ENTETES, ligne(nom: 'Martin-Durand', prénom: 'Michel', email: martin.email.upcase,
                              service: 'Technique', mémo: 'Mis à jour')], appliquer: true)
    end

    martin.reload
    assert_equal 'MARTIN-DURAND', martin.nom
    assert_equal 'Mis à jour', martin.memo
  end

  test 'une mise à jour ne déclenche aucune invitation' do
    assert_no_emails do
      importer([ENTETES, ligne(nom: 'Martin', prénom: 'Michel',
                              email: users(:martin_technique_paris).email, service: 'Technique')],
               appliquer: true)
    end
  end

  test 'un service déjà rattaché n’est pas rattaché une seconde fois' do
    assert_no_difference 'UserService.count' do
      importer([ENTETES, ligne(nom: 'Martin', prénom: 'Michel',
                              email: users(:martin_technique_paris).email, service: 'Technique')],
               appliquer: true)
    end
  end

  test 'un autre service remplace celui de l’agent' do
    martin = users(:martin_technique_paris)

    assert_no_difference 'UserService.count' do
      @rapport = importer([ENTETES, ligne(nom: 'Martin', prénom: 'Michel', email: martin.email,
                                         service: 'Informatique')], appliquer: true)
    end

    assert_equal [services(:informatique)], martin.reload.services
    assert_equal 1, @rapport.importés
  end

  test 'le remplacement de service est tracé dans l’audit trail' do
    martin = users(:martin_technique_paris)

    importer([ENTETES, ligne(nom: 'Martin', prénom: 'Michel', email: martin.email, service: 'Informatique')],
             appliquer: true)

    actions = Audited::Audit.where(auditable_type: 'UserService', associated_id: martin.id).pluck(:action)
    assert_includes actions, 'create'
    assert_includes actions, 'destroy'
  end

  test 'le bilan d’un remplacement nomme l’ancien et le nouveau service' do
    rapport = importer([ENTETES, ligne(nom: 'Martin', prénom: 'Michel',
                                      email: users(:martin_technique_paris).email, service: 'Informatique')],
                       appliquer: true)

    assert_equal %w[Technique Informatique], rapport.succès.first.changements['service']
  end

  test 'une colonne facultative absente n’efface pas la valeur en base' do
    martin = users(:martin_technique_paris)
    martin.update_columns(téléphone: '0102030405', memo: 'À conserver')

    importer([%w[Nom Prénom Email Service], ['Martin', 'Michel', martin.email, 'Technique']], appliquer: true)

    martin.reload
    assert_equal '0102030405', martin.téléphone
    assert_equal 'À conserver', martin.memo
  end

  test 'une colonne facultative présente mais vide efface la valeur en base' do
    martin = users(:martin_technique_paris)
    martin.update_columns(téléphone: '0102030405')

    importer([ENTETES, ligne(nom: 'Martin', prénom: 'Michel', email: martin.email, service: 'Technique')],
             appliquer: true)

    assert_nil martin.reload.téléphone, 'une colonne présente et vide vaut effacement explicite'
  end

  # --- D. Mode simulation --------------------------------------------------

  test 'la simulation ne crée rien et n’envoie rien' do
    assert_no_emails do
      assert_no_difference 'User.count' do
        @rapport = importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie@example.test')])
      end
    end

    assert_equal 1, @rapport.importés, 'la simulation annonce ce qui serait importé'
    assert_not @rapport.appliqué
  end

  test 'la simulation ne modifie pas un utilisateur existant' do
    martin = users(:martin_technique_paris)
    nom_initial = martin.nom

    importer([ENTETES, ligne(nom: 'Martin-Durand', prénom: 'Michel', email: martin.email,
                             service: 'Technique')])

    assert_equal nom_initial, martin.reload.nom
  end

  test 'la simulation d’un changement de service ne détache rien' do
    martin = users(:martin_technique_paris)

    assert_no_difference 'UserService.count' do
      importer([ENTETES, ligne(nom: 'Martin', prénom: 'Michel', email: martin.email, service: 'Informatique')])
    end

    assert_equal [services(:technique)], martin.reload.services
  end

  test 'la simulation signale les erreurs' do
    rapport = importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie@example.test',
                                      service: 'Zorglub')])

    assert_equal 1, rapport.en_erreur
    assert_match(/Zorglub/, rapport.erreurs.first.messages.join)
  end

  # --- E. Lignes en erreur -------------------------------------------------

  test 'une ligne sans nom est comptée en erreur avec son numéro' do
    rapport = importer([ENTETES, ligne(nom: '', prénom: 'Marie', email: 'marie@example.test')], appliquer: true)

    assert_equal 0, rapport.importés
    assert_equal 1, rapport.en_erreur
    assert_equal 2, rapport.erreurs.first.numéro
    assert_equal ['Nom manquant'], rapport.erreurs.first.messages
  end

  test 'une ligne sans email est comptée en erreur avec son numéro' do
    rapport = importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: '')], appliquer: true)

    assert_equal ['Email manquant'], rapport.erreurs.first.messages
    assert_equal 2, rapport.erreurs.first.numéro
  end

  test 'le numéro de ligne signalé est celui du classeur' do
    rapport = importer([ENTETES,
                        ligne(nom: 'Durand', prénom: 'Marie', email: 'marie@example.test'),
                        ligne(nom: 'Dupuis', prénom: 'Paul', email: 'paul@example.test', service: 'Zorglub')],
                       appliquer: true)

    assert_equal 3, rapport.erreurs.first.numéro
  end

  test 'un service introuvable cite la valeur lue' do
    rapport = importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie@example.test',
                                      service: 'Zorglub')], appliquer: true)

    assert_match(/Valeur lue: 'Zorglub'/, rapport.erreurs.first.messages.join)
    assert_no_match(/au moins un service/, rapport.erreurs.first.messages.join,
                    'le motif générique de présence doublerait la cause réelle')
    assert_equal 1, rapport.erreurs.first.messages.size
  end

  test 'un service vide cite VIDE' do
    rapport = importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'marie@example.test',
                                      service: '')], appliquer: true)

    assert_match(/Valeur lue: 'VIDE'/, rapport.erreurs.first.messages.join)
  end

  test 'un email invalide met la ligne en erreur' do
    assert_no_difference 'User.count' do
      @rapport = importer([ENTETES, ligne(nom: 'Durand', prénom: 'Marie', email: 'pas-un-email')],
                          appliquer: true)
    end

    assert_equal 1, @rapport.en_erreur
  end

  test 'une ligne en erreur n’empêche pas l’import des suivantes' do
    rapport = importer([ENTETES,
                        ligne(nom: 'Dupuis', prénom: 'Paul', email: 'paul@example.test', service: 'Zorglub'),
                        ligne(nom: 'Durand', prénom: 'Marie', email: 'marie@example.test')],
                       appliquer: true)

    assert_equal 1, rapport.importés
    assert_equal 1, rapport.en_erreur
    assert_not_nil User.find_by(email: 'marie@example.test')
  end

  test 'un échec d’enregistrement est compté en erreur, jamais en succès' do
    rapport = ImportQuiEchoue.call(fichier: televersement([ENTETES, ligne(nom: 'Durand', prénom: 'Marie',
                                                                        email: 'marie@example.test')]),
                                   importateur: @importateur, organisation: @organisation, appliquer: true)

    assert_equal 0, rapport.importés
    assert_equal 1, rapport.en_erreur
    assert_nil User.find_by(email: 'marie@example.test')
  end

  test 'un même email répété dans le fichier ne crée qu’un utilisateur' do
    rapport = importer([ENTETES,
                        ligne(nom: 'Durand', prénom: 'Marie', email: 'marie@example.test'),
                        ligne(nom: 'Durand-Dupuis', prénom: 'Marie', email: 'marie@example.test')],
                       appliquer: true)

    assert_equal 1, User.where(email: 'marie@example.test').count
    assert_equal 'DURAND-DUPUIS', User.find_by(email: 'marie@example.test').nom
    assert_equal ['Nouveau', 'Mise à jour'], rapport.succès.map(&:type)
  end

  # --- F. Périmètre de l'importateur --------------------------------------

  test 'un importateur sans organisation ne rattache aucun service' do
    rapport = ImportUtilisateursXls.call(fichier: televersement([ENTETES,
                                                                 ligne(nom: 'Durand', prénom: 'Marie',
                                                                       email: 'marie@example.test')]),
                                         importateur: @importateur, organisation: nil, appliquer: true)

    assert_equal 0, rapport.importés
    assert_nil User.find_by(email: 'marie@example.test')
  end

  private

  def importer(lignes, appliquer: false)
    ImportUtilisateursXls.call(fichier: televersement(lignes), importateur: @importateur,
                              organisation: @organisation, appliquer: appliquer)
  end
end

# Reproduit un `save` refusé alors que les validations passent (course sur
# l'unicité de l'email, échec d'invitation) : le bilan doit compter la ligne en
# erreur et ne rien laisser derrière lui.
class ImportQuiEchoue < ImportUtilisateursXls
  private

  def nouvel_utilisateur(email)
    super.tap { |utilisateur| utilisateur.define_singleton_method(:save) { |*| false } }
  end
end
