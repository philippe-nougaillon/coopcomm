# frozen_string_literal: true

class AddCommentairesToMouvement < ActiveRecord::Migration[8.0]
  def change
    add_column :mouvements, :commentaires, :string
  end
end
