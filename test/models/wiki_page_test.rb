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

  test 'un manager voit les documentations privées et les documentations non publiées' do
    résultats = WikiPage.by_role_for(users(:hidalgo))

    assert_includes résultats, wiki_pages(:blog_public)
    assert_includes résultats, wiki_pages(:blog_privé)
    assert_includes résultats, wiki_pages(:blog_non_publié)
  end

  test 'un administrateur voit les documentations privées et les documentations non publiées' do
    résultats = WikiPage.by_role_for(users(:administrateur_paris))

    assert_includes résultats, wiki_pages(:blog_public)
    assert_includes résultats, wiki_pages(:blog_privé)
    assert_includes résultats, wiki_pages(:blog_non_publié)
  end

  test 'un adhérent voit les documentations privées mais aucune documentation non publiée' do
    résultats = WikiPage.by_role_for(users(:weil))

    assert_includes résultats, wiki_pages(:blog_public)
    assert_includes résultats, wiki_pages(:blog_privé)
    assert_not_includes résultats, wiki_pages(:blog_non_publié)
  end

  # ==================== TESTS CRITIQUES ====================
  # `by_role_for` est le seul filtre entre les notes internes des gestionnaires
  # et les deux populations qui n'ont rien à y lire : les agents, et le public,
  # la documentation étant le seul écran ouvert sans authentification.

  test 'un agent ne voit ni les documentations privées ni les documentations non publiées (critique)' do
    résultats = WikiPage.by_role_for(users(:martin_technique_paris))

    assert_includes résultats, wiki_pages(:blog_public)
    assert_not_includes résultats, wiki_pages(:blog_privé)
    assert_not_includes résultats, wiki_pages(:blog_non_publié)
  end

  test 'un utilisateur non connecté ne voit ni les documentations privées ni les documentations non publiées (critique)' do
    résultats = WikiPage.by_role_for(nil)

    assert_includes résultats, wiki_pages(:blog_public)
    assert_not_includes résultats, wiki_pages(:blog_privé)
    assert_not_includes résultats, wiki_pages(:blog_non_publié)
  end

  # ==================== /TESTS CRITIQUES ====================
end
