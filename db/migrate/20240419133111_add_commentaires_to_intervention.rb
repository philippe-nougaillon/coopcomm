# frozen_string_literal: true

class AddCommentairesToIntervention < ActiveRecord::Migration[7.1]
  def change
    add_column :interventions, :commentaires, :text
  end
end
