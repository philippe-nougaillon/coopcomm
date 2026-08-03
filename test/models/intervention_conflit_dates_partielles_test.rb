# frozen_string_literal: true

require 'test_helper'

# Matrice de COMPLÉTUDE des dates pour la détection de conflit (agents + outils).
class InterventionConflitDatesPartiellesTest < ActiveSupport::TestCase
  setup do
    @agent = users(:bond)
    @tool = tools(:tondeuse)
    @adherent = users(:weil)
    @service = @adherent.services.first
    @org = organisations(:mairie_paris)
  end

  JOUR = '2025-04-08'

  # --- A. Complétude côté NOUVELLE (l'existante est fermée, réelle [10h, 12h]) --

  test 'A1 nouvelle avec début réel seul DANS le créneau → conflit' do
    creer_existante_agent

    nouvelle = construire_agent(début: "#{JOUR} 11:00")

    assert_not nouvelle.valid?
    assert_includes nouvelle.errors.full_messages.join(' '), 'Conflit(s) détecté(s) sur un agent'
  end

  test 'A2 nouvelle avec début réel seul HORS créneau → valide' do
    creer_existante_agent

    nouvelle = construire_agent(début: "#{JOUR} 08:00")

    assert nouvelle.valid?, nouvelle.errors.full_messages.to_sentence
  end

  test 'A3 nouvelle avec fin réelle seule DANS le créneau → conflit' do
    creer_existante_agent

    nouvelle = construire_agent(fin: "#{JOUR} 11:00")

    assert_not nouvelle.valid?
    assert_includes nouvelle.errors.full_messages.join(' '), 'Conflit(s) détecté(s) sur un agent'
  end

  test 'A4 nouvelle avec fin réelle seule HORS créneau → valide' do
    creer_existante_agent

    nouvelle = construire_agent(fin: "#{JOUR} 08:00")

    assert nouvelle.valid?, nouvelle.errors.full_messages.to_sentence
  end

  test 'A5 nouvelle avec début prévu seul DANS le créneau (repli sur une borne) → conflit' do
    creer_existante_agent

    nouvelle = construire_agent(début_prévue: "#{JOUR} 11:00")

    assert_not nouvelle.valid?
    assert_includes nouvelle.errors.full_messages.join(' '), 'Conflit(s) détecté(s) sur un agent'
  end

  test 'A6 nouvelle MIXTE (début réel + fin prévue) chevauchant le créneau → conflit' do
    creer_existante_agent

    nouvelle = construire_agent(début: "#{JOUR} 09:00", fin_prévue: "#{JOUR} 11:00")

    assert_not nouvelle.valid?
    assert_includes nouvelle.errors.full_messages.join(' '), 'Conflit(s) détecté(s) sur un agent'
  end

  test 'A7 nouvelle MIXTE (début réel + fin prévue) hors créneau → valide' do
    creer_existante_agent

    nouvelle = construire_agent(début: "#{JOUR} 13:00", fin_prévue: "#{JOUR} 14:00")

    assert nouvelle.valid?, nouvelle.errors.full_messages.to_sentence
  end

  test 'A8 nouvelle sans aucune date : la validation est sautée même si l’agent est occupé → valide' do
    creer_existante_agent

    nouvelle = construire_agent

    assert nouvelle.valid?, nouvelle.errors.full_messages.to_sentence
  end

  test 'A9 priorité PAR BORNE : début réel hors créneau prime sur début prévu dans le créneau → valide' do
    creer_existante_agent

    nouvelle = construire_agent(début: "#{JOUR} 13:00", début_prévue: "#{JOUR} 11:00")

    assert nouvelle.valid?, nouvelle.errors.full_messages.to_sentence
  end

  # --- B. Complétude côté EXISTANTE (la nouvelle est fermée, réelle [10h, 12h]) --

  test 'B1 existante avec début réel seul DANS la fenêtre de la nouvelle → conflit' do
    creer_agent(début: "#{JOUR} 11:00")

    assert_conflit_nouvelle_fermee
  end

  test 'B2 existante « ouverte » AVANT la fenêtre (début réel seul hors) → valide, borne NULL = inconnue' do
    # Comportement décidé : une fin absente n'est PAS traitée comme « toujours en
    # cours » ; l'existante ne conflicte que si sa borne connue tombe dans la fenêtre.
    creer_agent(début: "#{JOUR} 08:00")

    assert_valide_nouvelle_fermee
  end

  test 'B3 existante avec fin réelle seule DANS la fenêtre → conflit' do
    creer_agent(fin: "#{JOUR} 11:00")

    assert_conflit_nouvelle_fermee
  end

  test 'B4 existante MIXTE (début réel + fin prévue) chevauchant la fenêtre → conflit' do
    creer_agent(début: "#{JOUR} 09:00", fin_prévue: "#{JOUR} 11:00")

    assert_conflit_nouvelle_fermee
  end

  test 'B5 existante MIXTE (début réel + fin prévue) hors fenêtre → valide' do
    creer_agent(début: "#{JOUR} 07:00", fin_prévue: "#{JOUR} 08:00")

    assert_valide_nouvelle_fermee
  end

  test 'B6 existante sans aucune date → valide' do
    creer_agent

    assert_valide_nouvelle_fermee
  end

  test 'B7 existante avec début prévu seul DANS la fenêtre → conflit' do
    creer_agent(début_prévue: "#{JOUR} 11:00")

    assert_conflit_nouvelle_fermee
  end

  # --- C. Outils : mêmes règles de complétude (contraste minimal) ---------------

  test 'C1 nouvelle avec début réel seul dans le créneau de l’outil → conflit outil' do
    creer_outil(début: "#{JOUR} 10:00", fin: "#{JOUR} 12:00")

    nouvelle = construire_outil(début: "#{JOUR} 11:00")

    assert_not nouvelle.valid?
    assert_includes nouvelle.errors.full_messages.join(' '), 'Conflit(s) détecté(s) sur un outil'
  end

  test 'C2 existante outil avec début réel seul dans la fenêtre de la nouvelle → conflit outil' do
    creer_outil(début: "#{JOUR} 11:00")

    nouvelle = construire_outil(début: "#{JOUR} 10:00", fin: "#{JOUR} 12:00")

    assert_not nouvelle.valid?
    assert_includes nouvelle.errors.full_messages.join(' '), 'Conflit(s) détecté(s) sur un outil'
  end

  test 'C3 nouvelle sans dates avec un outil occupé → valide (validation sautée)' do
    creer_outil(début: "#{JOUR} 10:00", fin: "#{JOUR} 12:00")

    nouvelle = construire_outil

    assert nouvelle.valid?, nouvelle.errors.full_messages.to_sentence
  end

  private

  def creer_existante_agent
    creer_agent(début: "#{JOUR} 10:00", fin: "#{JOUR} 12:00")
  end

  def assert_conflit_nouvelle_fermee
    nouvelle = construire_agent(début: "#{JOUR} 10:00", fin: "#{JOUR} 12:00")

    assert_not nouvelle.valid?
    assert_includes nouvelle.errors.full_messages.join(' '), 'Conflit(s) détecté(s) sur un agent'
  end

  def assert_valide_nouvelle_fermee
    nouvelle = construire_agent(début: "#{JOUR} 10:00", fin: "#{JOUR} 12:00")

    assert nouvelle.valid?, nouvelle.errors.full_messages.to_sentence
  end

  def base_agent
    { description: 'Intervention', organisation: @org, agents: [@agent], adherent: @adherent, service: @service }
  end

  def base_outil
    { description: 'Intervention', organisation: @org, tools: [@tool], adherent: @adherent, service: @service }
  end

  def creer_agent(**attrs)
    Intervention.create!(base_agent.merge(attrs))
  end

  def construire_agent(**attrs)
    Intervention.new(base_agent.merge(attrs))
  end

  def creer_outil(**attrs)
    Intervention.create!(base_outil.merge(attrs))
  end

  def construire_outil(**attrs)
    Intervention.new(base_outil.merge(attrs))
  end
end
