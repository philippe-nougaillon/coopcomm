# frozen_string_literal: true

require 'test_helper'

# La vue matérialisée dashboard_intervention_stats doit refléter EXACTEMENT les requêtes
# live qu'elle remplace (parité), et rester en lecture seule.
class DashboardInterventionStatTest < ActiveSupport::TestCase
  setup { refresh_dashboard_views! }

  test 'scope between_months : période demandée → même total que le filtre live sur début' do
    org = Organisation.first
    début_période = 9.months.ago.beginning_of_month
    fin_période = Time.current.end_of_month
    live = org.interventions.where(début: début_période..fin_période).count

    vue = DashboardInterventionStat.for_organisation(org).between_months(début_période, fin_période).sum(:nb)

    assert_equal live, vue
  end

  test 'scope for_adherent : adhérent → ses interventions seulement' do
    adherent = User.where(rôle: :adhérent).joins(:interventions_adherent).first

    assert_not_nil adherent, 'aucun adhérent avec interventions dans les fixtures'
    live = adherent.interventions_adherent.where.not(service_id: nil).count

    vue = DashboardInterventionStat.for_adherent(adherent).sum(:nb)

    assert_equal live, vue
  end

  test 'readonly? : n\'importe quelle ligne → lecture seule' do
    assert DashboardInterventionStat.new.readonly?
  end

  test 'readonly? : mise à jour d\'une ligne existante → refusée' do
    stat = DashboardInterventionStat.first

    assert_not_nil stat, 'aucune ligne agrégée dans les fixtures'

    assert_raises(ActiveRecord::ReadOnlyRecord) { stat.update!(nb: 999) }
  end

  test 'parité : somme des nb → nombre d\'interventions rattachées à un service' do
    assert_equal Intervention.where.not(service_id: nil).count, DashboardInterventionStat.sum(:nb)
  end

  test 'parité : rollup par service → identique au calcul live' do
    org = Organisation.first
    live = org.interventions.joins(:service).group('services.nom').count

    vue = DashboardInterventionStat.for_organisation(org).joins(:service).group('services.nom').sum(:nb)

    assert_equal live, vue.transform_values(&:to_i)
  end

  test 'parité : rollup du temps par service → identique au calcul live' do
    org = Organisation.first
    live = org.interventions.joins(:service).group('services.nom').sum(:temps_total)

    vue = DashboardInterventionStat.for_organisation(org).joins(:service).group('services.nom').sum(:temps_total)

    arrondi = ->(h) { h.transform_values { |v| v.to_f.round(2) } }

    assert_equal arrondi.call(live), arrondi.call(vue)
  end
end
