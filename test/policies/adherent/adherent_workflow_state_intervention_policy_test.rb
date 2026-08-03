# frozen_string_literal: true

require 'test_helper'

class AdherentWorkflowStateInterventionPolicyTest < ActionDispatch::IntegrationTest
  def setup
    adherent_paris = users(:patrick_adherent_paris)

    intervention_paris = interventions(:intervention_paris)

    @policy = InterventionPolicy.new(adherent_paris, intervention_paris)
  end

  # Terminer
  test "should'nt get terminer" do
    refute @policy.terminer?
  end

  # Valider
  test 'should get valider' do
    assert @policy.valider?
  end

  # Refuser
  test 'should get refuser' do
    assert @policy.refuser?
  end

  # Archiver : réservé aux manager/administrateur.
  test "should'nt get archiver" do
    refute @policy.archiver?
  end
end
