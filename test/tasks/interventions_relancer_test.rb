# frozen_string_literal: true

require 'test_helper'
require 'rake'

# La tâche de relance des adhérents dont l'intervention est terminée depuis plus
# de trois jours.
class InterventionsRelancerTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake::Task.define_task(:environment)
    load Rails.root.join('lib/tasks/interventions.rake')
    @intervention = interventions(:intervention_terminée)
  end

  teardown do
    Rake.application = nil
  end

  # ÉPINGLAGE BUG — la condition est inversée : `updated_at::DATE - NOW()::DATE >= 3`
  # ne retient que les interventions modifiées dans plus de trois jours, donc
  # jamais rien en production. À inverser à la correction
  # (`NOW()::DATE - updated_at::DATE`).
  test 'une intervention terminée depuis dix jours ne déclenche aucune relance' do
    @intervention.update_columns(updated_at: 10.days.ago)

    assert_emails 0 do
      @rake['interventions:relancer'].invoke
    end
  end

  # ÉPINGLAGE BUG — une fois l'intervention sélectionnée, le mail part puis la
  # tâche plante : `intervention.organisation_id` n'existe pas (la table n'a pas
  # cette colonne, l'organisation dérive du service). Même famille que les quatre
  # jobs corrigés en `organisation&.id`. À inverser à la correction.
  test 'une intervention sélectionnée reçoit son mail puis la tâche plante sur organisation_id' do
    @intervention.update_columns(updated_at: 10.days.from_now)

    assert_emails 1 do
      assert_raises(NoMethodError) { @rake['interventions:relancer'].invoke }
    end

    assert_equal @intervention.adherent.email, ActionMailer::Base.deliveries.last.to.first
    assert_match(/Relance/i, ActionMailer::Base.deliveries.last.subject)
  end

  test 'une intervention sans adhérent est ignorée' do
    @intervention.update_columns(updated_at: 10.days.from_now, adherent_id: nil)

    assert_emails 0 do
      @rake['interventions:relancer'].invoke
    end
  end
end
