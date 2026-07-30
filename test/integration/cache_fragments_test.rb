# frozen_string_literal: true

require 'test_helper'

# Un fragment mis en cache sous une clé qui ignore l'utilisateur sert le HTML du
# premier arrivé à tous les suivants : boutons d'action visibles par un rôle qui
# n'y a pas droit, ou au contraire absents pour celui qui y a droit.
class CacheFragmentsTest < ActionDispatch::IntegrationTest
  # --- Sentinelle : couvre aussi les vues qui n'existent pas encore -----------

  test 'aucun render cached: ne pose une clé sans current_user' do
    fautifs = []

    Dir.glob(Rails.root.join('app/views/**/*.erb')).sort.each do |chemin|
      contenu = File.read(chemin)

      contenu.to_enum(:scan, /cached:/).each do
        début = Regexp.last_match.end(0)
        expression = contenu[début, 300].to_s.split('%>').first.to_s
        next if expression.include?('current_user')

        fautifs << "#{chemin.sub("#{Rails.root}/", '')} → cached:#{expression.strip}"
      end
    end

    assert_empty fautifs, <<~MESSAGE
      Ces fragments sont mis en cache sous une clé qui ne dépend pas de l'utilisateur.
      Le premier rendu sera servi à tous les rôles. Utiliser par exemple
      `cached: ->(objet) { [objet, current_user] }`.

      #{fautifs.join("\n")}
    MESSAGE
  end

  # --- Garde anti-faux-positif ------------------------------------------------

  # Sans cette garde, une régression du helper rendrait tous les tests ci-dessous
  # verts sans rien mettre en cache : ils ne prouveraient plus rien.
  test 'le helper avec_cache met réellement les fragments en cache' do
    avec_cache do |store|
      sign_in users(:hidalgo)
      get interventions_url

      assert_operator store.instance_variable_get(:@data).keys.count { |clé| clé.include?('_intervention') },
                      :>, 0, 'aucun fragment écrit : les tests de fuite ne prouveraient rien'
    end
  end

  # --- Fuites, vue par vue ----------------------------------------------------

  test 'absences : l’agent ne reçoit pas les boutons mis en cache par le manager' do
    agent = users(:bond)
    absence = absences(:one)

    avec_cache do
      sign_in users(:hidalgo)
      get user_url(agent)
      assert_match "edit_modal_#{absence.id}", response.body

      sign_in agent
      get user_url(agent)
      assert_no_match(/edit_modal_#{absence.id}\b/, response.body)
    end
  end

  test 'index des interventions : l’agent ne reçoit pas les actions du manager' do
    intervention = interventions(:intervention_terminée)
    intervention.touch

    avec_cache do
      sign_in users(:hidalgo)
      get interventions_url
      assert_match valider_intervention_path(intervention), response.body

      sign_in users(:bond)
      get interventions_url
      assert_match intervention.description, response.body
      assert_no_match(/#{Regexp.escape(valider_intervention_path(intervention))}/, response.body)
    end
  end

  test 'index compact des interventions : l’agent ne reçoit pas les actions du manager' do
    intervention = interventions(:intervention_terminée)
    intervention.touch

    avec_cache do
      sign_in users(:hidalgo)
      get interventions_url(vue: 'compact')
      assert_match valider_intervention_path(intervention), response.body

      sign_in users(:bond)
      get interventions_url(vue: 'compact')
      assert_no_match(/#{Regexp.escape(valider_intervention_path(intervention))}/, response.body)
    end
  end

  # john_wick est agent de la même organisation mais n'est affecté à aucune
  # intervention : la policy lui refuse le lien que le manager, lui, obtient.
  test 'fiche outil : l’agent ne reçoit pas le lien d’édition du manager' do
    intervention = interventions(:tonte_locaux)

    avec_cache do
      sign_in users(:hidalgo)
      get tool_url(tools(:tondeuse), vue: 'liste')
      assert_match(/href="#{Regexp.escape(intervention_path(intervention))}"/, response.body)

      sign_in users(:john_wick)
      get tool_url(tools(:tondeuse), vue: 'liste')
      assert_match intervention.description.humanize, response.body
      assert_no_match(/href="#{Regexp.escape(intervention_path(intervention))}"/, response.body)
    end
  end
end
