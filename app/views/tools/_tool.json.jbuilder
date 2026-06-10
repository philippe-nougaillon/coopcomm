# frozen_string_literal: true

json.extract! tool, :id, :name, :description, :organisation_id, :created_at, :updated_at
json.url tool_url(tool, format: :json)
