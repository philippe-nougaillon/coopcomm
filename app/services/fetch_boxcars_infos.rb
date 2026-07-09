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
    [Convention, User, Intervention]
  end

  def get_context
    "L'utilisateur qui demande des informations est #{User.adhérent.first.inspect}. 
    L'utilisateur ne connait pas forcement l'id des activeRecord, donc tu dois chercher par toi même en fonction du nom ou d'autres champs de type string des différentes tables."
  end
end