# frozen_string_literal: true

require 'test_helper'

class MailLogTest < ActiveSupport::TestCase
  test 'scope ordered : plusieurs envois → le plus récent en tête' do
    ancien = MailLog.create!(organisation: organisations(:mairie_paris), user_id: users(:hidalgo).id,
                             to: 'a@example.test', subject: 'Ancien', created_at: 2.days.ago)
    récent = MailLog.create!(organisation: organisations(:mairie_paris), user_id: users(:hidalgo).id,
                             to: 'b@example.test', subject: 'Récent', created_at: 1.hour.ago)

    ordonnés = MailLog.ordered.to_a

    assert_operator ordonnés.index(récent), :<, ordonnés.index(ancien)
  end
end
