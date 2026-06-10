# frozen_string_literal: true

module DashboardData
  extend ActiveSupport::Concern

  private

  def build_dashboard_for_manager(users, start_date, end_date)
    interventions = current_organisation.interventions.filter_by_service(current_user.services)
    co2 = build_co2_par_mois(interventions, start_date, end_date)

    {
      export_logs: current_organisation.export_logs.includes(:user).order(created_at: :desc),
      temps_total_par_adherent: temps_par_adherent(users),
      temps_total_par_agent: temps_par_agent(users),
      data_workflow_chart: build_workflow_chart(interventions, start_date, end_date),
      qte_interventions_par_service: interventions.joins(:service).group('services.nom').count,
      temps_total_par_service: interventions.joins(:service).group('services.nom').sum(:temps_total),
      co2_total_par_mois: co2,
      kpi_total_interventions: interventions.count,
      kpi_temps_total: "#{interventions.sum(:temps_total).round(1)}h",
      kpi_agents_actifs: users.agent.count,
      kpi_co2_total: "#{co2.values.sum} kg"
    }
  end

  def build_dashboard_for_adherent(start_date, end_date)
    interventions = current_user.interventions_adherent.filter_by_service(current_user.services)
    temps_consommable = 100
    temps_consomme = interventions.sum(:temps_total)
    co2 = build_co2_par_mois(interventions, start_date, end_date)

    {
      proportion_temps_consomme: {
        'temps_consomme' => temps_consomme,
        'temps_restant' => temps_consommable - temps_consomme
      },
      temps_total_par_mois: build_temps_par_mois(interventions, start_date, end_date),
      data_workflow_chart: build_workflow_chart(interventions, start_date, end_date),
      qte_interventions_par_service: interventions.joins(:service).group('services.nom').count,
      temps_total_par_service: interventions.joins(:service).group('services.nom').sum(:temps_total),
      co2_total_par_mois: co2,
      kpi_total_interventions: interventions.count,
      kpi_temps_total: "#{temps_consomme.round(1)}h",
      kpi_agents_actifs: current_organisation.users.agent.by_service(current_user.services).count,
      kpi_co2_total: "#{co2.values.sum} kg"
    }
  end

  def export_xls
    if current_user.manager_or_admin?
      xls = DashboardManagerToXls.new(
        @temps_total_par_adherent, @temps_total_par_agent,
        @data_workflow_chart, @qte_interventions_par_service,
        @temps_total_par_service, @co2_total_par_mois
      ).call
      ExportLog.create!(user: current_user, organisation: current_organisation, export_type: 'dashboard_manager')
    else
      xls = DashboardAdherentToXls.new(
        @proportion_temps_consomme, @temps_total_par_mois,
        @data_workflow_chart, @qte_interventions_par_service,
        @temps_total_par_service, @co2_total_par_mois
      ).call
      ExportLog.create!(user: current_user, organisation: current_organisation, export_type: 'dashboard_adherent')
    end
    send_data xls, filename: "Dashboard_#{l Date.today}.xls"
  end

  def temps_par_adherent(users)
    users.adhérent.includes(:interventions_adherent).each_with_object({}) do |adherent, hash|
      hash[adherent.nom_prénom] = adherent.interventions_adherent.to_a.sum(&:temps_total)
    end
  end

  def temps_par_agent(users)
    users.agent.includes(:agent_interventions, :interventions).each_with_object({}) do |agent, hash|
      hash[agent.nom_prénom] = agent.interventions.sum do |i|
        i.temps_total / i.agents.size
      end
    end
  end

  def build_workflow_chart(interventions, start_date, end_date)
    workflows = [
      Intervention::NOUVEAU, Intervention::POINTAGE_ACTIVE, Intervention::TERMINE,
      Intervention::VALIDE, Intervention::REFUSE, Intervention::ARCHIVE
    ]

    raw = interventions.where(début: start_date..end_date)
                       .group("DATE_TRUNC('month', début)", :workflow_state)
                       .count

    par_mois = fill_months(start_date, end_date, raw.each_with_object({}) do |(k, v), h|
      month = k[0].to_date.strftime('%Y-%m')
      h[month] ||= {}
      h[month][k[1]] = v
    end, workflows)

    labels = par_mois.keys
    datasets = workflows.map do |wf|
      { label: wf.capitalize, data: labels.map { |m| par_mois[m][wf] }, backgroundColor: workflow_color(wf) }
    end

    { labels: labels, datasets: datasets }
  end

  def build_co2_par_mois(interventions, start_date, end_date)
    raw = interventions.where(début: start_date..end_date)
                       .group("DATE_TRUNC('month', début)")
                       .sum(:co2)
                       .transform_keys { |m| m.to_date.strftime('%Y-%m') }

    fill_months(start_date, end_date, raw).sort.to_h
  end

  def build_temps_par_mois(interventions, start_date, end_date)
    raw = interventions.where(début: start_date..end_date)
                       .group("DATE_TRUNC('month', début)")
                       .sum(:temps_total)
                       .transform_keys { |m| m.to_date.strftime('%Y-%m') }

    fill_months(start_date, end_date, raw, nil, 0.0).sort.to_h
  end

  def fill_months(start_date, end_date, hash, keys_to_fill = nil, default = 0)
    (start_date.to_date..end_date.to_date).map(&:beginning_of_month).uniq.each do |month|
      m = month.strftime('%Y-%m')
      if keys_to_fill
        hash[m] ||= {}
        keys_to_fill.each { |k| hash[m][k] ||= default }
      else
        hash[m] ||= default
      end
    end
    hash.sort.to_h
  end

  def workflow_color(workflow)
    {
      Intervention::NOUVEAU => 'rgba(0,181,255,255)',
      Intervention::POINTAGE_ACTIVE => 'rgba(123,146,178,255)',
      Intervention::TERMINE => 'rgba(77,110,255,255)',
      Intervention::VALIDE => 'rgba(0,169,110,255)',
      Intervention::REFUSE => 'rgba(255,88,97,255)',
      Intervention::ARCHIVE => 'rgba(232,232,232,255)'
    }[workflow]
  end
end
