# frozen_string_literal: true

require 'application_system_test_case'

class AdherentFlowOnConventionsTest < ApplicationSystemTestCase
  test "En tant qu'adhérent, je veux suivre depuis ma page d'accueil mes conventions de l'année par service, sans filtre ni mon propre nom" do
    Convention.create!(user: users(:weil), service: services(:technique), date_début: Date.current.beginning_of_year,
                       date_fin_prévue: Date.current.end_of_year, heures_conventionnees: 50)

    login(users(:weil))

    within '[data-conventions]' do
      assert_text 'Technique'
      assert_no_text 'Weil Ariel'
      assert_no_selector '[data-groupement]'
    end
  end

  test "En tant qu'adhérent, je veux voir en vert la barre d'une convention sous-consommée" do
    Convention.create!(user: users(:weil), service: services(:technique), date_début: Date.current - 200, date_fin_prévue: Date.current + 100,
                       heures_conventionnees: 50)

    login(users(:weil))

    within '[data-conventions]' do
      assert_text 'Technique'
    end
    vert, couleur_de_la_barre = page.evaluate_script(<<~JS)
      (() => {
        const contexte = document.createElement('canvas').getContext('2d')
        const rgb = couleur => {
          contexte.clearRect(0, 0, 1, 1)
          contexte.fillStyle = couleur
          contexte.fillRect(0, 0, 1, 1)
          return [...contexte.getImageData(0, 0, 1, 1).data.slice(0, 3)].join(',')
        }
        const barre = [...document.querySelectorAll('[data-conventions] path.apexcharts-bar-area[index="0"]')]
          .find(chemin => chemin.getAttribute('data:pathKey') === 'c:Technique')
        return [rgb(getComputedStyle(document.documentElement).getPropertyValue('--color-success')), rgb(barre.getAttribute('fill'))]
      })()
    JS
    assert_equal vert, couleur_de_la_barre
  end

  test "En tant qu'adhérent, je veux voir mes conventions occuper toute la hauteur du bloc" do
    Convention.create!(user: users(:weil), service: services(:technique), date_début: Date.current.beginning_of_year,
                       date_fin_prévue: Date.current.end_of_year, heures_conventionnees: 50)

    login(users(:weil))

    within '[data-conventions]' do
      assert_text 'Technique'
    end
    vide_sous_les_barres, debordement = page.evaluate_script(<<~JS)
      (() => {
        const zone = document.querySelector('[data-conventions] [data-defilement]')
        const graphes = zone.querySelectorAll('[data-graphe]')
        return [zone.getBoundingClientRect().bottom - graphes[graphes.length - 1].getBoundingClientRect().bottom, zone.scrollHeight - zone.clientHeight]
      })()
    JS
    assert_operator vide_sous_les_barres, :<, 16
    assert_equal 0, debordement
  end

  test "En tant qu'adhérent, je veux lire sur mon téléphone la ligne de l'année et mes conventions sur toute la largeur du bloc" do
    page.current_window.resize_to(*self.class.taille_tel)
    Convention.create!(user: users(:weil), service: services(:technique), date_début: Date.current.beginning_of_year,
                       date_fin_prévue: Date.current.end_of_year, heures_conventionnees: 50)

    login(users(:weil))

    within '[data-conventions]' do
      assert_selector '[data-libelles] span', text: 'Technique'
    end
    mesures = page.evaluate_script(<<~JS)
      (() => {
        const zone = document.querySelector('[data-conventions] [data-defilement]').getBoundingClientRect()
        const ligne = document.querySelector('[data-conventions] [data-ligne]').getBoundingClientRect()
        const libelle = [...document.querySelectorAll('[data-conventions] [data-libelles] span')].find(span => span.textContent === 'Technique').getBoundingClientRect()
        const barre = [...document.querySelectorAll('[data-conventions] path.apexcharts-bar-area')]
          .filter(chemin => chemin.getAttribute('data:pathKey') === 'c:Technique').map(chemin => chemin.getBoundingClientRect())
        return { ligne: [ligne.left - zone.left, zone.right - ligne.right], debut_de_barre: Math.min(...barre.map(morceau => morceau.left)) - zone.left,
                 libelle_au_dessus: Math.min(...barre.map(morceau => morceau.top)) - libelle.bottom }
      })()
    JS
    (mesures['ligne'] + [mesures['debut_de_barre']]).each { |marge| assert_in_delta 0, marge, 3 }
    assert_operator mesures['libelle_au_dessus'], :>=, 0
  end
end
