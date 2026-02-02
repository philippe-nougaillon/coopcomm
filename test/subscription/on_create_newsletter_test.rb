require "test_helper"

class OnCreateNewsletterTest < ActionDispatch::IntegrationTest
  test "NotifConfirmEmailNewsletterJob mis en file d'attente quand un utilisateur s'inscrit" do

    assert_enqueued_with(job: NotifConfirmEmailNewsletterJob) do
      get new_newsletter_path, params: { email: "manual@aikku.eu" }
    end

  end
end
