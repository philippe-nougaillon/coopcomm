# frozen_string_literal: true

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # --- User.agents_for_services -------------------------------------------
  # Liste PLATE (sans groupe) des intervenants d'un ou plusieurs services,
  # au format [["NOM Prénom", id], …], triée par nom puis prénom.

  test 'agents_for_services ne renvoie que les intervenants du service' do
    agents = User.agents_for_services([services(:technique)])
    ids = agents.map(&:last)

    # Intervenants (agent / manager / administrateur) rattachés à « technique »
    assert_includes ids, users(:martin_technique_paris).id, 'agent du service attendu'
    assert_includes ids, users(:hidalgo).id,                'manager du service attendu'
    assert_includes ids, users(:administrateur_paris).id,   'administrateur du service attendu'
    assert_includes ids, users(:nettoyage).id,              'agent du service attendu'
  end

  test 'agents_for_services exclut les adhérents' do
    agents = User.agents_for_services([services(:informatique)])
    ids = agents.map(&:last)

    # weil est adhérent du service informatique : il ne doit pas apparaître
    assert_not_includes ids, users(:weil).id
  end

  test 'agents_for_services exclut les intervenants hors du service demandé' do
    ids = User.agents_for_services([services(:technique)]).map(&:last)

    # agent_whatsapp est intervenant mais seulement sur service_paris
    assert_not_includes ids, users(:agent_whatsapp).id
    # agent d'une autre organisation
    assert_not_includes ids, users(:agent_marseille).id
  end

  test 'agents_for_services renvoie le format [nom_complet, id]' do
    cible = users(:martin_technique_paris)
    agent = User.agents_for_services([services(:technique)]).find { |_nom, id| id == cible.id }

    assert_not_nil agent
    nom, id = agent
    assert_equal "#{cible.nom} #{cible.prénom}", nom
    assert_kind_of Integer, id
  end

  test 'agents_for_services dédoublonne sur plusieurs services' do
    services_demandés = [services(:service_paris), services(:technique)]
    ids = User.agents_for_services(services_demandés).map(&:last)

    # hidalgo appartient aux deux services : ne doit apparaître qu'une fois
    assert_equal 1, ids.count(users(:hidalgo).id)
  end

  test 'agents_for_services est trié par nom croissant' do
    noms = User.agents_for_services([services(:technique)]).map { |nom, _id| nom.split.first }

    # Les noms (premier mot) sont distincts et purement ASCII ici : un tri
    # croissant stable est vérifiable sans dépendre de la collation SQL.
    assert_equal noms.sort, noms
  end

  # --- User#find_current_intervention -------------------------------------
  # Cœur du « re-scan » du QRCode : retrouve l'intervention fille EN COURS
  # (état « nouveau ») de CET agent, datée d'AUJOURD'HUI, pour le modèle scanné.
  # Les filles sont fabriquées via le modèle répété `intervention_repete`
  # (create_next_intervention pose début = maintenant, état « nouveau »).

  test 'find_current_intervention : renvoie la fille du jour de l agent, en état nouveau' do
    mère = interventions(:intervention_repete)
    agent = users(:martin_technique_paris)
    fille = mère.create_next_intervention(mère, agent)

    assert_equal fille, agent.find_current_intervention(mère.slug)
  end

  test 'find_current_intervention : ignore les filles d un autre agent' do
    mère = interventions(:intervention_repete)
    # Seul bond a pointé aujourd'hui.
    mère.create_next_intervention(mère, users(:bond))

    assert_nil users(:martin_technique_paris).find_current_intervention(mère.slug)
  end

  test 'find_current_intervention : ignore une fille qui n est pas datée d aujourd hui' do
    mère = interventions(:intervention_repete)
    agent = users(:martin_technique_paris)
    fille = mère.create_next_intervention(mère, agent)
    fille.update_columns(début: 1.day.ago) # hors du jour, sans repasser par les callbacks

    assert_nil agent.find_current_intervention(mère.slug)
  end

  test 'find_current_intervention : ignore une fille déjà terminée' do
    mère = interventions(:intervention_repete)
    agent = users(:martin_technique_paris)
    fille = mère.create_next_intervention(mère, agent)
    fille.update_columns(workflow_state: 'terminé')

    assert_nil agent.find_current_intervention(mère.slug)
  end

  test 'find_current_intervention : renvoie la plus récemment mise à jour parmi plusieurs' do
    mère = interventions(:intervention_repete)
    agent = users(:martin_technique_paris)
    f_recente = mère.create_next_intervention(mère, agent)
    mère.create_next_intervention(mère, agent)
    f_recente.touch # force f_recente à devenir la dernière modifiée, sans ambiguïté

    assert_equal f_recente, agent.find_current_intervention(mère.slug)
  end
end
