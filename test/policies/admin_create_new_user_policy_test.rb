# frozen_string_literal: true

require 'test_helper'

# Le formulaire de création d'un utilisateur est servi par admin#create_new_user et
# poste sur users#create : les deux portes doivent s'ouvrir aux mêmes rôles.
class AdminCreateNewUserPolicyTest < ActiveSupport::TestCase
  test 'un administrateur accède au formulaire de création' do
    assert AdminPolicy.new(users(:administrateur_paris), :admin).create_new_user?
  end

  test 'un manager accède au formulaire de création' do
    assert AdminPolicy.new(users(:hidalgo), :admin).create_new_user?
  end

  test 'un agent n’accède pas au formulaire de création' do
    assert_not AdminPolicy.new(users(:bond), :admin).create_new_user?
  end

  test 'un adhérent n’accède pas au formulaire de création' do
    assert_not AdminPolicy.new(users(:weil), :admin).create_new_user?
  end

  test 'un visiteur non connecté n’accède pas au formulaire de création' do
    assert_not AdminPolicy.new(nil, :admin).create_new_user?
  end
end
