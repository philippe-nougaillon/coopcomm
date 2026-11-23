# frozen_string_literal: true

class AddDateSignatureAndResumeToConventions < ActiveRecord::Migration[8.1]
  def change
    add_column :conventions, :date_signature, :date
    add_column :conventions, :résumé, :text
  end
end
