# frozen_string_literal: true

class InterventionForBoxcars < ApplicationRecord
  # N'hérite pas du model Intervention car Boxcars n'a pas besoin des callbacks et du trie
  self.primary_key = "id"
  
  belongs_to :adherent, class_name: :User, foreign_key: :adherent_id, optional: true

  def self.semantic_informations
    {
      workflow_state: {
        Description: "A workflow_state define the statement of the intervention.",
        Model_specifications: "Column has valid values: #{Intervention.workflow_spec.state_names}"
      },
      adherent:  {
        Description: "An adherent is a User how demand interventions.",
        Model_specifications: "InterventionForBoxcars belongs_to :adherent, class_name: :User, foreign_key: :adherent_id"
      },
      description:  {
        Description: "A description is the name of the intervention. It may consist of a '#' symbol and numbers corresponding to the intervention identifier."
      },
      début_prévue:  {
        Description: "The field début_prévue is a date to plan an intervention in the future."
      },
    }
  end

  def readonly?
    true
  end
end
