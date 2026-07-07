# frozen_string_literal: true

require 'test_helper'

class NotifWhatsappAdherentInterventionPointageJobTest < ActiveJob::TestCase
  # Double Twilio : aucun appel réseau réel n'est émis (interdit en prod).
  class FakeTwilioMessages
    attr_reader :captured

    def create(**kwargs)
      @captured = kwargs
      Struct.new(:sid).new('SM_TEST_SID')
    end
  end

  class FakeTwilioClient
    def messages
      @messages ||= FakeTwilioMessages.new
    end
  end

  setup do
    @intervention = interventions(:tonte_locaux)
    @adherent     = users(:weil)
    @fake_client  = FakeTwilioClient.new
  end

  test 'envoie un WhatsApp d\'arrivée (sans date de fin) et trace un MailLog canal whatsapp' do
    @intervention.update_column(:fin, nil)

    assert_difference -> { MailLog.count }, 1 do
      Twilio::REST::Client.stub(:new, @fake_client) do
        NotifWhatsappAdherentInterventionPointageJob.perform_now(@intervention)
      end
    end

    envoi = @fake_client.messages.captured
    assert_equal "whatsapp:#{@adherent.téléphone}", envoi[:to]
    assert_match(/ARRIVÉE/, envoi[:body])
    assert_match(/#{@intervention.description}/, envoi[:body])

    log = MailLog.order(:created_at).last
    assert_equal 'whatsapp', log.channel
    assert_equal @adherent.téléphone, log.to
    assert_equal 'Intervention pointage', log.subject
    assert_equal 'SM_TEST_SID', log.message_id
    assert_equal @intervention.organisation.id, log.organisation_id
  end

  test 'envoie un WhatsApp de départ quand l\'intervention a une date de fin' do
    @intervention.update_column(:fin, Time.current)

    Twilio::REST::Client.stub(:new, @fake_client) do
      NotifWhatsappAdherentInterventionPointageJob.perform_now(@intervention)
    end

    assert_match(/DÉPART/, @fake_client.messages.captured[:body])
  end
end
