class CreateAbsences < ActiveRecord::Migration[7.1]
  def change
    create_table :absences do |t|
      t.date :du
      t.date :au
      t.string :motif
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
