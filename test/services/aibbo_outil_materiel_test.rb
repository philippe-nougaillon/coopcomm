# frozen_string_literal: true

require 'test_helper'

class AibboOutilMaterielTest < ActiveSupport::TestCase
  setup do
    @manager = users(:hidalgo)
  end

  # ==================== TESTS CRITIQUES ====================
  # Le matériel dit qui l'a réservé et pour quelle intervention : il ne sort pas de l'organisation de l'utilisateur,
  # et l'intitulé d'une intervention s'y lit comme sur la fiche du matériel, tant qu'aucun matériel n'est réservé à un service.
  test 'un agent ne reçoit que le matériel de son organisation (critique)' do
    resultat = Aibbo::OutilMateriel.new(users(:bond)).call(du: '2024-05-07')

    assert_equal tools(:tondeuse, :rateau, :cisaille, :outil_paris, :outil_adherent, :taille_haie_en_panne_en_mai_2024,
                       :souffleur_reserve_en_mai_2024).map(&:name).sort, resultat[:matériel].pluck(:nom).sort
  end

  test 'un adhérent ne reçoit aucun matériel (critique)' do
    resultat = Aibbo::OutilMateriel.new(users(:weil)).call(du: '2024-05-07')

    assert_empty resultat[:matériel]
  end

  test 'le nom d’un matériel d’une autre organisation n’est pas reconnu (critique)' do
    resultat = Aibbo::OutilMateriel.new(@manager).call(nom: tools(:camion).name)

    assert_match(/introuvable parmi le matériel/, resultat[:erreur])
    assert_nil resultat[:matériel]
  end

  test 'une intervention que l’agent ne peut pas consulter est nommée par son intitulé, comme sur la fiche du matériel (critique)' do
    resultat = Aibbo::OutilMateriel.new(users(:agent_whatsapp)).call(du: '2024-04-19', nom: 'rateau')

    assert_not Intervention.visible_to(users(:agent_whatsapp)).include?(interventions(:nouvelle_intervention))
    assert_equal 'en intervention', resultat[:matériel].first[:état]
    assert_match(/#{interventions(:nouvelle_intervention).description}/, resultat[:matériel].first[:raisons].join)
  end

  test 'aucun matériel n’est rattaché à un service, condition pour que tout non-adhérent lise l’intitulé de ses interventions (critique)' do
    rattachements = Tool.column_names.grep(/service/) + Tool.reflect_on_all_associations.map(&:name).grep(/service/)

    assert_empty rattachements, 'Le matériel a reçu un service : Tool.visible_to doit le filtrer, et Aibbo::OutilMateriel ne plus rendre ' \
                                'l’intitulé des interventions à qui ne voit pas ce matériel.'
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'un matériel pris par une intervention ce jour-là porte cette intervention pour raison' do
    rateau = Aibbo::OutilMateriel.new(@manager).call(du: '2024-04-19', nom: 'rateau')[:matériel].first

    assert_equal 'en intervention', rateau[:état]
    assert_match(/#{interventions(:nouvelle_intervention).description}/, rateau[:raisons].join)
  end

  test 'un matériel en panne porte le jour de la panne et la personne qui l’a déclarée' do
    taille_haie = Aibbo::OutilMateriel.new(@manager).call(du: '2024-05-08', nom: 'taille-haie')[:matériel].first

    assert_equal 'en panne', taille_haie[:état]
    assert_match(/en panne depuis le 2024-05-06, déclarée par #{users(:bond).nom_prénom}/, taille_haie[:raisons].join)
  end

  test 'un matériel redevient libre le jour de la fin de sa panne' do
    taille_haie = Aibbo::OutilMateriel.new(@manager).call(du: '2024-05-10', nom: 'taille-haie')[:matériel].first

    assert_equal 'libre', taille_haie[:état]
    assert_not taille_haie.key?(:raisons)
  end

  test 'un matériel réservé porte la personne qui l’a réservé' do
    souffleur = Aibbo::OutilMateriel.new(@manager).call(du: '2024-05-07', nom: 'souffleur')[:matériel].first

    assert_equal 'réservé', souffleur[:état]
    assert_match(/réservé par #{users(:martin_technique_paris).nom_prénom}/, souffleur[:raisons].join)
  end

  test 'un nom partiel rend tous les matériels qui le portent' do
    resultat = Aibbo::OutilMateriel.new(@manager).call(du: '2024-05-07', nom: 'outil')

    assert_equal tools(:outil_paris, :outil_adherent).map(&:name).sort, resultat[:matériel].pluck(:nom).sort
  end

  test 'le filtre par état ne garde que le matériel dans cet état ce jour-là' do
    resultat = Aibbo::OutilMateriel.new(@manager).call(du: '2024-05-08', etat: 'en panne')

    assert_equal [tools(:taille_haie_en_panne_en_mai_2024).name], resultat[:matériel].pluck(:nom)
  end

  test 'une période rend l’état du matériel pour chacun de ses jours' do
    resultat = Aibbo::OutilMateriel.new(@manager).call(du: '2024-05-09', au: '2024-05-10', nom: 'taille-haie')

    assert_equal [['2024-05-09', 'en panne'], ['2024-05-10', 'libre']], resultat[:matériel].map { |ligne| [ligne[:date], ligne[:état]] }
  end

  test 'une période trop longue pour tout le matériel est renvoyée à l’utilisateur sans rien chercher' do
    resultat = Aibbo::OutilMateriel.new(@manager).call(du: '2024-01-01', au: '2024-12-31')

    assert_match(/une période plus courte/, resultat[:erreur])
    assert_nil resultat[:matériel]
  end

  test 'un matériel est dit libre exactement quand l’application le dit disponible' do
    jour = Date.new(2024, 5, 7)

    resultat = Aibbo::OutilMateriel.new(@manager).call(du: jour.to_s)

    libres = resultat[:matériel].select { |ligne| ligne[:état] == 'libre' }.pluck(:nom)
    assert_equal Tool.visible_to(@manager).select { |materiel| materiel.disponible_le?(jour) }.map(&:name).sort, libres.sort
    assert_not_includes libres, tools(:taille_haie_en_panne_en_mai_2024).name
    assert_not_includes libres, tools(:souffleur_reserve_en_mai_2024).name
  end
end
