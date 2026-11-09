# frozen_string_literal: true

require 'test_helper'

# La vue matérialisée dashboard_intervention_stats doit refléter EXACTEMENT les requêtes
# live qu'elle remplace (parité), et rester en lecture seule.
class DashboardInterventionStatTest < ActiveSupport::TestCase
  setup { refresh_dashboard_views! }

  test "le nombre d'interventions du tableau de bord sur une période est identique au filtre live sur la date de début effective" do
    org = Organisation.first
    début_période = 9.months.ago.beginning_of_month
    fin_période = Time.current.end_of_month
    live = org.interventions.where("#{Intervention::EFFECTIVE_DEBUT_SQL} BETWEEN ? AND ?", début_période, fin_période).count

    vue = DashboardInterventionStat.for_organisation(org).between_months(début_période, fin_période).sum(:nb)

    assert_equal live, vue
  end

  test "une intervention prévue et non commencée est comptée dans le mois de son début prévu" do
    Intervention.create!(adherent: users(:weil), service: services(:technique), description: 'Intervention planifiée',
                         début_prévue: Time.zone.local(2023, 2, 10, 9), fin_prévue: Time.zone.local(2023, 2, 10, 11),
                         workflow_state: Intervention::NOUVEAU)
    refresh_dashboard_views!

    vue = DashboardInterventionStat.for_organisation(organisations(:mairie_paris)).between_months(Date.new(2023, 2, 1), Date.new(2023, 2, 28))

    assert_equal 1, vue.sum(:nb)
    assert_equal [Intervention::NOUVEAU], vue.pluck(:workflow_state)
  end

  test "le tableau de bord d'un adhérent ne compte que ses interventions" do
    adherent = User.where(rôle: :adhérent).joins(:interventions_adherent).first

    assert_not_nil adherent, 'aucun adhérent avec interventions dans les fixtures'
    live = adherent.interventions_adherent.where.not(service_id: nil).count

    vue = DashboardInterventionStat.for_adherent(adherent).sum(:nb)

    assert_equal live, vue
  end

  test "une statistique d'intervention du tableau de bord est en lecture seule" do
    assert DashboardInterventionStat.new.readonly?
  end

  test "la mise à jour d'une statistique d'intervention du tableau de bord est refusée" do
    stat = DashboardInterventionStat.first

    assert_not_nil stat, 'aucune ligne agrégée dans les fixtures'

    assert_raises(ActiveRecord::ReadOnlyRecord) { stat.update!(nb: 999) }
  end

  test "le nombre d'interventions du tableau de bord est celui des interventions rattachées à un service" do
    assert_equal Intervention.where.not(service_id: nil).count, DashboardInterventionStat.sum(:nb)
  end

  test "le nombre d'interventions par service du tableau de bord est identique au calcul live" do
    org = Organisation.first
    live = org.interventions.joins(:service).group('services.nom').count

    vue = DashboardInterventionStat.for_organisation(org).joins(:service).group('services.nom').sum(:nb)

    assert_equal live, vue.transform_values(&:to_i)
  end

  test 'le temps par service du tableau de bord est identique au calcul live' do
    org = Organisation.first
    live = org.interventions.joins(:service).group('services.nom').sum(:temps_total)

    vue = DashboardInterventionStat.for_organisation(org).joins(:service).group('services.nom').sum(:temps_total)

    arrondi = ->(h) { h.transform_values { |v| v.to_f.round(2) } }

    assert_equal arrondi.call(live), arrondi.call(vue)
  end
end
