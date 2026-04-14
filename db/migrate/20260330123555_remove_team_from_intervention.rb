class RemoveTeamFromIntervention < ActiveRecord::Migration[8.0]
  def change
    remove_column :interventions, :team_id
  end
end
