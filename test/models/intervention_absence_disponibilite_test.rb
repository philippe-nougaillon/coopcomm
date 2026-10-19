# frozen_string_literal: true

require 'test_helper'

# Disponibilité ↔ ABSENCES, dans les deux sens, avec des dates partielles.
class InterventionAbsenceDisponibiliteTest < ActiveSupport::TestCase
  setup do
    @agent = users(:bond)
    @adherent = users(:weil)
    @service = @adherent.services.first
    @org = organisations(:mairie_paris)
  end

  JOUR = '2025-04-08'
  LENDEMAIN = '2025-04-09'

  # --- D. Intervention créée alors qu'une absence existe ------------------------

  test 'une intervention à dates réelles seules pendant une absence est bloquée (D1)' do
    creer_absence

    intervention = construire(début: "#{JOUR} 10:00", fin: "#{JOUR} 11:00")

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages.join(' '), 'Agent(s) indisponible(s)'
  end

  test 'une intervention avec un début prévu seul le jour de l’absence est bloquée (D2)' do
    creer_absence

    intervention = construire(début_prévue: "#{JOUR} 10:00")

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages.join(' '), 'Agent(s) indisponible(s)'
  end

  test 'une fille de pointage pendant une absence est bloquée (dates réelles, jamais de prévues) (D3)' do
    creer_absence

    pointage = construire(début: "#{JOUR} 10:00", fin: "#{JOUR} 11:00", template_slug: 'modele-x')

    assert_not pointage.valid?
    assert_includes pointage.errors.full_messages.join(' '), 'Agent(s) indisponible(s)'
  end

  # --- E. Absence créée alors qu'une intervention existe ------------------------

  test 'une absence sur le créneau d’une intervention prévue est refusée (E1)' do
    Intervention.create!(base.merge(début_prévue: "#{JOUR} 09:00", fin_prévue: "#{JOUR} 17:00"))

    absence = Absence.new(du: JOUR, au: JOUR, motif: 0, user: @agent)

    assert_not absence.valid?
    assert_includes absence.errors.full_messages.join(' '), 'déjà en intervention'
  end

  test 'une absence sur le créneau d’une intervention à dates réelles seules est refusée (E2)' do
    Intervention.create!(base.merge(début: "#{JOUR} 09:00", fin: "#{JOUR} 17:00"))

    absence = Absence.new(du: JOUR, au: JOUR, motif: 0, user: @agent)

    assert_not absence.valid?
    assert_includes absence.errors.full_messages.join(' '), 'déjà en intervention'
  end

  test 'le refus d’une absence nomme l’intervention en conflit et ses horaires (E2b)' do
    Intervention.create!(base.merge(description: 'Tonte du stade', début_prévue: "#{JOUR} 09:00",
                                    fin_prévue: "#{JOUR} 17:00"))

    absence = Absence.new(du: JOUR, au: JOUR, motif: 0, user: @agent)
    absence.valid?

    message = absence.errors.full_messages.join(' ')

    assert_includes message, 'Tonte du stade'
    assert_includes message, '08/04/2025 09:00'
    assert_includes message, '08/04/2025 17:00'
  end

  test 'une absence de l’après-midi est acceptée alors que l’agent a réellement travaillé le matin (E4)' do
    Intervention.create!(base.merge(début: "#{JOUR} 09:00", fin: "#{JOUR} 12:00"))

    absence = Absence.new(du: JOUR, au: JOUR, motif: 0, après_midi: true, user: @agent)

    assert absence.valid?, absence.errors.full_messages.to_sentence
  end

  test 'une absence sur un pointage encore ouvert (sans fin) est acceptée (E5)' do
    Intervention.create!(base.merge(début: "#{JOUR} 09:00", template_slug: 'modele-x'))

    absence = Absence.new(du: JOUR, au: JOUR, motif: 0, user: @agent)

    assert absence.valid?, absence.errors.full_messages.to_sentence
  end

  test 'une absence du matin est acceptée alors qu’une intervention est prévue l’après-midi (E3)' do
    Intervention.create!(base.merge(début_prévue: "#{JOUR} 14:00", fin_prévue: "#{JOUR} 16:00"))

    absence = Absence.new(du: JOUR, au: JOUR, motif: 0, matin: true, user: @agent)

    assert absence.valid?, absence.errors.full_messages.to_sentence
  end

  # --- F. Demi-journées : matin = [00:00, 12:00[, après-midi = [12:00, 24:00[ ---

  test 'une intervention de 09:00 à 13:00 pendant une absence du matin est bloquée (F1)' do
    creer_absence(matin: true)

    intervention = construire(début_prévue: "#{JOUR} 09:00", fin_prévue: "#{JOUR} 13:00")

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages.join(' '), 'Agent(s) indisponible(s)'
  end

  test 'une intervention de 08:00 à 11:00 pendant une absence du matin est bloquée (F2)' do
    creer_absence(matin: true)

    intervention = construire(début_prévue: "#{JOUR} 08:00", fin_prévue: "#{JOUR} 11:00")

    assert_not intervention.valid?
  end

  test 'une intervention de 14:00 à 16:00 pendant une absence du matin est valide (F3)' do
    creer_absence(matin: true)

    intervention = construire(début_prévue: "#{JOUR} 14:00", fin_prévue: "#{JOUR} 16:00")

    assert intervention.valid?, intervention.errors.full_messages.to_sentence
  end

  test 'une intervention démarrant pile à 12:00 pendant une absence du matin est valide (borne exclusive) (F4)' do
    creer_absence(matin: true)

    intervention = construire(début_prévue: "#{JOUR} 12:00", fin_prévue: "#{JOUR} 16:00")

    assert intervention.valid?, intervention.errors.full_messages.to_sentence
  end

  test 'une intervention de 09:00 à 11:00 pendant une absence de l’après-midi est valide (F5)' do
    creer_absence(après_midi: true)

    intervention = construire(début_prévue: "#{JOUR} 09:00", fin_prévue: "#{JOUR} 11:00")

    assert intervention.valid?, intervention.errors.full_messages.to_sentence
  end

  test 'une intervention de 11:00 à 14:00 pendant une absence de l’après-midi est bloquée (F6)' do
    creer_absence(après_midi: true)

    intervention = construire(début_prévue: "#{JOUR} 11:00", fin_prévue: "#{JOUR} 14:00")

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages.join(' '), 'Agent(s) indisponible(s)'
  end

  test 'une intervention finissant pile à 12:00 pendant une absence de l’après-midi est valide (borne exclusive) (F7)' do
    creer_absence(après_midi: true)

    intervention = construire(début_prévue: "#{JOUR} 09:00", fin_prévue: "#{JOUR} 12:00")

    assert intervention.valid?, intervention.errors.full_messages.to_sentence
  end

  test 'une intervention l’après-midi pendant une absence de journée entière est bloquée (F8)' do
    creer_absence

    intervention = construire(début_prévue: "#{JOUR} 14:00", fin_prévue: "#{JOUR} 16:00")

    assert_not intervention.valid?
  end

  test 'une intervention avec un début prévu seul l’après-midi pendant une absence du matin est valide (F9)' do
    creer_absence(matin: true)

    intervention = construire(début_prévue: "#{JOUR} 15:00")

    assert intervention.valid?, intervention.errors.full_messages.to_sentence
  end

  test 'une absence du matin sur deux jours est une plage continue qui couvre l’après-midi du premier jour (F10)' do
    creer_absence(matin: true, au: LENDEMAIN)

    veille = construire(début_prévue: "#{JOUR} 14:00", fin_prévue: "#{JOUR} 16:00")
    lendemain_après_midi = construire(début_prévue: "#{LENDEMAIN} 14:00", fin_prévue: "#{LENDEMAIN} 16:00")

    assert_not veille.valid?
    assert lendemain_après_midi.valid?, lendemain_après_midi.errors.full_messages.to_sentence
  end

  test 'le grisage en direct du formulaire est cohérent avec la validation sur une demi-journée (F11)' do
    creer_absence(matin: true)

    matin = Intervention.get_unavailable_agents_with_absences([@agent.id], "#{JOUR} 09:00", "#{JOUR} 13:00")
    après_midi = Intervention.get_unavailable_agents_with_absences([@agent.id], "#{JOUR} 14:00", "#{JOUR} 16:00")

    assert_equal [@agent.id], matin
    assert_empty après_midi
  end

  # --- G. Pointage : un agent absent ne peut pas ouvrir de pointage ------------

  test 'un pointage ouvert le matin pendant une absence du matin est bloqué (G1)' do
    creer_absence(matin: true)

    pointage = construire(début: "#{JOUR} 09:00", template_slug: 'modele-x')

    assert_not pointage.valid?
    assert_includes pointage.errors.full_messages.join(' '), 'Agent(s) indisponible(s)'
  end

  test 'un pointage ouvert l’après-midi pendant une absence du matin est autorisé (G2)' do
    creer_absence(matin: true)

    pointage = construire(début: "#{JOUR} 14:00", template_slug: 'modele-x')

    assert pointage.valid?, pointage.errors.full_messages.to_sentence
  end

  test 'fermer un pointage déjà ouvert reste possible si une absence est posée après coup (G3)' do
    pointage = Intervention.create!(base.merge(début: "#{JOUR} 09:00", template_slug: 'modele-x'))
    creer_absence

    pointage.fin = "#{JOUR} 17:00"

    assert pointage.valid?, pointage.errors.full_messages.to_sentence
    assert pointage.save
  end

  test 'déplacer le début d’un pointage sur une absence reste bloqué (G4)' do
    pointage = Intervention.create!(base.merge(début: "#{LENDEMAIN} 09:00", template_slug: 'modele-x'))
    creer_absence

    pointage.début = "#{JOUR} 09:00"

    assert_not pointage.valid?
  end

  test 'un bon d’intervention saisi a posteriori sur un jour d’absence est bloqué (G5)' do
    creer_absence

    bon = construire(début: "#{JOUR} 08:00", fin: "#{JOUR} 12:00", workflow_state: 'terminé')

    assert_not bon.valid?
    assert_includes bon.errors.full_messages.join(' '), 'Agent(s) indisponible(s)'
  end

  private

  def creer_absence(du: JOUR, au: JOUR, matin: false, après_midi: false)
    Absence.create!(du: du, au: au, motif: 0, observation: 'Congé', user: @agent,
                    matin: matin, après_midi: après_midi)
  end

  def base
    { description: 'Intervention', organisation: @org, agents: [@agent], adherent: @adherent, service: @service }
  end

  def construire(**attrs)
    Intervention.new(base.merge(attrs))
  end
end
