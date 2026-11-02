# frozen_string_literal: true

require 'test_helper'

class NotifManagersNewAbsenceJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @absence = absences(:one) # user: bond, rattaché au service technique
    # Managers/admins du service de l'absent : hidalgo, administrateur_paris.
    @managers = @absence.user.services.flat_map(&:managers_and_admin).uniq
  end

  test "chaque manager du service de l'absent reçoit un mail, avec un mail log par mail, lorsqu'une absence est créée" do
    assert_equal 2, @managers.size, 'pré-condition : 2 managers attendus sur le service technique'

    assert_emails @managers.size do
      assert_difference -> { MailLog.count }, @managers.size do
        NotifManagersNewAbsenceJob.perform_now(@absence)
      end
    end

    destinataires = ActionMailer::Base.deliveries.last(@managers.size).flat_map(&:to)
    assert_equal @managers.map(&:email).sort, destinataires.sort

    log = MailLog.order(:created_at).last
    assert_equal 'Nouvelle absence', log.subject
    assert_equal 'mail', log.channel
    # absence sans audit `create` → aucun auteur connu → user_id retombe sur 0.
    assert_equal 0, log.user_id
  end

  test "le manager qui a lui-même créé l'absence ne reçoit pas de mail mais est l'auteur des mail logs" do
    auteur = users(:hidalgo) # manager du service_paris
    absence = nil
    # On rejoue le chemin réel : l'absence est créée PAR un manager → audit
    # `create` attribué à ce manager, qui ne doit donc pas être notifié.
    Audited.audit_class.as_user(auteur) do
      absence = Absence.create!(du: Date.current, au: Date.current, motif: :congés_payés, user: users(:bond))
    end

    attendus = @managers.reject { |m| m == auteur }

    assert_emails attendus.size do
      NotifManagersNewAbsenceJob.perform_now(absence)
    end

    destinataires = ActionMailer::Base.deliveries.last(attendus.size).flat_map(&:to)
    refute_includes destinataires, auteur.email
    assert_equal attendus.map(&:email).sort, destinataires.sort

    # L'auteur est tracé comme émetteur sur les MailLog.
    assert_equal auteur.id, MailLog.order(:created_at).last.user_id
  end
end
