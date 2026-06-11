# frozen_string_literal: true

json.array! @wiki_pages, partial: 'wiki_pages/wiki_page', as: :wiki_page
