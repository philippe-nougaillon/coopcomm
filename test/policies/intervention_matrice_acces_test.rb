# frozen_string_literal: true

require 'test_helper'
require_relative '../support/interventions_matrice'

# Matrice de caractérisation des accès aux interventions : chaque acteur, chaque
# type d'intervention, chaque état du workflow. Ce fichier fige le comportement
# EXISTANT — toute différence est une régression tant que la décision métier
# correspondante n'a pas été prise.
class InterventionMatriceAccesTest < ActiveSupport::TestCase
  include InterventionsMatrice

  ACTEURS = {
    'administrateur' => :administrateur_paris,
    'manager_avec_service' => :hidalgo,
    'manager_sans_service' => :manager_paris,
    'agent_affecte' => :martin_technique_paris,
    'agent_non_affecte' => :john_wick,
    'adherent_proprietaire' => :weil,
    'adherent_autre' => :patrick_adherent_paris,
    'manager_autre_organisation' => :manager_marseille,
    'agent_autre_organisation' => :agent_marseille,
    'adherent_autre_organisation' => :adherent_marseille
  }.freeze

  PREDICATS_RECORD = %i[show? edit? update? destroy? terminer? valider? refuser? archiver? purge?
                        pointer? pointage_statut? can_see_qrcode_pointage_pdf? update_location?].freeze

  PREDICATS_GLOBAUX = %i[index? new? create? get_unavailable_elements? services_for_adherent?
                         agents_for_service? new_intervention_modele_pointage?
                         create_intervention_modele_pointage?].freeze

  TOUS = %i[index? new? create? get_unavailable_elements? services_for_adherent? agents_for_service?].freeze
  AVEC_MODELE_POINTAGE = (TOUS + %i[new_intervention_modele_pointage?
                                    create_intervention_modele_pointage?]).freeze

  # Le droit de créer un modèle de pointage suit le seul rôle : manager ou
  # administrateur, y compris hors de l'organisation de l'intervention.
  GLOBAUX_ATTENDUS = {
    'administrateur' => AVEC_MODELE_POINTAGE,
    'manager_avec_service' => AVEC_MODELE_POINTAGE,
    'manager_sans_service' => AVEC_MODELE_POINTAGE,
    'manager_autre_organisation' => AVEC_MODELE_POINTAGE,
    'agent_affecte' => TOUS,
    'agent_non_affecte' => TOUS,
    'adherent_proprietaire' => TOUS,
    'adherent_autre' => TOUS,
    'agent_autre_organisation' => TOUS,
    'adherent_autre_organisation' => TOUS
  }.freeze

  GESTIONNAIRE = %i[show? edit? update? destroy? terminer? valider? refuser? archiver? purge?
                    can_see_qrcode_pointage_pdf?].freeze
  AGENT_AFFECTE = %i[show? edit? update? terminer? purge? pointer? pointage_statut?
                     update_location?].freeze
  # Un agent ne modifie pas un modèle de pointage (`edit?` exige !repeter).
  AGENT_AFFECTE_MODELE = %i[show? terminer? purge? pointer? pointage_statut? update_location?].freeze
  ADHERENT = %i[show? edit? update? valider? refuser? purge? can_see_qrcode_pointage_pdf?].freeze
  AUCUN = [].freeze

  RECORD_ATTENDUS = {
    'administrateur' => { classique: GESTIONNAIRE, modele: GESTIONNAIRE, fille: GESTIONNAIRE },
    'manager_avec_service' => { classique: GESTIONNAIRE, modele: GESTIONNAIRE, fille: GESTIONNAIRE },
    'manager_sans_service' => { classique: GESTIONNAIRE, modele: GESTIONNAIRE, fille: GESTIONNAIRE },
    'agent_affecte' => { classique: AGENT_AFFECTE, modele: AGENT_AFFECTE_MODELE, fille: AGENT_AFFECTE },
    'agent_non_affecte' => { classique: AUCUN, modele: AUCUN, fille: AUCUN },
    'adherent_proprietaire' => { classique: ADHERENT, modele: ADHERENT, fille: ADHERENT },
    'adherent_autre' => { classique: AUCUN, modele: AUCUN, fille: AUCUN },
    'manager_autre_organisation' => { classique: AUCUN, modele: AUCUN, fille: AUCUN },
    'agent_autre_organisation' => { classique: AUCUN, modele: AUCUN, fille: AUCUN },
    'adherent_autre_organisation' => { classique: AUCUN, modele: AUCUN, fille: AUCUN }
  }.freeze

  # Ce que l'acteur peut RÉELLEMENT déclencher : la policy conjuguée à la garde de
  # la gem workflow (`can_terminer?`…), c'est-à-dire ce que les vues calculent.
  ACTIONS = { terminer: :can_terminer?, valider: :can_valider?,
              refuser: :can_refuser?, archiver: :can_archiver? }.freeze

  PROFIL_GESTIONNAIRE = {
    Intervention::NOUVEAU => %i[terminer],
    Intervention::POINTAGE_ACTIVE => [],
    Intervention::TERMINE => %i[valider refuser],
    Intervention::VALIDE => %i[archiver],
    Intervention::REFUSE => %i[archiver],
    Intervention::ARCHIVE => []
  }.freeze

  PROFIL_AGENT_AFFECTE = PROFIL_GESTIONNAIRE.transform_values { |actions| actions & %i[terminer] }.freeze
  PROFIL_ADHERENT = PROFIL_GESTIONNAIRE.transform_values { |actions| actions & %i[valider refuser] }.freeze
  PROFIL_AUCUN = PROFIL_GESTIONNAIRE.transform_values { [] }.freeze

  PROFIL_PAR_ACTEUR = {
    'administrateur' => PROFIL_GESTIONNAIRE,
    'manager_avec_service' => PROFIL_GESTIONNAIRE,
    'manager_sans_service' => PROFIL_GESTIONNAIRE,
    'agent_affecte' => PROFIL_AGENT_AFFECTE,
    'agent_non_affecte' => PROFIL_AUCUN,
    'adherent_proprietaire' => PROFIL_ADHERENT,
    'adherent_autre' => PROFIL_AUCUN,
    'manager_autre_organisation' => PROFIL_AUCUN,
    'agent_autre_organisation' => PROFIL_AUCUN,
    'adherent_autre_organisation' => PROFIL_AUCUN
  }.freeze

  setup do
    mere_matrice
    @interventions = TYPES.to_h { |type| [type, intervention_matrice(type: type)] }
  end

  test 'garde : la matrice couvre bien les trois types et les six états' do
    assert_equal %i[classique modele fille], TYPES
    assert_equal 6, ETATS.size
    assert_equal Intervention.workflow_spec.states.keys.map(&:to_s).sort, ETATS.sort
  end

  ACTEURS.each_key do |nom_acteur|
    test "#{nom_acteur} : prédicats indépendants de l'intervention" do
      policy = InterventionPolicy.new(users(ACTEURS[nom_acteur]), Intervention)
      vrais = PREDICATS_GLOBAUX.select { |predicat| policy.public_send(predicat) }

      assert_equal GLOBAUX_ATTENDUS[nom_acteur], vrais
    end

    test "#{nom_acteur} : prédicats sur l'intervention, par type" do
      user = users(ACTEURS[nom_acteur])

      reel = TYPES.to_h do |type|
        policy = InterventionPolicy.new(user, @interventions[type])
        [type, PREDICATS_RECORD.select { |predicat| policy.public_send(predicat) }]
      end

      assert_equal RECORD_ATTENDUS[nom_acteur], reel
    end

    test "#{nom_acteur} : les prédicats ne dépendent d'aucun état du workflow" do
      user = users(ACTEURS[nom_acteur])

      TYPES.each do |type|
        par_etat = ETATS.to_h do |etat|
          policy = InterventionPolicy.new(user, etat_en_memoire(@interventions[type], etat))
          [etat, PREDICATS_RECORD.select { |predicat| policy.public_send(predicat) }]
        end

        assert_equal 1, par_etat.values.uniq.size,
                     "#{nom_acteur}/#{type} : la policy s'est mise à dépendre de l'état → #{par_etat}"
      end
    end

    test "#{nom_acteur} : actions déclenchables par état" do
      user = users(ACTEURS[nom_acteur])

      TYPES.each do |type|
        reel = ETATS.to_h do |etat|
          intervention = etat_en_memoire(@interventions[type], etat)
          policy = InterventionPolicy.new(user, intervention)
          actions = ACTIONS.select do |action, garde|
            policy.public_send(:"#{action}?") && intervention.public_send(garde)
          end.keys
          [etat, actions]
        end

        assert_equal PROFIL_PAR_ACTEUR[nom_acteur], reel, "#{nom_acteur} / #{type}"
      end
    end
  end
end
