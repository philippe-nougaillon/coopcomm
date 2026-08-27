# frozen_string_literal: true

require 'test_helper'

# Un formulaire refusé par une validation doit revenir avec la saisie intacte.
# Chaque cas soumet des données volontairement invalides ; l'assertion compare
# AUTOMATIQUEMENT chaque paramètre soumis au champ correspondant du formulaire
# ré-affiché — un champ ajouté demain est donc couvert sans toucher ce fichier.
class FormulairesConserventLaSaisieTest < ActionDispatch::IntegrationTest
  # Valeurs que le serveur recalcule ou normalise : elles n'ont pas à revenir
  # telles quelles.
  RECALCULES = %w[temps_total].freeze

  # Rails accompagne tout select multiple d'un champ caché vide : c'est le
  # select qui porte la saisie, jamais lui.
  def noeuds(champ)
    tous = @doc.css('input, select, textarea').select { |n| n['name'] == champ || n['name'] == "#{champ}[]" }
    tous.reject { |n| n.name == 'input' && n['type'] == 'hidden' }.presence || tous
  end

  def valeur_rendue(champ)
    trouves = noeuds(champ)
    return nil if trouves.empty?

    case trouves.first.name
    when 'select'
      selectionnees = trouves.flat_map { |n| n.css('option[selected]').map { |o| o['value'] } }
      trouves.first['multiple'] ? selectionnees : selectionnees.first
    when 'textarea' then trouves.first.text.sub(/\A\n/, '')
    else trouves.first['value']
    end
  end

  def champ_present?(champ)
    noeuds(champ).any?
  end

  # Parcourt les paramètres soumis et vérifie, pour chacun que le formulaire
  # ré-affiche, que la valeur revenue est celle qui a été envoyée.
  def assert_saisie_conservee(soumis, prefixe:, ignorer: [])
    @doc = Nokogiri::HTML(response.body)
    verifies = 0

    soumis.each do |attribut, valeur|
      next if RECALCULES.include?(attribut.to_s) || ignorer.map(&:to_s).include?(attribut.to_s)

      champ = "#{prefixe}[#{attribut}]"
      next unless champ_present?(champ)

      attendu = valeur.is_a?(Array) ? valeur.map(&:to_s) : valeur.to_s
      rendu   = valeur_rendue(champ)
      if valeur.is_a?(Array)
        # L'ordre vient des options du menu, pas de la saisie.
        attendu = attendu.sort
        rendu   = Array(rendu).map(&:to_s).sort
      else
        rendu = rendu.to_s
      end

      assert_equal attendu, rendu, "#{champ} : la saisie a été perdue par le formulaire ré-affiché"
      verifies += 1
    end

    assert_operator verifies, :>, 0, 'garde anti-faux-positif : aucun champ soumis n’a été retrouvé dans le formulaire'
  end

  def assert_refus(soumis, prefixe:, ignorer: [])
    assert_response :unprocessable_content
    assert_saisie_conservee(soumis, prefixe: prefixe, ignorer: ignorer)
  end

  # --- Interventions ---

  test 'intervention : un manager qui crée garde sa saisie' do
    sign_in users(:hidalgo)
    soumis = {
      description: 'Élaguer les tilleuls',
      adherent_id: users(:weil).id, service_id: services(:technique).id,
      agent_ids: [users(:bond).id],
      début_prévue: '2026-09-14', début_prévue_hour: 7, début_prévue_minute: 30,
      fin_prévue: '2026-09-17', fin_prévue_hour: 18, fin_prévue_minute: 45,
      début: '2026-09-14', début_hour: 10, début_minute: 45,
      fin: '2026-09-14', fin_hour: 9, fin_minute: 15,
      temps_de_pause: 1.0
    }

    post interventions_url, params: { intervention: soumis }

    assert_refus(soumis, prefixe: 'intervention')
  end

  test 'intervention : un manager qui modifie garde sa saisie' do
    sign_in users(:hidalgo)
    soumis = {
      description: 'Description corrigée',
      début: '2026-09-14', début_hour: 10, début_minute: 45,
      fin: '2026-09-14', fin_hour: 9, fin_minute: 15,
      temps_de_pause: 1.0
    }

    patch intervention_url(interventions(:nouvelle_intervention)), params: { intervention: soumis }

    assert_refus(soumis, prefixe: 'intervention')
  end

  # C'est le formulaire où la saisie se perdait : les heures étaient
  # délibérément ignorées tant que l'intervention n'était pas enregistrée.
  test 'intervention : un agent qui crée un bon garde ses heures' do
    agent = users(:bond)
    sign_in agent
    soumis = {
      adherent_id: users(:weil).id, service_id: services(:technique).id, agent_ids: [agent.id],
      début: '2026-09-14', début_hour: 10, début_minute: 45,
      fin: '2026-09-14', fin_hour: 9, fin_minute: 15,
      temps_de_pause: 1.0
    }

    post interventions_url, params: { intervention: soumis }

    assert_refus(soumis, prefixe: 'intervention')
  end

  test 'intervention : un agent qui modifie garde ses heures' do
    agent = users(:bond)
    sign_in agent
    soumis = {
      début: '2026-09-14', début_hour: 10, début_minute: 45,
      fin: '2026-09-14', fin_hour: 9, fin_minute: 15,
      temps_de_pause: 1.0
    }

    patch intervention_url(interventions(:tonte_locaux)), params: { intervention: soumis }

    assert_refus(soumis, prefixe: 'intervention')
  end

  # Les heures saisies sans leur date ne peuvent pas être fusionnées dans la
  # colonne datetime : elles doivent survivre par leurs accesseurs virtuels.
  test 'intervention : les heures survivent même quand la date manque' do
    agent = users(:bond)
    sign_in agent
    soumis = {
      adherent_id: users(:weil).id, service_id: services(:technique).id, agent_ids: [agent.id],
      début: '', début_hour: 9, début_minute: 15,
      fin: '', fin_hour: 17, fin_minute: 45,
      temps_de_pause: 1.0
    }

    post interventions_url, params: { intervention: soumis }

    assert_refus(soumis, prefixe: 'intervention', ignorer: %i[début fin])
  end

  # --- Utilisateurs ---

  test 'utilisateur : une modification refusée garde la saisie' do
    sign_in users(:administrateur_paris)
    soumis = {
      nom: 'BOND', prénom: 'James', email: 'bond@paris.fr',
      téléphone: '0600000000', memo: 'Mémo saisi par le test',
      service_ids: [services(:technique).id, services(:informatique).id]
    }

    patch user_url(users(:bond)), params: { user: soumis }

    assert_refus(soumis, prefixe: 'user')
  end

  test 'utilisateur : une création refusée garde la saisie' do
    sign_in users(:administrateur_paris)
    soumis = {
      nom: 'DUPONT', prénom: 'Jeanne', email: '',
      téléphone: '0611111111', memo: 'Nouveau compte',
      service_ids: [services(:technique).id]
    }

    post admin_create_new_user_do_url, params: { user: soumis }

    assert_refus(soumis, prefixe: 'user')
  end

  # --- Autres ressources ---

  test 'outil : une création refusée garde la saisie' do
    sign_in users(:administrateur_paris)
    soumis = { name: '', marque: 'Husqvarna', mod: 'LC 140',
               description: 'Doublon volontaire du nom' }

    post tools_url, params: { tool: soumis }

    assert_refus(soumis, prefixe: 'tool')
  end

  test 'outil : une modification refusée garde la saisie' do
    sign_in users(:administrateur_paris)
    soumis = { name: '', marque: 'Stihl', mod: 'MS 180', description: 'Nom vidé volontairement' }

    patch tool_url(tools(:tondeuse)), params: { tool: soumis }

    assert_refus(soumis, prefixe: 'tool')
  end

  test 'convention : une création refusée garde la saisie' do
    sign_in users(:administrateur_paris)
    soumis = { user_id: users(:weil).id, service_id: services(:technique).id,
               date_début: '2026-09-01', date_fin_prévue: '',
               heures_conventionnees: 42, mémo: 'Mémo de la convention' }

    post conventions_url, params: { convention: soumis }

    assert_refus(soumis, prefixe: 'convention')
  end

  test 'service : une création refusée garde la saisie' do
    sign_in users(:administrateur_paris)
    soumis = { nom: services(:technique).nom }

    post services_url, params: { service: soumis }

    assert_refus(soumis, prefixe: 'service')
  end

  test 'prestation : une création refusée garde la saisie' do
    sign_in users(:administrateur_paris)
    # `code`, `catégorie` et `sous_catégorie` sont soumis déjà normalisés : le
    # modèle les passe en majuscules, ce que le formulaire ré-affiche.
    soumis = { code: '', libellé: 'Tonte de pelouse', tarif: 25.5,
               description: 'Description de la prestation', compétence: 'Espaces verts',
               délai: '48 h', catégorie: 'VOIRIE', sous_catégorie: 'ENTRETIEN',
               unité: 'Mètre linéaire' }

    post prestations_url, params: { prestation: soumis }

    assert_refus(soumis, prefixe: 'prestation')
  end

  # Sans option vide en tête, aucune option n'est marquée `selected` et le
  # navigateur retient la première du menu.
  test 'prestation : une catégorie vidée ne revient pas à la première du menu' do
    sign_in users(:administrateur_paris)

    post prestations_url, params: { prestation: { code: '', libellé: 'Tonte', tarif: 25.5, catégorie: '' } }

    assert_response :unprocessable_content
    assert_dom 'select#prestation_catégorie option:first-child[value=""]'
    assert_dom 'select#prestation_catégorie option[selected]', 0
  end

  test 'site : une création refusée garde la saisie' do
    sign_in users(:administrateur_paris)
    soumis = { name: 'Atelier municipal', address: 'Adresse sans coordonnées',
               latitude: '', longitude: '' }

    post warehouses_url, params: { warehouse: soumis }

    assert_refus(soumis, prefixe: 'warehouse', ignorer: %i[latitude longitude])
  end
end
