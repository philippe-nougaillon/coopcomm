# frozen_string_literal: true

require 'test_helper'

class ExportToXlsAgentsTest < ActiveSupport::TestCase
  setup do
    @agents = User.agent
  end

  test 'aucun agent donne un classeur réduit à sa ligne d’en-tête' do
    assert_equal 1, feuille_des_agents(User.none).rows.count
  end

  test 'chaque agent occupe une ligne, sous l’en-tête' do
    assert_equal @agents.count + 1, feuille_des_agents(@agents).rows.count
  end

  test 'le classeur des agents porte huit colonnes' do
    assert_equal 8, feuille_des_agents(@agents).row(0).size
  end

  test 'le nom et les services de l’agent sont écrits dans leurs colonnes' do
    agent = users(:bond)
    feuille = feuille_des_agents(User.where(id: agent.id))

    assert_equal agent.nom, cellule_sous_entete(feuille, 'Nom')
    assert_equal agent.services.map(&:nom).join(', '), cellule_sous_entete(feuille, 'Service')
  end

  test 'un agent sans service porte « Aucun » dans sa colonne Service' do
    agent = users(:bond)
    agent.services.destroy_all

    assert_equal 'Aucun', cellule_sous_entete(feuille_des_agents(User.where(id: agent.id)), 'Service')
  end

  private

  def feuille_des_agents(agents)
    Spreadsheet.open(StringIO.new(ExportToXls::Agents.call(agents))).worksheet(0)
  end

  def cellule_sous_entete(feuille, entete)
    feuille.row(1)[feuille.row(0).index(entete)]
  end
end
