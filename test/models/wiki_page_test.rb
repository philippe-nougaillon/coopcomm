# frozen_string_literal: true

require 'test_helper'

class WikiPageTest < ActiveSupport::TestCase
  # Un attachement n'étant pas une colonne, audited n'écrit une ligne que si le
  # commentaire est renseigné : c'est ce commentaire qui fait exister l'audit.
  test 'pièce jointe : document ajouté → un audit portant le libellé' do
    page = wiki_pages(:blog)

    assert_difference -> { page.audits.count }, 1 do
      page.update!(document: piece('exemple.pdf', 'application/pdf'))
    end
    assert_match(/document ajouté/i, page.audits.last.comment)
  end

  test 'default_scope : page mise à la corbeille → hors de la liste' do
    page = wiki_pages(:guide)

    page.discard

    assert_not_includes WikiPage.all, page
  end

  test 'should_generate_new_friendly_id? : titre modifié → nouveau slug' do
    page = wiki_pages(:blog)
    ancien = page.slug

    page.update!(titre: 'Titre entièrement neuf')

    assert_not_equal ancien, page.reload.slug
  end

  private

  def piece(fichier, type)
    { io: File.open(Rails.root.join('test/fixtures/files', fichier)), filename: fichier, content_type: type }
  end
end
