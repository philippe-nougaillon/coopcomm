# frozen_string_literal: true

class Warehouse < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  audited

  belongs_to :organisation
  has_many :users, dependent: :nullify

  validates :address, :latitude, :longitude, presence: true

  scope :ordered, -> { trié_par(:name) }

  triable_par 'warehouses.name' => :texte,
              'warehouses.users' => "(SELECT STRING_AGG(#{TriTextuel.expression('users.nom')}, ',' " \
                                    "ORDER BY #{TriTextuel.expression('users.nom')}) FROM users " \
                                    'WHERE users.warehouse_id = warehouses.id AND users.discarded_at IS NULL)',
              'warehouses.address' => :texte

  private

  def slug_candidates
    [SecureRandom.uuid]
  end
end
