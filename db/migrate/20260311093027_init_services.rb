# frozen_string_literal: true

class InitServices < ActiveRecord::Migration[8.0]
  def change
    new_service = Service.create!(nom: 'Technique')
    User.all.each do |user|
      user.services << new_service
    end
  end
end
