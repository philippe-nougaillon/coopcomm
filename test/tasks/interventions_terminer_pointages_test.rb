# frozen_string_literal: true

require 'test_helper'
require 'rake'

class InterventionsTerminerPointagesTaskTest < ActiveJob::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    @task = Rake::Task['interventions:terminer_pointages']
    @task.reenable
  end

  test 'la task enfile le TerminerPointagesJob' do
    assert_enqueued_with(job: TerminerPointagesJob) do
      @task.invoke
    end
  end
end
