# frozen_string_literal: true

require 'test_helper'

class AibboOutilFaisabiliteTest < ActiveSupport::TestCase
  setup do
    @manager = users(:hidalgo)
    travel_to Time.zone.local(2024, 4, 15, 8, 0)
  end

  # ==================== TESTS CRITIQUES ====================
  # La faisabilité dit qui est libre et quel matériel l'est : elle ne sort ni des services de l'utilisateur, ni de son organisation,
  # et une météo en panne ne doit pas emporter le reste de la réponse.
  test 'un manager ne reçoit que les intervenants de ses services (critique)' do
    resultat = Aibbo::OutilFaisabilite.new(users(:manager_marseille)).call(du: '2024-04-19', au: '2024-04-19')
    vendredi = resultat[:jours].first

    assert_equal 3, resultat[:intervenants]
    assert_equal [nom(users(:manager_marseille)), nom(users(:nettoyeur_marseille))].sort,
                 vendredi[:libres_toute_la_journée][:les_plus_disponibles].pluck(:nom).sort
    assert_equal 1, vendredi[:indisponibles]
  end

  test 'le nom d’un service hors du périmètre n’est pas reconnu (critique)' do
    resultat = Aibbo::OutilFaisabilite.new(users(:manager_marseille)).call(service: 'Technique')

    assert_match(/introuvable parmi les services/, resultat[:erreur])
    assert_nil resultat[:jours]
  end

  test 'le nom d’un adhérent hors du périmètre n’est pas reconnu (critique)' do
    resultat = Aibbo::OutilFaisabilite.new(@manager).call(adherent: users(:adherent_marseille).nom)

    assert_match(/introuvable parmi les adhérents/, resultat[:erreur])
    assert_nil resultat[:jours]
  end

  test 'seuls les services auxquels l’adhérent adhère sont regardés (critique)' do
    resultat = Aibbo::OutilFaisabilite.new(@manager).call(adherent: 'berthout')

    assert_equal [services(:technique).nom], resultat[:services]
    assert_equal nom(users(:berthout)), resultat[:adhérent]
    assert_equal User.visible_to(@manager).intervenants_pour([services(:technique)]).count, resultat[:intervenants]
    assert_not_includes resultat.to_json, nom(users(:agent_whatsapp))
  end

  test 'un adhérent qui n’adhère pas au service demandé est renvoyé à l’utilisateur sans rien chercher (critique)' do
    resultat = Aibbo::OutilFaisabilite.new(@manager).call(adherent: 'berthout', service: 'informatique')

    assert_match(/n'adhère à aucun des services regardés/, resultat[:erreur])
    assert_nil resultat[:jours]
  end

  test 'le nom d’un matériel d’une autre organisation n’est pas reconnu, et les matériels existants proposés sont ceux de l’organisation (critique)' do
    resultat = Aibbo::OutilFaisabilite.new(@manager).call(du: '2024-04-18', au: '2024-04-18', materiels: [tools(:camion).name])

    assert_equal [tools(:camion).name], resultat[:matériel_introuvable][:demandés]
    assert_includes resultat[:matériel_introuvable][:matériel_existant], tools(:tondeuse).name
    assert_not_includes resultat[:matériel_introuvable][:matériel_existant], tools(:outil_marseille).name
    assert_nil resultat[:jours].first[:matériel]
  end

  test 'un agent ne reçoit la disponibilité d’aucun autre compte (critique)' do
    resultat = Aibbo::OutilFaisabilite.new(users(:bond)).call(du: '2024-04-18', au: '2024-04-18')

    assert_equal [nom(users(:bond))], resultat[:les_plus_disponibles].pluck(:nom)
    assert_equal [nom(users(:bond))], resultat[:jours].first[:libres_toute_la_journée][:les_plus_disponibles].pluck(:nom)
  end

  test 'une météo en panne ne prive pas l’utilisateur du reste de la réponse (critique)' do
    stub_request(:get, /api.meteo-concept.com/).to_timeout

    jeudi = Aibbo::OutilFaisabilite.new(@manager).call(du: '2024-04-18', au: '2024-04-18', service: 'technique')[:jours].first

    assert_equal 'prévision indisponible', jeudi[:météo]
    assert_includes jeudi[:libres_toute_la_journée][:les_plus_disponibles].pluck(:nom), nom(users(:bond))
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'sans période, les jours étudiés vont d’aujourd’hui au vendredi de la semaine' do
    travel_to Time.zone.local(2024, 4, 17, 8, 0)

    resultat = Aibbo::OutilFaisabilite.new(@manager).call

    assert_equal %w[2024-04-17 2024-04-18 2024-04-19], resultat[:jours].pluck(:date)
  end

  test 'les jours déjà passés d’une période ne sont pas étudiés, et leur nombre est rendu' do
    travel_to Time.zone.local(2024, 4, 17, 8, 0)

    resultat = Aibbo::OutilFaisabilite.new(@manager).call(du: '2024-04-15', au: '2024-04-19')

    assert_equal %w[2024-04-17 2024-04-18 2024-04-19], resultat[:jours].pluck(:date)
    assert_equal 2, resultat[:jours_passés_non_étudiés]
  end

  test 'une période dont le dernier jour précède le premier est renvoyée à l’utilisateur sans rien chercher' do
    resultat = Aibbo::OutilFaisabilite.new(@manager).call(du: '2024-04-19', au: '2024-04-15')

    assert_match(/Le dernier jour/, resultat[:erreur])
    assert_nil resultat[:jours]
  end

  test 'une période entièrement passée est renvoyée à l’utilisateur sans rien chercher' do
    resultat = Aibbo::OutilFaisabilite.new(@manager).call(du: '2024-04-08', au: '2024-04-12')

    assert_match(/Cette période est passée/, resultat[:erreur])
    assert_nil resultat[:jours]
  end

  test 'une période trop longue est renvoyée à l’utilisateur sans rien chercher' do
    resultat = Aibbo::OutilFaisabilite.new(@manager).call(du: '2024-04-15', au: '2024-05-15')

    assert_match(/ne peut pas dépasser/, resultat[:erreur])
    assert_nil resultat[:jours]
  end

  test 'une personne prise par une intervention toute la journée n’est libre ni le matin ni l’après-midi' do
    lundi = jour_du(semaine_du_15_avril_au_technique, '2024-04-15')

    assert_equal 2, lundi[:indisponibles]
    assert_empty lundi[:libres_une_demi_journée]
    assert_equal [users(:administrateur_paris), users(:hidalgo), users(:nettoyage), users(:électricité)].map { |personne| nom(personne) }.sort,
                 lundi[:libres_toute_la_journée][:les_plus_disponibles].pluck(:nom).sort
  end

  test 'une personne prise l’après-midi par une intervention prévue est libre le matin, avec cette intervention pour raison' do
    planifier_une_intervention_l_apres_midi_du_18_avril

    jeudi = jour_du(semaine_du_15_avril_au_technique, '2024-04-18')

    assert_equal [{ nom: nom(users(:bond)), rôle: 'agent', libre: 'le matin', retenu_par: ['intervention du 2024-04-18 13:00 au 2024-04-18 17:00'] }],
                 jeudi[:libres_une_demi_journée]
    assert_not_includes jeudi[:libres_toute_la_journée][:les_plus_disponibles].pluck(:nom), nom(users(:bond))
  end

  test 'une personne absente n’est pas libre ce jour-là' do
    travel_to Time.zone.local(2024, 11, 18, 8, 0)

    mercredi = Aibbo::OutilFaisabilite.new(@manager).call(du: '2024-11-20', au: '2024-11-20', service: 'technique')[:jours].first

    assert_equal 1, mercredi[:indisponibles]
    assert_not_includes mercredi[:libres_toute_la_journée][:les_plus_disponibles].pluck(:nom), nom(users(:bond))
    assert_includes mercredi[:libres_toute_la_journée][:les_plus_disponibles].pluck(:nom), nom(users(:martin_technique_paris))
  end

  test 'une personne absente le matin est libre l’après-midi, avec son absence pour raison' do
    poser_une_absence_le_matin_du_18_avril

    martin = jour_du(semaine_du_15_avril_au_technique, '2024-04-18')[:libres_une_demi_journée].first

    assert_equal nom(users(:martin_technique_paris)), martin[:nom]
    assert_equal "l'après-midi", martin[:libre]
    assert_match(/absence \(Matin/, martin[:retenu_par].join)
  end

  test 'les personnes qui ne sont pas libres un jour sont celles que le formulaire d’intervention signale sur la journée' do
    vendredi = Date.new(2024, 4, 19)
    intervenants = User.visible_to(@manager).intervenants_pour([services(:technique)])
    signales = Intervention.get_unavailable_agents(nil, intervenants.ids, vendredi.beginning_of_day, vendredi.end_of_day) |
               Intervention.get_unavailable_agents_with_absences(intervenants.ids, vendredi.beginning_of_day, vendredi.end_of_day)

    resultat = jour_du(semaine_du_15_avril_au_technique, '2024-04-19')

    assert_equal [users(:bond).id, users(:martin_technique_paris).id].sort, signales.sort
    assert_equal signales.size, resultat[:indisponibles]
    assert_equal intervenants.where.not(id: signales).map { |personne| nom(personne) }.sort,
                 resultat[:libres_toute_la_journée][:les_plus_disponibles].pluck(:nom).sort
  end

  test 'les personnes les plus disponibles sur la période viennent en tête, avec les jours où elles sont libres' do
    classement = semaine_du_15_avril_au_technique[:les_plus_disponibles]

    assert_equal [5, 5, 5, 5, 2, 2], classement.pluck(:jours_libres)
    assert_equal [nom(users(:bond)), nom(users(:martin_technique_paris))], classement.last(2).pluck(:nom)
    assert_equal ['mardi 16 avril', 'jeudi 18 avril'], classement[4][:libre_les]
    assert_equal ['mercredi 17 avril', 'jeudi 18 avril'], classement[5][:libre_les]
  end

  test 'une demi-journée libre départage deux personnes libres autant de jours' do
    poser_une_absence_le_matin_du_18_avril

    classement = semaine_du_15_avril_au_technique[:les_plus_disponibles]

    assert_equal [nom(users(:bond)), nom(users(:martin_technique_paris))], classement.last(2).pluck(:nom)
    assert_equal [2, 0], classement[4].values_at(:jours_libres, :demi_journées_libres)
    assert_equal [1, 1], classement[5].values_at(:jours_libres, :demi_journées_libres)
  end

  test 'un matériel pris par une intervention n’est pas libre ce jour-là' do
    resultat = Aibbo::OutilFaisabilite.new(@manager).call(du: '2024-04-15', au: '2024-04-16', materiels: ['cisaille'])
    lundi, mardi = resultat[:jours]

    assert_equal [{ demandé: 'cisaille', libre: false }], lundi[:matériel].map { |ligne| ligne.slice(:demandé, :libre) }
    assert_equal 'en intervention', lundi[:matériel].first[:matériels].first[:état]
    assert_not lundi[:tout_le_matériel_libre]
    assert mardi[:tout_le_matériel_libre]
    assert_nil resultat[:matériel_introuvable]
  end

  test 'un matériel demandé sous un nom inconnu est signalé sans priver l’utilisateur du reste de la réponse' do
    resultat = Aibbo::OutilFaisabilite.new(@manager).call(du: '2024-04-15', au: '2024-04-15', materiels: %w[cisaille licorne])
    lundi = resultat[:jours].first

    assert_equal ['licorne'], resultat[:matériel_introuvable][:demandés]
    assert_equal ['cisaille'], lundi[:matériel].pluck(:demandé)
    assert_not lundi[:tout_le_matériel_libre]
  end

  test 'un matériel réservé ou en panne n’est pas libre ce jour-là' do
    travel_to Time.zone.local(2024, 5, 6, 8, 0)

    resultat = Aibbo::OutilFaisabilite.new(@manager).call(du: '2024-05-06', au: '2024-05-10', materiels: %w[souffleur taille-haie])
    mardi = jour_du(resultat, '2024-05-07')

    assert_equal [false, false, false, false, true], resultat[:jours].pluck(:tout_le_matériel_libre)
    assert_equal %w[réservé], mardi[:matériel].first[:matériels].pluck(:état)
    assert_equal ['en panne'], mardi[:matériel].last[:matériels].pluck(:état)
  end

  test 'un nom partiel de matériel est tenu pour libre dès que l’un des matériels qui le portent l’est' do
    travel_to Time.zone.local(2024, 5, 6, 8, 0)

    demande = Aibbo::OutilFaisabilite.new(@manager).call(du: '2024-05-07', au: '2024-05-07', materiels: ['ou'])[:jours].first[:matériel].first

    assert demande[:libre]
    assert_equal tools(:souffleur_reserve_en_mai_2024, :outil_paris, :outil_adherent).map(&:name).sort, demande[:matériels].pluck(:nom).sort
    assert_equal %w[libre libre réservé], demande[:matériels].pluck(:état).sort
  end

  test 'la fiche d’un matériel demandé est rendue lorsqu’il en a une' do
    resultat = Aibbo::OutilFaisabilite.new(@manager).call(du: '2024-04-18', au: '2024-04-18', materiels: %w[tondeuse rateau])

    assert_equal [{ nom: tools(:tondeuse).name, fiche: tools(:tondeuse).description }], resultat[:fiches_du_matériel]
  end

  test 'la météo du matin et de l’après-midi est rendue pour chaque jour à portée des prévisions' do
    resultat = Aibbo::OutilFaisabilite.new(@manager).call(du: '2024-04-15', au: '2024-04-15')
    meteo = resultat[:jours].first[:météo]

    assert_equal 'Environnement de test', resultat[:prévisions_météo_pour]
    assert_equal({ temps: 'Peu nuageux', température_en_degrés: 16, vent_en_km_h: 10, rafales_en_km_h: 29,
                   risque_de_pluie_en_pourcent: 10, risque_de_gel_en_pourcent: 0 }, meteo[:matin])
    assert_equal 27, meteo[:après_midi][:température_en_degrés]
  end

  test 'un jour hors de portée des prévisions le dit' do
    resultat = Aibbo::OutilFaisabilite.new(@manager).call(du: '2024-04-29', au: '2024-04-29')

    assert_equal 'pas de prévision à cette échéance', resultat[:jours].first[:météo]
  end

  test 'les heures de travail de l’équipe sont additionnées par semaine' do
    assert_equal [{ semaine_du: '2024-04-15', heures_prévues_ou_réalisées: 54.0, moyenne_par_intervenant: 9.0, maximum_pour_une_personne: 27.0 }],
                 semaine_du_15_avril_au_technique[:heures_de_l_équipe_par_semaine]
  end

  test 'les heures d’une intervention prévue, pas encore réalisée, comptent dans les heures de l’équipe' do
    planifier_une_intervention_l_apres_midi_du_18_avril

    semaine = semaine_du_15_avril_au_technique[:heures_de_l_équipe_par_semaine].first

    assert_equal 58.0, semaine[:heures_prévues_ou_réalisées]
    assert_equal 31.0, semaine[:maximum_pour_une_personne]
  end

  test 'le rôle de chaque personne libre est rendu, managers et administrateurs comptés à part des agents' do
    jeudi = jour_du(semaine_du_15_avril_au_technique, '2024-04-18')

    assert_equal [4, 2], jeudi[:libres_toute_la_journée].values_at(:agents, :managers_et_administrateurs)
    assert_includes jeudi[:libres_toute_la_journée][:les_plus_disponibles], { nom: nom(users(:hidalgo)), rôle: 'manager' }
    assert_includes jeudi[:libres_toute_la_journée][:les_plus_disponibles], { nom: nom(users(:administrateur_paris)), rôle: 'administrateur' }
  end

  test 'le service de chaque personne est rendu quand plusieurs services sont regardés, borné à ces services' do
    jeudi = Aibbo::OutilFaisabilite.new(@manager).call(du: '2024-04-18', au: '2024-04-18')[:jours].first
    libres = jeudi[:libres_toute_la_journée][:les_plus_disponibles]

    assert_includes libres, { nom: nom(users(:bond)), rôle: 'agent', services: [services(:technique).nom] }
    assert_includes libres, { nom: nom(users(:agent_whatsapp)), rôle: 'agent', services: [services(:service_paris).nom] }
    assert_equal [services(:service_paris).nom], libres.find { |personne| personne[:nom] == nom(users(:manager_paris)) }[:services]
  end

  test 'le résultat dit quand il faut compter un manager ou un administrateur pour réunir assez de personnes' do
    resultat = Aibbo::OutilFaisabilite.new(@manager).call(du: '2024-04-15', au: '2024-04-19', service: 'technique', personnes: 3)
    jeudi = jour_du(resultat, '2024-04-18')
    vendredi = jour_du(resultat, '2024-04-19')

    assert_equal [true, true], jeudi.values_at(:assez_de_personnes, :assez_d_agents_sans_manager_ni_administrateur)
    assert_equal [true, false], vendredi.values_at(:assez_de_personnes, :assez_d_agents_sans_manager_ni_administrateur)
  end

  test 'le résultat dit quand trop peu de personnes sont libres' do
    resultat = Aibbo::OutilFaisabilite.new(@manager).call(du: '2024-04-19', au: '2024-04-19', service: 'technique', personnes: 5)

    assert_not resultat[:jours].first[:assez_de_personnes]
  end

  private

  def nom(utilisateur)
    utilisateur.nom_prénom.strip
  end

  def jour_du(resultat, date)
    resultat[:jours].find { |jour| jour[:date] == date }
  end

  # La semaine que les fixtures datent : deux agents du service technique y sont pris certains jours par des interventions réalisées.
  def semaine_du_15_avril_au_technique
    Aibbo::OutilFaisabilite.new(@manager).call(du: '2024-04-15', au: '2024-04-19', service: 'technique')
  end

  # James Bond reçoit une intervention prévue, pas encore réalisée, de quatre heures.
  def planifier_une_intervention_l_apres_midi_du_18_avril
    Intervention.create!(description: 'Tailler la haie', adherent: users(:weil), service: services(:technique), agents: [users(:bond)],
                         début_prévue: Time.zone.local(2024, 4, 18, 13, 0), fin_prévue: Time.zone.local(2024, 4, 18, 17, 0))
  end

  # Michel Martin, libre toute cette journée dans les fixtures, est absent le matin.
  def poser_une_absence_le_matin_du_18_avril
    Absence.create!(user: users(:martin_technique_paris), du: Date.new(2024, 4, 18), au: Date.new(2024, 4, 18), matin: true)
  end
end
