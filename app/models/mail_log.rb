# frozen_string_literal: true

class MailLog < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  belongs_to :organisation
  belongs_to :cotation, optional: true
  scope :ordered, -> { order('mail_logs.created_at DESC') }

  enum :channel, {
    mail: 0,
    whatsapp: 1
  }

  private

  def slug_candidates
    [SecureRandom.uuid]
  end
end
