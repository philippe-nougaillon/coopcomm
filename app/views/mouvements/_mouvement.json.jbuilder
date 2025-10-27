json.extract! mouvement, :id, :tool_id, :état, :slug, :created_at, :updated_at
json.url mouvement_url(mouvement, format: :json)
