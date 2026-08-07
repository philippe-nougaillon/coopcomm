# frozen_string_literal: true

require 'test_helper'

# Filtres de l'index des interventions autres que service et statut (couverts par
# leurs fichiers dédiés) : archives, recherche, dates, équipe, agents, outils,
# tags et tri de la vue compacte.
class InterventionsIndexFiltersTest < ActionDispatch::IntegrationTest
  setup do
    @manager = users(:hidalgo)
    @tonte = interventions(:tonte_locaux)
    sign_in @manager
  end

  # --- Archives ---

  test 'sans filtre, les interventions archivées sont exclues' do
    archivee = cree_intervention('Intervention archivée', workflow_state: 'archivé')

    get interventions_url

    assert_response :success
    assert_not_includes assigns(:interventions), archivee
  end

  test 'le paramètre archives ne montre que les interventions archivées' do
    archivee = cree_intervention('Intervention archivée', workflow_state: 'archivé')

    get interventions_url(archives: '1')

    assert_response :success
    assert_includes assigns(:interventions), archivee
    assert_not_includes assigns(:interventions), @tonte
  end

  # --- Recherche plein texte ---

  test 'la recherche filtre sur la description' do
    get interventions_url(search: 'Tonte locaux')

    assert_response :success
    assert_includes assigns(:interventions), @tonte
    assert_not_includes assigns(:interventions), interventions(:nouvelle_intervention)
  end

  test 'la recherche filtre aussi sur les commentaires' do
    get interventions_url(search: 'bord des routes')

    assert_response :success
    assert_includes assigns(:interventions), @tonte
  end

  test 'une recherche sans correspondance ne renvoie rien' do
    get interventions_url(search: 'zzz-aucune-correspondance-zzz')

    assert_response :success
    assert_empty assigns(:interventions)
  end

  # --- Dates ---

  test 'du et au encadrent les interventions sur leur date de début' do
    jour = @tonte.début.to_date

    get interventions_url(du: jour.to_s, au: jour.to_s)

    assert_response :success
    assert_includes assigns(:interventions), @tonte
    assert_not_includes assigns(:interventions), interventions(:nouvelle_intervention)
  end

  test 'du seul retient les interventions qui commencent ou finissent ce jour' do
    get interventions_url(du: @tonte.début.to_date.to_s)

    assert_response :success
    assert_includes assigns(:interventions), @tonte
  end

  test 'au seul retient les interventions qui finissent ce jour' do
    get interventions_url(au: @tonte.fin.to_date.to_s)

    assert_response :success
    assert_includes assigns(:interventions), @tonte
  end

  test 'un intervalle de dates hors période ne renvoie rien' do
    get interventions_url(du: '1900-01-01', au: '1900-01-02')

    assert_response :success
    assert_empty assigns(:interventions)
  end

  # --- Adhérent ---

  test 'adherent_id restreint aux interventions de cet adhérent' do
    get interventions_url(adherent_id: users(:weil).id)

    assert_response :success
    assert_includes assigns(:interventions), @tonte
    assert_not_includes assigns(:interventions), interventions(:intervention_autre_adhérent)
  end

  # --- Équipe (filtre supprimé avec le rôle équipe) ---

  test 'un paramètre équipe forgé est ignoré, en tableau comme en scalaire' do
    adherent = users(:weil)
    adherent.tag_list = 'mairie'
    adherent.save!(validate: false) # l'adresse est obligatoire à la mise à jour, hors sujet ici

    [['mairie'], 'mairie'].each do |valeur|
      get interventions_url(equipe: valeur)

      assert_response :success
      assert_includes assigns(:interventions), @tonte
    end
  end

  test 'un paramètre équipe forgé n_est pas réinjecté dans les liens de la page' do
    get interventions_url(equipe: ['mairie'])

    assert_response :success
    assert_no_match(/equipe/, response.body)
  end

  # --- Agents et outils ---

  test 'agent_ids restreint aux interventions de cet agent' do
    get interventions_url(agent_ids: [users(:bond).id])

    assert_response :success
    assert_includes assigns(:interventions), @tonte
    assert_not_includes assigns(:interventions), interventions(:intervention_autre_agent)
  end

  test 'tool_ids restreint aux interventions utilisant cet outil' do
    get interventions_url(tool_ids: [tools(:tondeuse).id])

    assert_response :success
    assert_includes assigns(:interventions), @tonte
    assert_not_includes assigns(:interventions), interventions(:intervention_terminée)
  end

  # --- Tags d'intervention ---

  test 'un tag d\'intervention restreint la liste et est mémorisé en session' do
    @tonte.update!(tag_list: 'urgent')

    get interventions_url(tags: ['urgent'])

    assert_response :success
    assert_includes assigns(:interventions), @tonte
    assert_not_includes assigns(:interventions), interventions(:nouvelle_intervention)
    assert_equal ['urgent'], session[:tags]
  end

  test 'sans tag soumis, la session est remise à vide' do
    get interventions_url

    assert_response :success
    assert_empty session[:tags]
  end

  # --- Tri de la vue compacte ---

  # Tri sur une colonne de dates : une colonne texte dépendrait de la collation
  # Postgres, qui ne classe pas les accents comme String#sort.
  test 'la vue compacte trie sur la colonne demandée' do
    get interventions_url(vue: 'compact', column: 'interventions.updated_at', direction: 'asc')

    assert_response :success
    dates = assigns(:interventions).map(&:updated_at)
    assert_equal dates.sort, dates
  end

  test 'une colonne de tri inconnue retombe sur updated_at décroissant' do
    get interventions_url(vue: 'compact', column: 'interventions.mot_de_passe', direction: 'haut')

    assert_response :success
    dates = assigns(:interventions).map(&:updated_at)
    assert_equal dates.sort.reverse, dates
  end

  def cree_intervention(description, attributs = {})
    Intervention.create!({
      description: description,
      adherent: users(:weil),
      service: services(:technique),
      workflow_state: 'nouveau',
      slug: SecureRandom.uuid
    }.merge(attributs))
  end
end
