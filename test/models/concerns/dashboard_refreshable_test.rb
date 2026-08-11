# frozen_string_literal: true

require 'test_helper'

# Le rafraîchissement des vues du dashboard est assuré par des triggers Postgres
# (db/functions/, db/triggers/) et non plus par des callbacks Rails : ces tests
# vérifient qu'ils sont installés, qu'ils couvrent toutes les écritures — y compris
# celles qui contournent Active Record — et qu'ils ne se déclenchent pas pour rien.
class DashboardRefreshableTest < ActiveSupport::TestCase
  TRIGGERS = %w[interventions_refresh_dashboard agent_interventions_refresh_dashboard].freeze

  setup { DashboardRefreshable.refresh_views! }

  def kpi = DashboardInterventionStat.sum(:temps_total).to_f

  def temps_par_agent = DashboardAgentStat.sum(:temps_total).to_f

  # Colonnes déclarées dans le `UPDATE OF …` d'un trigger.
  def colonnes_surveillées(trigger)
    ActiveRecord::Base.connection.select_values(<<~SQL)
      SELECT a.attname FROM pg_trigger t
      JOIN unnest(t.tgattr) AS col(attnum) ON true
      JOIN pg_attribute a ON a.attrelid = t.tgrelid AND a.attnum = col.attnum
      WHERE t.tgname = '#{trigger}'
    SQL
  end

  # Colonnes d'une table réellement lues par les vues matérialisées en base.
  def colonnes_lues(table)
    définitions = ActiveRecord::Base.connection.select_values(
      "SELECT definition FROM pg_matviews WHERE matviewname LIKE 'dashboard%'"
    ).join("\n")
    définitions.scan(/(?<![a-z_])#{table}\.("?)([a-zà-ÿ0-9_]+)\1/i).map { |_, col| col }.uniq - %w[id]
  end

  test 'la fonction et les deux triggers sont installés' do
    fonctions = ActiveRecord::Base.connection.select_values(
      "SELECT proname FROM pg_proc WHERE proname = 'refresh_dashboard_views'"
    )
    posés = ActiveRecord::Base.connection.select_values(
      'SELECT tgname FROM pg_trigger WHERE NOT tgisinternal'
    )

    assert_equal ['refresh_dashboard_views'], fonctions
    TRIGGERS.each { |trigger| assert_includes posés, trigger }
  end

  # Sentinelle : le jour où une vue lira une colonne de plus, le trigger doit la
  # surveiller — sinon les modifications de cette colonne n'atteindraient jamais le
  # dashboard, sans erreur ni trace.
  test 'les triggers surveillent toutes les colonnes lues par les vues' do
    { 'interventions' => TRIGGERS.first, 'agent_interventions' => TRIGGERS.last }.each do |table, trigger|
      manquantes = colonnes_lues(table) - colonnes_surveillées(trigger)

      assert_empty manquantes,
                   "#{table} : #{manquantes.join(', ')} ne figure(nt) pas dans le UPDATE OF de #{trigger} " \
                   "(db/triggers/#{trigger}_v01.sql)"
    end
  end

  test 'une colonne hors dashboard ne déclenche pas de rafraîchissement' do
    assert_not_includes colonnes_surveillées(TRIGGERS.first), 'description'
    assert_not_includes colonnes_surveillées(TRIGGERS.first), 'commentaires'
  end

  test "un changement d'état est répercuté sans aucune action Rails" do
    assert_difference -> { DashboardInterventionStat.where(workflow_state: 'archivé').sum(:nb) }, +1 do
      interventions(:tonte_locaux).update!(workflow_state: 'archivé')
    end
  end

  test 'update_columns, qui ne passe par aucun callback, est répercuté' do
    iv = interventions(:tonte_locaux)
    attendu = kpi - iv.temps_total + 7

    iv.update_columns(temps_total: 7)

    assert_in_delta attendu, kpi, 0.01
  end

  test 'update_all, qui ne passe par aucun callback, est répercuté' do
    iv = interventions(:tonte_locaux)
    attendu = kpi - iv.temps_total + 999

    Intervention.where(id: iv.id).update_all(temps_total: 999)

    assert_in_delta attendu, kpi, 0.01
  end

  test 'une écriture SQL directe est répercutée' do
    iv = interventions(:tonte_locaux)
    attendu = kpi - iv.temps_total + 4242

    ActiveRecord::Base.connection.execute("UPDATE interventions SET temps_total = 4242 WHERE id = #{iv.id}")

    assert_in_delta attendu, kpi, 0.01
  end

  test 'un delete_all sur les affectations est répercuté dans la vue agent' do
    iv = interventions(:tonte_locaux)
    avant = temps_par_agent

    AgentIntervention.where(intervention_id: iv.id).delete_all

    assert_in_delta avant - iv.temps_total, temps_par_agent, 0.01
  end

  test 'refresh_views! rafraîchit les deux vues matérialisées' do
    rafraîchies = []
    Scenic.database.stub(:refresh_materialized_view, ->(view, **) { rafraîchies << view }) do
      DashboardRefreshable.refresh_views!
    end

    assert_equal DashboardRefreshable::VIEWS, rafraîchies
  end
end
