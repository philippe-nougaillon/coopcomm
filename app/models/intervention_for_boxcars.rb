# frozen_string_literal: true

class InterventionForBoxcars < Intervention
  self.table_name = "interventions"

  default_scope -> { joins(:service).where("service.organisation_id": ENV["ORGANISATION_ID_FOR_BOXCARS"])}
end