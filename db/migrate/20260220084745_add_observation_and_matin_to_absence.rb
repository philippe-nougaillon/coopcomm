class AddObservationAndMatinToAbsence < ActiveRecord::Migration[8.0]
  def up
    rename_column :absences, :motif, :observation
    add_column :absences, :motif, :integer, default: 0
    add_column :absences, :matin, :boolean, default: false
    add_column :absences, :après_midi, :boolean, default: false
  end

  def down
    remove_column :absences, :motif    
    rename_column :absences, :observation, :motif
    remove_column :absences, :matin
    remove_column :absences, :après_midi
  end
end
