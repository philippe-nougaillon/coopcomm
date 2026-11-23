# frozen_string_literal: true

module Aibbo
  # Ce qu'AÏBBO lit de l'emploi du matériel sur une période : jours d'emploi, pannes, emploi simultané d'un groupe, retards, répartition par adhérent.
  class OutilUtilisationMateriel < Outil
    JOURS = 400
    TRIS = { 'utilisation' => :jours_d_emploi, 'pannes' => :jours_de_panne, 'heures' => :heures_en_intervention }.freeze

    description "Mesure l'emploi du matériel sur une période, pour juger s'il en manque ou s'il y en a trop. Par matériel : les jours ouvrés " \
                "(du lundi au vendredi) où il a servi, par réservation ou par intervention, ses jours ouvrés de panne, le nombre de ses pannes, " \
                "son taux d'occupation, et ses heures en intervention : le temps de travail d'un seul agent, pause déduite, " \
                "sur les interventions commencées dans la période et terminées, au total et en moyenne par intervention. " \
                "Pour l'ensemble des matériels retenus, par exemple toutes les tondeuses : combien ont servi " \
                "le même jour, les jours où aucun n'était libre, mois par mois aussi, et le retard au démarrage des interventions qui les emploient, " \
                "parmi celles que l'utilisateur peut consulter. " \
                "Avec par_adherent, pour chaque matériel : les jours d'emploi de chaque adhérent de ses interventions et leur part des jours " \
                "d'emploi du matériel, un jour partagé par deux adhérents comptant pour chacun, et à part les jours réservés sans intervention. " \
                'Sans période, les douze derniers mois, qui couvrent toutes les saisons : la bonne base pour juger un achat ou une vente. ' \
                "La période s'arrête au plus tard aujourd'hui. Une clé « erreur » dit ce qu'il faut demander à l'utilisateur."

    parameters do
      string :du, required: false, description: 'Premier jour de la période, au format AAAA-MM-JJ ; sans lui, un an avant le dernier jour'
      string :au, required: false, description: "Dernier jour de la période, inclus, au format AAAA-MM-JJ ; sans lui, et au plus tard, aujourd'hui"
      string :nom, required: false, description: 'Nom ou partie du nom du matériel, par exemple tondeuse ; sans lui, tout le matériel'
      string :trier_par, required: false, enum: TRIS.keys,
                         description: "Classement des matériels, du plus élevé au plus bas : « utilisation » (jours d'emploi, valeur par défaut), " \
                                      '« pannes » (jours de panne) ou « heures » (heures en intervention)'
      boolean :par_adherent, required: false,
                             description: "Pour répartir les jours d'emploi de chaque matériel entre les adhérents (communes ou structures) " \
                                          'de ses interventions, avec à part les jours réservés sans intervention'
    end

    def name
      'utilisation_materiel'
    end

    def execute(du: nil, au: nil, nom: nil, trier_par: nil, par_adherent: nil)
      fin = [au.present? ? jour(au).to_date : Date.current, Date.current].min
      debut = du.present? ? jour(du).to_date : fin - 1.year + 1.day
      raise Refus, "La période doit commencer au plus tard aujourd'hui, et avant son dernier jour." if fin < debut
      raise Refus, "La période ne peut pas dépasser #{JOURS} jours." if (debut..fin).count > JOURS

      tri = TRIS.fetch(trier_par.presence || 'utilisation') { raise Refus, "Le classement « #{trier_par} » n'existe pas : #{TRIS.keys.to_sentence}." }
      materiels = Tool.visible_to(@utilisateur).ordered
      if nom.present?
        materiels = materiels.by_nom(nom)
        raise Refus, "« #{nom} » est introuvable parmi le matériel que l'utilisateur peut voir." if materiels.none?
      end

      ouvres = (debut..fin).select(&:on_weekday?)
      emplois = materiels.to_h { |materiel| [materiel, emploi(materiel, debut, fin)] }
      noms = noms_des_adherents(emplois) if par_adherent
      heures = heures_en_intervention(materiels, debut, fin)
      lignes = emplois.map do |materiel, emploi|
        servis = ouvres.count { |jour| emploi[:servi].include?(jour) }
        nombre, total = heures.fetch(materiel.id, [0, 0.0])
        ligne = { nom: materiel.name, jours_d_emploi: servis, jours_de_panne: ouvres.count { |jour| emploi[:panne].include?(jour) },
                  pannes: emploi[:pannes], taux_d_occupation: ouvres.any? ? (100.0 * servis / ouvres.size).round(1) : 0.0,
                  interventions_réalisées: nombre, heures_en_intervention: total.round(2),
                  heures_par_intervention: nombre.positive? ? (total / nombre).round(2) : 0.0 }
        par_adherent ? ligne.merge(repartition(emploi, ouvres, servis, noms)) : ligne
      end
      en_service = ouvres.index_with { |jour| emplois.count { |_, emploi| emploi[:servi].include?(jour) } }
      sans_libre = ouvres.select { |jour| emplois.all? { |_, emploi| emploi[:servi].include?(jour) || emploi[:panne].include?(jour) } }.to_set
      retards = retards_au_demarrage(materiels, debut, fin)

      { du: debut.to_s, au: fin.to_s, jours_ouvrés: ouvres.size, matériels: lignes.size,
        ensemble: {
          emploi_simultané: en_service.values.tally.sort.map { |nombre, jours| { matériels_en_service: nombre, jours: jours } },
          maximum_en_service_le_même_jour: en_service.values.max.to_i,
          jours_sans_aucun_libre: sans_libre.size, jours_de_panne: lignes.sum { |ligne| ligne[:jours_de_panne] },
          interventions_datées: retards.size, commencées_en_retard: retards.count(&:positive?),
          retard_moyen_en_jours: retards.any?(&:positive?) ? (retards.select(&:positive?).sum.to_f / retards.count(&:positive?)).round(1) : 0.0,
          par_mois: ouvres.group_by { |jour| jour.strftime('%Y-%m') }.map do |mois, jours|
            { mois: mois, jours_ouvrés: jours.size, maximum_en_service: en_service.values_at(*jours).max,
              jours_sans_aucun_libre: jours.count { |jour| sans_libre.include?(jour) } }
          end
        },
        matériel: lignes.sort_by { |ligne| -ligne[tri] } }
    end

    private

    def emploi(materiel, debut, fin)
      evenements = materiel.mouvements.where(état: %w[panne fin_de_panne]).where(date: ..fin).order(date: :desc, id: :desc).pluck(:date, :état)
      panne = (debut..fin).select { |jour| evenements.find { |date, _| date <= jour }&.last == 'panne' }.to_set
      reserves = materiel.mouvements.réservé.where(date: debut..fin).pluck(:date).to_set
      par_adherent = materiel.interventions.where('COALESCE(début, début_prévue) <= ? AND COALESCE(fin, fin_prévue) >= ?',
                                                  fin.end_of_day, debut.beginning_of_day)
                             .group_by(&:adherent_id)
                             .transform_values do |siennes|
                               siennes.flat_map { |intervention| (intervention.effective_début.to_date..intervention.effective_fin.to_date).to_a }.to_set - panne
                             end
      en_intervention = par_adherent.values.reduce(Set.new, :|)
      { servi: (reserves | en_intervention) - panne, panne: panne, par_adherent: par_adherent, reserve_seul: reserves - en_intervention - panne,
        pannes: evenements.count { |date, etat| etat == 'panne' && date >= debut } }
    end

    def retards_au_demarrage(materiels, debut, fin)
      Intervention.visible_to(@utilisateur).where(id: ToolIntervention.where(tool_id: materiels.map(&:id)).select(:intervention_id))
                  .where(début: debut.beginning_of_day..fin.end_of_day).where.not(début_prévue: nil)
                  .pluck(:début_prévue, :début).map { |prevu, reel| (reel.to_date - prevu.to_date).to_i }
    end

    def noms_des_adherents(emplois)
      User.where(id: emplois.values.flat_map { |emploi| emploi[:par_adherent].keys }.compact).to_h { |adherent| [adherent.id, adherent.nom_prénom.strip] }
    end

    # Un jour partagé par deux adhérents compte pour chacun : les parts peuvent dépasser cent pour cent au total.
    def repartition(emploi, ouvres, servis, noms)
      part = ->(jours) { servis.positive? ? (100.0 * jours / servis).round(1) : 0.0 }
      adherents = emploi[:par_adherent].group_by { |adherent_id, _| adherent_id ? noms.fetch(adherent_id, 'Compte désactivé') : 'Sans adhérent' }
                                       .map do |nom, paires|
        jours = ouvres.count { |jour| paires.any? { |_, siens| siens.include?(jour) } }
        { adhérent: nom, jours_d_emploi: jours, part: part.call(jours) }
      end
      sans_intervention = ouvres.count { |jour| emploi[:reserve_seul].include?(jour) }
      { par_adhérent: adherents.select { |adherent| adherent[:jours_d_emploi].positive? }.sort_by { |adherent| [-adherent[:jours_d_emploi], adherent[:adhérent]] },
        réservations_sans_intervention: { jours_d_emploi: sans_intervention, part: part.call(sans_intervention) } }
    end

    # Par matériel : [interventions qui ont au moins un agent, heures d'un seul agent] ; sans agent, la part vaut NULL et ne compte pas.
    def heures_en_intervention(materiels, debut, fin)
      part = OutilInterventions::PART_DE_L_AGENT
      Intervention.joins(:tool_interventions).where(tool_interventions: { tool_id: materiels.map(&:id) })
                  .where(début: debut.beginning_of_day..fin.end_of_day).where.not(fin: nil)
                  .group('tool_interventions.tool_id')
                  .pluck(Arel.sql('tool_interventions.tool_id'), Arel.sql("COUNT(#{part})"), Arel.sql("COALESCE(SUM(#{part}), 0)"))
                  .to_h { |tool_id, nombre, heures| [tool_id, [nombre, heures.to_f]] }
    end
  end
end
