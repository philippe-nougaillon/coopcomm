# frozen_string_literal: true

require 'test_helper'
require_relative '../support/interventions_matrice'

# Inventaire exact des champs offerts par le formulaire d'intervention, pour
# chaque acteur, chaque type et chaque état du workflow — avec et sans la demande
# de terminaison (`?terminer=1`).
#
# Le découpage du formulaire en partials ne doit rien changer à cet inventaire :
# un champ qui apparaît, disparaît, ou perd son `required` / `disabled` est une
# régression. La référence exhaustive vit dans un fichier d'instantané ; les
# invariants qui portent une règle métier sont, eux, asserés explicitement.
class InterventionMatriceFormulaireTest < ActionDispatch::IntegrationTest
  include InterventionsMatrice

  INSTANTANE = Rails.root.join('test/fixtures/files/formulaires_interventions.txt')

  ACTEURS = {
    'administrateur' => :administrateur_paris,
    'manager' => :hidalgo,
    'agent_affecte' => :martin_technique_paris,
    'adherent_proprietaire' => :weil
  }.freeze

  setup { mere_matrice }

  test "instantané : l'inventaire des champs est inchangé" do
    reel = inventaire_complet
    reference = INSTANTANE.read.split("\n")

    reel.zip(reference).each do |ligne_reelle, ligne_reference|
      next if ligne_reelle == ligne_reference

      flunk <<~MESSAGE
        Le formulaire a changé.
          attendu : #{ligne_reference}
          obtenu  : #{ligne_reelle}
        Si le changement est voulu, régénérer avec :
          REGENERER_INSTANTANE=1 bin/rails test #{__FILE__}
      MESSAGE
    end

    assert_equal reference.size, reel.size, 'le nombre de cas couverts a changé'
  end

  test "l'adhérent ne se voit jamais offrir les champs de réalisation" do
    sign_in users(:weil)

    TYPES.each do |type|
      get edit_intervention_url(intervention_matrice(type: type, complete: true), terminer: 1)

      noms = champs_du_formulaire.map { |champ| champ[:nom] }
      %w[commentaires photos[] agent_ids[] tool_ids[] temps_de_pause temps_total début fin].each do |absent|
        assert_not_includes noms, "intervention[#{absent}]", "#{type} : champ #{absent}"
      end
    end
  end

  test "l'agent ne se voit jamais offrir l'évaluation ni la description" do
    sign_in users(:martin_technique_paris)

    %i[classique fille].each do |type|
      ETATS.each do |etat|
        get edit_intervention_url(intervention_matrice(type: type, etat: etat, complete: true), terminer: 1)

        noms = champs_du_formulaire.map { |champ| champ[:nom] }
        assert_not_includes noms, 'intervention[note]', "#{type}/#{etat}"
        assert_not_includes noms, 'intervention[avis]', "#{type}/#{etat}"
        assert_not_includes noms, 'intervention[description]', "#{type}/#{etat}"
      end
    end
  end

  test 'les dates prévues ne sont jamais offertes sur un pointage' do
    ACTEURS.each_value do |fixture|
      sign_in users(fixture)

      %i[modele fille].each do |type|
        ETATS.each do |etat|
          get edit_intervention_url(intervention_matrice(type: type, etat: etat, complete: true))
          next unless response.successful?

          noms = champs_du_formulaire.map { |champ| champ[:nom] }
          %w[début_prévue début_prévue_hour début_prévue_minute
             fin_prévue fin_prévue_hour fin_prévue_minute].each do |absent|
            assert_not_includes noms, "intervention[#{absent}]", "#{fixture}/#{type}/#{etat}"
          end
        end
      end
    end
  end

  test "l'agent ne peut pas changer les agents d'une fille de pointage" do
    sign_in users(:martin_technique_paris)
    get edit_intervention_url(intervention_matrice(type: :fille))

    agents = champs_du_formulaire.find { |champ| champ[:nom] == 'intervention[agent_ids][]' }
    assert agents[:inactif], 'le select des agents doit rester inactif sur une fille de pointage'
  end

  test "les mots clés du manager et ceux de l'intervenant ne coexistent jamais" do
    { administrateur_paris: 'tags_manager', hidalgo: 'tags_manager',
      martin_technique_paris: 'tags_intervenant' }.each do |fixture, attendu|
      sign_in users(fixture)
      get edit_intervention_url(intervention_matrice(type: :classique))

      noms = champs_du_formulaire.map { |champ| champ[:nom] }
      assert_includes noms, "intervention[#{attendu}][]", fixture.to_s
      autre = attendu == 'tags_manager' ? 'tags_intervenant' : 'tags_manager'
      assert_not_includes noms, "intervention[#{autre}][]", fixture.to_s
    end
  end

  test 'un agent ne peut ni créer ni modifier un modèle de pointage' do
    sign_in users(:martin_technique_paris)

    get new_intervention_modele_pointage_interventions_url
    assert_response :redirect

    get edit_intervention_url(intervention_matrice(type: :modele))
    assert_response :redirect
  end

  private

  def champs_du_formulaire
    doc = Nokogiri::HTML(response.body)
    formulaire = doc.at_css('form.max-w-5xl') || doc.at_css('form[action*="intervention"]')
    return [] if formulaire.nil?

    formulaire.css('input, select, textarea').filter_map do |champ|
      nom = champ['name']
      next if nom.blank? || %w[authenticity_token _method commit].include?(nom)

      { nom: nom, requis: !champ['required'].nil?, inactif: !champ['disabled'].nil?,
        lecture_seule: !champ['readonly'].nil? }
    end.uniq
  end

  def ligne_inventaire
    return 'REFUSE(redirection)' if response.redirect?
    return "STATUT #{response.status}" unless response.successful?

    doc = Nokogiri::HTML(response.body)
    formulaire = doc.at_css('form.max-w-5xl') || doc.at_css('form[action*="intervention"]')
    controleurs = formulaire ? formulaire['data-controller'].to_s : 'AUCUN FORMULAIRE'

    champs = champs_du_formulaire.map do |champ|
      drapeaux = []
      drapeaux << 'requis' if champ[:requis]
      drapeaux << 'inactif' if champ[:inactif]
      drapeaux << 'lecture-seule' if champ[:lecture_seule]
      "#{champ[:nom]}#{drapeaux.any? ? "(#{drapeaux.join(',')})" : ''}"
    end

    "[#{controleurs}] #{champs.sort.join(' ')}"
  end

  def inventaire_complet
    lignes = []

    ACTEURS.each do |nom_acteur, fixture|
      sign_in users(fixture)

      get new_intervention_url
      lignes << "#{nom_acteur} | new | - | - | #{ligne_inventaire}"

      # Une intervention neuve a un workflow_state nil : ce cas a déjà produit
      # un 500 dans le bloc compte-rendu.
      get new_intervention_url(terminer: 1)
      lignes << "#{nom_acteur} | new+terminer | - | - | #{ligne_inventaire}"

      get new_intervention_modele_pointage_interventions_url
      lignes << "#{nom_acteur} | new_modele | - | - | #{ligne_inventaire}"

      TYPES.each do |type|
        ETATS.each do |etat|
          intervention = intervention_matrice(type: type, etat: etat, complete: true)

          get edit_intervention_url(intervention)
          lignes << "#{nom_acteur} | edit | #{type} | #{etat} | #{ligne_inventaire}"

          get edit_intervention_url(intervention, terminer: 1)
          lignes << "#{nom_acteur} | edit+terminer | #{type} | #{etat} | #{ligne_inventaire}"
        end
      end
    end

    INSTANTANE.write("#{lignes.join("\n")}\n") if ENV['REGENERER_INSTANTANE']
    lignes
  end
end
