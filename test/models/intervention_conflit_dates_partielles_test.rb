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

  test 'une nouvelle intervention avec un début réel seul dans le créneau est en conflit (A1)' do
    creer_existante_agent

    nouvelle = construire_agent(début: "#{JOUR} 11:00")

    assert_not nouvelle.valid?
    assert_includes nouvelle.errors.full_messages.join(' '), 'Conflit(s) détecté(s) sur un agent'
  end

  test 'une nouvelle intervention avec un début réel seul hors du créneau est valide (A2)' do
    creer_existante_agent

    nouvelle = construire_agent(début: "#{JOUR} 08:00")

    assert nouvelle.valid?, nouvelle.errors.full_messages.to_sentence
  end

  test 'une nouvelle intervention avec une fin réelle seule dans le créneau est en conflit (A3)' do
    creer_existante_agent

    nouvelle = construire_agent(fin: "#{JOUR} 11:00")

    assert_not nouvelle.valid?
    assert_includes nouvelle.errors.full_messages.join(' '), 'Conflit(s) détecté(s) sur un agent'
  end

  test 'une nouvelle intervention avec une fin réelle seule hors du créneau est valide (A4)' do
    creer_existante_agent

    nouvelle = construire_agent(fin: "#{JOUR} 08:00")

    assert nouvelle.valid?, nouvelle.errors.full_messages.to_sentence
  end

  test 'une nouvelle intervention avec un début prévu seul dans le créneau est en conflit (repli sur une borne) (A5)' do
    creer_existante_agent

    nouvelle = construire_agent(début_prévue: "#{JOUR} 11:00")

    assert_not nouvelle.valid?
    assert_includes nouvelle.errors.full_messages.join(' '), 'Conflit(s) détecté(s) sur un agent'
  end

  test 'une nouvelle intervention avec une fin prévue seule dans le créneau est en conflit (repli sur une borne) (A5bis)' do
    creer_existante_agent

    nouvelle = construire_agent(fin_prévue: "#{JOUR} 11:00")

    assert_not nouvelle.valid?
    assert_includes nouvelle.errors.full_messages.join(' '), 'Conflit(s) détecté(s) sur un agent'
  end

  test 'une nouvelle intervention mixte (début réel et fin prévue) chevauchant le créneau est en conflit (A6)' do
    creer_existante_agent

    nouvelle = construire_agent(début: "#{JOUR} 09:00", fin_prévue: "#{JOUR} 11:00")

    assert_not nouvelle.valid?
    assert_includes nouvelle.errors.full_messages.join(' '), 'Conflit(s) détecté(s) sur un agent'
  end

  test 'une nouvelle intervention mixte (début réel et fin prévue) hors du créneau est valide (A7)' do
    creer_existante_agent

    nouvelle = construire_agent(début: "#{JOUR} 13:00", fin_prévue: "#{JOUR} 14:00")

    assert nouvelle.valid?, nouvelle.errors.full_messages.to_sentence
  end

  test 'une nouvelle intervention sans aucune date est valide même si l’agent est occupé, la validation étant sautée (A8)' do
    creer_existante_agent

    nouvelle = construire_agent

    assert nouvelle.valid?, nouvelle.errors.full_messages.to_sentence
  end

  test 'un début réel hors du créneau prime, borne par borne, sur un début prévu dans le créneau (A9)' do
    creer_existante_agent

    nouvelle = construire_agent(début: "#{JOUR} 13:00", début_prévue: "#{JOUR} 11:00")

    assert nouvelle.valid?, nouvelle.errors.full_messages.to_sentence
  end

  # --- B. Complétude côté EXISTANTE (la nouvelle est fermée, réelle [10h, 12h]) --

  test 'une intervention existante avec un début réel seul dans la fenêtre met la nouvelle en conflit (B1)' do
    creer_agent(début: "#{JOUR} 11:00")

    assert_conflit_nouvelle_fermee
  end

  test 'une intervention existante « ouverte » avant la fenêtre (début réel seul hors) laisse la nouvelle valide, une borne absente étant inconnue (B2)' do
    # Comportement décidé : une fin absente n'est PAS traitée comme « toujours en
    # cours » ; l'existante ne conflicte que si sa borne connue tombe dans la fenêtre.
    creer_agent(début: "#{JOUR} 08:00")

    assert_valide_nouvelle_fermee
  end

  test 'une intervention existante avec une fin réelle seule dans la fenêtre met la nouvelle en conflit (B3)' do
    creer_agent(fin: "#{JOUR} 11:00")

    assert_conflit_nouvelle_fermee
  end

  test 'une intervention existante mixte (début réel et fin prévue) chevauchant la fenêtre met la nouvelle en conflit (B4)' do
    creer_agent(début: "#{JOUR} 09:00", fin_prévue: "#{JOUR} 11:00")

    assert_conflit_nouvelle_fermee
  end

  test 'une intervention existante mixte (début réel et fin prévue) hors de la fenêtre laisse la nouvelle valide (B5)' do
    creer_agent(début: "#{JOUR} 07:00", fin_prévue: "#{JOUR} 08:00")

    assert_valide_nouvelle_fermee
  end

  test 'une intervention existante sans aucune date laisse la nouvelle valide (B6)' do
    creer_agent

    assert_valide_nouvelle_fermee
  end

  test 'une intervention existante avec un début prévu seul dans la fenêtre met la nouvelle en conflit (B7)' do
    creer_agent(début_prévue: "#{JOUR} 11:00")

    assert_conflit_nouvelle_fermee
  end

  # --- C. Outils : mêmes règles de complétude (contraste minimal) ---------------

  test 'une nouvelle intervention avec un début réel seul dans le créneau de l’outil est en conflit d’outil (C1)' do
    creer_outil(début: "#{JOUR} 10:00", fin: "#{JOUR} 12:00")

    nouvelle = construire_outil(début: "#{JOUR} 11:00")

    assert_not nouvelle.valid?
    assert_includes nouvelle.errors.full_messages.join(' '), 'Conflit(s) détecté(s) sur un outil'
  end

  test 'une intervention existante sur l’outil avec un début réel seul dans la fenêtre met la nouvelle en conflit d’outil (C2)' do
    creer_outil(début: "#{JOUR} 11:00")

    nouvelle = construire_outil(début: "#{JOUR} 10:00", fin: "#{JOUR} 12:00")

    assert_not nouvelle.valid?
    assert_includes nouvelle.errors.full_messages.join(' '), 'Conflit(s) détecté(s) sur un outil'
  end

  test 'une nouvelle intervention avec une fin prévue seule dans le créneau de l’outil est en conflit d’outil (C2bis)' do
    creer_outil(début: "#{JOUR} 10:00", fin: "#{JOUR} 12:00")

    nouvelle = construire_outil(fin_prévue: "#{JOUR} 11:00")

    assert_not nouvelle.valid?
    assert_includes nouvelle.errors.full_messages.join(' '), 'Conflit(s) détecté(s) sur un outil'
  end

  test 'une nouvelle intervention sans dates avec un outil occupé est valide (validation sautée) (C3)' do
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
