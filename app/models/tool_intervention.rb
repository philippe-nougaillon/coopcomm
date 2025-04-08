class ToolIntervention < ApplicationRecord
  belongs_to :tool
  belongs_to :intervention

  before_validation :check_tool_disponibilite

  def check_tool_disponibilite
    return if tool.nil? || intervention.nil?

    debut = intervention.début_prévue
    fin = intervention.fin_prévue
    return if debut.blank? || fin.blank?

    # Cherche les autres interventions pour ce tool avec chevauchement
    conflits = Intervention.joins(:tools)
      .where(tools: { id: tool.id })
      .where.not(id: intervention.id)
      .where(
        "(interventions.début_prévue = :debut) OR
        (interventions.début_prévue = :fin) OR
        (interventions.fin_prévue = :debut) OR
        (interventions.fin_prévue = :fin) OR
        (interventions.début_prévue BETWEEN :debut AND :fin) OR
        (interventions.fin_prévue BETWEEN :debut AND :fin) OR
        (:debut BETWEEN interventions.début_prévue AND interventions.fin_prévue) OR
        (:fin BETWEEN interventions.début_prévue AND interventions.fin_prévue) OR
        (interventions.début_prévue <= :debut AND interventions.fin_prévue >= :fin) OR
        (interventions.début_prévue >= :debut AND interventions.fin_prévue <= :fin)",
        debut: debut, fin: fin
      )

    return if conflits.empty?

    descriptions = conflits.map do |i|
      "#{i.description} (du #{i.début_prévue.strftime('%d/%m/%Y %H:%M')} au #{i.fin_prévue.strftime('%d/%m/%Y %H:%M')})"
    end

    errors.add(:base, "Outil '#{tool.name}' indisponible à cette période : #{descriptions.to_sentence}")
  end
end