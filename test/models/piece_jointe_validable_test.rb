# frozen_string_literal: true

require 'test_helper'

class PieceJointeValidableTest < ActiveSupport::TestCase
  test "refuse un PDF comme photo d'intervention" do
    intervention = interventions(:nouvelle_intervention)
    intervention.photos = [{ io: File.open(Rails.root.join('test/fixtures/files/exemple.pdf')),
                             filename: 'exemple.pdf', content_type: 'application/pdf' }]

    intervention.valid?

    assert intervention.errors[:photos].any?, 'un PDF ne doit pas être accepté comme photo'
  end

  test "accepte une image PNG comme photo d'intervention" do
    intervention = interventions(:nouvelle_intervention)
    intervention.photos = [{ io: File.open(Rails.root.join('test/fixtures/files/exemple.png')),
                             filename: 'exemple.png', content_type: 'image/png' }]

    intervention.valid?

    assert_empty intervention.errors[:photos]
  end

  test 'refuse une pièce jointe au-delà de la taille maximale' do
    intervention = interventions(:nouvelle_intervention)
    intervention.photos = [{ io: File.open(Rails.root.join('test/fixtures/files/exemple.png')),
                             filename: 'exemple.png', content_type: 'image/png' }]
    intervention.photos.attachments.select(&:new_record?).each do |piece|
      piece.blob.byte_size = 11.megabytes
    end

    intervention.valid?

    assert intervention.errors[:photos].any?, 'au-delà de 10 Mo la photo doit être refusée'
  end

  test 'accepte un PDF comme document de convention' do
    convention = conventions(:convention_paris)
    convention.document.attach(io: File.open(Rails.root.join('test/fixtures/files/exemple.pdf')),
                               filename: 'exemple.pdf', content_type: 'application/pdf')

    convention.valid?

    assert_empty convention.errors[:document]
  end
end
