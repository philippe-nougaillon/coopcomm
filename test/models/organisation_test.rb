# frozen_string_literal: true

require 'test_helper'

class OrganisationTest < ActiveSupport::TestCase
  test 'numero : nom suffixé après un souligné → le suffixe' do
    assert_equal '42', Organisation.new(nom: 'Organisation_42').numero
  end

  test 'numero : nom sans souligné → le nom entier' do
    assert_equal 'Mairie de Paris', organisations(:mairie_paris).numero
  end
end
