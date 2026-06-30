# frozen_string_literal: true

require 'test_helper'
require 'rake'

class InterventionsTerminerPointagesTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    @task = Rake::Task['interventions:terminer_pointages']
    @task.reenable

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
    @task.invoke

    @pointage.reload
    assert @pointage.terminé?
    assert @pointage.fin.present?
    assert_in_delta Time.current, @pointage.fin, 1.minute
  end

  test 'envoie un mail à l’unique agent et crée un MailLog' do
    assert_difference -> { ActionMailer::Base.deliveries.size } => 1,
                      -> { MailLog.count } => 1 do
      @task.invoke
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

  test 'ignore les interventions « nouveau » sans template_slug' do
    cible = interventions(:nouvelle_intervention)
    assert cible.nouveau?
    assert cible.template_slug.blank?

    @task.invoke

    assert cible.reload.nouveau?
  end

  test 'ignore les interventions déjà terminées' do
    déjà_terminée = interventions(:intervention_terminée)

    assert_no_changes -> { déjà_terminée.reload.workflow_state } do
      @task.invoke
    end
  end

  test 'un pointage en échec n’interrompt pas le traitement des suivants' do
    # On isole le scénario sur deux pointages maîtrisés et ordonnés.
    @pointage.destroy!
    mère = interventions(:intervention_repete)

    # Créé EN PREMIER → id le plus bas → traité en premier par find_each.
    # terminer! le fera planter : une date de début dans le futur, posée en base
    # sans validation (update_column), rend le save! invalide dès que la task
    # fixe fin = maintenant (début > fin).
    pointage_ko = mère.create_next_intervention(mère, users(:bond))
    pointage_ko.update_column(:début, 1.day.from_now)

    # Créé ENSUITE → traité APRÈS le crash : doit quand même être terminé.
    pointage_ok = mère.create_next_intervention(mère, @agent)

    # Un seul mail / MailLog : pour le pointage suivant uniquement, le crash du
    # premier n'a ni interrompu la task ni déclenché de notification.
    assert_difference -> { ActionMailer::Base.deliveries.size } => 1,
                      -> { MailLog.count } => 1 do
      @task.invoke
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
