# frozen_string_literal: true

require 'test_helper'

class TerminerPointagesJobTest < ActiveJob::TestCase
  setup do
    # Un vrai pointage : créé via le chemin réel (template_slug, début = now,
    # état « nouveau », repeter false, un seul agent).
    mère = interventions(:intervention_repete)
    @agent = users(:martin_technique_paris)
    @pointage = mère.create_next_intervention(mère, @agent)

    assert @pointage.persisted?
    assert @pointage.nouveau?
    assert @pointage.template_slug.present?
    assert @pointage.début.present?
    assert_equal [@agent], @pointage.agents.to_a

    ActionMailer::Base.deliveries.clear
  end

  test 'clôture le pointage : état terminé et date de fin à maintenant' do
    TerminerPointagesJob.perform_now

    @pointage.reload
    assert @pointage.terminé?
    assert @pointage.fin.present?
    assert_in_delta Time.current, @pointage.fin, 1.minute
  end

  test 'la clôture automatique enregistre le temps total et une pause à 0' do
    @pointage.update_columns(début: 3.hours.ago, temps_de_pause: nil, temps_total: nil)

    TerminerPointagesJob.perform_now

    @pointage.reload
    assert_equal 0, @pointage.temps_de_pause
    assert_in_delta 3.0, @pointage.temps_total, 0.05
  end

  test 'clôture le pointage même si une absence a été posée après son ouverture' do
    Absence.create!(user: @agent, du: Date.today, au: Date.today, motif: 0)

    TerminerPointagesJob.perform_now

    @pointage.reload
    assert @pointage.terminé?
    assert @pointage.fin.present?
  end

  test 'envoie un mail à l’unique agent et crée un MailLog' do
    assert_difference -> { ActionMailer::Base.deliveries.size } => 1,
                      -> { MailLog.count } => 1 do
      TerminerPointagesJob.perform_now
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal [@agent.email], mail.to
    assert_equal '[COOPCOMM] Pointage terminé automatiquement', mail.subject

    log = MailLog.order(:created_at).last
    assert_equal @agent.email, log.to
    assert_equal 'Pointage terminé automatiquement', log.subject
    assert_equal 'mail', log.channel
    assert_equal @pointage.organisation.id, log.organisation_id
    assert_equal mail.message_id, log.message_id
  end

  test 'la clôture automatique notifie les managers et l’adhérent' do
    assert_enqueued_with(job: NotifManagersWorkflowChangedJob) do
      assert_enqueued_with(job: NotifAdherentInterventionTermineeJob) do
        TerminerPointagesJob.perform_now
      end
    end

    assert @pointage.reload.terminé?, 'garde : la clôture doit bien avoir eu lieu'
  end

  test 'ignore les interventions « nouveau » sans template_slug' do
    cible = interventions(:nouvelle_intervention)
    assert cible.nouveau?
    assert cible.template_slug.blank?

    TerminerPointagesJob.perform_now

    assert cible.reload.nouveau?
  end

  test 'ignore les interventions déjà terminées' do
    déjà_terminée = interventions(:intervention_terminée)

    assert_no_changes -> { déjà_terminée.reload.workflow_state } do
      TerminerPointagesJob.perform_now
    end
  end

  # Décision : un pointage privé de son agent n'est pas clôturé de force, il reste
  # ouvert jusqu'à correction manuelle (l'erreur est journalisée par le job).
  test 'un pointage sans agent reste ouvert' do
    @pointage.agents.destroy_all

    TerminerPointagesJob.perform_now

    assert @pointage.reload.nouveau?
    assert_nil @pointage.fin
  end

  test 'un pointage en échec n’interrompt pas le traitement des suivants' do
    # On isole le scénario sur deux pointages maîtrisés et ordonnés.
    @pointage.destroy!
    mère = interventions(:intervention_repete)

    # Créé EN PREMIER → id le plus bas → traité en premier par find_each.
    pointage_ko = mère.create_next_intervention(mère, users(:bond))
    pointage_ko.update_column(:début, 1.day.from_now)

    # Créé ENSUITE → traité APRÈS le crash : doit quand même être terminé.
    pointage_ok = mère.create_next_intervention(mère, @agent)

    # Un seul mail / MailLog : pour le pointage suivant uniquement, le crash du
    # premier n'a ni interrompu le job ni déclenché de notification.
    assert_difference -> { ActionMailer::Base.deliveries.size } => 1,
                      -> { MailLog.count } => 1 do
      TerminerPointagesJob.perform_now
    end

    # Le pointage fautif est resté intact (rien de persisté)…
    pointage_ko.reload
    assert pointage_ko.nouveau?
    assert_nil pointage_ko.fin

    # …et son échec n'a pas empêché le pointage suivant d'être terminé et notifié.
    assert pointage_ok.reload.terminé?
    assert_equal [@agent.email], ActionMailer::Base.deliveries.last.to
  end
end
