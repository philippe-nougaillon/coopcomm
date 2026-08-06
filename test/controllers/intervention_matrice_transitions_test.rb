# frozen_string_literal: true

require 'test_helper'
require_relative '../support/interventions_matrice'

# Matrice de caractérisation de l'APPLICATION effective des droits : ce que le
# contrôleur accepte réellement de faire, pour chaque acteur et chaque état.
#
# C'est le filet qui garantit qu'aucune transition ne devient possible — ni
# impossible — au fil du remaniement du contrôleur.
class InterventionMatriceTransitionsTest < ActionDispatch::IntegrationTest
  include InterventionsMatrice

  ACTEURS = {
    'administrateur' => :administrateur_paris,
    'manager' => :hidalgo,
    'agent_affecte' => :martin_technique_paris,
    'agent_non_affecte' => :john_wick,
    'adherent_proprietaire' => :weil,
    'manager_autre_organisation' => :manager_marseille
  }.freeze

  ACTIONS = %i[terminer valider refuser archiver destroy].freeze

  GESTIONNAIRE = {
    terminer: [Intervention::NOUVEAU],
    valider: [Intervention::TERMINE],
    refuser: [Intervention::TERMINE],
    archiver: [Intervention::VALIDE, Intervention::REFUSE],
    # Aucune garde d'état sur la suppression : même une intervention archivée
    # est supprimable par un manager ou un administrateur.
    destroy: InterventionsMatrice::ETATS
  }.freeze

  TRANSITIONS_AUTORISEES = {
    'administrateur' => GESTIONNAIRE,
    'manager' => GESTIONNAIRE,
    'agent_affecte' => { terminer: [Intervention::NOUVEAU] },
    'agent_non_affecte' => {},
    'adherent_proprietaire' => { valider: [Intervention::TERMINE], refuser: [Intervention::TERMINE] },
    'manager_autre_organisation' => {}
  }.freeze

  # Les acteurs dont la policy autorise valider/refuser, et qui tombent donc sur
  # le bug B3/B7 lorsque l'état ne permet pas la transition.
  ACTEURS_AVEC_VALIDATION = %w[administrateur manager adherent_proprietaire].freeze

  ACTEURS.each_key do |nom_acteur|
    test "#{nom_acteur} : transitions acceptées et refusées, état par état" do
      InterventionsMatrice::ETATS.each do |etat|
        ACTIONS.each do |action|
          verifie_transition(nom_acteur, etat, action)
        end
      end
    end
  end

  # ÉPINGLAGE du bug B3/B7 : `valider!` et `refuser!` sont appelés sans garde
  # `can_valider?` / `can_refuser?` et sans rescue, contrairement à `terminer` et
  # `archiver`. Sur une intervention VALIDE dont l'état ne permet pas la
  # transition, la requête part en 500 au lieu de rediriger avec un message.
  # Le garde `redirect_si_invalide` ne masque le défaut que si l'intervention est
  # par ailleurs invalide — ce qui explique que le test existant du double-clic
  # soit resté en `skip`.
  # À inverser à la correction : le résultat attendu deviendra une redirection.
  test 'épinglage B3/B7 : valider hors état lève une exception au lieu de rediriger' do
    intervention = intervention_matrice(type: :classique, etat: Intervention::NOUVEAU, complete: true)
    assert intervention.valid?, "garde : l'intervention doit être valide, sinon le bug est masqué"
    sign_in users(:administrateur_paris)

    assert_raises(Workflow::NoTransitionAllowed) { post valider_intervention_url(intervention) }
  end

  test 'épinglage B3/B7 : refuser hors état lève une exception au lieu de rediriger' do
    intervention = intervention_matrice(type: :classique, etat: Intervention::VALIDE, complete: true)
    assert intervention.valid?, "garde : l'intervention doit être valide, sinon le bug est masqué"
    sign_in users(:administrateur_paris)

    assert_raises(Workflow::NoTransitionAllowed) { post refuser_intervention_url(intervention) }
  end

  private

  def verifie_transition(nom_acteur, etat, action)
    intervention = intervention_matrice(type: :classique, etat: etat, complete: true)
    reset!
    sign_in users(ACTEURS[nom_acteur])

    contexte = "#{nom_acteur} / #{etat} / #{action}"
    autorisee = TRANSITIONS_AUTORISEES.fetch(nom_acteur).fetch(action, []).include?(etat)

    if bug_b7?(nom_acteur, action, autorisee)
      assert_raises(Workflow::NoTransitionAllowed, contexte) { declenche(action, intervention) }
      return
    end

    declenche(action, intervention)

    if autorisee
      assert_equal 'notice', type_de_flash, "#{contexte} : la transition devait aboutir"
      assert_equal etat_attendu(action, etat), etat_final(intervention), contexte
    else
      assert_equal 'alert', type_de_flash, "#{contexte} : la transition devait être refusée"
      assert_equal etat, etat_final(intervention), "#{contexte} : l'état ne devait pas changer"
    end
  end

  def bug_b7?(nom_acteur, action, autorisee)
    !autorisee && %i[valider refuser].include?(action) &&
      ACTEURS_AVEC_VALIDATION.include?(nom_acteur)
  end

  def declenche(action, intervention)
    if action == :destroy
      delete intervention_url(intervention)
    else
      post send(:"#{action}_intervention_url", intervention)
    end
  end

  def etat_attendu(action, etat)
    return 'SUPPRIMEE' if action == :destroy

    { terminer: Intervention::TERMINE, valider: Intervention::VALIDE,
      refuser: Intervention::REFUSE, archiver: Intervention::ARCHIVE }.fetch(action)
  end

  def etat_final(intervention)
    Intervention.find_by(id: intervention.id)&.workflow_state || 'SUPPRIMEE'
  end

  def type_de_flash
    return 'alert' if flash[:alert]

    flash[:notice] ? 'notice' : '-'
  end
end
