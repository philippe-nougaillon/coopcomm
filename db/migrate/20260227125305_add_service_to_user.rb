# frozen_string_literal: true

class AddServiceToUser < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :service, foreign_key: true
  end
end
