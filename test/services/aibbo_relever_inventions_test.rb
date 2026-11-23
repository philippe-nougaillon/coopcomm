# frozen_string_literal: true

require 'test_helper'

class AibboReleverInventionsTest < ActiveSupport::TestCase
  # Ce que le modèle a lu pendant le tour : le résultat d'un outil, la demande qu'il lui a faite, la question de l'utilisateur.
  SOURCES = ['{"total":2,"heures":6.22,"interventions":[{"description":"Achat publics — mairie de Vandelainville",' \
             '"adhérent":"VANDELAINVILLE","agents":["ACHARD Nicolas"],"début":"2026-11-12 13:48","fin":"2026-11-12 16:31","heures":2.72}]}',
             '{"du":"2026-11-12","au":"2026-11-19","agent":"ACHARD Nicolas"}',
             'et celle d’après ?'].freeze
  # Le jour où la question est posée.
  JOUR = Date.new(2026, 11, 19)

  # ==================== TESTS CRITIQUES ====================
  # AÏBBO ne doit jamais affirmer une donnée qu'aucun outil n'a rendue : une intervention inventée, avec sa commune,
  # ses horaires et ses heures, a été annoncée à un agent le 2026-11-19.

  test 'une date absente des sources est relevée (critique)' do
    assert_equal ['18 novembre 2026'], inventions_de('Votre intervention suivante est celle du 18 novembre 2026.')
  end

  test 'un horaire absent des sources est relevé (critique)' do
    assert_equal %w[9h00 11h30], inventions_de('Elle a eu lieu le 12 novembre, de 9h00 à 11h30.')
  end

  test 'un nombre absent des sources est relevé (critique)' do
    assert_equal ['2,5'], inventions_de('Elle a duré 2,5 heures.')
  end

  test 'un nom propre absent des sources est relevé (critique)' do
    assert_equal ['Charey'], inventions_de('Elle était pour la mairie de Charey.')
  end

  test 'une supposition annoncée ne dispense ni la date, ni l’horaire, ni le nom d’avoir une source (critique)' do
    assert_equal ['18 novembre', '9h00', 'Charey'], inventions_de('Supposition : la suivante serait le 18 novembre à 9h00, à Charey.')
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'une réponse qui ne cite que ce que les sources contiennent ne relève rien' do
    reponse = 'Votre dernière intervention était pour **Achat publics — mairie de Vandelainville**, le **12 novembre 2026** ' \
              'de **13h48 à 16h31**, avec un total de **2,72 heures**, sur 2 interventions et 6,22 heures.'

    assert_empty inventions_de(reponse)
  end

  test 'la date du jour est admise sans source' do
    assert_empty Aibbo::ReleverInventions.call('Nous sommes le samedi 21 novembre 2026.', SOURCES, aujourd_hui: Date.new(2026, 11, 21))
  end

  test 'un jour cité seul doit figurer dans une date des sources' do
    assert_equal ['le 18'], inventions_de('Vous avez travaillé le 12, mais pas le 18.')
  end

  test 'une année citée seule doit figurer dans une date des sources' do
    assert_equal ['2025'], inventions_de('En 2026 comme en 2025.')
  end

  test 'une durée lue en heures décimales peut être redite en heures et minutes' do
    assert_empty inventions_de('Elle a duré 2 h 43.')
  end

  test 'un nombre calculé est admis sur une ligne annoncée comme une déduction' do
    assert_empty inventions_de("Vous avez travaillé 6,22 heures.\nDéduction : cela fait 3,11 heures par intervention.")
  end

  test 'ce qu’une ligne de déduction a avancé plus tôt dans la conversation ne vaut pas source' do
    sources = SOURCES + ["Vous avez travaillé 6,22 heures.\nDéduction : cela fait 3,11 heures par intervention."]

    assert_equal ['3,11'], Aibbo::ReleverInventions.call('Vous travaillez 3,11 heures par intervention.', sources, aujourd_hui: JOUR)
  end

  test 'un pourcentage est admis quand la source donne la proportion' do
    assert_empty Aibbo::ReleverInventions.call('Le taux est de 42 %.', ['{"taux":0.42}'], aujourd_hui: JOUR)
  end

  test 'le nombre d’éléments d’une liste rendue par un outil est admis' do
    inventions = Aibbo::ReleverInventions.call('3 agents sont libres, 4 sont pris.', ['{"libres":["DUPONT","MARTIN","PETIT"]}'], aujourd_hui: JOUR)

    assert_equal ['4'], inventions
  end

  test 'un nombre à séparateur de milliers est lu en entier' do
    assert_equal ['12 300'], Aibbo::ReleverInventions.call('4 104,5 heures, soit 12 300 €.', ['{"heures":4104.5}'], aujourd_hui: JOUR)
  end

  test 'un numéro de téléphone est reconnu quelle que soit sa mise en forme' do
    inventions = Aibbo::ReleverInventions.call('Appelez le 06 12 34 56 78, pas le 06 99 99 99 99.', ['{"téléphone":"0612345678"}'], aujourd_hui: JOUR)

    assert_equal ['06 99 99 99 99'], inventions
  end

  test 'le numéro d’une ligne de liste n’est pas pris pour un nombre' do
    assert_empty inventions_de("1. VANDELAINVILLE\n### 7. ACHARD Nicolas")
  end

  test 'un mot à majuscule en tête de phrase, après deux-points ou en tête de cellule n’est pas pris pour un nom' do
    assert_empty inventions_de("Voici la liste. Elle est courte : Pendant ce mois.\n| Agent | Heures |\n- **Total** : 2")
  end

  test 'un nom écrit tout en capitales est contrôlé où qu’il soit dans la phrase' do
    assert_equal ['CHAREY'], inventions_de('CHAREY est la commune suivante.')
  end

  private

  # Ce que la réponse contient et que les sources du tour ne contiennent pas.
  def inventions_de(reponse)
    Aibbo::ReleverInventions.call(reponse, SOURCES, aujourd_hui: JOUR)
  end
end
