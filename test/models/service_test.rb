# frozen_string_literal: true

require 'test_helper'

class ServiceTest < ActiveSupport::TestCase
  # ==== TEST CRITIQUE : un service doit avoir un nom ====
  # Un service sans nom apparaît comme une entrée VIDE dans le sélecteur de services
  # du formulaire utilisateur : impossible de distinguer un vrai service d'une ligne
  # accidentelle, et les utilisateurs qu'on y rattache semblent « sans service ».

  # ==================== TESTS CRITIQUES ====================

  test 'un service sans nom est invalide (critique)' do
    [nil, '', '   '].each do |nom|
      service = Service.new(nom: nom, organisation: organisations(:mairie_paris))

      assert_not service.valid?, "un nom #{nom.inspect} ne doit pas être accepté"
      assert_includes service.errors[:nom], 'doit être rempli(e)'
    end
  end
  # ==================== /TESTS CRITIQUES ====================

  test 'un service avec un nom est valide' do
    assert Service.new(nom: 'Voirie', organisation: organisations(:mairie_paris)).valid?
  end

  test 'le nom est normalisé' do
    service = Service.create!(nom: '  espaces verts  ', organisation: organisations(:mairie_paris))

    assert_equal 'Espaces verts', service.nom
  end

  test 'deux services de la même organisation ne peuvent pas porter le même nom' do
    doublon = Service.new(nom: services(:technique).nom, organisation: organisations(:mairie_paris))

    assert_not doublon.valid?
    assert_includes doublon.errors[:nom], 'est déjà utilisé(e)'
  end

  test 'deux organisations peuvent avoir un service du même nom' do
    assert Service.new(nom: services(:technique).nom, organisation: organisations(:mairie_marseille)).valid?
  end
end
