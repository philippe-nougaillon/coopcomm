# frozen_string_literal: true

require 'test_helper'

class PieceJointeValidableTest < ActiveSupport::TestCase
  # `attach` sur un enregistrement persisté enregistre aussitôt : la pièce ne
  # serait plus « nouvelle » et échapperait à la validation. On assigne donc.
  def pièce(fichier, type, nom: nil)
    { io: File.open(Rails.root.join('test/fixtures/files', fichier)), filename: nom || fichier, content_type: type }
  end

  test "un PDF déposé comme photo d'intervention est refusé" do
    intervention = interventions(:nouvelle_intervention)
    intervention.photos = [{ io: File.open(Rails.root.join('test/fixtures/files/exemple.pdf')),
                             filename: 'exemple.pdf', content_type: 'application/pdf' }]

    intervention.valid?

    assert intervention.errors[:photos].any?, 'un PDF ne doit pas être accepté comme photo'
  end

  test "un PNG déposé comme photo d'intervention est accepté" do
    intervention = interventions(:nouvelle_intervention)
    intervention.photos = [{ io: File.open(Rails.root.join('test/fixtures/files/exemple.png')),
                             filename: 'exemple.png', content_type: 'image/png' }]

    intervention.valid?

    assert_empty intervention.errors[:photos]
  end

  test "une photo d'intervention au-delà du plafond de taille est refusée" do
    intervention = interventions(:nouvelle_intervention)
    intervention.photos = [{ io: File.open(Rails.root.join('test/fixtures/files/exemple.png')),
                             filename: 'exemple.png', content_type: 'image/png' }]
    intervention.photos.attachments.select(&:new_record?).each do |piece|
      piece.blob.byte_size = 11.megabytes
    end

    intervention.valid?

    assert intervention.errors[:photos].any?, 'au-delà de 10 Mo la photo doit être refusée'
  end

  test "un AVIF, format annoncé par les deux formulaires, est accepté comme photo d'intervention" do
    intervention = interventions(:nouvelle_intervention)
    intervention.photos = [{ io: File.open(Rails.root.join('test/fixtures/files/exemple.png')),
                             filename: 'exemple.avif', content_type: 'image/avif' }]

    intervention.valid?

    assert_empty intervention.errors[:photos]
  end

  test 'un PDF est accepté comme document de convention' do
    convention = conventions(:convention_paris)
    convention.document = pièce('exemple.pdf', 'application/pdf')

    convention.valid?

    assert_empty convention.errors[:document]
  end

  test 'une photo du document signé est acceptée comme document de convention' do
    convention = conventions(:convention_paris)
    convention.document = pièce('exemple.png', 'image/jpeg', nom: 'convention_signée.jpg')

    convention.valid?

    assert_empty convention.errors[:document]
  end

  test 'un tableur est accepté comme document joint à une documentation' do
    page = wiki_pages(:guide_public)
    page.document = pièce('import_users.xls', 'application/vnd.ms-excel', nom: 'guide.xls')

    page.valid?

    assert_empty page.errors[:document]
  end

  test "un HEIC, format natif des téléphones, est accepté comme photo d'outil" do
    tool = tools(:rateau)
    tool.photo = pièce('exemple.png', 'image/heic', nom: 'photo.heic')

    tool.valid?

    assert_empty tool.errors[:photo]
  end

  test "un exécutable est refusé comme document d'outil" do
    tool = tools(:rateau)
    tool.document = pièce('exemple.png', 'application/x-msdownload', nom: 'notice.exe')

    tool.valid?

    assert tool.errors[:document].any?, 'un exécutable ne doit pas être accepté'
  end

  test "le type réel d'un fichier à l'extension renommée prime sur le type annoncé" do
    png = Tempfile.new(['faux', '.pdf'], binmode: true)
    png.write("\x89PNG\r\n\x1A\n\x00\x00\x00\rIHDR".b)
    png.rewind

    intervention = interventions(:nouvelle_intervention)
    intervention.photos = [{ io: png, filename: 'faux.pdf', content_type: 'application/pdf' }]

    assert_equal 'image/png', intervention.photos.attachments.last.blob.content_type
  end

  # ==== Taille maximale ====

  test 'un document de plus de 20 Mo est refusé' do
    convention = conventions(:convention_paris)
    convention.document = pièce('exemple.pdf', 'application/pdf')
    convention.document.attachment.blob.byte_size = 21.megabytes

    convention.valid?

    assert_includes convention.errors[:document].join, '20 Mo maximum'
  end

  test 'un document de moins de 20 Mo est accepté' do
    convention = conventions(:convention_paris)
    convention.document = pièce('exemple.pdf', 'application/pdf')
    convention.document.attachment.blob.byte_size = 19.megabytes

    convention.valid?

    assert_empty convention.errors[:document]
  end

  test 'une image de plus de 10 Mo est refusée' do
    tool = tools(:rateau)
    tool.photo = pièce('exemple.png', 'image/png')
    tool.photo.attachment.blob.byte_size = 11.megabytes

    tool.valid?

    assert_includes tool.errors[:photo].join, '10 Mo maximum'
  end

  # ==== Source unique des formats et de la taille ====

  test 'les règles de pièces jointes des modèles sont exposées aux formulaires' do
    assert_equal({ types: PieceJointeValidable::DOCUMENTS, max_octets: 20.megabytes },
                 Convention.regles_pieces_jointes['document'])
    assert_equal({ types: PieceJointeValidable::IMAGES, max_octets: 10.megabytes },
                 Intervention.regles_pieces_jointes['photos'])
    assert_equal({ types: PieceJointeValidable::IMAGES, max_octets: 10.megabytes },
                 Tool.regles_pieces_jointes['photo'])
    assert_equal({ types: PieceJointeValidable::DOCUMENTS, max_octets: 20.megabytes },
                 Tool.regles_pieces_jointes['document'])
  end

  test "l'attribut accept du champ de fichier liste les extensions et les types MIME" do
    accept = PieceJointeValidable.accept(%w[application/pdf image/jpeg])

    assert_equal '.pdf,.jpg,.jpeg,application/pdf,image/jpeg', accept
  end

  test 'le libellé des formats du champ de fichier ne liste que les extensions' do
    assert_equal 'PDF, JPG, JPEG', PieceJointeValidable.libellé_formats(%w[application/pdf image/jpeg])
  end

  test 'chaque type de document accepté a une extension connue' do
    sans_extension = PieceJointeValidable::DOCUMENTS.reject { |type| PieceJointeValidable::EXTENSIONS.key?(type) }

    assert_empty sans_extension,
                 "ces types ne produiraient aucune extension dans l'attribut accept des formulaires : #{sans_extension.inspect}"
  end

  # ==== Sentinelle : aucune pièce jointe ne doit échapper aux deux concerns ====

  test 'toute pièce jointe du domaine est validée et auditée (sentinelle)' do
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
