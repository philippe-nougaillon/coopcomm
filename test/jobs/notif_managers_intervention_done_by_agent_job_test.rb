# frozen_string_literal: true

require 'test_helper'

class NotifManagersInterventionDoneByAgentJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @intervention = interventions(:tonte_locaux)
    @agent        = users(:martin_technique_paris)
    # Managers/admins du service « technique » de l'intervention : hidalgo + administrateur_paris.
    @managers = @intervention.service.managers_and_admin.to_a
  end

  test 'envoie un mail à chaque manager du service de l\'intervention (un MailLog par mail)' do
    assert_equal 2, @managers.size, 'pré-condition : 2 managers attendus sur le service technique'

    assert_emails @managers.size do
      assert_difference -> { MailLog.count }, @managers.size do
        NotifManagersInterventionDoneByAgentJob.perform_now(@intervention, @agent)
      end
    end

    destinataires = ActionMailer::Base.deliveries.last(@managers.size).flat_map(&:to)
    assert_equal @managers.map(&:email).sort, destinataires.sort

    log = MailLog.order(:created_at).last
    assert_equal "Bon d'intervention agent", log.subject
    assert_equal @agent.id, log.user_id
    assert_equal 'mail', log.channel
  end

  test "les managers du service de l'agent ne sont pas prévenus si l'intervention relève d'un autre service" do
    @intervention.update_columns(service_id: services(:secretariat).id)
    @intervention.reload

    destinataires_attendus = [users(:manager_paris).email]
    assert_equal destinataires_attendus, services(:secretariat).managers_and_admin.map(&:email)
    assert_not_includes @agent.services, services(:secretariat)

    assert_emails 1 do
      NotifManagersInterventionDoneByAgentJob.perform_now(@intervention, @agent)
    end

    destinataires = ActionMailer::Base.deliveries.last.to
    assert_equal destinataires_attendus, destinataires
    assert_not_includes destinataires, users(:hidalgo).email
    assert_not_includes destinataires, users(:administrateur_paris).email
  end

  test "un service sans manager ne déclenche aucune notification" do
    @intervention.update_columns(service_id: services(:menage).id)
    @intervention.reload
    assert_empty @intervention.service.managers_and_admin

    assert_no_emails do
      assert_no_difference -> { MailLog.count } do
        NotifManagersInterventionDoneByAgentJob.perform_now(@intervention, @agent)
      end
    end
  end
end
