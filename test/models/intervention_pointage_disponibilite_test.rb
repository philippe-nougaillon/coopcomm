# frozen_string_literal: true

require 'test_helper'

# Disponibilité et POINTAGE.
class InterventionPointageDisponibiliteTest < ActiveSupport::TestCase
  setup do
    @agent = users(:bond)
    @adherent = users(:weil)
    @service = @adherent.services.first
    @org = organisations(:mairie_paris)
  end

  test 'deux pointages séquentiels clôturés (créneaux disjoints) ne conflictent pas' do
    creer(début: '2025-04-08 08:00', fin: '2025-04-08 12:00', template_slug: 'modele-x') # 1re fille clôturée

    suivant = construire(début: '2025-04-08 13:00', fin: '2025-04-08 17:00', template_slug: 'modele-x')

    assert suivant.valid?, suivant.errors.full_messages.to_sentence
  end

  test 'un agent ne peut pas avoir deux pointages ouverts simultanés (oubli de clôture puis nouveau scan)' do
    creer(début: '2025-04-08 08:00', template_slug: 'modele-a') # pointage A resté ouvert (fin nil)

    pointage_b = construire(début: '2025-04-08 09:00', template_slug: 'modele-b') # nouveau scan, ouvert

    assert_not pointage_b.valid?
    assert_includes pointage_b.errors.full_messages.join(' '), 'a déjà un pointage en cours'
  end

  test 'rouvrir un pointage est permis une fois le précédent clôturé' do
    creer(début: '2025-04-08 08:00', fin: '2025-04-08 12:00', template_slug: 'modele-a') # A clôturé

    pointage_b = construire(début: '2025-04-08 13:00', template_slug: 'modele-b') # nouveau pointage ouvert

    assert pointage_b.valid?, pointage_b.errors.full_messages.to_sentence
  end

  test "un pointage dont le début tombe dans un créneau déjà posé de l'agent est bloqué" do
    creer(début: '2025-04-08 08:00', fin: '2025-04-08 12:00') # créneau fermé de l'agent

    # Pointage qui démarre à 09:00 (dans le créneau) → conflit standard (le début
    # tombe dans un intervalle défini), indépendamment de la règle « pointage ouvert ».
    pointage = construire(début: '2025-04-08 09:00', template_slug: 'modele-a')

    assert_not pointage.valid?
    assert_includes pointage.errors.full_messages.join(' '), 'Conflit(s) détecté(s) sur un agent'
  end

  test 'un modèle de pointage (repeter) sans dates ne conflicte jamais' do
    creer(début: '2025-04-08 10:00', fin: '2025-04-08 12:00') # occupe l'agent sur le créneau

    mere = construire(repeter: true) # modèle sans dates

    assert mere.valid?, mere.errors.full_messages.to_sentence
  end

  test 'agents_must_be_available : re-pointage du même modèle dans la seconde → invitation à attendre' do
    creer(début: '2025-04-08 08:00', fin: '2025-04-08 10:00', template_slug: 'modele-a')

    reprise = construire(début: '2025-04-08 10:00', template_slug: 'modele-a')

    assert_not reprise.valid?
    assert_includes reprise.errors.full_messages.join(' '), 'Veuillez attendre quelques secondes'
  end

  test 'agents_must_be_available : re-pointage du même modèle la seconde suivante → accepté' do
    creer(début: '2025-04-08 08:00', fin: '2025-04-08 10:00', template_slug: 'modele-a')

    reprise = construire(début: '2025-04-08 10:01', template_slug: 'modele-a')

    assert reprise.valid?, reprise.errors.full_messages.to_sentence
  end

  test 'agents_must_be_available : deux interventions sans pointage qui se touchent → conflit standard' do
    creer(début: '2025-04-08 10:00', fin: '2025-04-08 12:00')

    ordinaire = construire(début: '2025-04-08 12:00', fin: '2025-04-08 14:00')

    assert_not ordinaire.valid?
    assert_includes ordinaire.errors.full_messages.join(' '), 'Conflit(s) détecté(s) sur un agent'
  end

  test 'agents_must_be_available : pointages de modèles différents qui se touchent → conflit standard' do
    creer(début: '2025-04-08 08:00', fin: '2025-04-08 10:00', template_slug: 'modele-a')

    autre_modele = construire(début: '2025-04-08 10:00', template_slug: 'modele-b')

    assert_not autre_modele.valid?
    assert_includes autre_modele.errors.full_messages.join(' '), 'Conflit(s) détecté(s) sur un agent'
  end

  test 'agents_must_be_available : pointage du même modèle qui chevauche vraiment → conflit standard' do
    creer(début: '2025-04-08 08:00', fin: '2025-04-08 12:00', template_slug: 'modele-a')

    chevauchant = construire(début: '2025-04-08 10:00', template_slug: 'modele-a')

    assert_not chevauchant.valid?
    assert_includes chevauchant.errors.full_messages.join(' '), 'Conflit(s) détecté(s) sur un agent'
  end

  test 'agents_must_be_available : reprise dans la minute doublée d’un vrai conflit → conflit standard' do
    creer(début: '2025-04-08 08:00', fin: '2025-04-08 10:00', template_slug: 'modele-a')
    ordinaire_chevauchante = creer(début: '2025-04-08 13:00', fin: '2025-04-08 15:00')
    ordinaire_chevauchante.update_columns(début: Time.zone.parse('2025-04-08 09:00'),
                                          fin: Time.zone.parse('2025-04-08 12:00'))

    reprise = construire(début: '2025-04-08 10:00', template_slug: 'modele-a')

    assert_not reprise.valid?
    assert_includes reprise.errors.full_messages.join(' '), 'Conflit(s) détecté(s) sur un agent'
  end

  private

  def base
    { description: 'Intervention', organisation: @org, agents: [@agent], adherent: @adherent, service: @service }
  end

  def creer(**attrs)
    Intervention.create!(base.merge(attrs))
  end

  def construire(**attrs)
    Intervention.new(base.merge(attrs))
  end
end
