# frozen_string_literal: true

require 'test_helper'

# Disponibilité ↔ ABSENCES, dans les deux sens, avec des dates partielles.
#
# ⚠ Incohérence CONNUE et ASSUMÉE (les absences restent sur les dates prévues,
# chantier reporté) : les deux gardes absence ne regardent QUE début_prévue /
# fin_prévue des interventions —
#   - Intervention#check_absence (intervention créée pendant une absence) ;
#   - Absence#no_overlapping_interventions (absence créée pendant une intervention).
# Une intervention n'ayant QUE des dates réelles passe donc au travers, dans les
# deux sens. Ces tests VERROUILLENT ce comportement actuel : s'ils cassent, c'est
# que la sémantique absences a changé — mettre à jour ces tests en conséquence.
class InterventionAbsenceDisponibiliteTest < ActiveSupport::TestCase
  setup do
    @agent = users(:bond)
    @adherent = users(:weil)
    @service = @adherent.services.first
    @org = organisations(:mairie_paris)
  end

  JOUR = '2025-04-08'

  # --- D. Intervention créée alors qu'une absence existe ------------------------

  test 'D1 intervention à dates RÉELLES seules pendant une absence → passe (check sur prévues uniquement)' do
    creer_absence

    intervention = construire(début: "#{JOUR} 10:00", fin: "#{JOUR} 11:00")

    assert intervention.valid?, intervention.errors.full_messages.to_sentence
  end

  test 'D2 intervention avec début PRÉVU seul le jour de l’absence → bloquée' do
    creer_absence

    intervention = construire(début_prévue: "#{JOUR} 10:00")

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages.join(' '), 'Agent(s) indisponible(s)'
  end

  test 'D3 pointage fille (dates réelles, jamais de prévues) pendant une absence → passe' do
    creer_absence

    pointage = construire(début: "#{JOUR} 10:00", fin: "#{JOUR} 11:00", template_slug: 'modele-x')

    assert pointage.valid?, pointage.errors.full_messages.to_sentence
  end

  # --- E. Absence créée alors qu'une intervention existe ------------------------

  test 'E1 absence sur le créneau d’une intervention PRÉVUE → refusée' do
    Intervention.create!(base.merge(début_prévue: "#{JOUR} 09:00", fin_prévue: "#{JOUR} 17:00"))

    absence = Absence.new(du: JOUR, au: JOUR, motif: 0, user: @agent)

    assert_not absence.valid?
    assert_includes absence.errors.full_messages.join(' '), 'déjà en intervention'
  end

  test 'E2 absence sur le créneau d’une intervention à dates RÉELLES seules → acceptée (trou symétrique connu)' do
    Intervention.create!(base.merge(début: "#{JOUR} 09:00", fin: "#{JOUR} 17:00"))

    absence = Absence.new(du: JOUR, au: JOUR, motif: 0, user: @agent)

    assert absence.valid?, absence.errors.full_messages.to_sentence
  end

  private

  def creer_absence
    Absence.create!(du: JOUR, au: JOUR, motif: 0, observation: 'Congé', user: @agent)
  end

  def base
    { description: 'Intervention', organisation: @org, agents: [@agent], adherent: @adherent, service: @service }
  end

  def construire(**attrs)
    Intervention.new(base.merge(attrs))
  end
end
