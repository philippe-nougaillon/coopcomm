# frozen_string_literal: true

require 'test_helper'

# Le parcours complet (contrôleur -> event) reste non testable : les deux publieurs de
# `organisation.created`.
class OnOrganisationCreatedTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test 'enqueue le mail de bienvenue et la notification de nouvelle organisation' do
    user = users(:weil) # rattaché à informatique -> organisation mairie_paris

    EmailSubscription.new.on_organisation_created({ payload: { user_id: user.id } })

    assert_enqueued_with(job: WelcomeNotificationJob, args: [user])
    assert_enqueued_with(job: NewOrganisationNotificationJob, args: [user.organisation])
  end

  test 'user sans service : NewOrganisationNotificationJob est enqueue avec nil (comportement actuel documenté)' do
    # L'organisation d'un User est dérivée de ses services : sans service, elle est nil.
    user = User.create!(nom: 'Sans-Service', email: 'sans-service@aikku.eu',
                        rôle: 'manager', password: 'qtDug$d843sqACz?V')

    EmailSubscription.new.on_organisation_created({ payload: { user_id: user.id } })

    assert_enqueued_with(job: WelcomeNotificationJob, args: [user])
    assert_enqueued_with(job: NewOrganisationNotificationJob, args: [nil])
  end
end
