# frozen_string_literal: true

require 'test_helper'

class ExporterPageWikiTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  test 'chaque fichier collé dans le contenu est exporté avec ses octets, sans rien qui désigne l’instance' do
    image = ActiveStorage::Blob.create_and_upload!(io: File.open('test/fixtures/files/exemple.png'),
                                                   filename: 'exemple.png', content_type: 'image/png')
    page = documentation(contenu: %(<div>Le plan</div><action-text-attachment sgid="#{image.attachable_sgid}" content-type="image/png" url="https://demo.exemple.fr/rails/active_storage/blobs/redirect/x/exemple.png" caption="Le plan"></action-text-attachment>))

    export = ExporterPageWiki.call(page)

    assert_equal({ filename: 'exemple.png', content_type: 'image/png',
                   data: Base64.strict_encode64(File.binread('test/fixtures/files/exemple.png')) },
                 export[:fichiers]['fichier-0'])
    assert_includes export[:contenu], 'sgid="fichier-0"'
    assert_includes export[:contenu], 'caption="Le plan"'
    assert_not_includes export[:contenu], image.attachable_sgid
    assert_not_includes export[:contenu], 'demo.exemple.fr'
  end

  test 'la photo et le document sont exportés avec leurs octets' do
    page = documentation(contenu: nil)
    page.update!(photo: fixture_file_upload('exemple.png', 'image/png'),
                 document: fixture_file_upload('exemple.pdf', 'application/pdf'))

    export = ExporterPageWiki.call(page)

    assert_equal Base64.strict_encode64(File.binread('test/fixtures/files/exemple.png')), export[:photo][:data]
    assert_equal 'exemple.pdf', export[:document][:filename]
    assert_equal Base64.strict_encode64(File.binread('test/fixtures/files/exemple.pdf')), export[:document][:data]
  end

  test 'une page sans pièce jointe est exportée sans fichier, sans photo ni document' do
    export = ExporterPageWiki.call(wiki_pages(:guide_public))

    assert_equal 'Réserver un outil', export[:titre]
    assert_empty export[:fichiers]
    assert_nil export[:photo]
    assert_nil export[:document]
  end

  private

  def documentation(contenu:)
    WikiPage.create!(titre: 'Guide à copier', sous_titre: 'Avec ses pièces jointes', catégorie: :guide,
                     publiée: true, private: false, épinglée: false, poids: 30, user: users(:hidalgo),
                     contenu: contenu)
  end
end
