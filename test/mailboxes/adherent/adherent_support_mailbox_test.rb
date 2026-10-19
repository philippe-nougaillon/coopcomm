# frozen_string_literal: true

require 'test_helper'
require_relative '../../support/adresse_support'

class AdherentSupportMailboxTest < ActionMailbox::TestCase
  include ActiveJob::TestHelper
  include AdresseSupport

  def recevoir(from:, subject: 'Gestion de paperasse', body: "Bonjour, j'ai besoin d'aide")
    receive_inbound_email_from_mail(
      to: ADRESSE_SUPPORT,
      from: from,
      subject: subject,
      body: body,
      charset: 'UTF-8'
    )
  end

  test "une intervention est créée quand un adhérent envoie un mail au support" do
    user = users(:weil)
    subject = 'Gestion de paperasse'
    body = "Bonjour, j'ai besoin d'aide du côté administratif"

    recevoir(from: user.email, subject: subject, body: body)

    intervention = Intervention.find_by(description: "[MAIL] #{subject}")

    assert_equal user.id, intervention.adherent_id
    assert_equal "De #{user.nom_prenom_role} : #{body}", intervention.commentaires
  end

  # ==================== TESTS CRITIQUES ====================
  # Le service rattaché décide de l'organisation de l'intervention et de qui est prévenu.
  test "l'intervention créée par mail est rattachée à un service de l'adhérent (critique)" do
    user = users(:berthout)

    recevoir(from: user.email, subject: 'Un seul service')

    intervention = Intervention.find_by(description: '[MAIL] Un seul service')

    assert_includes user.service_ids, intervention.service_id
  end

  test "les managers et administrateurs du service sont prévenus quand l'adhérent n'a qu'un service (critique)" do
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

  test "seuls les administrateurs de l'organisation sont prévenus quand l'adhérent a plusieurs services (critique)" do
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

  test "un mail d'un adhérent sans service ne crée ni intervention ni notification (critique)" do
    user = users(:berthout)
    user.services.clear

    assert_no_difference 'Intervention.count' do
      assert_no_enqueued_jobs only: NotifManagersNewInterventionFromAdherentJob do
        recevoir(from: user.email, subject: 'Sans service')
      end
    end
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'un mail sans sujet ni corps crée quand même une intervention' do
    user = users(:berthout)

    assert_difference 'Intervention.count', 1 do
      recevoir(from: user.email, subject: nil, body: nil)
    end
  end

  test "un mail adressé à une autre adresse que celle du support n'est pas routé" do
    user = users(:berthout)

    assert_no_difference 'Intervention.count' do
      assert_raises(ActionMailbox::Router::RoutingError) do
        receive_inbound_email_from_mail(to: 'support-autre-instance@mg.exemple.fr', from: user.email,
                                        subject: 'Autre instance', body: 'Bonjour', charset: 'UTF-8')
      end
    end

    assert_predicate ActionMailbox::InboundEmail.last, :bounced?
  end
end
