# frozen_string_literal: true

require 'test_helper'

class WarehouseTest < ActiveSupport::TestCase
  test 'les sites sont triés sans tenir compte des accents ni de la casse' do
    organisation = organisations(:mairie_paris)
    %w[Éclairage atelier Zone].each do |nom|
      Warehouse.create!(name: nom, organisation: organisation, address: 'Paris', latitude: 48.85, longitude: 2.35)
    end

    noms = organisation.warehouses.ordered.pluck(:name)

    assert_operator noms.index('atelier'), :<, noms.index('Éclairage')
    assert_operator noms.index('Éclairage'), :<, noms.index('Zone')
  end
end
