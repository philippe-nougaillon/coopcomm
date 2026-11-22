# frozen_string_literal: true

require 'test_helper'

class MettreEnFormeReponseIaTest < ActiveSupport::TestCase
  # ==================== TESTS CRITIQUES ====================
  # Un modèle de langage répète ce qu'il lit, dont la description d'une intervention venue du mail d'un adhérent :
  # rien de ce qu'il écrit ne doit s'exécuter dans le navigateur, ni lui faire appeler une adresse extérieure.

  test 'le HTML écrit par le modèle est affiché en texte, sans être interprété (critique)' do
    rendu = fragment_rendu('avant <script>alert(1)</script> <img src=x onerror=alert(1)> <b>gras</b>')

    assert_empty rendu.css('script, img, b')
    assert_equal 'avant <script>alert(1)</script> <img src=x onerror=alert(1)> <b>gras</b>', rendu.text.strip
  end

  test 'une image écrite par le modèle n’est pas rendue (critique)' do
    assert_empty fragment_rendu('![x](https://exemple.test/?q=secret)').css('img')
  end

  test 'un lien écrit par le modèle n’est pas rendu (critique)' do
    assert_empty fragment_rendu('[ici](https://exemple.test) et https://exemple.test').css('a')
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'un retour à la ligne simple est conservé' do
    assert_equal 1, fragment_rendu("ligne une\nligne deux").css('p br').size
  end

  test 'un trait collé sous une ligne de texte reste un trait, sans en faire un titre' do
    rendu = fragment_rendu("- dernier point\n---\nSuite")

    assert_equal 1, rendu.css('hr').size
    assert_equal ['dernier point'], rendu.css('li').map(&:text)
    assert_empty rendu.css('h2')
  end

  test 'des traits qui se suivent n’en font qu’un' do
    assert_equal 1, fragment_rendu("avant\n\n---\n---\naprès").css('hr').size
  end

  test 'une ligne qui commence par trois tirets suivis de texte reste du texte' do
    rendu = fragment_rendu('--- suite')

    assert_empty rendu.css('hr')
    assert_equal ['--- suite'], rendu.css('p').map(&:text)
  end

  test 'une liste collée à la phrase qui l’annonce est rendue en liste' do
    assert_equal %w[un deux], fragment_rendu("Par exemple :\n- un\n- deux").css('ul li').map(&:text)
  end

  test 'un nom à tirets bas reste entier' do
    rendu = fragment_rendu('selon heures_consommees et temps_total')

    assert_empty rendu.css('em')
    assert_equal 'selon heures_consommees et temps_total', rendu.text.strip
  end

  test 'un tableau est rendu en tableau' do
    rendu = fragment_rendu("Voici :\n\n| Agent | Heures |\n|---|---|\n| DUPONT | 12 |")

    assert_equal %w[Agent Heures], rendu.css('table th').map(&:text)
    assert_equal %w[DUPONT 12], rendu.css('table td').map(&:text)
  end

  test 'une colonne de tableau alignée est rendue sans attribut' do
    rendu = fragment_rendu("| Agent | Heures |\n|:---|---:|\n| DUPONT | 12 |")

    assert_equal %w[DUPONT 12], rendu.css('td').map(&:text)
    assert_empty rendu.css('*').flat_map(&:attribute_nodes)
  end

  test 'le texte seul d’une réponse ne garde ni marque ni balise' do
    texte = MettreEnFormeReponseIa.call("### **Sur le matériel**\n- *« une question »*\n\n---\nFin", texte_seul: true)

    assert_equal 'Sur le matériel « une question » Fin', texte
  end

  private

  # Le rendu d'une réponse, lu comme le navigateur le lira.
  def fragment_rendu(markdown)
    Nokogiri::HTML5.fragment(MettreEnFormeReponseIa.call(markdown))
  end
end
