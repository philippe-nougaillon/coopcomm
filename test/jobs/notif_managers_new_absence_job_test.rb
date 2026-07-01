# frozen_string_literal: true

require 'test_helper'

class NotifManagersNewAbsenceJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @absence = absences(:one) # user: bond, rattaché au service_paris
    # Managers/admins du service de l'absent : hidalgo, manager_paris, administrateur_paris.
    @managers = @absence.user.services.flat_map(&:managers_and_admin).uniq
  end

  test 'notifie tous les managers du service de l\'absent (un MailLog par mail)' do
    assert_equal 3, @managers.size, 'pré-condition : 3 managers attendus sur le service_paris'

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

  test 'exclut le manager qui a lui-même créé l\'absence' do
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
