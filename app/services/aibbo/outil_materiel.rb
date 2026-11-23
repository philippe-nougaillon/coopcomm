# frozen_string_literal: true

module Aibbo
  # Ce qu'AÏBBO lit du matériel un jour donné : libre, en panne, réservé ou pris par une intervention, comme sur sa fiche.
  class OutilMateriel < Outil
    ETATS = ['libre', 'en panne', 'réservé', 'en intervention'].freeze
    LIGNES = 160

    description "Dit, jour par jour, l'état de chaque matériel (outil ou véhicule) de l'organisation : libre, en panne (depuis quand, " \
                'déclarée par qui), réservé (par qui) ou pris par une intervention. Un nom partiel rend tous les matériels qui le portent : ' \
                "« tondeuse » rend toutes les tondeuses. Une clé « erreur » dit ce qu'il faut demander à l'utilisateur."

    parameters do
      string :du, required: false, description: "Premier jour, au format AAAA-MM-JJ ; sans lui, aujourd'hui"
      string :au, required: false, description: 'Dernier jour, inclus, au format AAAA-MM-JJ ; sans lui, le premier jour seul'
      string :nom, required: false, description: 'Nom ou partie du nom du matériel, par exemple tondeuse'
      string :etat, required: false, enum: ETATS, description: 'Pour ne garder que les jours où le matériel est dans cet état'
    end

    def name
      'materiel'
    end

    def execute(du: nil, au: nil, nom: nil, etat: nil)
      debut = du.present? ? jour(du).to_date : Date.current
      fin = au.present? ? jour(au).to_date : debut
      raise Refus, 'Le dernier jour ne peut pas précéder le premier.' if fin < debut
      raise Refus, "L'état « #{etat} » n'existe pas : #{ETATS.to_sentence}." if etat.present? && ETATS.exclude?(etat)

      materiels = Tool.visible_to(@utilisateur).ordered
      if nom.present?
        materiels = materiels.by_nom(nom)
        raise Refus, "« #{nom} » est introuvable parmi le matériel que l'utilisateur peut voir." if materiels.none?
      end

      if materiels.size * (debut..fin).count > LIGNES
        raise Refus, "#{materiels.size} matériels sur #{(debut..fin).count} jours : demandez un matériel précis ou une période plus courte."
      end

      lignes = (debut..fin).flat_map { |quand| materiels.map { |materiel| ligne(materiel, quand) } }
      lignes = lignes.select { |ligne| ligne[:état] == etat } if etat.present?
      { du: debut.to_s, au: fin.to_s, total: lignes.size, matériel: lignes }
    end

    private

    def ligne(materiel, quand)
      panne = materiel.mouvements.where(date: ..quand).where(état: %w[panne fin_de_panne]).order(date: :desc, id: :desc).first
      panne = nil unless panne&.panne?
      reservations = materiel.mouvements.réservé.where(date: quand).includes(:user).to_a
      interventions = materiel.interventions.where('COALESCE(début, début_prévue) <= ? AND COALESCE(fin, fin_prévue) >= ?',
                                                   quand.end_of_day, quand.beginning_of_day).to_a

      raisons = []
      raisons << "en panne depuis le #{panne.date}, déclarée par #{personne(panne.user)}" if panne
      raisons << "réservé par #{reservations.map { |reservation| personne(reservation.user) }.uniq.to_sentence}" if reservations.any?
      interventions.each do |intervention|
        raisons << "pris par l'intervention « #{intervention.description} » du #{horodatage(intervention.effective_début)} " \
                   "au #{horodatage(intervention.effective_fin)}"
      end

      etat = if panne then 'en panne'
             elsif reservations.any? then 'réservé'
             elsif interventions.any? then 'en intervention'
             else 'libre'
             end
      { nom: materiel.name, date: quand.to_s, état: etat, raisons: raisons.presence }.compact
    end

    def personne(utilisateur)
      utilisateur&.nom_prénom&.strip || 'Compte désactivé'
    end
  end
end
