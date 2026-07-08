# frozen_string_literal: true

require 'test_helper'

# Le parcours complet (contrôleur -> event) reste non testable : les deux
# publieurs de `organisation.created` (Users::RegistrationsController#create et
# User.from_omniauth) sont du code mort — modules Devise `:registerable` et
# `:omniauthable` commentés, donc aucune route — et tous deux planteraient de
# toute façon sur `user.organisation =` (writer inexistant, cf. bugs signalés
# lors de la session /tests du 2026-07-08). On teste donc le HANDLER en direct,
# avec le même event que celui qui serait publié.
class OnOrganisationCreatedTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test 'enqueue le mail de bienvenue et la notification de nouvelle organisation' do
    user = users(:weil) # rattaché à informatique -> organisation mairie_paris

    EmailSubscription.new.on_organisation_created({ payload: { user_id: user.id } })

    assert_enqueued_with(job: WelcomeNotificationJob, args: [user])
    assert_enqueued_with(job: NewOrganisationNotificationJob, args: [user.organisation])
  end

  test 'user sans service : NewOrganisationNotificationJob est enqueue avec nil (comportement actuel documenté)' do
    # L'organisation d'un User est dérivée de ses services : sans service, elle
    # est nil. Le handler enqueue quand même le job, qui plantera à l'exécution
    # (NotificationMailer.new_organisation(nil)). C'est précisément l'état dans
    # lequel un utilisateur fraîchement inscrit se trouverait si les publieurs
    # étaient réactivés — à corriger à ce moment-là.
    user = User.create!(nom: 'Sans-Service', email: 'sans-service@aikku.eu',
                        rôle: 'manager', password: 'qtDug$d843sqACz?V')

    EmailSubscription.new.on_organisation_created({ payload: { user_id: user.id } })

    assert_enqueued_with(job: WelcomeNotificationJob, args: [user])
    assert_enqueued_with(job: NewOrganisationNotificationJob, args: [nil])
  end
end
