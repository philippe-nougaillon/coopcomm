# frozen_string_literal: true

require 'test_helper'
require 'rake'

class CotationsRelancerASignerTaskTest < ActiveJob::TestCase
  setup do
    # Charge uniquement la tâche testée (pas de `load_tasks` complet) : sous `rails
    # test:all`.
    unless Rake::Task.task_defined?('cotations:relancer_adherents')
      Rake::Task.define_task(:environment) # stub du prérequis, l'app est déjà bootée
      load Rails.root.join('lib/tasks/cotations.rake')
    end
    @task = Rake::Task['cotations:relancer_adherents']
    @task.reenable

    @adherent = users(:weil) # a cotation_secretariat en état « envoyé »
    @cotation = cotations(:cotation_secretariat)
  end

  test 'enfile le job pour un adhérent ayant une cotation à signer, sans mail récent' do
    assert_enqueued_with(job: NotifAdherentCotationsASignerRelanceJob, args: [@adherent]) do
      @task.invoke
    end
  end

  test 'un seul job est enfilé quand un seul adhérent a des cotations à signer' do
    assert_enqueued_jobs 1, only: NotifAdherentCotationsASignerRelanceJob do
      @task.invoke
    end
  end

  test 'ne relance pas si un mail cotation a été reçu il y a moins de 48h' do
    creer_mail_log(created_at: 1.hour.ago)

    assert_no_enqueued_jobs only: NotifAdherentCotationsASignerRelanceJob do
      @task.invoke
    end
  end

  test 'relance si le dernier mail cotation date de plus de 48h' do
    creer_mail_log(created_at: 49.hours.ago)

    assert_enqueued_with(job: NotifAdherentCotationsASignerRelanceJob, args: [@adherent]) do
      @task.invoke
    end
  end

  test 'un mail sans cotation_id n\'entre pas dans la garde des 48h' do
    # Un mail récent mais NON lié à une cotation (ex. commande/facture) ne doit
    # pas empêcher la relance des cotations à signer.
    MailLog.create!(to: @adherent.email, cotation_id: nil,
                    organisation_id: @cotation.organisation.id,
                    created_at: 1.hour.ago, channel: 0,
                    subject: 'Autre mail', message_id: 'x')

    assert_enqueued_with(job: NotifAdherentCotationsASignerRelanceJob, args: [@adherent]) do
      @task.invoke
    end
  end

  test 'ne relance aucun adhérent quand aucune cotation n\'est à signer' do
    @cotation.update_column(:workflow_state, Cotation::SIGNE)

    assert_no_enqueued_jobs only: NotifAdherentCotationsASignerRelanceJob do
      @task.invoke
    end
  end

  private

  def creer_mail_log(created_at:)
    MailLog.create!(to: @adherent.email, cotation_id: @cotation.id,
                    organisation_id: @cotation.organisation.id,
                    created_at: created_at, channel: 0,
                    subject: 'Rappel', message_id: 'x')
  end
end
