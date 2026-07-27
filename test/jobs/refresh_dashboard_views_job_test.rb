# frozen_string_literal: true

require 'test_helper'

class RefreshDashboardViewsJobTest < ActiveJob::TestCase
  test 'refresh! peuple les vues matérialisées depuis les données courantes' do
    RefreshDashboardViewsJob.refresh!(concurrently: false)
    assert_equal Intervention.where.not(service_id: nil).count,
                 DashboardInterventionStat.sum(:nb)
  end

  test 'request_refresh planifie un refresh immédiat' do
    assert_enqueued_with(job: RefreshDashboardViewsJob) do
      RefreshDashboardViewsJob.request_refresh
    end
  end

  test 'request_refresh n’enfile qu’un seul job tant qu’un refresh est en vol' do
    with_memory_cache do
      assert_enqueued_jobs 1, only: RefreshDashboardViewsJob do
        5.times { RefreshDashboardViewsJob.request_refresh }
      end
    end
  end

  test 'perform recalcule en concurrently, consomme dirty et libère le verrou' do
    with_memory_cache do
      Rails.cache.write(RefreshDashboardViewsJob::DIRTY_KEY, true)
      Rails.cache.write(RefreshDashboardViewsJob::INFLIGHT_KEY, true)

      calls = []
      RefreshDashboardViewsJob.stub(:refresh!, ->(concurrently:) { calls << concurrently }) do
        RefreshDashboardViewsJob.new.perform
      end

      assert_equal [true], calls, 'un recalcul concurrent pour un dirty simple'
      assert_nil Rails.cache.read(RefreshDashboardViewsJob::DIRTY_KEY), 'dirty consommé'
      assert_nil Rails.cache.read(RefreshDashboardViewsJob::INFLIGHT_KEY), 'inflight libéré'
    end
  end

  test 'perform reprend un changement survenu PENDANT le refresh (aucune perte)' do
    with_memory_cache do
      Rails.cache.write(RefreshDashboardViewsJob::DIRTY_KEY, true)

      calls = 0
      simulate_concurrent_write = lambda do |concurrently:|
        calls += 1
        # une écriture arrive pendant le 1er recalcul
        Rails.cache.write(RefreshDashboardViewsJob::DIRTY_KEY, true) if calls == 1
      end

      RefreshDashboardViewsJob.stub(:refresh!, simulate_concurrent_write) do
        RefreshDashboardViewsJob.new.perform
      end

      assert_equal 2, calls, 'le changement concurrent doit déclencher un 2e recalcul'
    end
  end

  private

  def with_memory_cache
    original = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    yield
  ensure
    Rails.cache = original
  end
end
