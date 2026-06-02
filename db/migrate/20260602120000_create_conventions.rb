class CreateConventions < ActiveRecord::Migration[8.0]
  def change
    create_table :conventions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :service, null: false, foreign_key: true
      t.date :date_début
      t.date :date_fin_prévue

      t.timestamps
    end

    # Un adhérent ne peut avoir qu'une seule convention par service
    add_index :conventions, [:user_id, :service_id], unique: true
  end
end
