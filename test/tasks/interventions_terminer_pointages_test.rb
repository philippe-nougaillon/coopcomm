# frozen_string_literal: true

require 'test_helper'
require 'rake'

class InterventionsTerminerPointagesTaskTest < ActiveJob::TestCase
  setup do
    # Charge uniquement la tâche testée (pas de `load_tasks` complet) — même
    # motif que cotations_relancer_a_signer_test.rb (warning STATS_DIRECTORIES).
    unless Rake::Task.task_defined?('interventions:terminer_pointages')
      Rake::Task.define_task(:environment) # stub du prérequis, l'app est déjà bootée
      load Rails.root.join('lib/tasks/interventions.rake')
    end
    @task = Rake::Task['interventions:terminer_pointages']
    @task.reenable
  end

  test 'la tâche met en file la clôture des pointages' do
    assert_enqueued_with(job: TerminerPointagesJob) do
      @task.invoke
    end
  end
end
