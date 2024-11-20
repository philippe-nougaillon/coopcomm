class Absence < ApplicationRecord
  belongs_to :user

  scope :ordered, -> {order(du: :desc)}
end
