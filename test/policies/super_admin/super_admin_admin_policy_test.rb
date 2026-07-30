# frozen_string_literal: true

require 'test_helper'

# `stats?` est la seule action de l'espace admin réservée au super administrateur
# (identifié par la variable d'environnement SUPER_ADMIN, pas par un rôle).
class SuperAdminAdminPolicyTest < ActiveSupport::TestCase
  setup do
    @super_admin = users(:philippe_super_admin)
    @administrateur = users(:administrateur_paris)
    @super_admin_initial = ENV.fetch('SUPER_ADMIN', nil)
    ENV['SUPER_ADMIN'] = @super_admin.email
  end

  teardown do
    ENV['SUPER_ADMIN'] = @super_admin_initial
    ENV.delete('SUPER_ADMIN') if @super_admin_initial.nil?
  end

  test 'stats autorisé pour le super administrateur' do
    assert AdminPolicy.new(@super_admin, :admin).stats?
  end

  test 'stats refusé pour un administrateur ordinaire' do
    assert_not AdminPolicy.new(@administrateur, :admin).stats?
  end

  test 'stats refusé sans utilisateur connecté' do
    assert_not AdminPolicy.new(nil, :admin).stats?
  end
end
