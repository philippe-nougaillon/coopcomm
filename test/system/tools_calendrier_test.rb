# frozen_string_literal: true

require 'application_system_test_case'

# Les quatre couleurs de case, telles que le navigateur les peint. La logique qui
# décide de l'état d'un jour est couverte par `Tool#get_etats_from_mouvements`
# dans les tests de modèle : ici on ne vérifie que la couleur rendue.
class ToolsCalendrierTest < ApplicationSystemTestCase
  # Avant les autres : une panne se propage aux jours suivants jusqu'à une fin de panne.
  LIBRE = Date.new(2026, 6, 12)
  MA_RESERVATION = Date.new(2026, 6, 15)
  RESERVATION_AUTRE = Date.new(2026, 6, 16)
  PANNE = Date.new(2026, 6, 17)

  setup do
    @manager = users(:hidalgo)
    @outil = tools(:cisaille)
    @outil.mouvements.destroy_all
    Mouvement.create!(tool: @outil, user: @manager, état: :réservé, date: MA_RESERVATION)
    Mouvement.create!(tool: @outil, user: users(:bond), état: :réservé, date: RESERVATION_AUTRE)
    Mouvement.create!(tool: @outil, user: @manager, état: :panne, date: PANNE)
    login(@manager)
    visit tool_url(@outil, date: MA_RESERVATION.to_s)
  end

  teardown { @outil.mouvements.destroy_all }

  test 'une journée libre est verte' do
    rouge, vert, bleu = couleur_de("a[title*='pour le #{LIBRE.strftime('%d/%m')}'] span")

    assert_operator vert, :>, rouge
    assert_operator vert, :>, bleu
  end

  test 'ma réservation est bleue' do
    rouge, vert, bleu = couleur_de("a[title='Réservé par vous (cliquez pour libérer)'] span")

    assert_operator bleu, :>, rouge
    assert_operator bleu, :>, vert
  end

  test 'la réservation d’un autre est bleue, plus claire que la mienne' do
    mienne = couleur_de("a[title='Réservé par vous (cliquez pour libérer)'] span")
    rouge, vert, bleu = autre = couleur_de("a[title=\"Réservé par quelqu'un d'autre (cliquez pour libérer)\"] span")

    assert_operator bleu, :>, rouge
    assert_operator bleu, :>, vert
    assert_operator autre.sum, :>, mienne.sum
  end

  test 'une journée en panne est rouge' do
    rouge, vert, bleu = couleur_de("span[title='En panne']")

    assert_operator rouge, :>, vert
    assert_operator rouge, :>, bleu
  end

  private

  # [rouge, vert, bleu] tels que le navigateur les peint réellement. Le passage par
  # un canvas est obligatoire : Tailwind 4 déclare ses couleurs en oklch, que
  # `getComputedStyle` rend telles quelles.
  def couleur_de(selecteur)
    case_couleur = all(selecteur, visible: :all).first
    assert_not_nil case_couleur, "aucune case ne correspond à #{selecteur}"

    evaluate_script(<<~JS, case_couleur)
      (element => {
        const contexte = document.createElement('canvas').getContext('2d');
        contexte.fillStyle = getComputedStyle(element).backgroundColor;
        contexte.fillRect(0, 0, 1, 1);
        const pixel = contexte.getImageData(0, 0, 1, 1).data;
        return [pixel[0], pixel[1], pixel[2]];
      })(arguments[0])
    JS
  end
end
