# frozen_string_literal: true

require 'application_system_test_case'

# L'option vide d'un select obligatoire est le placeholder dont dépend `required` :
# la choisir la dupliquait, la sélection ne portait plus sur la première option, et
# la validation cessait de voir un champ vide.
class SlimSelectTest < ApplicationSystemTestCase
  setup do
    login(users(:administrateur_paris))
  end

  test 'le menu d’un champ obligatoire ne propose aucun choix vide' do
    visit new_prestation_url
    assert_selector 'form'

    ouvrir_menu('prestation_unité')

    assert_equal ['Heure(s)', 'Forfait', 'Jour'], options_proposées
    assert_equal ['', 'Heure(s)', 'Forfait', 'Jour'], options_de('prestation_unité')
  end

  test 'une prestation ne peut pas être enregistrée sans unité' do
    visit new_prestation_url
    assert_selector 'form'
    fill_in 'prestation_code', with: 'SLIM01'
    fill_in 'prestation_libellé', with: 'Sans unité'
    fill_in 'prestation_tarif', with: 10
    vider_par_le_placeholder('prestation_unité')

    assert_no_difference -> { Prestation.count } do
      find('input[type=submit]').click
      assert_current_path new_prestation_path
    end
    assert_predicate page.execute_script("return document.getElementById('prestation_unité').validationMessage"), :present?
  end

  test 'la croix de désélection laisse le champ obligatoire refusé à la soumission' do
    visit new_prestation_url
    assert_selector 'form'
    fill_in 'prestation_code', with: 'SLIM02'
    fill_in 'prestation_libellé', with: 'Vidé par la croix'
    fill_in 'prestation_tarif', with: 10

    page.execute_script(<<~JS)
      const croix = document.getElementById('prestation_unité').nextElementSibling.querySelector('.ss-deselect');
      if (croix) croix.click();
    JS

    assert signale_un_vide?('prestation_unité')
    assert_no_difference -> { Prestation.count } do
      find('input[type=submit]').click
      assert_current_path new_prestation_path
    end
  end

  test 'un filtre d’index garde son option « Tous » sélectionnable' do
    visit conventions_url

    premiere = page.execute_script(<<~JS)
      const s = document.querySelector('select[name="adherent_id"]');
      return { texte: s.options[0].textContent, desactivee: s.options[0].disabled };
    JS

    assert_equal 'Tous', premiere['texte']
    assert_not premiere['desactivee']
  end

  test 'un champ obligatoire à choix multiples reste désélectionnable' do
    visit edit_user_url(users(:bond))
    assert_selector 'form'

    premiere = page.execute_script(<<~JS)
      const s = document.getElementById('user_service_ids');
      return s.options[0] ? s.options[0].disabled : null;
    JS

    assert_not premiere
  end

  private

  def ouvrir_menu(id)
    page.execute_script("document.getElementById(#{id.to_json}).nextElementSibling.click()")
    assert_selector '.ss-option', visible: true
  end

  def options_proposées
    all('.ss-option', visible: true).map(&:text)
  end

  def valeur_de(id)
    page.execute_script("return document.getElementById(#{id.to_json}).value")
  end

  def options_de(id)
    page.execute_script("return Array.from(document.getElementById(#{id.to_json}).options).map(o => o.value)")
  end

  def vider_par_le_placeholder(id)
    page.execute_script("document.getElementById(#{id.to_json}).selectedIndex = 0")
  end

  def signale_un_vide?(id)
    page.execute_script("return document.getElementById(#{id.to_json}).validity.valueMissing")
  end
end
