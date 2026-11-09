# frozen_string_literal: true

class UserForBoxcars < ApplicationRecord
  # N'hérite pas du model User car Boxcars n'a pas besoin de Devise, des callbacks et du tri
  self.primary_key = "id"

  enum :rôle, User.rôles
  
  has_many :interventions_adherent, class_name: :InterventionForBoxcars, foreign_key: :adherent_id

  def self.semantic_informations
    {
      rôle: {
        Description: "A rôle defines the kind of user. An adhérent is the user how have many demands of interventions.",
        Model_specifications: "Column has valid values: #{User.rôles.keys}"
      },
      interventions_adherent: {
        Description: "Interventions requested by an adherent.",
        Model_specifications: "UserForBoxcars has_many :interventions_adherent, class_name: :InterventionForBoxcars, foreign_key: :adherent_id"
      },
      nom: {
        Description: "The field nom is the last name of the user."
      },
      prénom: {
        Description: "The field prénom is the first name of the user."
      },
    }
  end

  def readonly?
    true
  end
end
