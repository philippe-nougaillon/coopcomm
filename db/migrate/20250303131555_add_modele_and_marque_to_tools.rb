# frozen_string_literal: true

class AddModeleAndMarqueToTools < ActiveRecord::Migration[7.1]
  def change
    add_column :tools, :modèle, :string
    add_column :tools, :marque, :string
  end
end
