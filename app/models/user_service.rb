class UserService < ApplicationRecord
  audited associated_with: :user

  belongs_to :user
  belongs_to :service
end
