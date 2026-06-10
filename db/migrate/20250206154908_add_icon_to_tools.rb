# frozen_string_literal: true

class AddIconToTools < ActiveRecord::Migration[7.1]
  def change
    add_column :tools, :icon_name, :string
  end
end
