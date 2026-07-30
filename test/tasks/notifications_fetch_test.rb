# frozen_string_literal: true

require 'test_helper'
require 'rake'

# Les deux tâches de rafraîchissement des statuts d'envoi délèguent chacune à son
# service ; on vérifie le câblage, pas le service (testé à part).
class NotificationsFetchTest < ActiveSupport::TestCase
  setup do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake::Task.define_task(:environment)
    load Rails.root.join('lib/tasks/notifications.rake')
  end

  teardown do
    Rake.application = nil
  end

  test 'la tâche des statuts mail appelle son service' do
    appelé = false

    FetchMailgunInfos.stub :call, -> { appelé = true } do
      @rake['notifications:fetch_mailgun'].invoke
    end

    assert appelé
  end

  test 'la tâche des statuts SMS appelle son service' do
    appelé = false

    FetchTwilioInfos.stub :call, -> { appelé = true } do
      @rake['notifications:fetch_twilio'].invoke
    end

    assert appelé
  end
end
