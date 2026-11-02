# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :is_user_authorized
  before_action :lire_filtres, only: %i[index]

  trie User, { 'agents.nom' => "CASE WHEN users.discarded_at IS NULL THEN #{TriTextuel.expression('users.nom')} END",
               'agents.temps' => 'COALESCE(temps.temps, 0)',
               'agents.interventions' => 'COALESCE(stats.nb, 0)',
               'agents.validees' => 'stats.validees::float / NULLIF(stats.nb, 0)',
               'agents.note' => 'stats.note' },
       defaut: 'agents.temps', sens: :desc

  # Les agents désactivés gardent leur temps au dashboard, mais pas leur nom.
  LIBELLE_AGENT_DESACTIVE = 'Utilisateur désactivé'

  # Part du temps d'une intervention qui revient à chacun de ses agents, comme dans la vue dashboard_agent_stats.
  PART_AGENT = 'interventions.temps_total / GREATEST((SELECT COUNT(*) FROM agent_interventions ai ' \
               'WHERE ai.intervention_id = interventions.id), 1)'

  def index
    assigner(accueil(@perimetre, @du, @au))
    respond_to do |format|
      format.html { render partial: 'dashboard/activite_agents' if turbo_frame_request? }
      format.xls { export_xls }
    end
  end

  # Liste d'une cellule du calendrier des réservations de matériel : un jour, ou une plage de jours.
  def reservations_du_jour
    @mouvements = Mouvement.réservé.joins(:tool).where(tools: { organisation_id: current_organisation.id })
                           .where('mouvements.date BETWEEN ? AND ?', date_param(:du), date_param(:au))
                           .includes(:tool, :user, :intervention).order(:date, 'tools.name')
    render layout: false
  end

  private

  def is_user_authorized
    authorize :dashboard
  end

  def export_xls
    xls = ExportToXls::Dashboard.new(@activite_agents[:lignes], @donnees_graphes, @conventions).call
    ExportLog.create!(user: current_user, organisation: current_organisation,
                      export_type: current_user.manager_or_admin? ? 'dashboard_manager' : 'dashboard_adherent')
    send_data xls, filename: "Dashboard_#{l Date.today}.xls"
  end

  # Un libellé par intervenant du périmètre — pour un adhérent, par agent affecté à ses interventions —, jamais le
  # nom d'un agent désactivé : « Utilisateur désactivé », puis « … #2 », « … #3 » pour ne pas écraser le précédent.
  def libellés_agents(services, start_date, end_date, interventions_adherent = nil)
    if interventions_adherent
      affectes = User.with_discarded.where(id: interventions_adherent.joins(:agent_interventions).select('agent_interventions.agent_id'))
      actifs = affectes.kept
      desactives = affectes.discarded
    else
      temps = DashboardAgentStat.for_services(services).between_months(start_date, end_date)
                                .where("temps_total >= 0")
                                .group(:agent_id).sum(:temps_total)
      actifs = User.intervenants_pour(services)
      desactives = User.with_discarded.discarded.intervenants_pour(services).select { |agent| (temps[agent.id] || 0).positive? }
    end
    libellés = actifs.each_with_object({}) { |agent, hash| hash[agent.id] = agent.nom_prénom }
    desactives.sort_by(&:id).each_with_object(libellés) do |agent, hash|
      rang = hash.values.count { |libellé| libellé.start_with?(LIBELLE_AGENT_DESACTIVE) } + 1
      hash[agent.id] = rang == 1 ? LIBELLE_AGENT_DESACTIVE : "#{LIBELLE_AGENT_DESACTIVE} ##{rang}"
    end
  end

  def date_param(clé)
    Date.parse(params[clé].to_s) if params[clé].present?
  rescue Date::Error
    nil
  end

  def mois_de_la_periode(start_date, end_date)
    (start_date.to_date..end_date.to_date).map(&:beginning_of_month).uniq
  end

  def periodes_proposees(bornes)
    aujourdhui = Date.current
    periodes = [
      ['Année en cours', aujourdhui.beginning_of_year, aujourdhui.end_of_year],
      ['9 derniers mois · 3 à venir', aujourdhui << 9, aujourdhui >> 3],
      ['12 derniers mois', aujourdhui << 11, aujourdhui],
      ['6 derniers mois', aujourdhui << 5, aujourdhui],
      ['3 derniers mois', aujourdhui << 2, aujourdhui],
      ['Mois en cours', aujourdhui, aujourdhui]
    ]
    periodes << ['Tout', *bornes] if bornes.first
    periodes.map { |libellé, du, au| { libellé: libellé, du: du.beginning_of_month, au: au.end_of_month } }
  end

  def etats_par_mois_et_service(services, stats, start_date, end_date)
    workflows = [Intervention::NOUVEAU, Intervention::TERMINE, Intervention::VALIDE, Intervention::REFUSE]
    raw = stats.group(:service_id, :mois, :workflow_state).sum(:nb)

    services.each_with_object({}) do |service, par_service|
      par_service[service.nom] = mois_de_la_periode(start_date, end_date).each_with_object({}) do |mois, par_mois|
        par_mois[mois.strftime('%Y-%m')] = workflows.index_with { |état| raw[[service.id, mois, état]] || 0 }
      end
    end
  end

  def temps_par_mois_et_service(services, stats, start_date, end_date)
    raw = stats.where("temps_total >= 0").group(:service_id, :mois).sum(:temps_total)

    services.each_with_object({}) do |service, par_service|
      par_service[service.nom] = mois_de_la_periode(start_date, end_date).each_with_object({}) do |mois, par_mois|
        par_mois[mois.strftime('%Y-%m')] = raw[[service.id, mois]] || 0
      end
    end
  end

  def bornes_des_stats(services, adherent = nil)
    statistiques(services, adherent).pick(Arel.sql('MIN(mois), MAX(mois)'))
  end

  # Une ligne par intervenant, sur le service et les derniers mois propres à la carte : temps lu dans la vue
  # dashboard_agent_stats, interventions hors modèles de pointage et hors « nouveau », note des interventions
  # validées ou refusées notées, et les deux séries mensuelles de la courbe. Pour un adhérent : les agents affectés
  # à ses interventions, et leur temps sur celles-ci seulement.
  def activite_des_agents(services, start_date, end_date, adherent = nil)
    choisi = services.find { |service| service.nom == params[:agents_service] }
    services = [choisi] if choisi
    mois = mois_de_la_periode(start_date, end_date)
    passes = mois.select { |m| m <= Date.current.beginning_of_month }.presence || mois
    derniers = [12, 6, 3].find { |nombre| nombre == params[:agents_periode].to_i && passes.size > nombre }
    mois = passes.last(derniers) if derniers
    start_date, end_date = mois.first, mois.last.end_of_month if mois.any?
    jour = Arel.sql("(#{Intervention::EFFECTIVE_DEBUT_SQL})::date")
    notee = "interventions.workflow_state IN ('#{Intervention::VALIDE}', '#{Intervention::REFUSE}') AND interventions.note > 0"
    base = Intervention.where(service: services).where.not(workflow_state: [Intervention::POINTAGE_ACTIVE, Intervention::NOUVEAU])
                       .where("#{jour} BETWEEN ? AND ?", start_date, end_date)
    base = base.where(adherent: adherent) if adherent
    libellés = libellés_agents(services, start_date, end_date, adherent && base)
    interventions = base.joins(:agent_interventions).where(agent_interventions: { agent_id: libellés.keys })
    stats = interventions.group('agent_interventions.agent_id')
                         .select('agent_interventions.agent_id', 'COUNT(*) AS nb',
                                 'COUNT(*) FILTER (WHERE interventions.template_slug IS NOT NULL) AS pointages',
                                 "COUNT(*) FILTER (WHERE interventions.workflow_state = '#{Intervention::TERMINE}') AS terminees",
                                 "COUNT(*) FILTER (WHERE interventions.workflow_state = '#{Intervention::VALIDE}') AS validees",
                                 "COUNT(*) FILTER (WHERE interventions.workflow_state = '#{Intervention::REFUSE}') AS refusees",
                                 "COUNT(*) FILTER (WHERE interventions.workflow_state = '#{Intervention::ARCHIVE}') AS archivees",
                                 "AVG(interventions.note) FILTER (WHERE #{notee}) AS note", "COUNT(*) FILTER (WHERE #{notee}) AS avis")
    temps = if adherent
              interventions.where('interventions.temps_total >= 0').group('agent_interventions.agent_id')
                           .select('agent_interventions.agent_id', "SUM(#{PART_AGENT}) AS temps")
            else
              DashboardAgentStat.for_services(services).between_months(start_date, end_date).where('temps_total >= 0')
                                .group(:agent_id).select(:agent_id, 'SUM(temps_total) AS temps')
            end
    agents = User.with_discarded.where(id: libellés.keys).with_attached_profile_picture.preload(:services, :organisations)
                 .joins("LEFT JOIN (#{temps.to_sql}) temps ON temps.agent_id = users.id")
                 .joins("LEFT JOIN (#{stats.to_sql}) stats ON stats.agent_id = users.id")
                 .select('users.*', 'COALESCE(temps.temps, 0) AS temps', 'stats.*')
    bornes, tranches = tranches_de(mois)
    tranche = Arel.sql("CASE #{bornes[1...-1].to_a.each_with_index.map { |borne, rang| "WHEN #{jour} < '#{borne}' THEN #{rang}" }.join(' ')} " \
                       "ELSE #{tranches.size - 1} END")
    courbes = tranches.empty? ? {} : interventions.group('agent_interventions.agent_id', tranche)
                                                  .pluck(Arel.sql('agent_interventions.agent_id'), tranche, Arel.sql('COUNT(*)'),
                                                         Arel.sql("SUM(#{PART_AGENT})"))
                                                  .to_h { |agent_id, rang, nb, temps| [[agent_id, rang], [nb, temps.to_f]] }
    lignes = trier(agents).map do |agent|
      { agent: agent, libellé: libellés[agent.id], temps: agent[:temps].to_f, note: agent[:note]&.to_f&.round(1),
        **%i[nb pointages terminees validees refusees archivees avis].index_with { |champ| agent[champ].to_i },
        nb_courbe: tranches.each_index.map { |rang| courbes.dig([agent.id, rang], 0) || 0 },
        temps_courbe: tranches.each_index.map { |rang| courbes.dig([agent.id, rang], 1) || 0.0 } }
    end
    { lignes: lignes, mois: mois.map { |m| m.strftime('%Y-%m') }, tranches: tranches, service: choisi&.nom, periode: derniers }
  end

  # Douze tranches égales de la période pour la courbe de chaque agent : des mois entiers quand elle en compte un multiple
  # de douze, des jours sinon. Rend les bornes (la dernière exclue) et le libellé de chaque tranche.
  def tranches_de(mois)
    return [[], []] if mois.empty?

    if (mois.size % 12).zero?
      pas = mois.size / 12
      bornes = (0..12).map { |rang| mois.first >> (rang * pas) }
      libellés = bornes.each_cons(2).map { |du, au| [(l(du, format: '%b') if pas > 1), l(au << 1, format: '%b %Y')].compact.join(' – ') }
    else
      jours = (mois.last.end_of_month - mois.first).to_i + 1
      nombre = [12, jours].min
      bornes = (0..nombre).map { |rang| mois.first + jours * rang / nombre }
      libellés = bornes.each_cons(2).map do |du, au|
        [l(du, format: du.month == (au - 1).month ? '%-d' : '%-d %b'), l(au - 1, format: '%-d %b')].join(' – ')
      end
    end
    [bornes, libellés]
  end

  def lire_filtres
    @perimetre = scoped_services(:service)
    @du = (date_param(:du) || Date.current.beginning_of_year).beginning_of_month
    @au = (date_param(:au) || Date.current.end_of_year).end_of_month
  end

  def assigner(donnees)
    donnees.each { |clé, valeur| instance_variable_set("@#{clé}", valeur) }
  end

  # Les quatre tuiles de l'accueil ; un adhérent n'y voit que ses interventions, ses documents et ses conventions.
  def accueil(services, start_date, end_date)
    adherent = current_user unless current_user.manager_or_admin?
    ordonnés = services.sort_by(&:nom)
    bornes = bornes_des_stats(services, adherent)
    annees, annee = annees_proposees(bornes)
    stats = statistiques(services, adherent).between_months(start_date, end_date)

    {
      periodes: periodes_proposees(bornes),
      annees: annees,
      annee: annee,
      activite_agents: activite_des_agents(ordonnés, start_date, end_date, adherent),
      conventions: (ConventionsDeLAnnee.call(adherent) if adherent),
      donnees_graphes: {
        services: ordonnés.map(&:nom),
        mois: mois_de_la_periode(start_date, end_date).map { |mois| mois.strftime('%Y-%m') },
        mois_courant: Date.current.strftime('%Y-%m'),
        aujourdhui: Date.current.iso8601,
        du: start_date.iso8601,
        au: end_date.iso8601,
        annee: annee,
        etats: etats_par_mois_et_service(ordonnés, stats, start_date, end_date),
        temps: temps_par_mois_et_service(ordonnés, stats, start_date, end_date),
        prevus: temps_prevus_par_mois_et_service(ordonnés, start_date, end_date, adherent),
        crm: montants_crm(ordonnés, start_date, end_date, adherent),
        reservations: (reservations_par_jour(annee) unless adherent)
      }.deep_transform_values { |valeur| valeur.is_a?(BigDecimal) ? valeur.to_f : valeur }
    }
  end

  def statistiques(services, adherent = nil)
    stats = adherent ? DashboardInterventionStat.for_adherent(adherent) : DashboardInterventionStat.for_organisation(current_organisation)
    stats.for_services(services)
  end

  # Devis et commandes sont du prévisionnel ; seules les factures envoyées ou validées
  # comptent comme chiffre d'affaires.
  def documents_crm(adherent = nil)
    { devis: Cotation.kept.where.not(workflow_state: [Cotation::CREE, Cotation::REFUSE]),
      commandes: Commande.kept.where.not(workflow_state: [Commande::CREE, Commande::REFUSE]),
      factures: Facture.kept.where(workflow_state: [Facture::ENVOYE, Facture::VALIDE]) }
      .transform_values { |scope| adherent ? scope.where(adherent: adherent) : scope }
  end

  # Montants HT par mois de saisie, pour les trois courbes de la tuile CRM.
  def montants_crm(services, start_date, end_date, adherent = nil)
    mois_sql = Arel.sql("date_trunc('month', created_at)::date")
    sommes = documents_crm(adherent).transform_values do |scope|
      scope.where(service: services, created_at: start_date.beginning_of_day..end_date.end_of_day)
           .group(:service_id, mois_sql).sum(:total_ht)
    end

    services.each_with_object({}) do |service, par_service|
      par_service[service.nom] = mois_de_la_periode(start_date, end_date).each_with_object({}) do |mois, par_mois|
        par_mois[mois.strftime('%Y-%m')] = sommes.transform_values { |par_mois_du_service| par_mois_du_service[[service.id, mois]] || 0 }
      end
    end
  end

  # Les années proposées au calendrier, de la première statistique à l'année en cours, et celle qui est demandée.
  def annees_proposees(bornes)
    annees = ([bornes.first&.year, Date.current.year].compact.min..[bornes.last&.year, Date.current.year].compact.max).to_a
    [annees, annees.include?(params[:annee].to_i) ? params[:annee].to_i : Date.current.year]
  end

  # Par jour de l'année : [réservations de matériel de l'organisation], pannes exclues.
  def reservations_par_jour(annee)
    Mouvement.réservé.joins(:tool)
             .where(tools: { organisation_id: current_organisation.id }, date: Date.new(annee, 1, 1)..Date.new(annee, 12, 31))
             .group(:date).count
             .to_h { |date, nombre| [date.iso8601, [nombre]] }
  end

  # Les interventions « nouveau » n'ont pas de temps réel : durée prévue × agents affectés, par service et par mois
  # du début prévu.
  def temps_prevus_par_mois_et_service(services, start_date, end_date, adherent = nil)
    mois_sql = Arel.sql("date_trunc('month', #{Intervention::EFFECTIVE_DEBUT_SQL})::date")
    heures = "GREATEST(EXTRACT(EPOCH FROM (#{Intervention::EFFECTIVE_FIN_SQL} - #{Intervention::EFFECTIVE_DEBUT_SQL})) / 3600, 0) " \
             '* GREATEST((SELECT COUNT(*) FROM agent_interventions WHERE agent_interventions.intervention_id = interventions.id), 1)'
    prevues = Intervention.where(service: services, workflow_state: Intervention::NOUVEAU)
                          .where("#{Intervention::EFFECTIVE_DEBUT_SQL} BETWEEN ? AND ?", start_date.beginning_of_day, end_date.end_of_day)
    prevues = prevues.where(adherent: adherent) if adherent
    raw = prevues.group(:service_id, mois_sql).pluck(:service_id, mois_sql, Arel.sql("COALESCE(SUM(#{heures}), 0)"))
                 .to_h { |service_id, mois, total| [[service_id, mois], total] }

    services.each_with_object({}) do |service, par_service|
      par_service[service.nom] = mois_de_la_periode(start_date, end_date).each_with_object({}) do |mois, par_mois|
        par_mois[mois.strftime('%Y-%m')] = (raw[[service.id, mois]] || 0).round(2)
      end
    end
  end
end
