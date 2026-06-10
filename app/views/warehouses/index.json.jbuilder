# frozen_string_literal: true

json.array! @warehouses, partial: 'warehouses/warehouse', as: :warehouse
