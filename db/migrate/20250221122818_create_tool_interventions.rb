class CreateToolInterventions < ActiveRecord::Migration[7.1]
  def change
    create_table :tool_interventions do |t|
      t.references :tool, null: false, foreign_key: true
      t.references :intervention, null: false, foreign_key: true

      t.timestamps
    end
  end
end
