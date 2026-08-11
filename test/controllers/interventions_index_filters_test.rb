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

  test 'un tag d\'intervention restreint la liste' do
    @tonte.update!(tag_list: 'urgent')

    get interventions_url(tags: ['urgent'])

    assert_response :success
    assert_includes assigns(:interventions), @tonte
    assert_not_includes assigns(:interventions), interventions(:nouvelle_intervention)
  end

  test 'sans tag soumis, la liste n\'est pas restreinte' do
    get interventions_url

    assert_response :success
    assert_includes assigns(:interventions), @tonte
  end

  test 'deux mots clés se cumulent : seules les interventions qui portent les deux' do
    les_deux = cree_intervention('Porte les deux mots clés', tag_list: 'urgence, plomberie')
    un_seul = cree_intervention('Ne porte qu\'un mot clé', tag_list: 'urgence')

    get interventions_url, params: { tags: %w[urgence plomberie] }

    assert_response :success
    assert_includes assigns(:interventions), les_deux
    assert_not_includes assigns(:interventions), un_seul
  end

  test 'le filtre par mot clé ignore la casse' do
    urgente = cree_intervention('Intervention urgente', tag_list: 'urgence')

    get interventions_url, params: { tags: ['URGENCE'] }

    assert_response :success
    assert_includes assigns(:interventions), urgente
  end

  test 'un mot clé inconnu rend une liste vide sans erreur' do
    get interventions_url, params: { tags: ['mot-clé-qui-n-existe-pas'] }

    assert_response :success
    assert_empty assigns(:interventions)
  end

  # Filtre vidé = filtre retiré, comme pour la saisie des mots clés (B90) : ce que
  # l'utilisateur n'a pas demandé ne doit rien restreindre.
  test 'un filtre de mots clés vidé rend toutes les interventions' do
    get interventions_url, params: { tags: [''] }

    assert_response :success
    assert_includes assigns(:interventions), @tonte
  end

  test 'un paramètre tags scalaire est accepté au lieu de faire tomber la page' do
    @tonte.update!(tag_list: 'urgence')

    get interventions_url, params: { tags: 'urgence' }

    assert_response :success
    assert_includes assigns(:interventions), @tonte
  end

  test 'un paramètre tags non textuel est ignoré' do
    get interventions_url, params: { tags: { a: 'b' } }

    assert_response :success
    assert_includes assigns(:interventions), @tonte
  end

  # --- Cloisonnement multi-organisations des mots clés ---
  # La table des mots clés est commune à toutes les organisations : seul le périmètre de
  # la relation interrogée les sépare.

  test 'critique : un mot clé d une autre organisation ne remonte aucune intervention' do
    marseille = interventions(:nettoyage_port)
    marseille.update!(tag_list: 'secret-marseille')

    get interventions_url, params: { tags: ['secret-marseille'] }

    assert_response :success
    assert_empty assigns(:interventions)
  end

  test 'critique : la liste des mots clés proposée est bornée à l organisation' do
    interventions(:nettoyage_port).update!(tag_list: 'secret-marseille')
    @tonte.update!(tag_list: 'urgence')

    get interventions_url

    assert_response :success
    noms = assigns(:intervention_tags).map(&:name)
    assert_includes noms, 'urgence'
    assert_not_includes noms, 'secret-marseille'
  end

  test 'le filtre par mot clé se combine avec le filtre Statut' do
    urgente_nouvelle = cree_intervention('Urgente et nouvelle', tag_list: 'urgence')
    urgente_validée = cree_intervention('Urgente et validée', tag_list: 'urgence',
                                                             workflow_state: 'validé')

    get interventions_url, params: { tags: ['urgence'], workflow_state: ['Nouveau'] }

    assert_response :success
    assert_includes assigns(:interventions), urgente_nouvelle
    assert_not_includes assigns(:interventions), urgente_validée
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
