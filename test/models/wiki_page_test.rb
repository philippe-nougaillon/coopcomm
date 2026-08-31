# frozen_string_literal: true

require 'test_helper'

class WikiPageTest < ActiveSupport::TestCase
  test 'la recherche retrouve une documentation par un mot de son titre' do
    résultats = WikiPage.search_titre_and_contenu('Réserver')

    assert_includes résultats, wiki_pages(:guide_public)
    assert_not_includes résultats, wiki_pages(:faq_publique)
  end

  test 'la recherche retrouve une documentation par un mot de son contenu' do
    résultats = WikiPage.search_titre_and_contenu('matériel')

    assert_includes résultats, wiki_pages(:guide_public)
    assert_not_includes résultats, wiki_pages(:faq_publique)
  end

  test 'la recherche retrouve une documentation par le début d’un mot de son contenu' do
    résultats = WikiPage.search_titre_and_contenu('scann')

    assert_includes résultats, wiki_pages(:faq_publique)
    assert_not_includes résultats, wiki_pages(:guide_public)
  end

  test 'la recherche ne retourne aucune documentation quand aucun titre ni aucun contenu ne correspond' do
    assert_empty WikiPage.search_titre_and_contenu('astrophysique')
  end

  test 'la recherche ignore les documentations mises à la corbeille' do
    wiki_pages(:guide_public).discard

    assert_not_includes WikiPage.search_titre_and_contenu('matériel'), wiki_pages(:guide_public)
  end

  test 'une documentation mise à la corbeille sort de la liste des documentations' do
    page = wiki_pages(:guide_public)

    page.discard

    assert_not_includes WikiPage.all, page
    assert_includes WikiPage.with_discarded, page
  end
end
