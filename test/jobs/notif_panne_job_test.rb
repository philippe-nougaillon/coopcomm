# frozen_string_literal: true

require 'test_helper'

class NotifPanneJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @tool = tools(:tondeuse) # rattaché à mairie_paris
    @reserviste = users(:bond)
    @declarant  = users(:martin_technique_paris)

    # Une réservation future de la tondeuse par un agent.
    @reservation = Mouvement.create!(tool: @tool, user: @reserviste, état: :réservé,
                                     date: 2.days.from_now)
    # La panne déclarée par un autre agent (after_create enqueue d'éventuels
    # NotifPanneJob.perform_later : sans effet synchrone, on ne s'appuie pas dessus).
    @panne = Mouvement.create!(tool: @tool, user: @declarant, état: :panne,
                               date: Time.current)

    ActionMailer::Base.deliveries.clear
  end

  test "le réserviste reçoit un mail et un mail log est créé lorsque l'outil est déclaré en panne" do
    assert_emails 1 do
      assert_difference -> { MailLog.count }, 1 do
        NotifPanneJob.perform_now(@panne.id, @reservation.id)
      end
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal [@reserviste.email], mail.to

    titre_propre = "[COOPCOMM] L'outil #{@tool.name} a été déclaré en panne"

    log = MailLog.order(:created_at).last
    assert_equal @tool.organisation_id, log.organisation_id
    assert_equal @declarant.id, log.user_id
    assert_equal 'mail', log.channel
    # Le MailLog porte le titre propre (variable locale `title` du job).
    assert_equal titre_propre, log.subject

    # BUG (non corrigé, voir note bas de fichier) : le job passe `title:` en mot-clé alors
    # que le mailer attend un positionnel → le SUJET DE L'EMAIL réellement envoyé est…
    assert_equal "{title: #{titre_propre.inspect}}", mail.subject
    refute_equal log.subject, mail.subject

    # Le MailLog trace l'EMAIL du réserviste destinataire (et non son ID).
    assert_equal @reserviste.email, log.to
  end
end

# =============================================================================
# ANOMALIES DÉTECTÉES — NON CORRIGÉES (signalées, hors périmètre)
# ----------------------------------------------------------------------------- 1.
