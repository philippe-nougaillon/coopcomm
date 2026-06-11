# frozen_string_literal: true

class AddServiceFieldToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :service, :integer
  end
end
