# frozen_string_literal: true

json.array! @interventions, partial: 'interventions/intervention', as: :intervention
