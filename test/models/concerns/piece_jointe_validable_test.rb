# frozen_string_literal: true

require 'test_helper'

class PieceJointeValidableTest < ActiveSupport::TestCase
  # `attach` sur un enregistrement persisté enregistre aussitôt : la pièce ne
  # serait plus « nouvelle » et échapperait à la validation. On assigne donc.
  def pièce(fichier, type, nom: nil)
    { io: File.open(Rails.root.join('test/fixtures/files', fichier)), filename: nom || fichier, content_type: type }
  end

  test 'valide_image : PDF déposé comme photo d\'intervention → refusé' do
    intervention = interventions(:nouvelle_intervention)
    intervention.photos = [{ io: File.open(Rails.root.join('test/fixtures/files/exemple.pdf')),
                             filename: 'exemple.pdf', content_type: 'application/pdf' }]

    intervention.valid?

    assert intervention.errors[:photos].any?, 'un PDF ne doit pas être accepté comme photo'
  end

  test 'valide_image : PNG comme photo d\'intervention → accepté' do
    intervention = interventions(:nouvelle_intervention)
    intervention.photos = [{ io: File.open(Rails.root.join('test/fixtures/files/exemple.png')),
                             filename: 'exemple.png', content_type: 'image/png' }]

    intervention.valid?

    assert_empty intervention.errors[:photos]
  end

  test 'taille : pièce jointe au-delà du plafond → refusée' do
    intervention = interventions(:nouvelle_intervention)
    intervention.photos = [{ io: File.open(Rails.root.join('test/fixtures/files/exemple.png')),
                             filename: 'exemple.png', content_type: 'image/png' }]
    intervention.photos.attachments.select(&:new_record?).each do |piece|
      piece.blob.byte_size = 11.megabytes
    end

    intervention.valid?

    assert intervention.errors[:photos].any?, 'au-delà de 10 Mo la photo doit être refusée'
  end

  test 'valide_image : AVIF, annoncé par les deux formulaires → accepté' do
    intervention = interventions(:nouvelle_intervention)
    intervention.photos = [{ io: File.open(Rails.root.join('test/fixtures/files/exemple.png')),
                             filename: 'exemple.avif', content_type: 'image/avif' }]

    intervention.valid?

    assert_empty intervention.errors[:photos]
  end

  test 'valide_document : PDF comme document de convention → accepté' do
    convention = conventions(:convention_paris)
    convention.document = pièce('exemple.pdf', 'application/pdf')

    convention.valid?

    assert_empty convention.errors[:document]
  end

  test 'valide_document : photo du document signé → acceptée' do
    convention = conventions(:convention_paris)
    convention.document = pièce('exemple.png', 'image/jpeg', nom: 'convention_signée.jpg')

    convention.valid?

    assert_empty convention.errors[:document]
  end

  test 'valide_document : tableur comme document de page wiki → accepté' do
    page = wiki_pages(:guide_public)
    page.document = pièce('import_users.xls', 'application/vnd.ms-excel', nom: 'guide.xls')

    page.valid?

    assert_empty page.errors[:document]
  end

  test 'valide_image : HEIC, format natif des téléphones → accepté' do
    tool = tools(:rateau)
    tool.photo = pièce('exemple.png', 'image/heic', nom: 'photo.heic')

    tool.valid?

    assert_empty tool.errors[:photo]
  end

  test 'valide_document : exécutable comme document d\'outil → refusé' do
    tool = tools(:rateau)
    tool.document = pièce('exemple.png', 'application/x-msdownload', nom: 'notice.exe')

    tool.valid?

    assert tool.errors[:document].any?, 'un exécutable ne doit pas être accepté'
  end

  test 'validation : extension renommée → le type réel prime sur celui annoncé' do
    png = Tempfile.new(['faux', '.pdf'], binmode: true)
    png.write("\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR".b)
    png.rewind

    intervention = interventions(:nouvelle_intervention)
    intervention.photos = [{ io: png, filename: 'faux.pdf', content_type: 'application/pdf' }]

    assert_equal 'image/png', intervention.photos.attachments.last.blob.content_type
  end

  # ==== Taille maximale ====

  test 'taille : document de plus de 20 Mo → refusé' do
    convention = conventions(:convention_paris)
    convention.document = pièce('exemple.pdf', 'application/pdf')
    convention.document.attachment.blob.byte_size = 21.megabytes

    convention.valid?

    assert_includes convention.errors[:document].join, '20 Mo maximum'
  end

  test 'taille : document de moins de 20 Mo → accepté' do
    convention = conventions(:convention_paris)
    convention.document = pièce('exemple.pdf', 'application/pdf')
    convention.document.attachment.blob.byte_size = 19.megabytes

    convention.valid?

    assert_empty convention.errors[:document]
  end

  test 'taille : image au-delà de 10 Mo → refusée' do
    tool = tools(:rateau)
    tool.photo = pièce('exemple.png', 'image/png')
    tool.photo.attachment.blob.byte_size = 11.megabytes

    tool.valid?

    assert_includes tool.errors[:photo].join, '10 Mo maximum'
  end

  # ==== Source unique des formats et de la taille ====

  test 'regles_pieces_jointes : règles des modèles → exposées aux formulaires' do
    assert_equal({ types: PieceJointeValidable::DOCUMENTS, max_octets: 20.megabytes },
                 Convention.regles_pieces_jointes['document'])
    assert_equal({ types: PieceJointeValidable::IMAGES, max_octets: 10.megabytes },
                 Intervention.regles_pieces_jointes['photos'])
    assert_equal({ types: PieceJointeValidable::IMAGES, max_octets: 10.megabytes },
                 Tool.regles_pieces_jointes['photo'])
    assert_equal({ types: PieceJointeValidable::DOCUMENTS, max_octets: 20.megabytes },
                 Tool.regles_pieces_jointes['document'])
  end

  test 'accept : rendu du champ → extensions ET types MIME' do
    accept = PieceJointeValidable.accept(%w[application/pdf image/jpeg])

    assert_equal '.pdf,.jpg,.jpeg,application/pdf,image/jpeg', accept
  end

  test 'libellé des formats : rendu du champ → seulement les extensions' do
    assert_equal 'PDF, JPG, JPEG', PieceJointeValidable.libellé_formats(%w[application/pdf image/jpeg])
  end

  test 'regles_pieces_jointes : chaque type accepté → une extension connue' do
    sans_extension = PieceJointeValidable::DOCUMENTS.reject { |type| PieceJointeValidable::EXTENSIONS.key?(type) }

    assert_empty sans_extension,
                 "ces types ne produiraient aucune extension dans l'attribut accept des formulaires : #{sans_extension.inspect}"
  end

  # ==== Sentinelle : aucune pièce jointe ne doit échapper aux deux concerns ====

  test 'sentinelle : tout attachement du domaine → validé et audité' do
    Rails.application.eager_load!

    ApplicationRecord.descendants.select { |modèle| modèle.attachment_reflections.any? }.each do |modèle|
      assert_includes modèle.ancestors, PieceJointeValidable,
                      "#{modèle} a une pièce jointe sans `include PieceJointeValidable`"
      assert_includes modèle.ancestors, PieceJointeAuditable,
                      "#{modèle} a une pièce jointe sans `include PieceJointeAuditable`"

      modèle.attachment_reflections.each_key do |nom|
        assert modèle.regles_pieces_jointes.key?(nom),
               "#{modèle}##{nom} n'a ni `valide_image` ni `valide_document` : n'importe quel fichier serait accepté"
      end
    end
  end
end
