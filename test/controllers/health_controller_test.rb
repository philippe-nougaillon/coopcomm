# frozen_string_literal: true

require 'test_helper'

class HealthControllerTest < ActionDispatch::IntegrationTest
  test 'le serveur doit se lancer correctement' do
    # Changement de l'eager_load à true pour compiler entièrement l'application (Initialisé à false dans environments/test.rb)
    assert_nothing_raised do
      Rails.application.eager_load!
    end

    get rails_health_check_url
    assert_response :success
  end
end
