class Service < ApplicationRecord
  belongs_to :organisation

  has_many :user_services, dependent: :destroy
  has_many :users, through: :user_services

  validates_uniqueness_of :nom

  normalizes :nom, with: -> nom { nom.humanize.strip }

end
