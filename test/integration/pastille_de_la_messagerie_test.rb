# frozen_string_literal: true

require 'test_helper'

class PastilleDeLaMessagerieTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:bond)
  end

  test "En tant qu'agent, je veux voir dans la navbar le nombre de mes messages non lus, jusqu'à ce que je les lise" do
    non_lus = [messages(:one), Message.create!(message: 'Bonjour', from_id: users(:martin_technique_paris).id, to_id: users(:bond).id)]

    get home_url
    assert_dom 'a[title=?]', 'Messagerie', text: '2', count: 2

    non_lus.each { |message| post messagerie_mark_as_read_url, params: { id: message.id } }

    get home_url
    assert_dom 'a[title=?]', 'Messagerie', text: '', count: 2
  end

  test "En tant qu'agent, je veux une pastille qui reste lisible quand plus de 99 messages m'attendent" do
    Message.insert_all(Array.new(100) { { message: 'Bonjour', from_id: users(:hidalgo).id, to_id: users(:bond).id } })

    get home_url

    assert_dom 'a[title=?]', 'Messagerie', text: '99+', count: 2
  end
end
