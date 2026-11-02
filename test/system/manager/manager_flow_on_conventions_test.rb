# frozen_string_literal: true

require 'application_system_test_case'

class ManagerFlowOnConventionsTest < ApplicationSystemTestCase
  test "En tant que manager de plusieurs services, je veux suivre depuis ma page d'accueil les conventions de l'année, par adhérent puis par service" do
    Convention.create!(user: users(:berthout), service: services(:technique), date_début: Date.current.beginning_of_year,
                       date_fin_prévue: Date.current.end_of_year, heures_conventionnees: 50)

    login(users(:hidalgo))
    fermer_notification

    within '[data-conventions]' do
      assert_selector '[data-groupes] p', text: 'Berthout Florence'
      assert_no_selector '[data-groupes] p', text: 'Technique'
      assert_text 'Technique'

      cliquer_element(find('[data-groupement] label', text: 'Par service'))

      assert_selector '[data-groupes] p', text: 'Technique'
      assert_no_selector '[data-groupes] p', text: 'Berthout Florence'
      assert_text 'Berthout Florence'
    end
  end

  test "En tant que manager d'un seul service, je veux suivre depuis ma page d'accueil les conventions de l'année sans filtre ni nom de service" do
    Convention.create!(user: users(:adherent_marseille), service: services(:service_marseille), date_début: Date.current.beginning_of_year,
                       date_fin_prévue: Date.current.end_of_year, heures_conventionnees: 50)

    login(users(:manager_marseille))

    within '[data-conventions]' do
      assert_text 'Tapie'
      assert_no_text 'Service_Marseille'
      assert_no_selector '[data-groupement]'
    end
  end

  test "En tant que manager, je veux voir les conventions de l'année sur la page d'accueil où j'arrive en me connectant" do
    Convention.create!(user: users(:berthout), service: services(:technique), date_début: Date.current.beginning_of_year,
                       date_fin_prévue: Date.current.end_of_year, heures_conventionnees: 50)

    login(users(:hidalgo))

    within '[data-conventions]' do
      assert_text 'Technique'
    end
  end

  test "En tant que manager, je veux voir en faisant défiler le bloc les conventions des adhérents du bas de la liste" do
    12.times do |mois|
      debut = Date.current.beginning_of_year + mois.months
      Convention.create!(user: users(:berthout), service: services(:technique), date_début: debut, date_fin_prévue: debut.end_of_month, heures_conventionnees: 10)
      Convention.create!(user: users(:adhérent_sans_intervention), service: services(:informatique), date_début: debut, date_fin_prévue: debut.end_of_month,
                         heures_conventionnees: 10)
    end
    Convention.create!(user: users(:weil), service: services(:technique), date_début: Date.current.beginning_of_year,
                       date_fin_prévue: Date.current.end_of_year, heures_conventionnees: 50)

    login(users(:hidalgo))

    within '[data-conventions]' do
      within(find('[data-groupes] > div', text: 'Berthout Florence')) { assert_text 'Technique' }
      groupe_du_bas = find('[data-groupes] > div', text: 'Weil Ariel')
      within(groupe_du_bas) { assert_no_text 'Technique' }

      find('[data-defilement]').scroll_to(:bottom)

      within(groupe_du_bas) { assert_text 'Technique' }
    end
  end

  test "En tant que manager d'un seul service, je veux lire le nom d'un adhérent au nom long sans qu'il soit coupé à gauche" do
    Convention.create!(user: users(:adherent_nom_long), service: services(:service_marseille), date_début: Date.current.beginning_of_year,
                       date_fin_prévue: Date.current.end_of_year, heures_conventionnees: 50)

    login(users(:manager_marseille))

    { self.class.taille_tel => '[data-libelles] span', self.class.taille_pc => '.apexcharts-yaxis-label' }.each do |taille, libelles|
      page.current_window.resize_to(*taille)

      within '[data-conventions]' do
        assert_selector libelles, text: 'THIAUCOURT'
      end
      bord_gauche = page.evaluate_script(<<~JS)
        (() => {
          const libelle = [...document.querySelectorAll('[data-conventions] #{libelles}')].find(texte => texte.textContent.startsWith('THIAUCOURT'))
          return libelle.getBoundingClientRect().left - document.querySelector('[data-conventions] [data-defilement]').getBoundingClientRect().left
        })()
      JS
      assert_operator bord_gauche, :>=, 0, "fenêtre de #{taille.join(' × ')}"
    end
  end
end
