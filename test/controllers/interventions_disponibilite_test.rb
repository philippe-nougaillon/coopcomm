# frozen_string_literal: true

require 'test_helper'

# Vérifie le câblage de l'action live `get_unavailable_elements` après la bascule
# des disponibilités sur les dates réelles (plage effective : réel prioritaire,
# repli sur prévu).
class InterventionsDisponibiliteTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:administrateur_paris)
    @agent = users(:bond)
    @adherent = users(:weil)
    @service = @adherent.services.first
  end

  test 'signale un agent en conflit sur les dates RÉELLES' do
    creer_intervention(début: '2025-04-08 09:00', fin: '2025-04-08 12:00')

    json = interroger(date_debut: '2025-04-08 10:00', date_fin: '2025-04-08 11:00')

    assert_includes json['agents'], @agent.id
  end

  test 'pas de conflit si les dates réelles sont disjointes' do
    creer_intervention(début: '2025-04-08 09:00', fin: '2025-04-08 12:00')

    json = interroger(date_debut: '2025-04-08 14:00', date_fin: '2025-04-08 17:00')

    assert_not_includes json['agents'], @agent.id
  end

  test 'le réel est prioritaire : prévu chevauchant ignoré quand le réel est disjoint' do
    creer_intervention(début: '2025-04-08 09:00', fin: '2025-04-08 12:00',
                       début_prévue: '2025-04-08 14:00', fin_prévue: '2025-04-08 17:00')

    # On interroge sur le réel 14-17 (chevauche la PRÉVUE de l'existante) :
    # aucun conflit car le réel de l'existante (09-12) est disjoint.
    json = interroger(date_debut: '2025-04-08 14:00', date_fin: '2025-04-08 17:00')

    assert_not_includes json['agents'], @agent.id
  end

  test 'repli sur les dates prévues quand le réel est absent' do
    creer_intervention(début_prévue: '2025-04-08 09:00', fin_prévue: '2025-04-08 12:00')

    json = interroger(date_debut_prevue: '2025-04-08 10:00', date_fin_prevue: '2025-04-08 11:00')

    assert_includes json['agents'], @agent.id
  end

  # --- Complétude des dates de la requête (le repli réel→prévu est PAR borne) ---

  test 'F1 bornes mixtes : date_debut réelle + date_fin prévue → conflit détecté' do
    creer_intervention(début: '2025-04-08 09:00', fin: '2025-04-08 12:00')

    json = interroger(date_debut: '2025-04-08 10:30', date_fin_prevue: '2025-04-08 11:30')

    assert_includes json['agents'], @agent.id
  end

  test 'F2 priorité par borne : début réel (hors) prime sur début prévu (dans) → pas de conflit' do
    creer_intervention(début: '2025-04-08 09:00', fin: '2025-04-08 12:00')

    json = interroger(date_debut: '2025-04-08 13:00', date_debut_prevue: '2025-04-08 10:30',
                      date_fin: '2025-04-08 14:00')

    assert_not_includes json['agents'], @agent.id
  end

  test 'F3 outil occupé sur la plage → id renvoyé dans "tools"' do
    tool = tools(:tondeuse)
    Intervention.create!(description: 'Occupe l’outil', organisation: organisations(:mairie_paris),
                         tools: [tool], adherent: @adherent, service: @service,
                         début: '2025-04-08 09:00', fin: '2025-04-08 12:00')

    json = interroger(date_debut: '2025-04-08 10:00', date_fin: '2025-04-08 11:00',
                      agents_ids: '', tool_ids: tool.id.to_s)

    assert_includes json['tools'], tool.id
  end

  test 'F4 agent absent sur la plage → id renvoyé dans "agents" (branche absences)' do
    Absence.create!(du: '2025-04-08', au: '2025-04-08', motif: 0, user: @agent)

    json = interroger(date_debut: '2025-04-08 10:00', date_fin: '2025-04-08 11:00')

    assert_includes json['agents'], @agent.id
  end

  test 'édition : les dates réelles déclenchent la vérification live même si l’intervention est passée' do
    # Les dates réelles sont toujours passées (saisie a posteriori) : le listener
    # change->verificationWithInput doit être présent malgré `passed` — sinon la
    # couleur des agents ne se met à jour qu'à l'enregistrement.
    intervention = creer_intervention(début: '2025-04-08 09:00', fin: '2025-04-08 12:00')

    get edit_intervention_url(intervention)

    assert_response :success
    # Le champ de date réelle « début » est une cible ET déclenche le check live
    # (l'action est ce qui recolore l'agent au changement), sans garde sur `passed`.
    assert_select 'input[name=?][data-verification-disponibilites-target=?]',
                  'intervention[début]', 'debut'
    assert_select 'input[name=?][data-action*=?]',
                  'intervention[début]', 'verification-disponibilites#verificationWithInput'
  end

  # --- Câblage du check live dans le formulaire AGENT (_form_for_agents) --------
  # Le partial agent n'a que des dates réelles (pas de prévues) : le contrôleur JS
  # doit y être branché et fonctionner sans champs prévus.

  test 'form agent (new) : contrôleur + cibles/action câblés sur les dates réelles et les agents' do
    sign_in users(:martin_technique_paris) # agent

    get new_intervention_url

    assert_response :success
    assert_select 'form[data-controller~=?]', 'verification-disponibilites'
    assert_select 'input[name=?][data-verification-disponibilites-target=?]', 'intervention[début]', 'debut'
    assert_select 'input[name=?][data-action*=?]',
                  'intervention[début]', 'verification-disponibilites#verificationWithInput'
    assert_select 'select[name=?][data-verification-disponibilites-target=?]',
                  'intervention[agent_ids][]', 'agents'
    # Aucun champ de date prévue dans le form agent : la JS doit rester robuste
    # (cibles prévues absentes → lues avec garde has...Target).
    assert_not_includes response.body, 'intervention[début_prévue]'
  end

  test 'form agent (edit) : contrôleur + cible sur la date de fin réelle' do
    sign_in users(:martin_technique_paris) # agent

    get edit_intervention_url(interventions(:nouvelle_intervention))

    assert_response :success
    assert_select 'form[data-controller~=?]', 'verification-disponibilites'
    assert_select 'input[name=?][data-verification-disponibilites-target=?]', 'intervention[fin]', 'fin'
  end

  test 'F5 aucune date fournie → réponse vide sans erreur' do
    creer_intervention(début: '2025-04-08 09:00', fin: '2025-04-08 12:00')

    json = interroger

    assert_empty json['agents']
    assert_empty json['tools']
  end

  private

  def creer_intervention(**attrs)
    Intervention.create!({
      description: 'Intervention existante',
      organisation: organisations(:mairie_paris),
      agents: [@agent],
      adherent: @adherent,
      service: @service
    }.merge(attrs))
  end

  def interroger(date_debut: 'null', date_fin: 'null', date_debut_prevue: 'null', date_fin_prevue: 'null',
                 agents_ids: @agent.id.to_s, tool_ids: '')
    get get_unavailable_elements_interventions_url, params: {
      intervention_id: 'null',
      agents_ids: agents_ids,
      tool_ids: tool_ids,
      date_debut_prevue: en_utc(date_debut_prevue),
      date_fin_prevue: en_utc(date_fin_prevue),
      date_debut: en_utc(date_debut),
      date_fin: en_utc(date_fin)
    }

    assert_response :success
    JSON.parse(response.body)
  end

  # Le JS envoie les dates en UTC ISO (toISOString) ; les colonnes sont stockées
  # en UTC. On convertit donc l'heure locale des tests comme le ferait le vrai
  # appelant — des chaînes locales naïves ne matcheraient pas la base.
  def en_utc(valeur)
    return valeur if valeur == 'null'

    Time.zone.parse(valeur).utc.iso8601
  end
end
