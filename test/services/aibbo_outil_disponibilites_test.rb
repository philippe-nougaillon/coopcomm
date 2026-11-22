# frozen_string_literal: true

require 'test_helper'

class AibboOutilDisponibilitesTest < ActiveSupport::TestCase
  setup do
    @manager = users(:hidalgo)
  end

  # ==================== TESTS CRITIQUES ====================
  # La disponibilité d'un agent dit où il est : elle ne sort ni des services de l'utilisateur,
  # ni de ce que sa liste d'interventions lui montre.
  test 'un manager ne reçoit que les intervenants de ses services (critique)' do
    resultat = Aibbo::OutilDisponibilites.new(users(:manager_marseille)).call(debut: '2024-04-19 12:00', fin: '2024-04-19 14:00')

    assert_equal [nom(users(:manager_marseille)), nom(users(:nettoyeur_marseille))].sort, resultat[:disponibles].sort
    assert_equal [nom(users(:agent_marseille))], resultat[:indisponibles].pluck(:agent)
  end

  test 'le nom d’un service hors du périmètre n’est pas reconnu (critique)' do
    resultat = Aibbo::OutilDisponibilites.new(users(:manager_marseille))
                                         .call(debut: '2024-04-19 12:00', fin: '2024-04-19 14:00', service: 'Technique')

    assert_match(/introuvable parmi les services/, resultat[:erreur])
    assert_nil resultat[:disponibles]
  end

  test 'une intervention d’un service que le manager n’encadre pas retient l’agent sans dire son intitulé (critique)' do
    affecter_un_agent_du_manager_a_une_intervention_d_un_autre_service

    resultat = Aibbo::OutilDisponibilites.new(users(:manager_paris)).call(debut: '2024-04-15 12:00', fin: '2024-04-15 14:00')
    raisons = resultat[:indisponibles].find { |ligne| ligne[:agent] == nom(users(:agent_whatsapp)) }[:raisons]

    assert_match(/intervention d'un autre service/, raisons.join)
    assert_no_match(/#{interventions(:intervention_terminée).description}/, resultat.to_json)
  end

  test 'un agent ne reçoit la disponibilité d’aucun autre compte (critique)' do
    resultat = Aibbo::OutilDisponibilites.new(users(:bond)).call(debut: '2024-04-16 12:00', fin: '2024-04-16 14:00')

    assert_equal [nom(users(:bond))], resultat[:disponibles] + resultat[:indisponibles].pluck(:agent)
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'un agent pris par une intervention sur le créneau est indisponible, avec cette intervention pour raison' do
    resultat = Aibbo::OutilDisponibilites.new(@manager).call(debut: '2024-04-16 12:00', fin: '2024-04-16 14:00', service: 'technique')
    martin = resultat[:indisponibles].find { |ligne| ligne[:agent] == nom(users(:martin_technique_paris)) }

    assert_match(/#{interventions(:intervention_autre_agent).description}/, martin[:raisons].join)
    assert_includes resultat[:disponibles], nom(users(:bond))
  end

  test 'un agent absent le jour du créneau est indisponible, avec son absence pour raison' do
    resultat = Aibbo::OutilDisponibilites.new(@manager).call(debut: '2024-11-20 09:00', fin: '2024-11-20 11:00', service: 'technique')
    bond = resultat[:indisponibles].find { |ligne| ligne[:agent] == nom(users(:bond)) }

    assert_match(/absence du 2024-11-20 au 2024-11-20/, bond[:raisons].join)
    assert_includes resultat[:disponibles], nom(users(:martin_technique_paris))
  end

  test 'les agents indisponibles sont ceux que le formulaire d’intervention signale' do
    debut = Time.zone.parse('2024-04-19 12:00')
    fin = Time.zone.parse('2024-04-19 14:00')
    agents = User.visible_to(@manager).intervenants_pour(@manager.get_services_by_role)
    signales = Intervention.get_unavailable_agents(nil, agents.ids, debut, fin) |
               Intervention.get_unavailable_agents_with_absences(agents.ids, debut, fin)

    resultat = Aibbo::OutilDisponibilites.new(@manager).call(debut: '2024-04-19 12:00', fin: '2024-04-19 14:00')

    assert_equal User.where(id: signales).map { |agent| nom(agent) }.sort, resultat[:indisponibles].pluck(:agent).sort
    assert_equal [nom(users(:bond)), nom(users(:martin_technique_paris))].sort, resultat[:indisponibles].pluck(:agent).sort
  end

  test 'sans fin de créneau, la disponibilité est celle de l’instant du début' do
    resultat = Aibbo::OutilDisponibilites.new(@manager).call(debut: '2024-04-16 12:00', service: 'technique')

    assert_includes resultat[:indisponibles].pluck(:agent), nom(users(:martin_technique_paris))
    assert_includes resultat[:disponibles], nom(users(:bond))
  end

  test 'le filtre par agent ne rend que cet agent' do
    resultat = Aibbo::OutilDisponibilites.new(@manager).call(debut: '2024-04-16 12:00', fin: '2024-04-16 14:00', agent: 'james bond')

    assert_equal [nom(users(:bond))], resultat[:disponibles]
    assert_empty resultat[:indisponibles]
  end

  test 'un créneau dont la fin précède le début est renvoyé à l’utilisateur sans rien chercher' do
    resultat = Aibbo::OutilDisponibilites.new(@manager).call(debut: '2024-04-19 14:00', fin: '2024-04-19 12:00')

    assert_match(/La fin du créneau/, resultat[:erreur])
    assert_nil resultat[:disponibles]
  end

  test 'un manager et un administrateur des services de l’utilisateur sont des intervenants, comme dans le formulaire d’intervention' do
    resultat = Aibbo::OutilDisponibilites.new(@manager).call(debut: '2024-04-16 12:00', fin: '2024-04-16 14:00', service: 'technique')

    assert_includes resultat[:disponibles], nom(users(:hidalgo))
    assert_includes resultat[:disponibles], nom(users(:administrateur_paris))
  end

  private

  def nom(utilisateur)
    utilisateur.nom_prénom.strip
  end

  # L'agent de service_paris, que manager_paris encadre, travaille aussi sur une intervention du service technique, qu'il n'encadre pas.
  def affecter_un_agent_du_manager_a_une_intervention_d_un_autre_service
    AgentIntervention.create!(agent: users(:agent_whatsapp), intervention: interventions(:intervention_terminée))
  end
end
