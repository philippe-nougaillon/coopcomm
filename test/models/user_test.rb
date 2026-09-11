# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test 'absences imbriquées : ligne sans dates → ignorée' do
    agent = users(:bond)

    assert_no_difference('Absence.count') do
      agent.update(absences_attributes: { '0' => { du: '', au: '', motif: 'formation' } })
    end
  end

  test 'normalisation : nom et prénom saisis à la volée → nom en capitales, prénom humanisé' do
    utilisateur = User.create!(nom: '  dupont ', prénom: '  jeanne ', email: "n-#{SecureRandom.hex(4)}@example.test",
                               rôle: 'adhérent', password: 'qtDug$d843sqACz?V',
                               service_ids: [services(:informatique).id],
                               address: 'Mairie de Paris', latitude: 48.85, longitude: 2.35)

    assert_equal 'DUPONT', utilisateur.nom
    assert_equal 'Jeanne', utilisateur.prénom
  end

  # ==================== TESTS CRITIQUES ====================
  # Rattachement aux services :
  # L'organisation d'un utilisateur dérive de ses services : un compte sans service
  # n'appartient à aucune organisation, n'apparaît dans aucune liste (`by_service`
  # joint `user_services`) et fait échouer tout ce qui lit `current_organisation`.

  User.rôles.each_key do |rôle|
    test "must_have_at_least_one_service : un #{rôle} sans service → refusé (critique)" do
      user = nouveau(rôle: rôle)

      assert_not user.valid?
      assert_includes user.errors[:services], 'doit comporter au moins un service'
    end

    test "must_have_at_least_one_service : un #{rôle} avec un service → accepté (critique)" do
      assert nouveau(rôle: rôle, service_ids: [services(:informatique).id]).valid?
    end
  end

  test 'must_have_at_least_one_service : dernier service retiré → refusé (critique)' do
    agent = users(:martin_technique_paris)

    agent.user_services.each(&:mark_for_destruction)

    assert_not agent.valid?
    assert_includes agent.errors[:services], 'doit comporter au moins un service'
  end

  test 'must_have_at_least_one_service : service remplacé dans le même enregistrement → accepté (critique)' do
    agent = users(:martin_technique_paris)

    agent.user_services.load
    agent.user_services.first.mark_for_destruction
    agent.user_services.build(service: services(:informatique))

    assert agent.valid?, agent.errors.full_messages.to_s
  end

  test 'agent_must_have_exactly_one_service : agent créé avec deux services → refusé (critique)' do
    agent = nouveau(rôle: 'agent', service_ids: [services(:informatique).id, services(:technique).id])

    assert_not agent.valid?
    assert_includes agent.errors[:services], "ne doit comporter qu'un seul service pour un agent"
  end

  test 'agent_must_have_exactly_one_service : second service ajouté à un agent existant → refusé (critique)' do
    agent = users(:martin_technique_paris)

    agent.user_services.build(service: services(:informatique))

    assert_not agent.valid?
    assert_includes agent.errors[:services], "ne doit comporter qu'un seul service pour un agent"
  end

  test 'agent_must_have_exactly_one_service : multi-services basculé en agent → refusé (critique)' do
    utilisateur = users(:hidalgo)

    utilisateur.rôle = 'agent'

    assert_not utilisateur.valid?
    assert_includes utilisateur.errors[:services], "ne doit comporter qu'un seul service pour un agent"
  end

  test 'agent_must_have_exactly_one_service : adhérent, manager et administrateur → plusieurs services acceptés (critique)' do
    %w[adhérent manager administrateur].each do |rôle|
      user = nouveau(rôle: rôle, service_ids: [services(:informatique).id, services(:technique).id])

      assert user.valid?, "#{rôle} devrait pouvoir porter deux services : #{user.errors.full_messages}"
    end
  end

  # Sans `dependent: :destroy` sur la through, Rails retire la ligne de liaison
  # par delete_all : aucun callback, donc aucune trace du service retiré.
  test 'services : service retiré à un utilisateur → trace dans l\'audit (critique)' do
    manager = users(:hidalgo)
    retiré = manager.services.first
    restants = manager.services.where.not(id: retiré.id)

    assert_difference -> { Audited::Audit.where(auditable_type: 'UserService', action: 'destroy').count }, 1 do
      manager.update!(service_ids: restants.ids)
    end

    audit = Audited::Audit.where(auditable_type: 'UserService', action: 'destroy').last

    assert_equal retiré.id, audit.audited_changes['service_id']
    assert_equal manager.id, audit.associated_id
  end

  test 'services : rattachement à un service → l\'organisation en dérive (critique)' do
    utilisateur = nouveau(rôle: 'adhérent', service_ids: [services(:informatique).id])

    utilisateur.save!

    assert_equal services(:informatique).organisation, utilisateur.organisation
  end

  test 'by_service : services demandés → leurs utilisateurs, jamais ceux des autres services (critique)' do
    utilisateurs = User.by_service([services(:informatique)])

    assert_includes utilisateurs, users(:weil)
    assert_not_includes utilisateurs, users(:agent_marseille)
  end

  test 'by_service : utilisateur de deux services demandés → rendu une seule fois (critique)' do
    utilisateurs = User.by_service([services(:service_paris), services(:technique)])

    assert_equal 1, utilisateurs.to_a.count(users(:hidalgo))
  end

  test 'by_service : utilisateur désactivé → exclu (critique)' do
    users(:weil).discard

    assert_not_includes User.by_service([services(:informatique)]), users(:weil)
  end

  test 'get_services_by_role : administrateur → tous les services de son organisation (critique)' do
    services_proposés = users(:administrateur_paris).get_services_by_role

    assert_includes services_proposés, services(:secretariat)
    assert_not_includes services_proposés, services(:service_marseille)
  end

  test 'get_services_by_role : manager → seulement les siens (critique)' do
    manager = users(:manager_paris)

    assert_equal manager.services.sort_by(&:id), manager.get_services_by_role.sort_by(&:id)
  end

  # Liste PLATE (sans groupe) des intervenants d'un ou plusieurs services, au format
  # [["NOM Prénom", id], …], triée par nom puis prénom.

  test 'agents_for_services : service demandé → ses intervenants (critique)' do
    ids = User.agents_for_services([services(:technique)]).map(&:last)

    assert_includes ids, users(:martin_technique_paris).id, 'agent du service attendu'
    assert_includes ids, users(:hidalgo).id,                'manager du service attendu'
    assert_includes ids, users(:administrateur_paris).id,   'administrateur du service attendu'
    assert_includes ids, users(:nettoyage).id,              'agent du service attendu'
  end

  test 'agents_for_services : adhérent du service → exclu (critique)' do
    ids = User.agents_for_services([services(:informatique)]).map(&:last)

    assert_not_includes ids, users(:weil).id
  end

  test 'agents_for_services : intervenant d\'un autre service ou d\'une autre organisation → exclu (critique)' do
    ids = User.agents_for_services([services(:technique)]).map(&:last)

    assert_not_includes ids, users(:agent_whatsapp).id
    assert_not_includes ids, users(:agent_marseille).id
  end

  test 'agents_for_services : intervenant retenu → rendu au format [nom complet, id] (critique)' do
    cible = users(:martin_technique_paris)

    agent = User.agents_for_services([services(:technique)]).find { |_nom, id| id == cible.id }

    assert_not_nil agent
    nom, id = agent

    assert_equal "#{cible.nom} #{cible.prénom}", nom
    assert_kind_of Integer, id
  end

  test 'agents_for_services : intervenant de deux services demandés → rendu une seule fois (critique)' do
    ids = User.agents_for_services([services(:service_paris), services(:technique)]).map(&:last)

    assert_equal 1, ids.count(users(:hidalgo).id)
  end

  # Les noms (premier mot) sont distincts et purement ASCII ici : un tri
  # croissant stable est vérifiable sans dépendre de la collation SQL.
  test 'agents_for_services : plusieurs intervenants → triés par nom croissant (critique)' do
    noms = User.agents_for_services([services(:technique)]).map { |nom, _id| nom.split.first }

    assert_equal noms.sort, noms
  end

  test 'agents_for_services : administrateur hors du service demandé → proposé quand même (critique)' do
    admin = users(:philippe_super_admin)

    ids = User.agents_for_services([services(:technique)]).map(&:last)

    assert_not_includes admin.service_ids, services(:technique).id
    assert_includes ids, admin.id
  end

  test 'agents_for_services : administrateur d\'une autre organisation → exclu (critique)' do
    ids = User.agents_for_services([services(:service_marseille)]).map(&:last)

    assert_not_includes ids, users(:philippe_super_admin).id
    assert_not_includes ids, users(:administrateur_paris).id
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'scope ordered : plusieurs comptes → triés sans tenir compte des accents ni de la casse' do
    service = services(:menage)
    %w[Élan aiguille Zoé].each do |nom|
      User.create!(nom: nom, prénom: 'Test', email: "#{SecureRandom.hex(4)}@example.test",
                   rôle: 'agent', password: 'qtDug$d843sqACz?V', service_ids: [service.id])
    end

    noms = User.by_service([service]).ordered.pluck(:nom)

    assert_operator noms.index('AIGUILLE'), :<, noms.index('ÉLAN')
    assert_operator noms.index('ÉLAN'), :<, noms.index('ZOÉ')
  end

  test 'nom_prénom : nom et prénom renseignés → les deux accolés' do
    assert_equal 'Bond James', users(:bond).nom_prénom
  end

  test 'nom_prenom_role : compte quelconque → nom, prénom et rôle en capitales' do
    assert_equal 'Bond James (AGENT)', users(:bond).nom_prenom_role
  end

  test 'initiales : nom et prénom renseignés → deux capitales' do
    assert_equal 'BJ', users(:bond).initiales
  end

  test 'super_admin? : email listé dans SUPER_ADMIN → vrai' do
    précédent = ENV.fetch('SUPER_ADMIN', nil)
    ENV['SUPER_ADMIN'] = "autre@example.test,#{users(:bond).email}"

    assert users(:bond).super_admin?
    assert_not users(:weil).super_admin?
  ensure
    ENV['SUPER_ADMIN'] = précédent
  end

  test 'super_admin? : variable d\'environnement absente → faux' do
    précédent = ENV.fetch('SUPER_ADMIN', nil)
    ENV['SUPER_ADMIN'] = nil

    assert_not users(:bond).super_admin?
  ensure
    ENV['SUPER_ADMIN'] = précédent
  end

  test 'moyenne : interventions notées → la moyenne de leurs notes' do
    agent = users(:bond)

    assert_in_delta agent.rated_interventions.average(:note).to_f, agent.moyenne, 1e-6
  end

  test 'moyenne : aucune intervention notée → nil' do
    assert_nil users(:weil).moyenne
  end

  test 'rated_interventions : interventions de l\'agent → celles notées, hors modèles de pointage' do
    notées = users(:bond).rated_interventions

    assert notées.all? { |i| i.note.present? && i.repeter == false }
    assert_equal notées.count, users(:bond).total_rating
  end

  test 'star_count : note donnée → sa part en pourcentage des interventions notées' do
    agent = users(:bond)
    total = (1..5).sum { |note| agent.interventions.where(note: note, repeter: false).count }
    quatre_étoiles = agent.interventions.where(note: 4, repeter: false).count

    assert_in_delta (quatre_étoiles.to_f / total) * 100, agent.star_count(4), 1e-6
  end

  test 'star_count : aucune intervention notée → zéro, sans division par zéro' do
    assert_equal 0.0, users(:adhérent_sans_intervention).star_count(3)
  end

  test 'avatar : chaque rôle → l\'icône qui le distingue à l\'écran' do
    assert_equal 'manage_accounts', users(:hidalgo).avatar
    assert_equal 'person', users(:bond).avatar
    assert_equal 'corporate_fare', users(:weil).avatar
    assert_equal 'supervisor_account', users(:administrateur_paris).avatar
  end

  test 'new_messages? : message non lu reçu d\'un collègue de service → vrai' do
    Message.create!(from_user: users(:hidalgo), to_user: users(:weil), message: 'Bonjour', read_at: nil)

    assert users(:weil).new_messages?
  end

  test 'new_messages? : message déjà lu → faux' do
    Message.create!(from_user: users(:hidalgo), to_user: users(:weil), message: 'Bonjour', read_at: Time.current)

    assert_not users(:weil).new_messages?
  end

  test 'current_absence : sans période demandée → l\'absence du jour' do
    agent = users(:john_wick)
    absence = Absence.create!(user: agent, du: Date.new(2030, 9, 2), au: Date.new(2030, 9, 2), motif: :formation)

    assert_equal absence, agent.current_absence(Date.new(2030, 9, 2))
  end

  test 'current_absence : aucune absence à cette date → nil' do
    assert_nil users(:john_wick).current_absence(Date.new(2030, 9, 3))
  end

  test 'current_absence : absence journée entière → répond à n\'importe quelle période' do
    agent = users(:john_wick)
    absence = Absence.create!(user: agent, du: Date.new(2030, 9, 4), au: Date.new(2030, 9, 4), motif: :formation)

    assert_equal absence, agent.current_absence(Date.new(2030, 9, 4), :matin)
    assert_equal absence, agent.current_absence(Date.new(2030, 9, 4), :apres_midi)
  end

  test 'current_absence : absence du matin → répond au matin, pas à l\'après-midi' do
    agent = users(:john_wick)
    absence = Absence.create!(user: agent, du: Date.new(2030, 9, 5), au: Date.new(2030, 9, 5),
                              motif: :formation, matin: true, après_midi: false)

    assert_equal absence, agent.current_absence(Date.new(2030, 9, 5), :matin)
    assert_nil agent.current_absence(Date.new(2030, 9, 5), :apres_midi)
  end

  test 'current_absence : absence de l\'après-midi → répond à l\'après-midi, pas au matin' do
    agent = users(:john_wick)
    absence = Absence.create!(user: agent, du: Date.new(2030, 9, 6), au: Date.new(2030, 9, 6),
                              motif: :formation, matin: false, après_midi: true)

    assert_equal absence, agent.current_absence(Date.new(2030, 9, 6), :apres_midi)
    assert_nil agent.current_absence(Date.new(2030, 9, 6), :matin)
  end

  test 'absent? : absence du matin → absent le matin, présent l\'après-midi' do
    agent = users(:john_wick)
    Absence.create!(user: agent, du: Date.new(2030, 9, 7), au: Date.new(2030, 9, 7),
                    motif: :formation, matin: true, après_midi: false)

    assert agent.absent?(Date.new(2030, 9, 7), :matin)
    assert_not agent.absent?(Date.new(2030, 9, 7), :apres_midi)
  end

  test 'nb_bad_words : messages envoyés contenant des insultes → total cumulé sur tous les messages' do
    auteur = users(:hidalgo)
    Message.create!(from_user: auteur, to_user: users(:weil), message: 'Quel abruti, quel crétin !')
    Message.create!(from_user: auteur, to_user: users(:weil), message: 'Espèce de bouffon')

    assert_equal 3, auteur.nb_bad_words
  end

  test 'nb_bad_words : messages corrects → zéro' do
    auteur = users(:hidalgo)
    Message.create!(from_user: auteur, to_user: users(:weil), message: 'Bonjour, merci pour votre travail.')

    assert_equal 0, auteur.nb_bad_words
  end

  test 'nb_bad_words : messages reçus mais aucun envoyé → zéro, seul l\'auteur est compté' do
    Message.create!(from_user: users(:hidalgo), to_user: users(:weil), message: 'Quel abruti')

    assert_equal 0, users(:weil).nb_bad_words
  end

  test 'find_by_whatsapp_phone : numéro préfixé par whatsapp → le compte correspondant' do
    agent = users(:agent_whatsapp)

    assert_equal agent, User.find_by_whatsapp_phone("whatsapp:#{agent.téléphone}")
  end

  test 'find_by_whatsapp_phone : numéro inconnu → nil' do
    assert_nil User.find_by_whatsapp_phone('whatsapp:330000000000')
  end

  test 'intervention_en_cours : pointage ouvert sur le créneau courant → l\'intervention' do
    agent = users(:martin_technique_paris)
    en_cours = Intervention.create!(
      description: 'Pointage ouvert', adherent: users(:weil), service: services(:technique),
      workflow_state: 'nouveau', début_prévue: 1.hour.ago, fin_prévue: 1.hour.from_now,
      agents: [agent], slug: SecureRandom.uuid
    )

    assert_equal en_cours, agent.intervention_en_cours
  end

  test 'intervention_en_cours : aucune intervention sur le créneau courant → nil' do
    assert_nil users(:john_wick).intervention_en_cours
  end

  test 'generate_random_password : appel → douze caractères, un de chaque famille, sans caractère ambigu' do
    mot_de_passe = User.generate_random_password

    assert_equal 12, mot_de_passe.length
    assert_match(/[a-z]/, mot_de_passe)
    assert_match(/[A-Z]/, mot_de_passe)
    assert_match(/[1-9]/, mot_de_passe)
    assert_match(/[!@\#$%&*\-+=?]/, mot_de_passe)
    assert_no_match(/[lOI0]/, mot_de_passe)
  end

  test 'manager_or_admin? : manager et administrateur → vrai, agent et adhérent → faux' do
    assert users(:hidalgo).manager_or_admin?
    assert users(:administrateur_paris).manager_or_admin?
    assert_not users(:bond).manager_or_admin?
    assert_not users(:weil).manager_or_admin?
  end

  test 'intervenants : tous les comptes → agents, managers et administrateurs, jamais les adhérents' do
    rôles = User.intervenants.pluck(:rôle).uniq

    assert_includes rôles, 'agent'
    assert_includes rôles, 'manager'
    assert_includes rôles, 'administrateur'
    assert_not_includes rôles, 'adhérent'
  end

  test 'assignable_roles : manager → le rôle agent seulement' do
    assert_equal ['agent'], users(:hidalgo).assignable_roles
  end

  test 'assignable_roles : agent → le rôle agent seulement' do
    assert_equal ['agent'], users(:bond).assignable_roles
  end

  test 'assignable_roles : administrateur → tous les rôles' do
    assert_equal User.rôles.keys, users(:administrateur_paris).assignable_roles
  end

  # Cœur du « re-scan » du QRCode : retrouve l'intervention fille EN COURS (état
  # « nouveau ») de CET agent, datée d'AUJOURD'HUI, pour le modèle scanné.

  test 'find_current_intervention : fille du jour de l\'agent en état nouveau → trouvée' do
    mère = interventions(:intervention_repete)
    agent = users(:martin_technique_paris)
    fille = mère.create_next_intervention(mère, agent)

    assert_equal fille, agent.find_current_intervention(mère.slug)
  end

  test 'find_current_intervention : fille d\'un autre agent → nil' do
    mère = interventions(:intervention_repete)
    mère.create_next_intervention(mère, users(:bond))

    assert_nil users(:martin_technique_paris).find_current_intervention(mère.slug)
  end

  test 'find_current_intervention : fille datée d\'un autre jour → nil' do
    mère = interventions(:intervention_repete)
    agent = users(:martin_technique_paris)
    fille = mère.create_next_intervention(mère, agent)
    fille.update_columns(début: 1.day.ago)

    assert_nil agent.find_current_intervention(mère.slug)
  end

  test 'find_current_intervention : fille déjà terminée → nil' do
    mère = interventions(:intervention_repete)
    agent = users(:martin_technique_paris)
    fille = mère.create_next_intervention(mère, agent)
    fille.update_columns(workflow_state: 'terminé')

    assert_nil agent.find_current_intervention(mère.slug)
  end

  test 'find_current_intervention : plusieurs filles ouvertes → la plus récemment mise à jour' do
    mère = interventions(:intervention_repete)
    agent = users(:martin_technique_paris)
    récente = mère.create_next_intervention(mère, agent)
    mère.create_next_intervention(mère, agent)
    récente.touch

    assert_equal récente, agent.find_current_intervention(mère.slug)
  end

  private

  def nouveau(rôle:, service_ids: [])
    User.new(nom: 'Essai', prénom: 'Service', email: "essai-#{SecureRandom.hex(4)}@example.test",
             rôle: rôle, password: 'qtDug$d843sqACz?V', service_ids: service_ids,
             address: 'Mairie de Paris', latitude: 48.85, longitude: 2.35)
  end

  test 'xls_headers : modèle XLS proposé aux utilisateurs → en-têtes figées' do
    assert_equal %w[Nom Prénom Email Téléphone Service Mémo], User.xls_headers
  end

  test 'generate_random_password : mot de passe engendré → satisfait la politique de complexité' do
    mot_de_passe = User.generate_random_password

    candidat = User.new(nom: 'DURAND', prénom: 'Marie', email: 'marie.durand@example.test',
                        rôle: 'agent', password: mot_de_passe)
    candidat.user_services.build(service: services(:informatique))

    assert_equal 12, mot_de_passe.length
    assert candidat.valid?, candidat.errors.full_messages.join(', ')
  end
end
