# frozen_string_literal: true

require 'test_helper'

class MouvementsHelperTest < ActionView::TestCase
  test 'les états du matériel portent un libellé métier' do
    assert_equal 'Panne',             field_label('panne')
    assert_equal 'Fin de la panne',   field_label('fin_panne')
    assert_equal 'Réservé',           field_label('réservé')
  end

  test 'le libellé est trouvé quelle que soit la casse reçue' do
    assert_equal 'Panne', field_label('PANNE')
    assert_equal 'Panne', field_label(:panne)
  end

  test 'un état non répertorié est rendu lisiblement' do
    assert_equal 'Hors service', field_label('hors_service')
  end

  test 'une clé vide ne lève pas d\'erreur' do
    assert_equal '', field_label(nil)
  end
end
