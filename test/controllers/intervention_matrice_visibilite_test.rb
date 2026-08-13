# frozen_string_literal: true

require 'test_helper'
require_relative '../support/interventions_matrice'

# Matrice de caractérisation de la page d'une intervention : qui voit quoi, pour
# chaque type d'intervention et chaque état du workflow. Ce fichier fige le
# comportement EXISTANT, incohérences comprises — les incohérences connues sont
# signalées au registre, pas corrigées ici.
#
# Chaque sonde est une donnée ou un intitulé de section, jamais une classe CSS :
# un renommage de style ne doit rien casser.
class InterventionMatriceVisibiliteTest < ActionDispatch::IntegrationTest
  include InterventionsMatrice

  ACTEURS = {
    'administrateur' => :administrateur_paris,
    'manager' => :hidalgo,
    'agent_affecte' => :martin_technique_paris,
    'adherent_proprietaire' => :weil
  }.freeze

  SONDES = {
    'bloc:demande' => %r{>Demande</h2>}i,
    'bloc:assignation' => %r{>Assignation</h2>}i,
    'bloc:intervention' => %r{>Intervention</h2>}i,
    'bloc:compte_rendu' => %r{>Compte-rendu</h2>}i,
    'bloc:actions' => %r{>Actions</h2>}i,
    'bloc:activite' => %r{>Activité</h2>}i,
    'bloc:pointages' => %r{>Pointages</h2>}i,
    'donnee:debut_prevue' => 'Début prévue',
    'donnee:agent_pointage' => '<span>Agent</span>',
    'donnee:temps_passe' => 'Temps passé',
    'donnee:temps_total' => 'Temps total',
    'donnee:pause' => 'Pause',
    'donnee:commentaires' => InterventionsMatrice::SONDE_COMMENTAIRES,
    'donnee:avis' => InterventionsMatrice::SONDE_AVIS,
    'donnee:meteo' => InterventionsMatrice::SONDE_METEO,
    'donnee:photos' => %r{>\s*Photos\s*</span>},
    'donnee:photos_demande' => %r{>\s*Photos de la demande\s*</span>},
    'action:modifier' => 'Modifier',
    'action:supprimer' => "Supprimer l'intervention",
    'action:qrcode' => 'QR Code',
    'action:terminer' => '>Terminer<',
    'action:valider' => '>Valider<',
    'action:refuser' => '>Refuser<'
  }.freeze

  DEMANDE = %w[bloc:demande donnee:meteo donnee:photos_demande].freeze
  DATES_PREVUES = %w[donnee:debut_prevue].freeze
  ASSIGNATION = %w[bloc:assignation].freeze
  REALISATION = %w[bloc:intervention donnee:temps_passe donnee:temps_total donnee:pause
                   donnee:commentaires donnee:photos].freeze
  # Section « Intervention » de l'adhérent : dates et temps, sans les
  # commentaires ni les photos de réalisation que voient les autres rôles.
  TEMPS_ADHERENT = %w[bloc:intervention donnee:temps_passe donnee:temps_total donnee:pause].freeze
  POINTAGES = %w[bloc:pointages donnee:temps_total].freeze
  # La colonne « Agent » du tableau des pointages, masquée au seul agent noté.
  AGENT_POINTAGE = %w[donnee:agent_pointage].freeze
  ACTIVITE = %w[bloc:activite].freeze
  COMPTE_RENDU = %w[bloc:compte_rendu donnee:avis].freeze

  GESTION = %w[action:modifier action:supprimer].freeze

  # Ce que chaque acteur voit indépendamment de l'état du workflow.
  BASE = {
    %w[administrateur classique] => DEMANDE + DATES_PREVUES + ASSIGNATION + REALISATION + ACTIVITE + GESTION,
    %w[administrateur modele] => DEMANDE + DATES_PREVUES + ASSIGNATION + POINTAGES + AGENT_POINTAGE +
                                 ACTIVITE + GESTION + ['action:qrcode'],
    %w[administrateur fille] => DEMANDE + DATES_PREVUES + ASSIGNATION + REALISATION + ACTIVITE + GESTION,
    %w[manager classique] => DEMANDE + DATES_PREVUES + ASSIGNATION + REALISATION + ACTIVITE + GESTION,
    %w[manager modele] => DEMANDE + DATES_PREVUES + ASSIGNATION + POINTAGES + AGENT_POINTAGE +
                          ACTIVITE + GESTION + ['action:qrcode'],
    %w[manager fille] => DEMANDE + DATES_PREVUES + ASSIGNATION + REALISATION + ACTIVITE + GESTION,
    # L'agent ne voit ni l'historique d'activité ni le compte-rendu (évaluation),
    # et ne peut pas modifier un modèle de pointage.
    %w[agent_affecte classique] => DEMANDE + DATES_PREVUES + ASSIGNATION + REALISATION + ['action:modifier'],
    %w[agent_affecte modele] => DEMANDE + DATES_PREVUES + ASSIGNATION + POINTAGES,
    %w[agent_affecte fille] => DEMANDE + DATES_PREVUES + ASSIGNATION + REALISATION + ['action:modifier'],
    # L'adhérent a sa propre section « Intervention » : dates et temps, sauf sur
    # un modèle de pointage, où il reçoit le tableau des pointages comme les
    # autres rôles. Les dates prévues et l'assignation lui sont ajoutées par
    # `attendu`, sauf à l'état « pointage activé ».
    %w[adherent_proprietaire classique] => DEMANDE + TEMPS_ADHERENT + ['action:modifier'],
    %w[adherent_proprietaire modele] => DEMANDE + POINTAGES + AGENT_POINTAGE +
                                        ['action:modifier', 'action:qrcode'],
    %w[adherent_proprietaire fille] => DEMANDE + TEMPS_ADHERENT + ['action:modifier']
  }.freeze

  ETATS_AVEC_COMPTE_RENDU = [Intervention::VALIDE, Intervention::REFUSE].freeze
  ACTEURS_AVEC_COMPTE_RENDU = %w[administrateur manager adherent_proprietaire].freeze

  # Boutons de workflow proposés par la page. Aucun bouton « Archiver » n'existe
  # nulle part dans l'application, alors que l'action et sa policy existent.
  BOUTONS = {
    'administrateur' => { Intervention::NOUVEAU => ['action:terminer'],
                          Intervention::TERMINE => ['action:valider', 'action:refuser'] },
    'manager' => { Intervention::NOUVEAU => ['action:terminer'],
                   Intervention::TERMINE => ['action:valider', 'action:refuser'] },
    'agent_affecte' => { Intervention::NOUVEAU => ['action:terminer'] },
    'adherent_proprietaire' => { Intervention::TERMINE => ['action:valider', 'action:refuser'] }
  }.freeze

  setup { mere_matrice }

  ACTEURS.each_key do |nom_acteur|
    InterventionsMatrice::TYPES.each do |type|
      test "#{nom_acteur} / #{type} : blocs visibles sur la page, état par état" do
        sign_in users(ACTEURS[nom_acteur])

        InterventionsMatrice::ETATS.each do |etat|
          intervention = intervention_matrice(type: type, etat: etat, complete: true)
          get intervention_url(intervention)

          assert_response :success, "#{nom_acteur}/#{type}/#{etat}"
          assert_equal attendu(nom_acteur, type, etat), sondes_presentes,
                       "#{nom_acteur} / #{type} / #{etat}"
        end
      end
    end
  end

  test "garde anti-faux-positif : chaque sonde apparaît au moins une fois dans la matrice" do
    couvertes = ACTEURS.keys.product(InterventionsMatrice::TYPES, InterventionsMatrice::ETATS)
                       .flat_map { |acteur, type, etat| attendu(acteur, type, etat) }.uniq

    assert_equal SONDES.keys.sort, couvertes.sort,
                 'une sonde jamais attendue ne prouve rien : elle ne vérifie que son absence'
  end

  private

  def sondes_presentes
    SONDES.select { |_, sonde| sonde.is_a?(Regexp) ? response.body.match?(sonde) : response.body.include?(sonde) }.keys.sort
  end

  def attendu(nom_acteur, type, etat)
    sondes = BASE[[nom_acteur, type.to_s]].dup
    if ETATS_AVEC_COMPTE_RENDU.include?(etat) && ACTEURS_AVEC_COMPTE_RENDU.include?(nom_acteur)
      sondes += COMPTE_RENDU
    end

    if nom_acteur == 'adherent_proprietaire' && etat != Intervention::POINTAGE_ACTIVE
      sondes += DATES_PREVUES + ASSIGNATION
    end

    # Un modèle de pointage ne propose aucune transition de workflow.
    boutons = type == :modele ? [] : BOUTONS.fetch(nom_acteur, {}).fetch(etat, [])
    sondes += ['bloc:actions'] + boutons if boutons.any?

    sondes.uniq.sort
  end
end
