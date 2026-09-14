# frozen_string_literal: true

require 'test_helper'

class AgentInterventionTest < ActiveSupport::TestCase
  # Aucun comportement à tester : ni validation écrite à la main, ni callback, ni méthode propre.
  # Les conflits de disponibilité d'un agent appartiennent au modèle Intervention, qui porte la
  # validation : test/models/intervention_conflit_agent_matrix_test.rb.
end
