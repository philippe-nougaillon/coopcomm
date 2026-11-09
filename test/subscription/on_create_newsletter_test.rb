# frozen_string_literal: true

require 'test_helper'

class OnCreateNewsletterTest < ActionDispatch::IntegrationTest
  test "le mail de confirmation d'inscription à la newsletter est mis en file lorsqu'un utilisateur s'inscrit" do
    assert_enqueued_with(job: NotifConfirmEmailNewsletterJob) do
      get new_newsletter_path, params: { email: 'manual@aikku.eu' }
    end
  end
end
