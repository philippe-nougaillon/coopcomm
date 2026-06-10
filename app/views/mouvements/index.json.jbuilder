# frozen_string_literal: true

json.array! @mouvements, partial: 'mouvements/mouvement', as: :mouvement
