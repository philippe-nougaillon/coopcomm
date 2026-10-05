# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test 'une absence sans dates saisie en même temps que le compte est ignorée' do
    agent = users(:bond)

    assert_no_difference('Absence.count') do
      agent.update(absences_attributes: { '0' => { du: '', au: '', motif: 'formation' } })
    end
  end

  test 'le nom est mis en capitales et le prénom humanisé à la création du compte' do
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
    test "un #{rôle} sans service est refusé (critique)" do
      user = nouveau(rôle: rôle)

      assert_not user.valid?
      assert_includes user.errors[:services], 'doit comporter au moins un service'
    end

    test "un #{rôle} avec un service est accepté (critique)" do
      assert nouveau(rôle: rôle, service_ids: [services(:informatique).id]).valid?
    end
  end

  test 'un utilisateur dont le dernier service est retiré est refusé (critique)' do
    agent = users(:martin_technique_paris)

    agent.user_services.each(&:mark_for_destruction)

    assert_not agent.valid?
    assert_includes agent.errors[:services], 'doit comporter au moins un service'
  end

  test 'un utilisateur dont le service est remplacé en une seule opération est accepté (critique)' do
    agent = users(:martin_technique_paris)

    agent.user_services.load
    agent.user_services.first.mark_for_destruction
    agent.user_services.build(service: services(:informatique))

    assert agent.valid?, agent.errors.full_messages.to_s
  end

  test 'un agent créé avec deux services est refusé (critique)' do
    agent = nouveau(rôle: 'agent', service_ids: [services(:informatique).id, services(:technique).id])

    assert_not agent.valid?
    assert_includes agent.errors[:services], "ne doit comporter qu'un seul service pour un agent"
  end

  test 'un agent existant qui reçoit un second service est refusé (critique)' do
    agent = users(:martin_technique_paris)

    agent.user_services.build(service: services(:informatique))

    assert_not agent.valid?
    assert_includes agent.errors[:services], "ne doit comporter qu'un seul service pour un agent"
  end

  test 'un utilisateur de plusieurs services basculé en agent est refusé (critique)' do
    utilisateur = users(:hidalgo)

    utilisateur.rôle = 'agent'

    assert_not utilisateur.valid?
    assert_includes utilisateur.errors[:services], "ne doit comporter qu'un seul service pour un agent"
  end

  test 'un adhérent, un manager et un administrateur peuvent avoir plusieurs services (critique)' do
    %w[adhérent manager administrateur].each do |rôle|
      user = nouveau(rôle: rôle, service_ids: [services(:informatique).id, services(:technique).id])

      assert user.valid?, "#{rôle} devrait pouvoir porter deux services : #{user.errors.full_messages}"
    end
  end

  # Sans `dependent: :destroy` sur la through, Rails retire la ligne de liaison
  # par delete_all : aucun callback, donc aucune trace du service retiré.
  test "un service retiré à un utilisateur laisse une trace dans l'audit (critique)" do
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

  test "l'organisation d'un utilisateur dérive de son service (critique)" do
    utilisateur = nouveau(rôle: 'adhérent', service_ids: [services(:informatique).id])

    utilisateur.save!

    assert_equal services(:informatique).organisation, utilisateur.organisation
  end

  test 'le filtre par service ne retourne que les utilisateurs des services demandés (critique)' do
    utilisateurs = User.by_service([services(:informatique)])

    assert_includes utilisateurs, users(:weil)
    assert_not_includes utilisateurs, users(:agent_marseille)
  end

  test 'le filtre par service retourne une seule fois un utilisateur rattaché à deux des services demandés (critique)' do
    utilisateurs = User.by_service([services(:service_paris), services(:technique)])

    assert_equal 1, utilisateurs.to_a.count(users(:hidalgo))
  end

  test 'le filtre par service exclut un utilisateur désactivé (critique)' do
    users(:weil).discard

    assert_not_includes User.by_service([services(:informatique)]), users(:weil)
  end

  test 'un administrateur se voit proposer tous les services de son organisation (critique)' do
    services_proposés = users(:administrateur_paris).get_services_by_role

    assert_includes services_proposés, services(:secretariat)
    assert_not_includes services_proposés, services(:service_marseille)
  end

  test 'un manager ne se voit proposer que ses propres services (critique)' do
    manager = users(:manager_paris)

    assert_equal manager.services.sort_by(&:id), manager.get_services_by_role.sort_by(&:id)
  end

  # Liste PLATE (sans groupe) des intervenants d'un ou plusieurs services, au format
  # [["NOM Prénom", id], …], triée par nom puis prénom.

  test 'la liste des intervenants par service comprend les agents, les managers et les administrateurs du service (critique)' do
    ids = User.agents_for_services([services(:technique)]).map(&:last)

    assert_includes ids, users(:martin_technique_paris).id, 'agent du service attendu'
    assert_includes ids, users(:hidalgo).id,                'manager du service attendu'
    assert_includes ids, users(:administrateur_paris).id,   'administrateur du service attendu'
    assert_includes ids, users(:nettoyage).id,              'agent du service attendu'
  end

  test 'la liste des intervenants par service exclut un adhérent du service (critique)' do
    ids = User.agents_for_services([services(:informatique)]).map(&:last)

    assert_not_includes ids, users(:weil).id
  end

  test "la liste des intervenants par service exclut un intervenant d'un autre service ou d'une autre organisation (critique)" do
    ids = User.agents_for_services([services(:technique)]).map(&:last)

    assert_not_includes ids, users(:agent_whatsapp).id
    assert_not_includes ids, users(:agent_marseille).id
  end

  test 'la liste des intervenants par service rend chaque intervenant sous la forme [nom complet, id] (critique)' do
    cible = users(:martin_technique_paris)

    agent = User.agents_for_services([services(:technique)]).find { |_nom, id| id == cible.id }

    assert_not_nil agent
    nom, id = agent

    assert_equal "#{cible.nom} #{cible.prénom}", nom
    assert_kind_of Integer, id
  end

  test 'la liste des intervenants par service retourne une seule fois un intervenant rattaché à deux des services demandés (critique)' do
    ids = User.agents_for_services([services(:service_paris), services(:technique)]).map(&:last)

    assert_equal 1, ids.count(users(:hidalgo).id)
  end

  # Les noms (premier mot) sont distincts et purement ASCII ici : un tri
  # croissant stable est vérifiable sans dépendre de la collation SQL.
  test 'la liste des intervenants par service est triée par nom croissant (critique)' do
    noms = User.agents_for_services([services(:technique)]).map { |nom, _id| nom.split.first }

    assert_equal noms.sort, noms
  end

  test 'la liste des intervenants par service comprend un administrateur non rattaché au service demandé (critique)' do
    admin = users(:philippe_super_admin)

    ids = User.agents_for_services([services(:technique)]).map(&:last)

    assert_not_includes admin.service_ids, services(:technique).id
    assert_includes ids, admin.id
  end

  test "la liste des intervenants par service exclut un administrateur d'une autre organisation (critique)" do
    ids = User.agents_for_services([services(:service_marseille)]).map(&:last)

    assert_not_includes ids, users(:philippe_super_admin).id
    assert_not_includes ids, users(:administrateur_paris).id
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'les utilisateurs sont triés sans tenir compte des accents ni de la casse' do
    service = services(:menage)
    %w[Élan aiguille Zoé].each do |nom|
      User.create!(nom: nom, prénom: 'Test', email: "#{SecureRandom.hex(4)}@example.test",
                   rôle: 'agent', password: 'qtDug$d843sqACz?V', service_ids: [service.id])
    end

    noms = User.by_service([service]).ordered.pluck(:nom)

    assert_operator noms.index('AIGUILLE'), :<, noms.index('ÉLAN')
    assert_operator noms.index('ÉLAN'), :<, noms.index('ZOÉ')
  end

  test 'le nom complet accole le nom et le prénom' do
    assert_equal 'Bond James', users(:bond).nom_prénom
  end

  test 'le nom complet avec rôle accole le nom, le prénom et le rôle en capitales' do
    assert_equal 'Bond James (AGENT)', users(:bond).nom_prenom_role
  end

  test 'les initiales sont la première lettre du nom et celle du prénom en capitales' do
    assert_equal 'BJ', users(:bond).initiales
  end

  test "un utilisateur dont l'email est listé dans SUPER_ADMIN est super administrateur" do
    précédent = ENV.fetch('SUPER_ADMIN', nil)
    ENV['SUPER_ADMIN'] = "autre@example.test,#{users(:bond).email}"

    assert users(:bond).super_admin?
    assert_not users(:weil).super_admin?
  ensure
    ENV['SUPER_ADMIN'] = précédent
  end

  test "aucun utilisateur n'est super administrateur quand la variable SUPER_ADMIN est absente" do
    précédent = ENV.fetch('SUPER_ADMIN', nil)
    ENV['SUPER_ADMIN'] = nil

    assert_not users(:bond).super_admin?
  ensure
    ENV['SUPER_ADMIN'] = précédent
  end

  test "la note moyenne d'un agent est la moyenne des notes de ses interventions" do
    agent = users(:bond)

    assert_in_delta agent.rated_interventions.average(:note).to_f, agent.moyenne, 1e-6
  end

  test "un utilisateur sans intervention notée n'a pas de note moyenne" do
    assert_nil users(:weil).moyenne
  end

  test "les interventions notées d'un agent excluent les modèles de pointage" do
    notées = users(:bond).rated_interventions

    assert notées.all? { |i| i.note.present? && i.repeter == false }
    assert_equal notées.count, users(:bond).total_rating
  end

  test "la part d'une note est son pourcentage parmi les interventions notées" do
    agent = users(:bond)
    total = (1..5).sum { |note| agent.interventions.where(note: note, repeter: false).count }
    quatre_étoiles = agent.interventions.where(note: 4, repeter: false).count

    assert_in_delta (quatre_étoiles.to_f / total) * 100, agent.star_count(4), 1e-6
  end

  test "la part d'une note vaut zéro sans intervention notée, sans division par zéro" do
    assert_equal 0.0, users(:adhérent_sans_intervention).star_count(3)
  end

  test "chaque rôle a l'icône qui le distingue à l'écran" do
    assert_equal 'manage_accounts', users(:hidalgo).avatar
    assert_equal 'person', users(:bond).avatar
    assert_equal 'corporate_fare', users(:weil).avatar
    assert_equal 'supervisor_account', users(:administrateur_paris).avatar
  end

  test 'un message reçu non lu compte comme nouveau message' do
    Message.create!(from_user: users(:hidalgo), to_user: users(:weil), message: 'Bonjour', read_at: nil)

    assert users(:weil).new_messages?
  end

  test 'un message déjà lu ne compte pas comme nouveau message' do
    Message.create!(from_user: users(:hidalgo), to_user: users(:weil), message: 'Bonjour', read_at: Time.current)

    assert_not users(:weil).new_messages?
  end

  test "l'absence du jour est trouvée sans préciser de période" do
    agent = users(:john_wick)
    absence = Absence.create!(user: agent, du: Date.new(2030, 9, 2), au: Date.new(2030, 9, 2), motif: :formation)

    assert_equal absence, agent.current_absence(Date.new(2030, 9, 2))
  end

  test "aucune absence n'est trouvée à une date sans absence" do
    assert_nil users(:john_wick).current_absence(Date.new(2030, 9, 3))
  end

  test "une absence de journée entière est trouvée pour le matin comme pour l'après-midi" do
    agent = users(:john_wick)
    absence = Absence.create!(user: agent, du: Date.new(2030, 9, 4), au: Date.new(2030, 9, 4), motif: :formation)

    assert_equal absence, agent.current_absence(Date.new(2030, 9, 4), :matin)
    assert_equal absence, agent.current_absence(Date.new(2030, 9, 4), :apres_midi)
  end

  test "une absence du matin est trouvée pour le matin mais pas pour l'après-midi" do
    agent = users(:john_wick)
    absence = Absence.create!(user: agent, du: Date.new(2030, 9, 5), au: Date.new(2030, 9, 5),
                              motif: :formation, matin: true, après_midi: false)

    assert_equal absence, agent.current_absence(Date.new(2030, 9, 5), :matin)
    assert_nil agent.current_absence(Date.new(2030, 9, 5), :apres_midi)
  end

  test "une absence de l'après-midi est trouvée pour l'après-midi mais pas pour le matin" do
    agent = users(:john_wick)
    absence = Absence.create!(user: agent, du: Date.new(2030, 9, 6), au: Date.new(2030, 9, 6),
                              motif: :formation, matin: false, après_midi: true)

    assert_equal absence, agent.current_absence(Date.new(2030, 9, 6), :apres_midi)
    assert_nil agent.current_absence(Date.new(2030, 9, 6), :matin)
  end

  test "un agent absent le matin est présent l'après-midi" do
    agent = users(:john_wick)
    Absence.create!(user: agent, du: Date.new(2030, 9, 7), au: Date.new(2030, 9, 7),
                    motif: :formation, matin: true, après_midi: false)

    assert agent.absent?(Date.new(2030, 9, 7), :matin)
    assert_not agent.absent?(Date.new(2030, 9, 7), :apres_midi)
  end

  test "les insultes d'un utilisateur sont comptées sur l'ensemble de ses messages envoyés" do
    auteur = users(:hidalgo)
    Message.create!(from_user: auteur, to_user: users(:weil), message: 'Quel abruti, quel crétin !')
    Message.create!(from_user: auteur, to_user: users(:weil), message: 'Espèce de bouffon')

    assert_equal 3, auteur.nb_bad_words
  end

  test 'un utilisateur aux messages corrects compte zéro insulte' do
    auteur = users(:hidalgo)
    Message.create!(from_user: auteur, to_user: users(:weil), message: 'Bonjour, merci pour votre travail.')

    assert_equal 0, auteur.nb_bad_words
  end

  test 'les insultes reçues ne comptent pas pour le destinataire, seulement pour leur auteur' do
    Message.create!(from_user: users(:hidalgo), to_user: users(:weil), message: 'Quel abruti')

    assert_equal 0, users(:weil).nb_bad_words
  end

  test 'un utilisateur est retrouvé par son numéro préfixé par whatsapp' do
    agent = users(:agent_whatsapp)

    assert_equal agent, User.find_by_whatsapp_phone("whatsapp:#{agent.téléphone}")
  end

  test 'un numéro whatsapp inconnu ne retrouve aucun utilisateur' do
    assert_nil User.find_by_whatsapp_phone('whatsapp:330000000000')
  end

  test "l'intervention en cours d'un agent est celle prévue sur le créneau courant" do
    agent = users(:martin_technique_paris)
    en_cours = Intervention.create!(
      description: 'Pointage ouvert', adherent: users(:weil), service: services(:technique),
      workflow_state: 'nouveau', début_prévue: 1.hour.ago, fin_prévue: 1.hour.from_now,
      agents: [agent], slug: SecureRandom.uuid
    )

    assert_equal en_cours, agent.intervention_en_cours
  end

  test "un agent sans intervention prévue sur le créneau courant n'a aucune intervention en cours" do
    assert_nil users(:john_wick).intervention_en_cours
  end

  test 'un mot de passe engendré fait douze caractères, un de chaque famille, sans caractère ambigu' do
    mot_de_passe = User.generate_random_password

    assert_equal 12, mot_de_passe.length
    assert_match(/[a-z]/, mot_de_passe)
    assert_match(/[A-Z]/, mot_de_passe)
    assert_match(/[1-9]/, mot_de_passe)
    assert_match(/[!@\#$%&*\-+=?]/, mot_de_passe)
    assert_no_match(/[lOI0]/, mot_de_passe)
  end

  test 'un manager et un administrateur sont des gestionnaires, un agent et un adhérent non' do
    assert users(:hidalgo).manager_or_admin?
    assert users(:administrateur_paris).manager_or_admin?
    assert_not users(:bond).manager_or_admin?
    assert_not users(:weil).manager_or_admin?
  end

  test 'les intervenants sont les agents, les managers et les administrateurs, jamais les adhérents' do
    rôles = User.intervenants.pluck(:rôle).uniq

    assert_includes rôles, 'agent'
    assert_includes rôles, 'manager'
    assert_includes rôles, 'administrateur'
    assert_not_includes rôles, 'adhérent'
  end

  test 'un manager ne peut attribuer que le rôle agent' do
    assert_equal ['agent'], users(:hidalgo).assignable_roles
  end

  test 'un agent ne peut attribuer que le rôle agent' do
    assert_equal ['agent'], users(:bond).assignable_roles
  end

  test 'un administrateur peut attribuer tous les rôles' do
    assert_equal User.rôles.keys, users(:administrateur_paris).assignable_roles
  end

  # Cœur du « re-scan » du QRCode : retrouve l'intervention fille EN COURS (état
  # « nouveau ») de CET agent, datée d'AUJOURD'HUI, pour le modèle scanné.

  test "l'intervention fille du jour de l'agent, à l'état nouveau, est retrouvée" do
    mère = interventions(:intervention_repete)
    agent = users(:martin_technique_paris)
    fille = mère.create_next_intervention(mère, agent)

    assert_equal fille, agent.find_current_intervention(mère.slug)
  end

  test "l'intervention fille d'un autre agent n'est pas retrouvée" do
    mère = interventions(:intervention_repete)
    mère.create_next_intervention(mère, users(:bond))

    assert_nil users(:martin_technique_paris).find_current_intervention(mère.slug)
  end

  test "l'intervention fille datée d'un autre jour n'est pas retrouvée" do
    mère = interventions(:intervention_repete)
    agent = users(:martin_technique_paris)
    fille = mère.create_next_intervention(mère, agent)
    fille.update_columns(début: 1.day.ago)

    assert_nil agent.find_current_intervention(mère.slug)
  end

  test "l'intervention fille déjà terminée n'est pas retrouvée" do
    mère = interventions(:intervention_repete)
    agent = users(:martin_technique_paris)
    fille = mère.create_next_intervention(mère, agent)
    fille.update_columns(workflow_state: 'terminé')

    assert_nil agent.find_current_intervention(mère.slug)
  end

  test 'entre plusieurs interventions filles ouvertes, la plus récemment mise à jour est retrouvée' do
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

  test 'le modèle XLS des utilisateurs a des en-têtes figées' do
    assert_equal %w[Nom Prénom Email Téléphone Service Mémo], User.xls_headers
  end

  test 'un mot de passe engendré satisfait la politique de complexité' do
    mot_de_passe = User.generate_random_password

    candidat = User.new(nom: 'DURAND', prénom: 'Marie', email: 'marie.durand@example.test',
                        rôle: 'agent', password: mot_de_passe)
    candidat.user_services.build(service: services(:informatique))

    assert_equal 12, mot_de_passe.length
    assert candidat.valid?, candidat.errors.full_messages.join(', ')
  end
end
