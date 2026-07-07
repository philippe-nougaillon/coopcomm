# frozen_string_literal: true

json.extract! warehouse, :id, :name, :localisation, :created_at, :updated_at
json.url warehouse_url(warehouse, format: :json)
