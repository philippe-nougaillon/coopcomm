# frozen_string_literal: true

# Prototype de l'appel de boxcars, en développement
class FetchBoxcarsInfos < ApplicationService
  def initialize
    # Outil boxcars utilisé pour la requete
    boxcars = [Boxcars::ActiveRecord.new(
      models: self.get_models,
      context: self.get_context
    )]

    # Train permet de rebondir sur ses propres réponses pour épurer la réponse
    @boxcars_builder = Boxcars.train.new(boxcars: boxcars)
  end

  def call(demande)
    @boxcars_builder.run(demande)
  end

  def get_models
    [Cotation, User, Service]
  end

  def get_context
    "
    Le workflow_state peut avoir #{Cotation.workflow_state_humanized}, en minuscules.
    "
    # [Convention, User]
    # "
    # Adhérent is a User.
    # "
    # [Tool, Mouvement]
    # "
    # Tool has many Mouvement.
    # Mouvement has etats (panne, réservé)
    # "
    # [User, Absence]
    # "
    # Agent is a User.
    # "
    # [Intervention, User, AgentIntervention, Service]
    # " 
    # Agent is a User.
    # Adhérent is a User.
    # User belongs to Service.
    # Intervention belongs to many Agent.
    # "
    # Autre
    # "
    # User has many services, service has many users, service has one organisation
    # User has one organisation through the services of the user
    # Returns only users and services associated with organisation : #{User.adhérent.first.organisation.inspect}.
    # If the records in the response are not associated with organisation_id : #{User.adhérent.first.organisation.id}, you need to return 'I made a mistake'.
    # L'adhérent a une convention, associé à un service.
    # Cette convention appartient à un seul adhérent, à un seul service, est dans une période (avec une date de début et de fin), à un nombre d'heures conventionnées, et un nombre d'heures consommées (calculé à partir des interventions de l'adhérent et du service dans la période de la convention, via la fonction temps_total_interventions dans le model convention)
    # L'utilisateur qui demande des informations est #{User.adhérent.first.inspect}.
    # L'utilisateur ne connait pas forcement l'id des activeRecord, donc tu dois chercher par toi même en fonction du nom ou d'autres champs de type string des différentes tables.
    # Date d'aujourd'hui #{Time.zone.now}.
    # "
  end
end