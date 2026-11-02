# frozen_string_literal: true

require 'test_helper'

class DashboardHelperTest < ActionView::TestCase
  test 'le filtre par service d’une carte n’est pas proposé quand un seul service est affiché' do
    assert_nil filtre_services_graphe('co2ParMois', %w[Technique])
  end

  test 'le filtre par service d’une carte propose chaque service affiché' do
    assert_dom_equal filtre_graphe('co2ParMois', 'services', [['Services : hérités', ''], %w[Informatique Informatique], %w[Technique Technique]]),
                     filtre_services_graphe('co2ParMois', %w[Informatique Technique])
  end

  test 'les derniers mois d’une carte ne comptent que les mois écoulés de la fenêtre' do
    mois = (Date.new(2026, 1, 1)..Date.new(2027, 1, 1)).map(&:beginning_of_month).uniq.map { |m| m.strftime('%Y-%m') }

    travel_to Date.new(2026, 10, 23) do
      options = Nokogiri::HTML.fragment(filtre_periode_graphe('co2ParMois', mois)).css('option').map(&:text)

      assert_equal ['Période globale', '6 derniers mois', '3 derniers mois'], options
    end
  end

  test 'les derniers mois d’une carte retombent sur toute la fenêtre quand elle est entièrement à venir' do
    mois = %w[2030-01 2030-02 2030-03 2030-04]

    travel_to Date.new(2026, 10, 23) do
      options = Nokogiri::HTML.fragment(filtre_periode_graphe('co2ParMois', mois)).css('option').map(&:text)

      assert_equal ['Période globale', '3 derniers mois'], options
    end
  end

  test 'un filtre de carte nommé est soumis au serveur avec son choix présélectionné' do
    select = Nokogiri::HTML.fragment(filtre_services_graphe('activiteAgents', %w[Informatique Technique], 'Technique',
                                                            name: 'agents_service')).at_css('select')

    assert_equal 'agents_service', select['name']
    assert_equal 'Technique', select.at_css('option[selected]').text
  end

  test 'les derniers mois d’une carte peuvent être présélectionnés' do
    mois = (Date.new(2026, 1, 1)..Date.new(2026, 12, 1)).map(&:beginning_of_month).uniq.map { |m| m.strftime('%Y-%m') }

    travel_to Date.new(2026, 10, 23) do
      select = Nokogiri::HTML.fragment(filtre_periode_graphe('activiteAgents', mois, 3, name: 'agents_periode')).at_css('select')

      assert_equal 'agents_periode', select['name']
      assert_equal '3 derniers mois', select.at_css('option[selected]').text
    end
  end
end
