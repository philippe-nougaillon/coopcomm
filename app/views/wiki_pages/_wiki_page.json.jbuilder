# frozen_string_literal: true

json.extract! wiki_page, :id, :nom, :publié, :poids, :created_at, :updated_at
json.url wiki_page_url(wiki_page, format: :json)
