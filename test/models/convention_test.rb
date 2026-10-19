# frozen_string_literal: true

require 'test_helper'

class ConventionTest < ActiveSupport::TestCase
  setup do
    @adherent = users(:patrick_adherent_paris)
    @service  = services(:service_paris)
  end

  DANS_LA_PÉRIODE_DE_CONVENTION_PARIS = Time.zone.parse('2026-03-02 09:00:00')

  test 'une seconde convention du même adhérent sur le même service et la même période est refusée' do
    build_convention.save!

    doublon = build_convention

    assert_not doublon.valid?
    assert doublon.errors[:base].any?
  end

  test 'deux conventions du même adhérent sur le même service à des périodes disjointes sont acceptées' do
    build_convention.save!

    suivante = build_convention(date_début: Date.new(2027, 1, 1), date_fin_prévue: Date.new(2027, 12, 31))

    assert suivante.valid?
  end

  test 'une convention qui chevauche une autre convention du même adhérent sur le même service est refusée' do
    build_convention.save!

    chevauchante = build_convention(date_début: Date.new(2026, 12, 31), date_fin_prévue: Date.new(2027, 6, 30))

    assert_not chevauchante.valid?
    assert chevauchante.errors[:base].any?
  end

  test 'une convention sur un autre service du même adhérent est acceptée' do
    @adherent.services << services(:secretariat)
    build_convention.save!

    autre = build_convention(service: services(:secretariat))

    assert autre.valid?
  end

  test "une convention d'un autre adhérent sur le même service est acceptée" do
    build_convention.save!

    autre = build_convention(user: users(:hidalgo))

    assert autre.valid?
  end

  test "une convention modifiée n'est pas comptée comme son propre doublon" do
    convention = build_convention
    convention.save!

    convention.date_fin_prévue = Date.new(2026, 12, 31)

    assert convention.valid?
  end

  test "une convention sur un service de l'adhérent est acceptée" do
    assert build_convention.valid?
  end

  test "une convention sur un service étranger à l'adhérent est refusée" do
    convention = build_convention(service: services(:informatique))

    assert_not convention.valid?
    assert convention.errors[:service].any?
  end

  test 'une convention dont la fin est postérieure au début est acceptée' do
    assert build_convention(date_fin_prévue: Date.new(2026, 12, 31)).valid?
  end

  test 'une convention qui commence et finit le même jour est acceptée' do
    même_jour = Date.new(2026, 6, 1)

    assert build_convention(date_début: même_jour, date_fin_prévue: même_jour).valid?
  end

  test 'une convention dont la fin est antérieure au début est refusée' do
    convention = build_convention(date_début: Date.new(2026, 6, 1), date_fin_prévue: Date.new(2026, 1, 1))

    assert_not convention.valid?
    assert convention.errors[:date_fin_prévue].any?
  end

  test 'une convention créée reçoit une référence au format CONV-AAAA-N' do
    convention = build_convention

    convention.save!

    assert_match(/\ACONV-#{Date.current.year}-\d+\z/, convention.ref)
  end

  test "la référence d'une convention ne change pas à la mise à jour" do
    convention = build_convention
    convention.save!
    ref = convention.ref

    convention.update!(mémo: 'Précision ajoutée')

    assert_equal ref, convention.ref
  end

  test 'une référence de convention fournie explicitement est conservée' do
    convention = build_convention(ref: 'CONV-MANUELLE')

    convention.save!

    assert_equal 'CONV-MANUELLE', convention.ref
  end

  test 'la convention la plus récente est listée en tête' do
    ancienne = build_convention(date_début: Date.new(2025, 1, 1))
    ancienne.save!
    récente = build_convention(user: users(:hidalgo), service: services(:technique),
                               date_début: Date.new(2030, 1, 1), date_fin_prévue: Date.new(2030, 12, 31))
    récente.save!

    ordonnées = Convention.ordered.to_a

    assert ordonnées.index(récente) < ordonnées.index(ancienne)
  end

  test 'un administrateur voit les conventions de son organisation' do
    assert_includes Convention.visible_to(users(:administrateur_paris)), conventions(:convention_paris)
  end

  test "un administrateur ne voit pas les conventions d'une autre organisation" do
    assert_not_includes Convention.visible_to(users(:administrateur_paris)), conventions(:convention_marseille)
  end

  test 'un manager voit les conventions de ses services' do
    assert_includes Convention.visible_to(users(:hidalgo)), conventions(:convention_paris)
  end

  test 'un manager ne voit pas les conventions des autres services' do
    assert_not_includes Convention.visible_to(users(:manager_marseille)), conventions(:convention_paris)
  end

  test "un adhérent voit ses conventions, jamais celles d'un autre adhérent" do
    convention_de_patrick = build_convention
    convention_de_patrick.save!

    visibles = Convention.visible_to(users(:weil))

    assert_includes visibles, conventions(:convention_paris)
    assert_not_includes visibles, convention_de_patrick
  end

  test 'un agent ne voit aucune convention' do
    assert_empty Convention.visible_to(users(:agent_whatsapp))
  end

  test "les interventions d'une convention sont celles de l'adhérent dans sa période, pas celles en dehors" do
    convention = conventions(:convention_paris)
    dans_la_période = Intervention.create!(
      description: 'Intervention sous convention',
      adherent_id: convention.user_id, service_id: convention.service_id,
      workflow_state: 'nouveau', début: convention.date_début.beginning_of_day + 9.hours,
      slug: SecureRandom.uuid
    )
    hors_période = Intervention.create!(
      description: 'Intervention hors convention',
      adherent_id: convention.user_id, service_id: convention.service_id,
      workflow_state: 'nouveau', début: convention.date_début.beginning_of_day - 2.days,
      slug: SecureRandom.uuid
    )

    interventions = convention.interventions

    assert_includes interventions, dans_la_période
    assert_not_includes interventions, hors_période
  end

  test "les heures consommées d'une convention sont la somme du temps total de ses interventions" do
    convention = conventions(:convention_paris)
    intervention_conventionnee(heures: 3)
    intervention_conventionnee(heures: 5, début: DANS_LA_PÉRIODE_DE_CONVENTION_PARIS + 4.hours)

    assert_equal 8, convention.heures_consommees
  end

  test "les heures consommées d'une convention sans intervention valent zéro" do
    assert_equal 0, conventions(:convention_paris).heures_consommees
  end

  test "une intervention d'un autre service n'est pas comptée dans les heures consommées" do
    convention = conventions(:convention_paris)
    intervention_conventionnee(heures: 4, service: services(:technique))

    assert_equal 0, convention.heures_consommees
  end

  test "une intervention d'un autre adhérent n'est pas comptée dans les heures consommées" do
    convention = conventions(:convention_paris)
    intervention_conventionnee(heures: 4, adherent_id: users(:adhérent_sans_intervention).id)

    assert_equal 0, convention.heures_consommees
  end

  test "une intervention hors période n'est pas comptée dans les heures consommées" do
    convention = conventions(:convention_paris)
    intervention_conventionnee(heures: 4, début: convention.date_début.beginning_of_day - 2.days)

    assert_equal 0, convention.heures_consommees
  end

  test "les heures consommées sont recalculées lorsque le temps d'une intervention est modifié" do
    convention = conventions(:convention_paris)
    intervention = intervention_conventionnee(heures: 3)

    intervention.update!(fin: intervention.début + 5.hours)

    assert_equal 5, convention.heures_consommees
  end

  test "les heures consommées sont recalculées lorsqu'une intervention est supprimée" do
    convention = conventions(:convention_paris)
    intervention_conventionnee(heures: 3).destroy!

    assert_equal 0, convention.heures_consommees
  end

  private

  def intervention_conventionnee(heures:, **attrs)
    convention = conventions(:convention_paris)
    début = attrs.delete(:début) || DANS_LA_PÉRIODE_DE_CONVENTION_PARIS
    Intervention.create!({ description: 'Intervention sous convention',
                           adherent_id: convention.user_id,
                           service: convention.service,
                           agents: [users(:hidalgo)],
                           temps_de_pause: 0,
                           début: début,
                           fin: début + heures.hours,
                           slug: SecureRandom.uuid }.merge(attrs))
  end

  def build_convention(attrs = {})
    Convention.new({ user: @adherent, service: @service, heures_conventionnees: 100,
                     date_début: Date.new(2026, 1, 1), date_fin_prévue: Date.new(2026, 12, 31) }.merge(attrs))
  end
end
