# frozen_string_literal: true

require 'test_helper'

# Disponibilité et POINTAGE.
#
# Un pointage (intervention fille) est une intervention comme une autre vis-à-vis
# des conflits de chevauchement. Règle dédiée en plus : un agent ne peut pas avoir
# deux POINTAGES OUVERTS simultanés (fille de pointage sans fin). Donc s'il oublie
# de clôturer un pointage et en démarre un autre (scan d'un autre QR), c'est bloqué.
# Le flux séquentiel normal (on clôture avant d'ouvrir le suivant) n'a jamais deux
# pointages ouverts à la fois et n'est donc pas gêné.
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
