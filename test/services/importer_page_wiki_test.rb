# frozen_string_literal: true

require 'test_helper'
require_relative '../support/page_wiki_exportee'

class ImporterPageWikiTest < ActiveSupport::TestCase
  include PageWikiExportee

  setup do
    @auteur = users(:administrateur_paris)
    @origine = { 'instance' => 'demo.exemple.fr', 'slug' => 'reserver-une-benne', 'par' => 'philippe.nougaillon@aikku.eu' }
  end

  test 'la page importée reprend la page d’origine avec l’auteur et la publication demandés' do
    page = ImporterPageWiki.call(page_wiki_exportée, auteur: @auteur, publiée: false, origine: @origine)

    page.reload
    assert_equal 'Réserver une benne', page.titre
    assert_equal 'Depuis la fiche outil', page.sous_titre
    assert_equal 'guide', page.catégorie
    assert_equal 4, page.poids
    assert page.épinglée
    assert_not page.private
    assert_not page.publiée
    assert_equal @auteur, page.user
  end

  test 'chaque fichier du contenu est recréé sur l’instance et le contenu le désigne' do
    page = ImporterPageWiki.call(page_wiki_exportée, auteur: @auteur, publiée: true, origine: @origine)

    image = page.reload.contenu.body.attachments.sole
    assert_kind_of ActiveStorage::Blob, image.attachable
    assert_equal File.binread('test/fixtures/files/exemple.png'), image.attachable.download
    assert_equal 'Le plan', image.caption
    assert_equal Rails.application.routes.url_helpers.rails_blob_path(image.attachable, only_path: true), image.node['url']
  end

  test 'la photo et le document sont recréés sur l’instance' do
    page = ImporterPageWiki.call(page_wiki_exportée, auteur: @auteur, publiée: true, origine: @origine)

    assert_equal File.binread('test/fixtures/files/exemple.png'), page.reload.photo.download
    assert_equal File.binread('test/fixtures/files/exemple.pdf'), page.document.download
  end

  test 'l’audit de création nomme l’instance et la page d’origine, et n’a pas d’auteur' do
    page = ImporterPageWiki.call(page_wiki_exportée, auteur: @auteur, publiée: true, origine: @origine)

    audit = page.audits.find_by!(action: 'create')
    assert_match 'Copiée depuis demo.exemple.fr, page reserver-une-benne, par philippe.nougaillon@aikku.eu', audit.comment
    assert_nil audit.user
  end

  test 'un titre déjà pris crée une seconde page sans toucher la première' do
    page_existante = wiki_pages(:guide_public)

    page = ImporterPageWiki.call(page_wiki_exportée.merge('titre' => page_existante.titre), auteur: @auteur,
                                                                                         publiée: true, origine: @origine)

    assert_not_equal page_existante, page
    assert_not_equal page_existante.slug, page.slug
    assert_equal users(:hidalgo), page_existante.reload.user
  end

  test 'un import refusé ne laisse ni page ni fichier derrière lui' do
    page_refusée = page_wiki_exportée.merge('fichiers' => { 'fichier-0' => fichier_wiki_exporté('responseMeteoConcept.json', 'application/json') })

    assert_no_difference(['WikiPage.count', 'ActiveStorage::Blob.count']) do
      assert_raises(ActiveRecord::RecordInvalid) do
        ImporterPageWiki.call(page_refusée, auteur: @auteur, publiée: true, origine: @origine)
      end
    end
  end
end
