# frozen_string_literal: true

require 'test_helper'

class AibboOutilInterventionsTest < ActiveSupport::TestCase
  setup do
    @manager = users(:hidalgo)
  end

  # ==================== TESTS CRITIQUES ====================
  # Ce qu'AÏBBO rend au modèle de langage part chez un tiers et revient à l'utilisateur :
  # rien ne doit sortir du périmètre de son rôle, ni des champs que sa fiche d'intervention lui montre.
  test 'un agent ne reçoit que les interventions auxquelles il est affecté (critique)' do
    resultat = interventions_lues_par(users(:bond))

    assert_equal interventions(:tonte_locaux, :nouvelle_intervention, :intervention_terminée, :intervention_autre_adhérent,
                               :intervention_repete).map(&:id).sort, identifiants(resultat)
  end

  test 'un adhérent ne reçoit que les interventions qu’il a demandées (critique)' do
    assert_equal [interventions(:intervention_autre_adhérent).id], identifiants(interventions_lues_par(users(:berthout)))
  end

  test 'un manager ne reçoit aucune intervention d’un service qu’il n’encadre pas (critique)' do
    assert_empty identifiants(interventions_lues_par(users(:manager_paris)))
  end

  test 'le nom d’un service hors du périmètre n’est pas reconnu (critique)' do
    resultat = Aibbo::OutilInterventions.new(users(:manager_paris)).call(service: 'Technique')

    assert_match(/introuvable parmi les services/, resultat[:erreur])
    assert_nil resultat[:total]
  end

  test 'le nom d’un agent hors du périmètre n’est pas reconnu (critique)' do
    resultat = Aibbo::OutilInterventions.new(users(:administrateur_paris)).call(agent: users(:agent_marseille).nom)

    assert_match(/introuvable parmi les agents/, resultat[:erreur])
    assert_nil resultat[:total]
  end

  test 'un agent ne reçoit ni la note, ni l’avis, ni la note moyenne (critique)' do
    resultat = interventions_lues_par(users(:bond))
    tonte = resultat[:interventions].find { |ligne| ligne[:id] == interventions(:tonte_locaux).id }

    assert_not tonte.key?(:note)
    assert_not tonte.key?(:avis)
    assert_not resultat.key?(:note_moyenne)
  end

  test 'aucun résultat ne porte le mail ni le téléphone d’une personne (critique)' do
    resultat = interventions_lues_par(users(:administrateur_paris)).to_json

    assert_no_match(/#{Regexp.escape(users(:weil).email)}/, resultat)
    assert_no_match(/#{users(:weil).téléphone}/, resultat)
    assert_no_match(/#{Regexp.escape(users(:bond).email)}/, resultat)
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'un manager reçoit la note et l’avis d’une intervention validée' do
    resultat = interventions_lues_par(@manager)
    tonte = resultat[:interventions].find { |ligne| ligne[:id] == interventions(:tonte_locaux).id }

    assert_equal 4, tonte[:note]
    assert_equal interventions(:tonte_locaux).avis, tonte[:avis]
  end

  test 'la note moyenne porte sur les interventions validées ou refusées' do
    validees = interventions(:tonte_locaux, :intervention_validé)

    assert_equal validees.sum(&:note) / 2.0, interventions_lues_par(@manager)[:note_moyenne]
  end

  test 'la période porte par défaut sur le début réel' do
    resultat = Aibbo::OutilInterventions.new(@manager).call(du: '2024-04-15', au: '2024-04-17')

    assert_equal interventions(:intervention_terminée, :intervention_autre_agent, :intervention_autre_adhérent).map(&:id).sort,
                 identifiants(resultat)
  end

  test 'la période porte sur le début prévu lorsqu’il est demandé' do
    resultat = Aibbo::OutilInterventions.new(@manager).call(du: '2024-04-15', au: '2024-04-17', sur: 'prévu')

    assert_empty identifiants(resultat)
  end

  test 'une date illisible est renvoyée à l’utilisateur sans rien compter' do
    resultat = Aibbo::OutilInterventions.new(@manager).call(du: '15/04/2024')

    assert_match(%r{15/04/2024}, resultat[:erreur])
    assert_nil resultat[:total]
  end

  test 'le filtre par adhérent retrouve un nom écrit sans majuscule' do
    resultat = Aibbo::OutilInterventions.new(@manager).call(adherent: 'berthout')

    assert_equal [interventions(:intervention_autre_adhérent).id], identifiants(resultat)
  end

  test 'un nom qui désigne plusieurs agents est renvoyé à l’utilisateur avec les noms possibles' do
    resultat = Aibbo::OutilInterventions.new(@manager).call(agent: 'm')

    assert_match(/Bond James/, resultat[:erreur])
    assert_match(/Martin Michel/, resultat[:erreur])
    assert_nil resultat[:total]
  end

  test 'un agent des services de l’utilisateur qui n’a aucune intervention est reconnu, avec zéro intervention' do
    resultat = Aibbo::OutilInterventions.new(@manager).call(agent: 'Team Nettoyage')

    assert_nil resultat[:erreur]
    assert_equal 0, resultat[:total]
    assert_empty resultat[:interventions]
  end

  test 'le filtre par état ne garde que les interventions dans cet état' do
    resultat = Aibbo::OutilInterventions.new(@manager).call(etat: 'terminé')

    assert_equal interventions(:intervention_terminée, :intervention_autre_agent, :intervention_autre_adhérent).map(&:id).sort,
                 identifiants(resultat)
  end

  test 'les heures additionnent le temps total de toutes les interventions' do
    resultat = interventions_lues_par(users(:administrateur_paris))

    assert_equal Intervention.visible_to(users(:administrateur_paris)).sum(:temps_total).to_f, resultat[:heures]
    assert_equal 18.0, resultat[:heures]
  end

  test 'avec le filtre par agent, les heures sont la part de cet agent dans chaque intervention' do
    resultat = Aibbo::OutilInterventions.new(@manager).call(agent: 'james bond')

    assert_equal 4.5, resultat[:heures]
  end

  test 'le regroupement par service compte les interventions et les heures de chaque service' do
    resultat = Aibbo::OutilInterventions.new(users(:administrateur_paris)).call(regrouper_par: 'service')
    technique = resultat[:groupes].find { |groupe| groupe['service'] == services(:technique).nom }
    sans_service = resultat[:groupes].find { |groupe| groupe['service'] == 'Sans service' }

    assert_equal services(:technique).interventions.count, technique[:interventions]
    assert_equal 9.0, technique[:heures]
    assert_equal 1, sans_service[:interventions]
  end

  test 'le regroupement par agent donne à chacun sa part des heures' do
    resultat = Aibbo::OutilInterventions.new(@manager).call(regrouper_par: 'agent')
    bond = resultat[:groupes].find { |groupe| groupe['agent'] == 'Bond James' }

    assert_equal users(:bond).interventions.count, bond[:interventions]
    assert_equal 4.5, bond[:heures]
  end

  test 'sans classement demandé, le premier groupe est celui qui compte le plus d’interventions' do
    resultat = Aibbo::OutilInterventions.new(users(:administrateur_paris)).call(regrouper_par: 'agent')

    assert_equal 'Martin Michel', resultat[:groupes].first['agent']
    assert_equal users(:martin_technique_paris).interventions.count, resultat[:groupes].first[:interventions]
  end

  test 'le classement par heures place en tête le groupe qui en compte le plus' do
    resultat = Aibbo::OutilInterventions.new(users(:administrateur_paris)).call(regrouper_par: 'agent', trier_par: 'heures')

    assert_equal users(:agent_with_location).nom_prénom.strip, resultat[:groupes].first['agent']
    assert_equal 9.0, resultat[:groupes].first[:heures]
  end

  test 'une demande répétée à l’identique reçoit un rappel au lieu d’un second résultat' do
    outil = Aibbo::OutilInterventions.new(@manager)

    assert outil.call(etat: 'terminé').key?(:total)
    assert_equal({ deja_demande: Aibbo::Outil::DEJA_DEMANDE }, outil.call(etat: 'terminé'))
    assert outil.call(etat: 'nouveau').key?(:total)
  end

  private

  # Ce que l'outil rend à l'utilisateur quand le modèle l'appelle sans aucun filtre.
  def interventions_lues_par(utilisateur)
    Aibbo::OutilInterventions.new(utilisateur).call
  end

  def identifiants(resultat)
    resultat[:interventions].pluck(:id).sort
  end
end
