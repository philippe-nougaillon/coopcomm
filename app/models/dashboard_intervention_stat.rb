# frozen_string_literal: true

# Modèle en LECTURE SEULE mappé sur la vue matérialisée `dashboard_intervention_stats`.
# Pré-agrégat des interventions au grain (organisation, service, adhérent, mois, statut).
# On ne fait que des where/group/sum par-dessus : les écritures sont interdites,
# la donnée est rafraîchie par RefreshDashboardViewsJob (cf. db/views/*.sql).
class DashboardInterventionStat < ApplicationRecord
  belongs_to :organisation
  belongs_to :service
  belongs_to :adherent, class_name: 'User', optional: true

  scope :for_organisation, ->(org) { where(organisation_id: org) }
  scope :for_services, ->(services) { where(service_id: services) }
  scope :for_adherent, ->(user) { where(adherent_id: user) }
  scope :between_months, ->(start_date, end_date) {
    where(mois: start_date.to_date.beginning_of_month..end_date.to_date.end_of_month)
  }

  def readonly?
    true
  end
end
