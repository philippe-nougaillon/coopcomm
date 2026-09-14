# frozen_string_literal: true

require 'test_helper'

class ToolInterventionTest < ActiveSupport::TestCase
  # Aucun comportement à tester : ni validation écrite à la main, ni callback, ni méthode propre.
  # Les conflits de disponibilité d'un outil appartiennent au modèle Intervention, qui porte la
  # validation : test/models/intervention_conflit_outil_matrix_test.rb.
end
