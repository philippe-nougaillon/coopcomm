# frozen_string_literal: true

require 'test_helper'

# L'ajout de photo(s) sur une intervention doit laisser une trace dans l'audit
# (cf. before_save :audit_photo_added dans Intervention). Deux garanties non
# évidentes sont protégées ici — on n'asserte PAS le libellé exact, pour rester
# robuste à une reformulation du message :
#   1. un audit AVEC message est créé alors qu'attacher une photo ne change
#      aucune colonne (dépend du comportement `update_with_comment_only` d'audited) ;
#   2. ré-émettre une photo existante (comportement du formulaire) ne déclenche
#      PAS un faux « photo ajoutée » (c'est tout l'intérêt de la garde new_record?).
#
# ⚠ Les photos sont assignées via le WRITER `photos=` (comme le formulaire), PAS
# via `.attach` : sur un record persisté, `.attach` écrit l'attachement sans
# repasser par le `save`, donc sans déclencher le callback.
class InterventionAuditPhotoTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  def photo_upload
    fixture_file_upload('exemple.png', 'image/png')
  end

  def intervention_valide
    Intervention.create!(description: 'Photo test',
                         adherent_id: users(:weil).id,
                         service: services(:informatique),
                         début_prévue: 1.day.from_now,
                         fin_prévue: 1.day.from_now + 1.hour)
  end

  test "ajout d'une photo : un audit portant un message est créé" do
    intervention = intervention_valide

    assert_difference -> { intervention.audits.count }, 1 do
      intervention.update!(photos: [photo_upload])
    end
    assert_match(/photo/i, intervention.audits.last.comment)
  end

  test "ré-émission d'une photo existante : aucun faux message d'ajout" do
    intervention = intervention_valide
    intervention.update!(photos: [photo_upload])
    existante = intervention.photos.first

    # Le formulaire ré-émet le signed_id de la photo existante (String), sans
    # nouveau fichier : rien n'a été « ajouté ».
    intervention.update!(description: 'Titre modifié', photos: [existante.signed_id])

    assert_equal 1, intervention.reload.photos.count
    refute_match(/photo/i, intervention.audits.last.comment.to_s)
  end
end
