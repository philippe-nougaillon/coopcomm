# frozen_string_literal: true

require 'test_helper'

class ConventionTest < ActiveSupport::TestCase
  setup do
    @adherent = users(:patrick_adherent_paris)
    @service  = services(:service_paris)
  end

  DANS_LA_PÉRIODE_DE_CONVENTION_PARIS = Time.zone.parse('2026-03-02 09:00:00')

  test 'one_convention_per_service : doublon sur le même couple adhérent/service → refusé' do
    build_convention.save!

    doublon = build_convention

    assert_not doublon.valid?
    assert doublon.errors[:base].any?
  end

  test 'one_convention_per_service : périodes disjointes sur le même service → accepté' do
    build_convention.save!

    suivante = build_convention(date_début: Date.new(2027, 1, 1), date_fin_prévue: Date.new(2027, 12, 31))

    assert suivante.valid?
  end

  test 'one_convention_per_service : périodes qui se chevauchent sur le même service → refusé' do
    build_convention.save!

    chevauchante = build_convention(date_début: Date.new(2026, 12, 31), date_fin_prévue: Date.new(2027, 6, 30))

    assert_not chevauchante.valid?
    assert chevauchante.errors[:base].any?
  end

  test 'one_convention_per_service : autre service du même adhérent → accepté' do
    @adherent.services << services(:secretariat)
    build_convention.save!

    autre = build_convention(service: services(:secretariat))

    assert autre.valid?
  end

  test 'one_convention_per_service : autre adhérent sur le même service → accepté' do
    build_convention.save!

    autre = build_convention(user: users(:hidalgo))

    assert autre.valid?
  end

  test 'one_convention_per_service : mise à jour de la convention elle-même → non comptée comme doublon' do
    convention = build_convention
    convention.save!

    convention.date_fin_prévue = Date.new(2026, 12, 31)

    assert convention.valid?
  end

  test 'service_must_belong_to_adherent : service de l\'adhérent → accepté' do
    assert build_convention.valid?
  end

  test 'service_must_belong_to_adherent : service étranger à l\'adhérent → refusé' do
    convention = build_convention(service: services(:informatique))

    assert_not convention.valid?
    assert convention.errors[:service].any?
  end

  test 'end_date_after_start_date : fin postérieure au début → accepté' do
    assert build_convention(date_fin_prévue: Date.new(2026, 12, 31)).valid?
  end

  test 'end_date_after_start_date : début et fin le même jour → accepté' do
    même_jour = Date.new(2026, 6, 1)

    assert build_convention(date_début: même_jour, date_fin_prévue: même_jour).valid?
  end

  test 'end_date_after_start_date : fin antérieure au début → refusée' do
    convention = build_convention(date_début: Date.new(2026, 6, 1), date_fin_prévue: Date.new(2026, 1, 1))

    assert_not convention.valid?
    assert convention.errors[:date_fin_prévue].any?
  end

  test 'assign_ref : création → référence au format CONV-AAAA-N' do
    convention = build_convention

    convention.save!

    assert_match(/\ACONV-#{Date.current.year}-\d+\z/, convention.ref)
  end

  test 'assign_ref : mise à jour → référence inchangée' do
    convention = build_convention
    convention.save!
    ref = convention.ref

    convention.update!(mémo: 'Précision ajoutée')

    assert_equal ref, convention.ref
  end

  test 'assign_ref : référence fournie explicitement → conservée' do
    convention = build_convention(ref: 'CONV-MANUELLE')

    convention.save!

    assert_equal 'CONV-MANUELLE', convention.ref
  end

  test 'scope ordered : plusieurs conventions → la plus récente en tête' do
    ancienne = build_convention(date_début: Date.new(2025, 1, 1))
    ancienne.save!
    récente = build_convention(user: users(:hidalgo), service: services(:technique),
                               date_début: Date.new(2030, 1, 1), date_fin_prévue: Date.new(2030, 12, 31))
    récente.save!

    ordonnées = Convention.ordered.to_a

    assert ordonnées.index(récente) < ordonnées.index(ancienne)
  end

  test 'visible_to : administrateur → les conventions de son organisation' do
    assert_includes Convention.visible_to(users(:administrateur_paris)), conventions(:convention_paris)
  end

  test 'visible_to : administrateur → aucune convention d\'une autre organisation' do
    assert_not_includes Convention.visible_to(users(:administrateur_paris)), conventions(:convention_marseille)
  end

  test 'visible_to : manager → les conventions des services qu\'il gère' do
    assert_includes Convention.visible_to(users(:hidalgo)), conventions(:convention_paris)
  end

  test 'visible_to : manager → aucune convention d\'un service qu\'il ne gère pas' do
    assert_not_includes Convention.visible_to(users(:manager_marseille)), conventions(:convention_paris)
  end

  test 'visible_to : adhérent → les siennes, jamais celles d\'un autre adhérent' do
    convention_de_patrick = build_convention
    convention_de_patrick.save!

    visibles = Convention.visible_to(users(:weil))

    assert_includes visibles, conventions(:convention_paris)
    assert_not_includes visibles, convention_de_patrick
  end

  test 'visible_to : agent → aucune convention' do
    assert_empty Convention.visible_to(users(:agent_whatsapp))
  end

  test 'interventions : période de la convention → celles de l\'adhérent dedans, pas celles dehors' do
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

  test 'heures_consommees : interventions de la période → la somme de leur temps total' do
    convention = conventions(:convention_paris)
    intervention_conventionnee(heures: 3)
    intervention_conventionnee(heures: 5, début: DANS_LA_PÉRIODE_DE_CONVENTION_PARIS + 4.hours)

    assert_equal 8, convention.heures_consommees
  end

  test 'heures_consommees : aucune intervention → zéro' do
    assert_equal 0, conventions(:convention_paris).heures_consommees
  end

  test 'heures_consommees : intervention d\'un autre service → non comptée' do
    convention = conventions(:convention_paris)
    intervention_conventionnee(heures: 4, service: services(:technique))

    assert_equal 0, convention.heures_consommees
  end

  test 'heures_consommees : intervention d\'un autre adhérent → non comptée' do
    convention = conventions(:convention_paris)
    intervention_conventionnee(heures: 4, adherent_id: users(:adhérent_sans_intervention).id)

    assert_equal 0, convention.heures_consommees
  end

  test 'heures_consommees : intervention hors période → non comptée' do
    convention = conventions(:convention_paris)
    intervention_conventionnee(heures: 4, début: convention.date_début.beginning_of_day - 2.days)

    assert_equal 0, convention.heures_consommees
  end

  test 'heures_consommees : temps d\'une intervention modifié → somme recalculée' do
    convention = conventions(:convention_paris)
    intervention = intervention_conventionnee(heures: 3)

    intervention.update!(fin: intervention.début + 5.hours)

    assert_equal 5, convention.heures_consommees
  end

  test 'heures_consommees : intervention supprimée → somme recalculée' do
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
    Convention.new({ user: @adherent, service: @service,
                     date_début: Date.new(2026, 1, 1), date_fin_prévue: Date.new(2026, 12, 31) }.merge(attrs))
  end
end
