# frozen_string_literal: true

require 'test_helper'

class NotifManagersInterventionDoneByAgentJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @intervention = interventions(:tonte_locaux)
    @agent        = users(:martin_technique_paris)
    # Managers/admins du service « technique » de l'agent : hidalgo + administrateur_paris.
    @managers = @agent.services.flat_map(&:managers_and_admin).uniq
  end

  test 'envoie un mail à chaque manager du service de l\'agent (un MailLog par mail)' do
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

  test 'un agent sans service ne déclenche aucune notification' do
    # Un compte sans service ne peut plus être créé (User#must_have_at_least_one_service)
    # mais peut subsister en base pour les comptes antérieurs à la validation.
    sans_service = User.new(nom: 'Sans', prénom: 'Service', email: 'sans.service.agent@example.test',
                            rôle: 'agent', password: 'qtDug$d843sqACz?V')
    sans_service.save(validate: false)
    assert_empty sans_service.services

    assert_no_emails do
      assert_no_difference -> { MailLog.count } do
        NotifManagersInterventionDoneByAgentJob.perform_now(@intervention, sans_service)
      end
    end
  end
end
