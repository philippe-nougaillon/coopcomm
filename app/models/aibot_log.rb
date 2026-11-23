# frozen_string_literal: true

class AibotLog < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  belongs_to :user, -> { with_discarded }
  belongs_to :request_message, class_name: 'Message'
  belongs_to :response_message, class_name: 'Message'

  scope :ordered, -> { order('aibot_logs.created_at DESC') }

  def duree
    response_message.created_at - request_message.created_at
  end

  private

  def slug_candidates
    [SecureRandom.uuid]
  end
end
