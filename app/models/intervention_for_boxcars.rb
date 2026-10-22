# frozen_string_literal: true

class InterventionForBoxcars < ApplicationRecord
  # N'hérite pas du model Intervention car Boxcars n'a pas besoin des callbacks et du trie
  self.table_name = "interventions_for_boxcars"
  self.primary_key = "id"

  def readonly?
    true
  end
end
