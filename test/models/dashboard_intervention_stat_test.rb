# frozen_string_literal: true

require 'test_helper'

# La vue matérialisée dashboard_intervention_stats doit refléter EXACTEMENT les requêtes
# live qu'elle remplace (parité), être en lecture seule.
class DashboardInterventionStatTest < ActiveSupport::TestCase
  setup { refresh_dashboard_views! }

  test 'est en lecture seule' do
    assert DashboardInterventionStat.new.readonly?
  end

  test 'interdit toute écriture' do
    stat = DashboardInterventionStat.first
    skip 'aucune ligne agrégée dans les fixtures' if stat.nil?
    assert_raises(ActiveRecord::ReadOnlyRecord) { stat.update!(nb: 999) }
  end

  test 'somme(nb) égale le nombre d’interventions rattachées à un service' do
    assert_equal Intervention.where.not(service_id: nil).count,
                 DashboardInterventionStat.sum(:nb)
  end

  test 'rollup par service identique au calcul live' do
    org = Organisation.first
    live = org.interventions.joins(:service).group('services.nom').count
    vue  = DashboardInterventionStat.for_organisation(org)
                                    .joins(:service).group('services.nom').sum(:nb)
    assert_equal live, vue.transform_values(&:to_i)
  end

  test 'rollup du temps par service identique au calcul live' do
    org = Organisation.first
    live = org.interventions.joins(:service).group('services.nom').sum(:temps_total)
    vue  = DashboardInterventionStat.for_organisation(org)
                                    .joins(:service).group('services.nom').sum(:temps_total)
    round = ->(h) { h.transform_values { |v| v.to_f.round(2) } }
    assert_equal round.call(live), round.call(vue)
  end

  test 'between_months borne l’agrégat sur la colonne mois comme le filtre live sur début' do
    org = Organisation.first
    start_date = 9.months.ago.beginning_of_month
    end_date   = Time.current.end_of_month
    live = org.interventions.where(début: start_date..end_date).count
    vue  = DashboardInterventionStat.for_organisation(org)
                                    .between_months(start_date, end_date).sum(:nb)
    assert_equal live, vue
  end

  test 'for_adherent restreint aux interventions d’un adhérent' do
    adherent = User.where(rôle: :adhérent).joins(:interventions_adherent).first
    skip 'aucun adhérent avec interventions dans les fixtures' if adherent.nil?
    live = adherent.interventions_adherent.where.not(service_id: nil).count
    vue  = DashboardInterventionStat.for_adherent(adherent).sum(:nb)
    assert_equal live, vue
  end
end
