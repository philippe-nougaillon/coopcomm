class Absence < ApplicationRecord
  audited associated_with: :user

  belongs_to :user

  scope :ordered, -> {order(du: :desc)}

  def en_cours?
    return (self.du..self.au).include?(Date.today)
  end
end
