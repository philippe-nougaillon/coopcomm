# frozen_string_literal: true

require 'test_helper'

# Le concern PieceJointeAuditable généralise à tous les modèles ce qui n'existait
# que pour les photos d'intervention (cf. intervention_audit_photo_test.rb, qui
# couvre le cas has_many et la ré-émission des signed_id).
#
# Ce fichier couvre ce que la généralisation apporte en plus : le cas has_one,
# plusieurs attachements dans un même save, l'accord du libellé, et l'absence de
# commentaire quand aucune pièce jointe n'est ajoutée. On n'asserte jamais le
# libellé exact — seulement les mots porteurs de sens — pour rester robuste à
# une reformulation.
class PieceJointeAuditableTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  def png
    fixture_file_upload('exemple.png', 'image/png')
  end

  def pdf
    fixture_file_upload('exemple.pdf', 'application/pdf')
  end

  test 'has_one : un audit portant un message est créé alors qu\'aucune colonne ne change' do
    tool = tools(:rateau)

    assert_difference -> { tool.audits.count }, 1 do
      tool.update!(document: pdf)
    end
    assert_match(/document ajouté/i, tool.audits.last.comment)
  end

  test 'deux attachements dans le même save : les deux sont mentionnés' do
    tool = tools(:rateau)

    tool.update!(photo: png, document: pdf)

    comment = tool.audits.last.comment
    assert_match(/photo ajoutée/i, comment)
    assert_match(/document ajouté/i, comment)
  end

  test 'has_one : ré-émettre la pièce jointe existante ne produit pas de faux message' do
    tool = tools(:rateau)
    tool.update!(document: pdf)
    existant = tool.document

    tool.update!(name: 'Rateau renommé', document: existant.signed_id)

    assert_equal existant.blob_id, tool.reload.document.blob_id
    refute_match(/ajouté/i, tool.audits.last.comment.to_s)
  end

  test 'aucune pièce jointe ajoutée : aucun commentaire posé sur l\'audit' do
    tool = tools(:rateau)

    tool.update!(description: 'Description modifiée')

    assert_nil tool.audits.last.comment
  end

  test 'has_many : le libellé s\'accorde au nombre de pièces jointes' do
    intervention = Intervention.create!(description: 'Photo test',
                                        adherent_id: users(:weil).id,
                                        service: services(:informatique),
                                        début_prévue: 1.day.from_now,
                                        fin_prévue: 1.day.from_now + 1.hour)

    intervention.update!(photos: [png])
    assert_match(/1 photo ajoutée/i, intervention.audits.last.comment)

    intervention.update!(photos: intervention.photos.map(&:signed_id) + [png, png])
    assert_match(/2 photos ajoutées/i, intervention.audits.last.comment)
  end
end
