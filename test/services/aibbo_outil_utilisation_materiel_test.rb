# frozen_string_literal: true

require 'test_helper'

class AibboOutilUtilisationMaterielTest < ActiveSupport::TestCase
  setup do
    @manager = users(:hidalgo)
  end

  # ==================== TESTS CRITIQUES ====================
  # L'emploi du matériel ne sort pas de l'organisation de l'utilisateur, ni ses retards des interventions qu'il peut consulter.
  test 'un manager ne reçoit que l’emploi du matériel de son organisation (critique)' do
    resultat = Aibbo::OutilUtilisationMateriel.new(@manager).call(du: '2024-05-06', au: '2024-05-10')

    assert_equal tools(:tondeuse, :rateau, :cisaille, :outil_paris, :outil_adherent, :taille_haie_en_panne_en_mai_2024,
                       :souffleur_reserve_en_mai_2024).map(&:name).sort, resultat[:matériel].pluck(:nom).sort
  end

  test 'le nom d’un matériel d’une autre organisation n’est pas reconnu (critique)' do
    resultat = Aibbo::OutilUtilisationMateriel.new(@manager).call(du: '2024-05-06', au: '2024-05-10', nom: tools(:camion).name)

    assert_match(/introuvable parmi le matériel/, resultat[:erreur])
    assert_nil resultat[:matériel]
  end

  test 'un adhérent ne reçoit l’emploi d’aucun matériel (critique)' do
    resultat = Aibbo::OutilUtilisationMateriel.new(users(:weil)).call(du: '2024-05-06', au: '2024-05-10')

    assert_empty resultat[:matériel]
  end

  test 'un retard ne se compte que sur les interventions que l’utilisateur peut consulter (critique)' do
    ensemble = Aibbo::OutilUtilisationMateriel.new(@manager).call(du: '2024-04-22', au: '2024-04-26', nom: 'souffleur')[:ensemble]

    assert_not Intervention.visible_to(@manager).include?(interventions(:intervention_en_retard_avril_2024))
    assert_equal 0, ensemble[:interventions_datées]
    assert_equal 0, ensemble[:commencées_en_retard]
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'un jour réservé compte pour un jour d’emploi et pour sa part du taux d’occupation' do
    resultat = Aibbo::OutilUtilisationMateriel.new(@manager).call(du: '2024-05-06', au: '2024-05-10', nom: 'souffleur')

    assert_equal 5, resultat[:jours_ouvrés]
    assert_equal 1, resultat[:matériel].first[:jours_d_emploi]
    assert_equal 20.0, resultat[:matériel].first[:taux_d_occupation]
  end

  test 'un jour pris par une intervention compte pour un jour d’emploi' do
    resultat = Aibbo::OutilUtilisationMateriel.new(@manager).call(du: '2024-04-15', au: '2024-04-19', nom: 'cisaille')

    assert_equal 1, resultat[:matériel].first[:jours_d_emploi]
  end

  test 'les jours de panne vont de la panne à la veille de sa fin' do
    resultat = Aibbo::OutilUtilisationMateriel.new(@manager).call(du: '2024-05-01', au: '2024-05-31', nom: 'taille-haie')

    assert_equal 4, resultat[:matériel].first[:jours_de_panne]
    assert_equal 1, resultat[:matériel].first[:pannes]
    assert_equal 0, resultat[:matériel].first[:jours_d_emploi]
  end

  test 'les samedis et les dimanches ne comptent pas dans les jours ouvrés' do
    resultat = Aibbo::OutilUtilisationMateriel.new(@manager).call(du: '2024-05-06', au: '2024-05-12', nom: 'souffleur')

    assert_equal 5, resultat[:jours_ouvrés]
  end

  test 'l’emploi simultané compte les jours selon le nombre de matériels en service' do
    ensemble = Aibbo::OutilUtilisationMateriel.new(@manager).call(du: '2024-05-06', au: '2024-05-10')[:ensemble]

    assert_equal [{ matériels_en_service: 0, jours: 4 }, { matériels_en_service: 1, jours: 1 }], ensemble[:emploi_simultané]
    assert_equal 1, ensemble[:maximum_en_service_le_même_jour]
    assert_equal 0, ensemble[:jours_sans_aucun_libre]
  end

  test 'un jour où le seul matériel retenu est en panne est un jour sans aucun libre' do
    ensemble = Aibbo::OutilUtilisationMateriel.new(@manager).call(du: '2024-05-06', au: '2024-05-10', nom: 'taille-haie')[:ensemble]

    assert_equal 4, ensemble[:jours_sans_aucun_libre]
  end

  test 'une intervention commencée après son début prévu compte pour un retard, en jours' do
    ensemble = Aibbo::OutilUtilisationMateriel.new(users(:administrateur_paris)).call(du: '2024-04-22', au: '2024-04-26', nom: 'souffleur')[:ensemble]

    assert_equal 1, ensemble[:interventions_datées]
    assert_equal 1, ensemble[:commencées_en_retard]
    assert_equal 2.0, ensemble[:retard_moyen_en_jours]
  end

  test 'sans période, l’emploi porte sur les douze derniers mois' do
    resultat = travel_to(Time.zone.local(2024, 5, 31, 12)) { Aibbo::OutilUtilisationMateriel.new(@manager).call(nom: 'taille-haie') }

    assert_equal %w[2023-06-01 2024-05-31], resultat.values_at(:du, :au)
    assert_equal 4, resultat[:matériel].first[:jours_de_panne]
  end

  test 'une période qui dépasse aujourd’hui s’arrête à aujourd’hui, sans compter de panne à venir' do
    resultat = travel_to(Time.zone.local(2024, 5, 8, 12)) do
      Aibbo::OutilUtilisationMateriel.new(@manager).call(du: '2024-05-06', au: '2024-05-31', nom: 'taille-haie')
    end

    assert_equal '2024-05-08', resultat[:au]
    assert_equal 3, resultat[:matériel].first[:jours_de_panne]
  end

  test 'le détail par mois donne à chaque mois ses jours ouvrés et ses jours sans aucun matériel libre' do
    ensemble = Aibbo::OutilUtilisationMateriel.new(@manager).call(du: '2024-04-01', au: '2024-05-31', nom: 'taille-haie')[:ensemble]

    assert_equal [{ mois: '2024-04', jours_ouvrés: 22, maximum_en_service: 0, jours_sans_aucun_libre: 0 },
                  { mois: '2024-05', jours_ouvrés: 23, maximum_en_service: 0, jours_sans_aucun_libre: 4 }], ensemble[:par_mois]
    assert_equal 4, ensemble[:jours_de_panne]
  end

  test 'le classement par pannes place en tête le matériel le plus longtemps en panne' do
    resultat = Aibbo::OutilUtilisationMateriel.new(@manager).call(du: '2024-05-06', au: '2024-05-10', trier_par: 'pannes')

    assert_equal tools(:taille_haie_en_panne_en_mai_2024).name, resultat[:matériel].first[:nom]
  end

  test 'sans classement demandé, le matériel le plus employé vient en tête' do
    resultat = Aibbo::OutilUtilisationMateriel.new(@manager).call(du: '2024-05-06', au: '2024-05-10')

    assert_equal tools(:souffleur_reserve_en_mai_2024).name, resultat[:matériel].first[:nom]
  end

  test 'une période de plus de quatre cents jours est renvoyée à l’utilisateur sans rien calculer' do
    resultat = Aibbo::OutilUtilisationMateriel.new(@manager).call(du: '2022-01-01', au: '2024-12-31')

    assert_match(/400 jours/, resultat[:erreur])
    assert_nil resultat[:matériel]
  end
end
