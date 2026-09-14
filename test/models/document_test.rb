# frozen_string_literal: true

require 'test_helper'

class DocumentTest < ActiveSupport::TestCase
  test 'valide_document : PDF joint au document d\'un outil → accepté' do
    document = documents(:carte_grise)
    document.fichier = piece('exemple.pdf', 'application/pdf')

    document.valid?

    assert_empty document.errors[:fichier]
  end

  test 'valide_document : exécutable joint au document d\'un outil → refusé' do
    document = documents(:carte_grise)
    document.fichier = piece('exemple.png', 'application/x-msdownload', nom: 'notice.exe')

    document.valid?

    assert document.errors[:fichier].any?
  end

  # Un attachement n'étant pas une colonne, audited n'écrit une ligne que si le
  # commentaire est renseigné : c'est ce commentaire qui fait exister l'audit.
  test 'pièce jointe : fichier ajouté → un audit portant le libellé' do
    document = documents(:carte_grise)

    assert_difference -> { document.audits.count }, 1 do
      document.update!(fichier: piece('exemple.pdf', 'application/pdf'))
    end
    assert_match(/fichier ajouté/i, document.audits.last.comment)
  end

  private

  # `attach` sur un enregistrement persisté enregistre aussitôt : la pièce ne
  # serait plus « nouvelle » et échapperait à la validation. On assigne donc.
  def piece(fichier, type, nom: nil)
    { io: File.open(Rails.root.join('test/fixtures/files', fichier)), filename: nom || fichier, content_type: type }
  end
end
