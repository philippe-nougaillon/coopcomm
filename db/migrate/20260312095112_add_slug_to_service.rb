# frozen_string_literal: true

class AddSlugToService < ActiveRecord::Migration[8.0]
  def change
    add_column :services, :slug, :string

    Service.all.each(&:save)
  end
end
