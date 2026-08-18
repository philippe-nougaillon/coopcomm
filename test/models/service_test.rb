# frozen_string_literal: true

require 'test_helper'

class ServiceTest < ActiveSupport::TestCase
  test 'unicité du nom : doublon dans la même organisation → refusé' do
    doublon = Service.new(nom: services(:technique).nom, organisation: organisations(:mairie_paris))

    assert_not doublon.valid?
    assert_includes doublon.errors[:nom], 'est déjà utilisé(e)'
  end

  test 'unicité du nom : même nom dans une autre organisation → accepté' do
    assert Service.new(nom: services(:technique).nom, organisation: organisations(:mairie_marseille)).valid?
  end

  test 'normalisation du nom : espaces et casse → humanisé et détouré' do
    service = Service.create!(nom: '  espaces verts  ', organisation: organisations(:mairie_paris))

    assert_equal 'Espaces verts', service.nom
  end

  # ==================== TESTS CRITIQUES ====================
  # Un service sans nom apparaît comme une entrée VIDE dans le sélecteur du formulaire
  # utilisateur : impossible de distinguer un vrai service d'une ligne accidentelle, et
  # les utilisateurs qu'on y rattache semblent « sans service ». La normalisation vide
  # un nom fait d'espaces, c'est elle qui déclenche alors le refus.

  test 'normalisation du nom : nom fait uniquement d\'espaces → refusé (critique)' do
    service = Service.new(nom: '   ', organisation: organisations(:mairie_paris))

    assert_not service.valid?
    assert_includes service.errors[:nom], 'doit être rempli(e)'
  end

  # ==================== /TESTS CRITIQUES ====================
end
