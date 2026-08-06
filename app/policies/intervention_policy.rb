# frozen_string_literal: true

class InterventionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    user
  end

  def show?
    index? && organisation? && (manager_or_admin? || record.adherent == user || record.agents.include?(user))
  end

  def can_see_qrcode_pointage_pdf?
    show? && !user.agent?
  end

  def new?
    index?
  end

  def create?
    new?
  end

  def edit?
    show? && (!record.repeter || !user.agent?)
  end

  def update?
    edit?
  end

  def destroy?
    show? && manager_or_admin?
  end

  # def accepter?
  #   show?
  # end

  # def en_cours?
  #   show?
  # end

  def terminer?
    show? && !user.adhérent?
  end

  def valider?
    show? && !user.agent?
  end

  def refuser?
    valider? && !user.agent?
  end

  def archiver?
    show? && manager_or_admin?
  end

  def purge?
    show?
  end

  def get_unavailable_elements?
    index?
  end

  def pointer?
    user && record.agents.include?(user)
  end

  def pointage_statut?
    pointer?
  end

  def services_for_adherent?
    new?
  end

  def agents_for_service?
    new?
  end

  def update_location?
    pointer?
  end

  def new_intervention_modele_pointage?
    manager_or_admin?
  end

  def create_intervention_modele_pointage?
    new_intervention_modele_pointage?
  end

  # --- Blocs affichés sur la page d'une intervention ---
  # L'adhérent ne voit que sa demande. La liste, elle, lui montre tout : cette
  # divergence est connue, signalée, et figée par les matrices de visibilité.

  # Agents, matériel et mots clés.
  def voir_assignation?
    show? && !adhérent?
  end

  # Dates réelles, temps, commentaires, photos et trajet.
  def voir_realisation?
    voir_assignation? && !record.repeter?
  end

  def voir_pointages?
    voir_assignation? && record.repeter?
  end

  # Avis de l'adhérent et évaluation des agents : jamais visibles de l'agent noté.
  def voir_compte_rendu?
    show? && !agent? && (record.validé? || record.refusé?)
  end

  def voir_activite?
    show? && manager_or_admin?
  end

  def voir_qrcode_pointage?
    can_see_qrcode_pointage_pdf? && record.repeter?
  end

  # La colonne « Agent » du tableau des pointages : un agent n'y voit que les siens.
  def voir_agent_des_pointages?
    voir_pointages? && !agent?
  end

  # --- Blocs et champs du formulaire ---
  # Ces prédicats ne dépendent que du rôle et du type d'intervention : le
  # formulaire de création porte un enregistrement neuf, sans organisation, sur
  # lequel `show?` serait faux.

  def saisir_description?
    !agent?
  end

  def choisir_adherent?
    !adhérent?
  end

  def choisir_service?
    !agent?
  end

  # Dates souhaitées et prévision météo : sans objet sur un modèle de pointage.
  def planifier_dates?
    !agent? && !record.repeter?
  end

  # Agents, matériel et mots clés.
  def saisir_assignation?
    !adhérent?
  end

  # Dates réelles, pause et temps passé.
  def saisir_realisation?
    saisir_assignation? && !record.repeter?
  end

  def saisir_commentaires?
    saisir_assignation?
  end

  def mots_cles_manager?
    manager_or_admin?
  end

  # Contrôleur Stimulus `dynamic-select` : cascade adhérent → service → agents.
  def cascade_services?
    manager_or_admin?
  end

  # Contrôleur Stimulus `verification-disponibilites` : conflits agents et outils.
  def verifier_disponibilites?
    !adhérent? && !record.repeter?
  end
end
