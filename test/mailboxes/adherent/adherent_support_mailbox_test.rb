# frozen_string_literal: true

require 'test_helper'

class AdherentSupportMailboxTest < ActionMailbox::TestCase
  include ActiveJob::TestHelper

  def recevoir(from:, subject: 'Gestion de paperasse', body: "Bonjour, j'ai besoin d'aide")
    receive_inbound_email_from_mail(
      to: 'support@mg.coopcom.fr',
      from: from,
      subject: subject,
      body: body,
      charset: 'UTF-8'
    )
  end

  test 'Créer une intervention quand un adhérent envoie un mail au support' do
    user = users(:weil)
    subject = 'Gestion de paperasse'
    body = "Bonjour, j'ai besoin d'aide du côté administratif"

    recevoir(from: user.email, subject: subject, body: body)

    intervention = Intervention.find_by(description: "[MAIL] #{subject}")

    assert_equal user.id, intervention.adherent_id
    assert_equal "De #{user.nom_prenom_role} : #{body}", intervention.commentaires
  end

  test "L'intervention est rattachée à un service de l'adhérent" do
    user = users(:berthout)

    recevoir(from: user.email, subject: 'Un seul service')

    intervention = Intervention.find_by(description: '[MAIL] Un seul service')

    assert_includes user.service_ids, intervention.service_id
  end

  test 'Adhérent mono-service : les managers et admins du service sont prévenus' do
    user = users(:berthout)

    assert_equal 1, user.services.count

    service = user.services.first
    attendus = service.managers_and_admin.pluck(:id).sort

    assert_predicate service.managers_and_admin.where(rôle: :manager), :any?,
                     'la fixture doit contenir un manager, sinon le test ne distingue rien'

    assert_enqueued_with(job: NotifManagersNewInterventionFromAdherentJob,
                         args: ->(args) { args[2].map(&:id).sort == attendus }) do
      recevoir(from: user.email, subject: 'Mono service')
    end
  end

  test "Adhérent multi-services : seuls les administrateurs de l'organisation sont prévenus" do
    user = users(:weil)

    assert_operator user.services.count, :>, 1

    attendus = user.organisation.users.administrateur.pluck(:id).sort
    managers_ecartes = user.services.flat_map { |s| s.managers_and_admin.where(rôle: :manager).ids }

    assert_predicate managers_ecartes, :any?,
                     'la fixture doit contenir un manager, sinon le test ne distingue rien'

    assert_enqueued_with(job: NotifManagersNewInterventionFromAdherentJob,
                         args: lambda { |args|
                           args[2].map(&:id).sort == attendus &&
                             args[2].all?(&:administrateur?)
                         }) do
      recevoir(from: user.email, subject: 'Multi services')
    end
  end

  test "Un adhérent sans service ne crée ni intervention ni notification" do
    user = users(:berthout)
    user.services.clear

    assert_no_difference 'Intervention.count' do
      assert_no_enqueued_jobs only: NotifManagersNewInterventionFromAdherentJob do
        recevoir(from: user.email, subject: 'Sans service')
      end
    end
  end

  test 'Un mail sans sujet ni corps crée quand même une intervention' do
    user = users(:berthout)

    assert_difference 'Intervention.count', 1 do
      recevoir(from: user.email, subject: nil, body: nil)
    end
  end
end
