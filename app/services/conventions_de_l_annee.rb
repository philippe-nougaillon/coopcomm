# frozen_string_literal: true

# Les conventions visibles d'un utilisateur, comme sur leur liste, actives dans l'année en cours, avec leurs
# heures : bloc « Suivi des heures » de l'accueil et tuile du tableau de bord adhérent.
class ConventionsDeLAnnee < ApplicationService
  def initialize(user)
    @user = user
  end

  def call
    annee = Date.current.all_year
    avec_heures(Convention.visible_to(@user)
                          .where('conventions.date_début <= ? AND conventions.date_fin_prévue >= ?', annee.end, annee.begin))
      .map do |convention|
        { adherent: convention.user.nom_prénom, service: convention.service.nom,
          du: convention.date_début.iso8601, au: convention.date_fin_prévue.iso8601,
          conventionnees: convention.heures_conventionnees, consommees: convention.consommees, prevues: convention.prevues }
          .transform_values { |valeur| valeur.is_a?(BigDecimal) ? valeur.to_f : valeur }
      end
  end

  private

  # Heures consommées de toute la convention, comme sur la liste des conventions (même jointure que son tri) ;
  # heures planifiées : interventions pas encore commencées, hors modèles de pointage, durée prévue × agents affectés.
  def avec_heures(conventions)
    prevues = 'COALESCE((SELECT SUM(EXTRACT(EPOCH FROM (prevues.fin_prévue - prevues.début_prévue)) / 3600 ' \
              '* GREATEST((SELECT COUNT(*) FROM agent_interventions WHERE agent_interventions.intervention_id = prevues.id), 1)) ' \
              'FROM interventions prevues WHERE prevues.adherent_id = conventions.user_id AND prevues.service_id = conventions.service_id ' \
              "AND prevues.début IS NULL AND prevues.fin_prévue > prevues.début_prévue AND prevues.workflow_state <> '#{Intervention::POINTAGE_ACTIVE}' " \
              'AND prevues.début_prévue >= conventions.date_début AND prevues.début_prévue < conventions.date_fin_prévue + 1), 0) AS prevues'
    conventions.joins('LEFT JOIN interventions ON interventions.adherent_id = conventions.user_id ' \
                      'AND interventions.service_id = conventions.service_id ' \
                      'AND interventions.début >= conventions.date_début ' \
                      'AND interventions.début < conventions.date_fin_prévue + 1')
               .select('conventions.*', 'COALESCE(SUM(interventions.temps_total), 0) AS consommees', prevues)
               .group('conventions.id')
               .preload(:user, :service)
  end
end
