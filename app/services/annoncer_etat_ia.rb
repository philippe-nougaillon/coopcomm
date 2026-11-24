# frozen_string_literal: true

# Remplace en direct l'annonce de l'état de l'IA sur la page d'analyse des conventions, chez tous ses lecteurs.
class AnnoncerEtatIa < ApplicationService
  def initialize(etat)
    @etat = etat
  end

  def call
    Rails.cache.delete(InstanceIa::CACHE)
    Turbo::StreamsChannel.broadcast_replace_to(:etat_ia, target: 'etat_ia', partial: 'conventions/etat_ia', locals: { etat: @etat })
  end
end
