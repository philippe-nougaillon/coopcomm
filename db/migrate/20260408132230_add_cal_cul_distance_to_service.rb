class AddCalCulDistanceToService < ActiveRecord::Migration[8.0]
  def change
    add_column :services, :calculate_distance, :boolean, default: false
  end
end
