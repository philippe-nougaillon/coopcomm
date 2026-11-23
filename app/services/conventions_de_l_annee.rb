# frozen_string_literal: true

# Les conventions validées visibles d'un utilisateur, actives dans l'année en cours, avec leurs
# heures : bloc « Suivi des heures » de l'accueil et tuile du tableau de bord adhérent.
class ConventionsDeLAnnee < ApplicationService
  def initialize(user)
    @user = user
  end

  def call
    annee = Date.current.all_year
    avec_heures(Convention.visible_to(@user).with_validé_state
                          .where('conventions.date_début <= ? AND (conventions.date_fin_prévue IS NULL OR conventions.date_fin_prévue >= ?)', annee.end, annee.begin), annee)
      .map do |convention|
        { adherent: convention.user.nom_prénom, service: convention.service.nom,
          du: [convention.date_début, annee.begin].max.iso8601, au: [convention.date_fin_prévue, annee.end].compact.min.iso8601,
          conventionnees: convention.heures_conventionnees, consommees: convention.consommees, prevues: convention.prevues }
          .transform_values { |valeur| valeur.is_a?(BigDecimal) ? valeur.to_f : valeur }
      end
  end

  private

  # Heures consommées de l'année, comme sur la liste des conventions (même jointure que son tri) ;
  # heures planifiées : interventions pas encore commencées, hors modèles de pointage, durée prévue × agents affectés.
  def avec_heures(conventions, annee)
    debut = "GREATEST(conventions.date_début, '#{annee.begin}')"
    fin = "LEAST(conventions.date_fin_prévue, '#{annee.end}') + 1"
    prevues = 'COALESCE((SELECT SUM(EXTRACT(EPOCH FROM (prevues.fin_prévue - prevues.début_prévue)) / 3600 ' \
              '* GREATEST((SELECT COUNT(*) FROM agent_interventions WHERE agent_interventions.intervention_id = prevues.id), 1)) ' \
              'FROM interventions prevues WHERE prevues.adherent_id = conventions.user_id AND prevues.service_id = conventions.service_id ' \
              "AND prevues.début IS NULL AND prevues.fin_prévue > prevues.début_prévue AND prevues.workflow_state <> '#{Intervention::POINTAGE_ACTIVE}' " \
              "AND prevues.début_prévue >= #{debut} AND prevues.début_prévue < #{fin}), 0) AS prevues"
    conventions.joins('LEFT JOIN interventions ON interventions.adherent_id = conventions.user_id ' \
                      'AND interventions.service_id = conventions.service_id ' \
                      "AND interventions.début >= #{debut} " \
                      "AND interventions.début < #{fin}")
               .select('conventions.*', 'COALESCE(SUM(interventions.temps_total), 0) AS consommees', prevues)
               .group('conventions.id')
               .preload(:user, :service)
  end
end
