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

  test 'D1 intervention à dates RÉELLES seules pendant une absence → bloquée' do
    creer_absence

    intervention = construire(début: "#{JOUR} 10:00", fin: "#{JOUR} 11:00")

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages.join(' '), 'Agent(s) indisponible(s)'
  end

  test 'D2 intervention avec début PRÉVU seul le jour de l’absence → bloquée' do
    creer_absence

    intervention = construire(début_prévue: "#{JOUR} 10:00")

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages.join(' '), 'Agent(s) indisponible(s)'
  end

  test 'D3 pointage fille (dates réelles, jamais de prévues) pendant une absence → bloquée' do
    creer_absence

    pointage = construire(début: "#{JOUR} 10:00", fin: "#{JOUR} 11:00", template_slug: 'modele-x')

    assert_not pointage.valid?
    assert_includes pointage.errors.full_messages.join(' '), 'Agent(s) indisponible(s)'
  end

  # --- E. Absence créée alors qu'une intervention existe ------------------------

  test 'E1 absence sur le créneau d’une intervention PRÉVUE → refusée' do
    Intervention.create!(base.merge(début_prévue: "#{JOUR} 09:00", fin_prévue: "#{JOUR} 17:00"))

    absence = Absence.new(du: JOUR, au: JOUR, motif: 0, user: @agent)

    assert_not absence.valid?
    assert_includes absence.errors.full_messages.join(' '), 'déjà en intervention'
  end

  test 'E2 absence sur le créneau d’une intervention à dates RÉELLES seules → refusée' do
    Intervention.create!(base.merge(début: "#{JOUR} 09:00", fin: "#{JOUR} 17:00"))

    absence = Absence.new(du: JOUR, au: JOUR, motif: 0, user: @agent)

    assert_not absence.valid?
    assert_includes absence.errors.full_messages.join(' '), 'déjà en intervention'
  end

  test 'E2b le refus nomme l’intervention en conflit et ses horaires' do
    Intervention.create!(base.merge(description: 'Tonte du stade', début_prévue: "#{JOUR} 09:00",
                                    fin_prévue: "#{JOUR} 17:00"))

    absence = Absence.new(du: JOUR, au: JOUR, motif: 0, user: @agent)
    absence.valid?

    message = absence.errors.full_messages.join(' ')

    assert_includes message, 'Tonte du stade'
    assert_includes message, '08/04/2025 09:00'
    assert_includes message, '08/04/2025 17:00'
  end

  test 'E4 absence de l’APRÈS-MIDI alors que l’agent a réellement travaillé le matin → acceptée' do
    Intervention.create!(base.merge(début: "#{JOUR} 09:00", fin: "#{JOUR} 12:00"))

    absence = Absence.new(du: JOUR, au: JOUR, motif: 0, après_midi: true, user: @agent)

    assert absence.valid?, absence.errors.full_messages.to_sentence
  end

  test 'E5 absence sur un pointage encore OUVERT (sans fin) → acceptée' do
    Intervention.create!(base.merge(début: "#{JOUR} 09:00", template_slug: 'modele-x'))

    absence = Absence.new(du: JOUR, au: JOUR, motif: 0, user: @agent)

    assert absence.valid?, absence.errors.full_messages.to_sentence
  end

  test 'E3 absence du MATIN alors qu’une intervention est prévue l’après-midi → acceptée' do
    Intervention.create!(base.merge(début_prévue: "#{JOUR} 14:00", fin_prévue: "#{JOUR} 16:00"))

    absence = Absence.new(du: JOUR, au: JOUR, motif: 0, matin: true, user: @agent)

    assert absence.valid?, absence.errors.full_messages.to_sentence
  end

  # --- F. Demi-journées : matin = [00:00, 12:00[, après-midi = [12:00, 24:00[ ---

  test 'F1 intervention 09:00-13:00 pendant une absence du MATIN → bloquée' do
    creer_absence(matin: true)

    intervention = construire(début_prévue: "#{JOUR} 09:00", fin_prévue: "#{JOUR} 13:00")

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages.join(' '), 'Agent(s) indisponible(s)'
  end

  test 'F2 intervention 08:00-11:00 pendant une absence du MATIN → bloquée' do
    creer_absence(matin: true)

    intervention = construire(début_prévue: "#{JOUR} 08:00", fin_prévue: "#{JOUR} 11:00")

    assert_not intervention.valid?
  end

  test 'F3 intervention 14:00-16:00 pendant une absence du MATIN → valide' do
    creer_absence(matin: true)

    intervention = construire(début_prévue: "#{JOUR} 14:00", fin_prévue: "#{JOUR} 16:00")

    assert intervention.valid?, intervention.errors.full_messages.to_sentence
  end

  test 'F4 intervention démarrant pile à 12:00 pendant une absence du MATIN → valide (borne exclusive)' do
    creer_absence(matin: true)

    intervention = construire(début_prévue: "#{JOUR} 12:00", fin_prévue: "#{JOUR} 16:00")

    assert intervention.valid?, intervention.errors.full_messages.to_sentence
  end

  test 'F5 intervention 09:00-11:00 pendant une absence de l’APRÈS-MIDI → valide' do
    creer_absence(après_midi: true)

    intervention = construire(début_prévue: "#{JOUR} 09:00", fin_prévue: "#{JOUR} 11:00")

    assert intervention.valid?, intervention.errors.full_messages.to_sentence
  end

  test 'F6 intervention 11:00-14:00 pendant une absence de l’APRÈS-MIDI → bloquée' do
    creer_absence(après_midi: true)

    intervention = construire(début_prévue: "#{JOUR} 11:00", fin_prévue: "#{JOUR} 14:00")

    assert_not intervention.valid?
    assert_includes intervention.errors.full_messages.join(' '), 'Agent(s) indisponible(s)'
  end

  test 'F7 intervention finissant pile à 12:00 pendant une absence de l’APRÈS-MIDI → valide (borne exclusive)' do
    creer_absence(après_midi: true)

    intervention = construire(début_prévue: "#{JOUR} 09:00", fin_prévue: "#{JOUR} 12:00")

    assert intervention.valid?, intervention.errors.full_messages.to_sentence
  end

  test 'F8 intervention l’après-midi pendant une absence de JOURNÉE ENTIÈRE → bloquée' do
    creer_absence

    intervention = construire(début_prévue: "#{JOUR} 14:00", fin_prévue: "#{JOUR} 16:00")

    assert_not intervention.valid?
  end

  test 'F9 début PRÉVU seul l’après-midi pendant une absence du MATIN → valide' do
    creer_absence(matin: true)

    intervention = construire(début_prévue: "#{JOUR} 15:00")

    assert intervention.valid?, intervention.errors.full_messages.to_sentence
  end

  test 'F10 absence du MATIN sur deux jours = plage continue : l’après-midi du 1er jour est couvert' do
    creer_absence(matin: true, au: LENDEMAIN)

    veille = construire(début_prévue: "#{JOUR} 14:00", fin_prévue: "#{JOUR} 16:00")
    lendemain_après_midi = construire(début_prévue: "#{LENDEMAIN} 14:00", fin_prévue: "#{LENDEMAIN} 16:00")

    assert_not veille.valid?
    assert lendemain_après_midi.valid?, lendemain_après_midi.errors.full_messages.to_sentence
  end

  test 'F11 grisage live du formulaire : cohérent avec la validation sur une demi-journée' do
    creer_absence(matin: true)

    matin = Intervention.get_unavailable_agents_with_absences([@agent.id], "#{JOUR} 09:00", "#{JOUR} 13:00")
    après_midi = Intervention.get_unavailable_agents_with_absences([@agent.id], "#{JOUR} 14:00", "#{JOUR} 16:00")

    assert_equal [@agent.id], matin
    assert_empty après_midi
  end

  # --- G. Pointage : un agent absent ne peut pas ouvrir de pointage ------------

  test 'G1 pointage ouvert le matin pendant une absence du MATIN → bloqué' do
    creer_absence(matin: true)

    pointage = construire(début: "#{JOUR} 09:00", template_slug: 'modele-x')

    assert_not pointage.valid?
    assert_includes pointage.errors.full_messages.join(' '), 'Agent(s) indisponible(s)'
  end

  test 'G2 pointage ouvert l’après-midi pendant une absence du MATIN → autorisé' do
    creer_absence(matin: true)

    pointage = construire(début: "#{JOUR} 14:00", template_slug: 'modele-x')

    assert pointage.valid?, pointage.errors.full_messages.to_sentence
  end

  test 'G3 fermer un pointage déjà ouvert reste possible si une absence est posée après coup' do
    pointage = Intervention.create!(base.merge(début: "#{JOUR} 09:00", template_slug: 'modele-x'))
    creer_absence

    pointage.fin = "#{JOUR} 17:00"

    assert pointage.valid?, pointage.errors.full_messages.to_sentence
    assert pointage.save
  end

  test 'G4 déplacer le début d’un pointage sur une absence reste bloqué' do
    pointage = Intervention.create!(base.merge(début: "#{LENDEMAIN} 09:00", template_slug: 'modele-x'))
    creer_absence

    pointage.début = "#{JOUR} 09:00"

    assert_not pointage.valid?
  end

  test 'G5 bon d’intervention saisi a posteriori sur un jour d’absence → bloqué' do
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
