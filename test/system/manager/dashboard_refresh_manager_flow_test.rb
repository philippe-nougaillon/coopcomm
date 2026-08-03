# frozen_string_literal: true

require 'application_system_test_case'

# Vérifie EN CONDITIONS RÉELLES (navigateur + serveur + vrais commits) que les vues
# matérialisées du dashboard se rafraîchissent — ou non — selon les cas.
class DashboardRefreshManagerFlowTest < ApplicationSystemTestCase
  setup do
    @manager = users(:hidalgo)
    # Informatique compte ainsi 2 agents (Bond + Martin) : nécessaire pour affecter deux
    # agents via le formulaire.
    UserService.create!(user: users(:bond), service: services(:informatique))
    UserService.create!(user: users(:martin_technique_paris), service: services(:informatique))
    # Base connue : les vues reflètent exactement les fixtures (leur insertion
    # ne passe pas par les callbacks, donc ne rafraîchit rien).
    refresh_dashboard_views!
    login(@manager)
  end

  # Valeur affichée dans la tuile KPI portant ce libellé. Les libellés sont en
  # `text-transform: uppercase` : Selenium renvoie le texte RENDU → regex /i.
  def kpi(label)
    find('span', text: /#{label}/i).sibling('span').text
  end

  # Attend qu'une condition métier (en base) devienne vraie — même recette que
  # intervention_manager_flow_test (la navigation Turbo post-POST est capricieuse).
  def attendre_que(message)
    10.times do
      return if yield

      sleep 0.3
    end
    flunk message
  end

  # Erreurs typiques d'une liste d'options reconstruite PENDANT l'interaction (dynamic-
  # select re-fetch les services/agents en asynchrone)
  RACE_SELECT = [Capybara::ElementNotFound,
                 Selenium::WebDriver::Error::StaleElementReferenceError,
                 Selenium::WebDriver::Error::ElementClickInterceptedError].freeze

  # select_option durci : si la repopulation frappe en plein clic (option
  # momentanément absente, élément recyclé), on referme et on réessaie.
  def select_option_stable(id, valeur)
    tentatives = 0
    begin
      select_option(id, valeur)
    rescue *RACE_SELECT
      tentatives += 1
      raise if tentatives >= 5

      fermer_menus_slim_select
      sleep 0.4
      retry
    end
  end

  # Referme un menu slim-select resté ouvert (un menu multi ouvert intercepte
  # les clics suivants).
  def fermer_menus_slim_select
    find('label', text: 'Description', match: :first).click
    assert_no_selector '.ss-option', visible: true
  end

  # Pose le service et les agents puis VÉRIFIE que les valeurs ont survécu : dynamic-
  # select repeuple service et agents en cascade (fetch asynchrones)
  def fixer_service_et_agents(service_record, agents)
    attendus = agents.map { |a| a.id.to_s }
    5.times do
      select_option_stable('#intervention_service_id', service_record.nom) if service_selectionne != service_record.id.to_s
      (attendus - agents_selectionnes).each do |id|
        select_option_stable('#intervention_agent_ids', agents.find { |a| a.id.to_s == id }.nom_prénom)
      end
      fermer_menus_slim_select
      sleep 0.3 # laisse retomber une éventuelle repopulation en vol
      return if service_selectionne == service_record.id.to_s && (attendus - agents_selectionnes).empty?
    end
    flunk 'service/agents ne survivent pas aux repopulations dynamic-select'
  end

  def service_selectionne
    page.evaluate_script("document.getElementById('intervention_service_id').value").to_s
  end

  def agents_selectionnes
    page.evaluate_script(
      "Array.from(document.getElementById('intervention_agent_ids').selectedOptions).map(o => o.value)"
    )
  end

  test 'création avec deux agents : le dashboard est à jour à la navigation suivante' do
    visit dashboard_path
    total_avant = kpi('Total Interventions').to_i

    visit interventions_url
    click_sur_boutton_ajouter('intervention')
    fill_in 'Description', with: 'Refresh dashboard — création à deux agents'
    select_option('#intervention_adherent_id', 'Weil Ariel')
    fixer_service_et_agents(services(:informatique), [users(:bond), users(:martin_technique_paris)])

    # Créneau passé à J-10 : hors de portée des fixtures (tonte_locaux occupe Bond au plus
    # 7 jours en arrière) → jamais de conflit #357.
    jour = (Date.today - 10).strftime('%m%d%Y')
    fill_in 'Début', with: jour
    select '08', from: 'intervention_début_hour'
    select '00', from: 'intervention_début_minute'
    fill_in 'Fin', with: jour
    select '16', from: 'intervention_fin_hour'
    select '00', from: 'intervention_fin_minute'
    page.select '1,0', from: 'intervention_temps_de_pause'

    # Garde anti-écrasement : les deux agents sont bien posés au moment du submit.
    assert_includes agents_selectionnes, users(:bond).id.to_s
    assert_includes agents_selectionnes, users(:martin_technique_paris).id.to_s
    click_on 'enregistrer_intervention'

    créée = nil
    attendre_que("l'intervention n'a pas été créée") do
      créée = Intervention.find_by(description: 'Refresh dashboard — création à deux agents')
    end
    assert_equal 2, créée.agents.count, 'les deux agents doivent être affectés'
    temps = créée.temps_total
    assert temps.to_f.positive?, 'le formulaire (JS calc-temps-passe) doit avoir rempli temps_total'

    # Le dashboard reflète la création SANS action de rafraîchissement.
    visit dashboard_path
    assert_equal total_avant + 1, kpi('Total Interventions').to_i

    # Vue agent : le temps est réparti entre les deux agents (temps / 2 chacun,
    # Bond cumulant en plus les 9 h de tonte_locaux).
    tonte = interventions(:tonte_locaux)
    assert_in_delta temps / 2.0, DashboardAgentStat.find_by(agent: users(:martin_technique_paris)).temps_total, 0.01
    assert_in_delta tonte.temps_total + (temps / 2.0), DashboardAgentStat.find_by(agent: users(:bond)).temps_total, 0.01
  end

  test "ajout d'un deuxième agent en modification : la répartition du temps est recalculée" do
    tonte = interventions(:tonte_locaux)

    # Point de départ (anti-faux-positif) : Bond porte seul les 9 h de la fixture.
    assert_in_delta tonte.temps_total, DashboardAgentStat.find_by(agent: users(:bond)).temps_total, 0.01

    visit edit_intervention_url(tonte)
    # dynamic-select ne propose que les services de l'adhérent : pour weil, seul
    # Informatique est disponible.
    fixer_service_et_agents(services(:informatique), [users(:bond), users(:martin_technique_paris)])
    click_on 'enregistrer_intervention'

    attendre_que("l'agent n'a pas été ajouté à l'intervention") do
      tonte.reload.agents.count == 2
    end
    temps = tonte.reload.temps_total

    # Le dashboard reflète la nouvelle répartition : temps / 2 pour chacun.
    visit dashboard_path
    assert_equal "#{temps.round(1)}h", kpi('Temps Cumulé')
    assert_in_delta temps / 2.0, DashboardAgentStat.find_by(agent: users(:bond)).temps_total, 0.01
    assert_in_delta temps / 2.0, DashboardAgentStat.find_by(agent: users(:martin_technique_paris)).temps_total, 0.01
  end

  test 'une modification sans impact dashboard ne déclenche PAS de refresh' do
    # Intervention cohérente avec l'UI (service ∈ services de l'adhérent) pour
    # que re-choisir « Informatique » à l'édition soit un non-changement.
    iv = Intervention.create!(
      adherent: users(:weil), service: services(:informatique),
      description: 'À modifier sans impact', workflow_state: 'nouveau',
      début: 12.days.ago.change(hour: 8), slug: SecureRandom.uuid
    )
    # Marqueur de péremption : la BASE porte 5 h mais pas la vue
    # (update_columns ne passe pas par les callbacks → pas de refresh).
    iv.update_columns(temps_total: 5)
    assert_equal 5.0, iv.reload.temps_total

    visit edit_intervention_url(iv)
    fixer_service_et_agents(services(:informatique), []) # même valeur qu'en base → pas un changement
    fill_in 'Description', with: 'Modif sans impact dashboard'
    click_on 'enregistrer_intervention'

    attendre_que('la description n’a pas été modifiée') do
      iv.reload.description == 'Modif sans impact dashboard'
    end

    # La description n'est pas une colonne du dashboard → aucun refresh : le marqueur 5 h
    # n'apparaît pas, le dashboard affiche toujours le seul temps des fixtures.
    visit dashboard_path
    assert_equal "#{interventions(:tonte_locaux).temps_total.round(1)}h", kpi('Temps Cumulé')
  end

  test "une transition d'état déclenche le refresh et rattrape les données en attente" do
    iv = interventions(:nouvelle_intervention)
    iv.update_columns(temps_total: 5) # même marqueur de péremption que ci-dessus

    visit intervention_url(iv)
    click_button 'Terminer'
    assert_text 'Intervention terminée'

    # workflow_state EST une colonne du dashboard → refresh : le marqueur est
    # rattrapé (le refresh reconstruit la vue depuis TOUTE la base).
    visit dashboard_path
    assert_equal "#{(interventions(:tonte_locaux).temps_total + 5).round(1)}h", kpi('Temps Cumulé')
  end
end
