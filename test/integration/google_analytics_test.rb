# frozen_string_literal: true

require 'test_helper'

# L'identifiant de mesure diffère d'une instance à l'autre : il ne doit jamais
# revenir en dur dans une vue.
class GoogleAnalyticsTest < ActionDispatch::IntegrationTest
  setup do
    @identifiant_initial = ENV.fetch('GOOGLE_ANALYTICS_ID', nil)
    sign_in users(:administrateur_paris)
  end

  teardown do
    ENV['GOOGLE_ANALYTICS_ID'] = @identifiant_initial
  end

  test 'la balise Google Analytics porte l’identifiant de l’instance' do
    ENV['GOOGLE_ANALYTICS_ID'] = 'G-INSTANCE01'
    get home_url

    assert_response :success
    assert_select 'script[src=?]', 'https://www.googletagmanager.com/gtag/js?id=G-INSTANCE01'
    assert_includes response.body, %(gtag('config', 'G-INSTANCE01'))
  end

  test 'aucune balise Google Analytics n’est posée sans identifiant' do
    ENV['GOOGLE_ANALYTICS_ID'] = nil
    get home_url

    assert_response :success
    assert_no_match(/googletagmanager|gtag/, response.body)
  end
end
