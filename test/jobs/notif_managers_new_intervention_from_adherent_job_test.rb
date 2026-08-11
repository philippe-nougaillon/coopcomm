# frozen_string_literal: true

require 'test_helper'

class NotifManagersNewInterventionFromAdherentJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @intervention = interventions(:tonte_locaux)
    @adherent     = users(:weil) # rattaché au service « informatique »
    # Managers/admins du service de l'intervention : hidalgo + administrateur_paris.
    @managers = @intervention.service.managers_and_admin.to_a
  end

  test 'envoie un mail à chaque manager du service de l\'intervention (un MailLog par mail)' do
    assert_equal 2, @managers.size, 'pré-condition : 2 managers attendus sur le service technique'

    assert_emails @managers.size do
      assert_difference -> { MailLog.count }, @managers.size do
        NotifManagersNewInterventionFromAdherentJob.perform_now(@intervention, @adherent)
      end
    end

    destinataires = ActionMailer::Base.deliveries.last(@managers.size).flat_map(&:to)
    assert_equal @managers.map(&:email).sort, destinataires.sort

    log = MailLog.order(:created_at).last
    assert_equal 'Nouvelle intervention adhérent', log.subject
    assert_equal @adherent.id, log.user_id
    assert_equal 'mail', log.channel
  end

  test "les managers des autres services de l'adhérent ne sont pas prévenus" do
    @intervention.update_columns(service_id: services(:secretariat).id)
    @intervention.reload

    destinataires_attendus = [users(:manager_paris).email]
    assert_equal destinataires_attendus, services(:secretariat).managers_and_admin.map(&:email)

    assert_emails 1 do
      NotifManagersNewInterventionFromAdherentJob.perform_now(@intervention, @adherent)
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
        NotifManagersNewInterventionFromAdherentJob.perform_now(@intervention, @adherent)
      end
    end
  end
end
