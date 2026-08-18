# frozen_string_literal: true

require 'test_helper'

class ChaineVideEnNilTest < ActiveSupport::TestCase
  setup do
    @user = users(:bond)
  end

  test 'chaîne vide soumise par un formulaire → enregistrée en NULL' do
    @user.update!(address: '')

    assert_nil @user.reload.address
  end

  test 'chaîne faite d\'espaces → enregistrée en NULL' do
    @user.update!(memo: "   \n ")

    assert_nil @user.reload.memo
  end

  test 'champ déjà vide réenregistré → aucun audit' do
    @user.update!(address: nil)

    assert_no_difference -> { @user.audits.count } do
      @user.update!(address: '')
    end
  end

  test 'valeur réelle → jamais touchée' do
    @user.update!(address: '3 rue des Lilas')

    assert_equal '3 rue des Lilas', @user.reload.address
  end

  test 'colonne NOT NULL → laissée telle quelle, la validation fait son travail' do
    @user.email = ''

    assert_not @user.valid?
    assert_equal '', @user.email
  end

  test 'colonne qui n\'est pas du texte → jamais touchée' do
    intervention = interventions(:tonte_locaux)
    intervention.update!(temps_de_pause: 0)

    assert_equal 0, intervention.reload.temps_de_pause
  end
end
