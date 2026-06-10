# frozen_string_literal: true

json.array! @organisations, partial: 'organisations/organisation', as: :organisation
