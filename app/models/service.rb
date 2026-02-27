class Service < ApplicationRecord
  has_many :users

  normalizes :nom, with: -> nom { nom.humanize.strip }

end
