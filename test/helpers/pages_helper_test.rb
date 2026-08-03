# frozen_string_literal: true

require 'test_helper'

class PagesHelperTest < ActionView::TestCase
  test 'les deux exports du dashboard portent un libellé métier' do
    assert_equal 'Dashboard (Manager)',  export_type_label('dashboard_manager')
    assert_equal 'Dashboard (Adhérent)', export_type_label('dashboard_adherent')
  end

  test 'un type d\'export non répertorié est rendu lisiblement' do
    assert_equal 'Interventions xls', export_type_label('interventions_xls')
  end
end
