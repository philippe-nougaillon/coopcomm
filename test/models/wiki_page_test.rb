# frozen_string_literal: true

require 'test_helper'

class WikiPageTest < ActiveSupport::TestCase
  test 'la recherche retrouve une documentation par un mot de son titre' do
    résultats = WikiPage.search_titre_and_contenu('Réserver')

    assert_includes résultats, wiki_pages(:guide_public)
    assert_not_includes résultats, wiki_pages(:faq_publique)
  end

  test 'la recherche retrouve une documentation par un mot de son sous-titre' do
    résultats = WikiPage.search_titre_and_contenu('Pas à pas')

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

  # ==================== PIÈCES JOINTES DANS LE CONTENU (TRIX) ====================
  # `valide_piece_jointe_riche` protège contre l'upload de fichiers non
  # autorisés (sécurité) ou trop volumineux (stockage) directement dans le
  # rich text, un point d'entrée distinct de `document` et `photo`.

  test 'refuse un nouveau fichier de format non autorisé collé dans le contenu' do
    blob = blob_attaché(nom_fichier: 'virus.exe', content_type: 'application/x-msdownload')
    page = wiki_page_valide(contenu: html_attachment_pour(blob))

    assert_not page.valid?
    assert_includes page.errors.full_messages.join(' '), 'format non pris en charge'
  end

  test 'refuse un nouveau fichier trop volumineux collé dans le contenu' do
    blob = blob_attaché(nom_fichier: 'gros.pdf', content_type: 'application/pdf', octets: 21.megabytes)
    page = wiki_page_valide(contenu: html_attachment_pour(blob))

    assert_not page.valid?
    assert_includes page.errors.full_messages.join(' '), 'trop volumineux'
  end

  test 'accepte un fichier valide (PDF, taille correcte) collé dans le contenu' do
    blob = blob_attaché(nom_fichier: 'note.pdf', content_type: 'application/pdf', octets: 1.megabyte)
    page = wiki_page_valide(contenu: html_attachment_pour(blob))

    assert page.valid?, page.errors.full_messages.to_sentence
  end

  test 'ne revalide pas un fichier déjà présent quand on ne touche que le titre' do
    page = wiki_page_valide(contenu: 'Contenu initial')
    page.save!

    blob_invalide = blob_attaché(nom_fichier: 'vieux.exe', content_type: 'application/x-msdownload')
    page.rich_text_content.update_column(:body, html_attachment_pour(blob_invalide))
    page.reload

    page.titre = 'Nouveau titre'

    assert page.valid?, page.errors.full_messages.to_sentence
  end

  test 'revalide si on ajoute un nouveau fichier invalide à un contenu existant valide' do
    blob_valide = blob_attaché(nom_fichier: 'ok.pdf', content_type: 'application/pdf')
    page = wiki_page_valide(contenu: html_attachment_pour(blob_valide))
    page.save!

    blob_invalide = blob_attaché(nom_fichier: 'nouveau.exe', content_type: 'application/x-msdownload')
    page.contenu = html_attachment_pour(blob_valide) + html_attachment_pour(blob_invalide)

    assert_not page.valid?
    assert_includes page.errors.full_messages.join(' '), 'format non pris en charge'
  end

  # ==================== /PIÈCES JOINTES DANS LE CONTENU (TRIX) ====================

  private

  def blob_attaché(nom_fichier:, content_type:, octets: 1.kilobyte)
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new('x' * octets),
      filename: nom_fichier,
      content_type: content_type
    )
  end

  def html_attachment_pour(blob)
    %(<action-text-attachment sgid="#{blob.attachable_sgid}" content-type="#{blob.content_type}" filename="#{blob.filename}" filesize="#{blob.byte_size}"></action-text-attachment>)
  end

 # Construit une WikiPage valide par ailleurs (titre, sous_titre, etc.), pour
  # isoler les tests sur la seule validation du contenu riche.
  def wiki_page_valide(**attrs)
    WikiPage.new(
      titre: 'Titre de test',
      sous_titre: 'Sous-titre de test',
      catégorie: :guide,
      publiée: true,
      private: false,
      épinglée: false,
      poids: 99,
      user: users(:hidalgo),
      **attrs
    )
  end
end