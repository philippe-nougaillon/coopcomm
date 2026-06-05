class ReplaceStatutWithWorkflowStateOnCotations < ActiveRecord::Migration[8.0]
  STATUT_MAP = { 0 => "créé", 1 => "envoyé", 2 => "validé", 3 => "refusé", 4 => "archivé" }.freeze

  def up
    add_column :cotations, :workflow_state, :string
    STATUT_MAP.each do |value, state|
      execute("UPDATE cotations SET workflow_state = '#{state}' WHERE statut = #{value}")
    end
    change_column_default :cotations, :workflow_state, "créé"
    remove_column :cotations, :statut
  end

  def down
    add_column :cotations, :statut, :integer, default: 0
    STATUT_MAP.each do |value, state|
      execute("UPDATE cotations SET statut = #{value} WHERE workflow_state = '#{state}'")
    end
    remove_column :cotations, :workflow_state
  end
end
