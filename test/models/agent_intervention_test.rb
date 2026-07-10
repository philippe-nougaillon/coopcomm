# frozen_string_literal: true

require 'test_helper'

class AgentInterventionTest < ActiveSupport::TestCase
  setup do
    @agent = users(:bond)
    @template_adherent = users(:weil)
  end

  test "Intervention créée si l'agent est disponible" do
    intervention = createDefaultIntervention

    assert intervention.valid?
  end

  test "Intervention non créée si l'agent est occupé à la même heure" do
    intervention = createDefaultIntervention

    nouvelle_intervention = createOverlapsIntervention(intervention.début_prévue, intervention.fin_prévue)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], 'Conflit(s) détecté(s) sur un agent'
  end

  test "Intervention non créée si l'agent commence avant et fini pendant" do
    intervention = createDefaultIntervention

    début_prévue_décalé = intervention.début_prévue - 1.hour
    fin_prévue_décalé = intervention.fin_prévue + 0.hour

    nouvelle_intervention = createOverlapsIntervention(début_prévue_décalé, fin_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], 'Conflit(s) détecté(s) sur un agent'
  end

  test "Intervention non créée si l'agent commence pendant et fini après" do
    intervention = createDefaultIntervention

    début_prévue_décalé = intervention.début_prévue + 0.hour
    fin_prévue_décalé = intervention.fin_prévue + 1.hour

    nouvelle_intervention = createOverlapsIntervention(début_prévue_décalé, fin_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], 'Conflit(s) détecté(s) sur un agent'
  end

  test "Intervention non créée si l'agent commence pendant et fini pendant" do
    intervention = createDefaultIntervention

    début_prévue_décalé = intervention.début_prévue + 1.hour
    fin_prévue_décalé = intervention.fin_prévue - 1.hour

    nouvelle_intervention = createOverlapsIntervention(début_prévue_décalé, fin_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], 'Conflit(s) détecté(s) sur un agent'
  end

  test "Intervention non créée si l'agent commence avant et fini après" do
    intervention = createDefaultIntervention

    début_prévue_décalé = intervention.début_prévue - 1.hour
    fin_prévue_décalé = intervention.fin_prévue + 1.hour

    nouvelle_intervention = createOverlapsIntervention(début_prévue_décalé, fin_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], 'Conflit(s) détecté(s) sur un agent'
  end

  test "Intervention non créée si l'agent fini au début" do
    intervention = createDefaultIntervention

    fin_prévue_décalé = intervention.début_prévue

    nouvelle_intervention = createOverlapsIntervention(nil, fin_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], 'Conflit(s) détecté(s) sur un agent'
  end

  test "Intervention non créée si l'agent commence à la fin" do
    intervention = createDefaultIntervention

    début_prévue_décalé = intervention.fin_prévue

    nouvelle_intervention = createOverlapsIntervention(début_prévue_décalé)

    assert_not nouvelle_intervention.valid?
    assert_includes nouvelle_intervention.errors.full_messages[0], 'Conflit(s) détecté(s) sur un agent'
  end

  # --- Disponibilité sur les DATES RÉELLES ------------------------------------

  test 'Conflit agent détecté quand les dates RÉELLES se chevauchent' do
    createRealIntervention(début: '2025-04-08 09:00', fin: '2025-04-08 12:00')

    nouvelle = buildIntervention(début: '2025-04-08 10:00', fin: '2025-04-08 11:00')

    assert_not nouvelle.valid?
    assert_includes nouvelle.errors.full_messages[0], 'Conflit(s) détecté(s) sur un agent'
  end

  test 'Pas de conflit agent : dates RÉELLES disjointes même si les PRÉVUES se chevaucheraient' do
    # Existante : réel 09-12, prévue 14-17.
    createRealIntervention(début: '2025-04-08 09:00', fin: '2025-04-08 12:00',
                           début_prévue: '2025-04-08 14:00', fin_prévue: '2025-04-08 17:00')

    # Nouvelle : réel 14-17 (chevauche la PRÉVUE de l'existante),
    # prévue 09-12 (chevaucherait le RÉEL de l'existante).
    nouvelle = buildIntervention(début: '2025-04-08 14:00', fin: '2025-04-08 17:00',
                                 début_prévue: '2025-04-08 09:00', fin_prévue: '2025-04-08 12:00')

    assert nouvelle.valid?, nouvelle.errors.full_messages.to_sentence
  end

  test 'Repli : conflit entre un réel nouveau et un prévu existant (sans réel)' do
    createRealIntervention(début_prévue: '2025-04-08 09:00', fin_prévue: '2025-04-08 12:00')

    nouvelle = buildIntervention(début: '2025-04-08 10:00', fin: '2025-04-08 11:00')

    assert_not nouvelle.valid?
    assert_includes nouvelle.errors.full_messages[0], 'Conflit(s) détecté(s) sur un agent'
  end

  def createRealIntervention(**attrs)
    Intervention.create!(baseAttributes.merge(description: 'Intervention existante').merge(attrs))
  end

  def buildIntervention(**attrs)
    Intervention.new(baseAttributes.merge(description: "L'intervention de trop").merge(attrs))
  end

  def baseAttributes
    {
      organisation: organisations(:mairie_paris),
      agents: [@agent],
      adherent: @template_adherent,
      service: @template_adherent.services.first
    }
  end

  def createOverlapsIntervention(debut = nil, fin = nil)
    Intervention.new(
      début_prévue: debut,
      fin_prévue: fin,
      description: "L'intervention de trop",
      organisation: organisations(:mairie_paris),
      agents: [@agent],
      adherent: @template_adherent,
      service: @template_adherent.services.first
    )
  end

  def createDefaultIntervention
    Intervention.create!(
      début_prévue: '2025-04-08 09:00',
      fin_prévue: '2025-04-08 12:00',
      description: 'Entretien des locaux',
      organisation: organisations(:mairie_paris),
      agents: [@agent],
      adherent: @template_adherent,
      service: @template_adherent.services.first
    )
  end
end
