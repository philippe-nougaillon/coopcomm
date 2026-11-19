# frozen_string_literal: true

class RemoveHeuresConsommeesFromConventions < ActiveRecord::Migration[8.1]
  def change
    remove_column :conventions, :heures_consommees, :decimal, precision: 8, scale: 2, default: '0.0'
  end
end
