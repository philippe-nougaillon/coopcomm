# frozen_string_literal: true

class AddOrganisationReferenceToUser < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :organisation, foreign_key: true
  end
end
