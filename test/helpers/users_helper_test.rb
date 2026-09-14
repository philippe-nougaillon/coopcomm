# frozen_string_literal: true

require 'test_helper'

class UsersHelperTest < ActionView::TestCase
  test 'un administrateur peut assigner tous les services de son organisation' do
    assignables = services_assignables_par(users(:administrateur_paris))

    assert_equal organisations(:mairie_paris).services.ids.sort, assignables.ids.sort
  end

  test 'un manager ne peut assigner que ses propres services' do
    manager = users(:hidalgo)

    assert_equal manager.services.ids.sort, services_assignables_par(manager).ids.sort
  end

  test 'aucun service d’une autre organisation n’est assignable' do
    assignables = services_assignables_par(users(:administrateur_paris))

    assert_not_includes assignables.ids, services(:service_marseille).id
  end

  test 'la liste est triée par nom' do
    noms = services_assignables_par(users(:administrateur_paris)).pluck(:nom)

    assert_equal noms.sort_by { |nom| I18n.transliterate(nom).downcase }, noms
  end

  # L'organisation dérive des services : elle est nil pour un compte antérieur à
  # la validation `must_have_at_least_one_service`.
  test 'un administrateur sans organisation n’a aucun service assignable' do
    orphelin = User.new(nom: 'Orphelin', prénom: 'Sans', email: 'orphelin-helper@example.test',
                        rôle: 'administrateur', password: 'qtDug$d843sqACz?V')
    orphelin.save(validate: false)

    assert_empty services_assignables_par(orphelin)
  end
end
