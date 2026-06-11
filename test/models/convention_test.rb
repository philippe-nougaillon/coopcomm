# frozen_string_literal: true

require 'test_helper'

class ConventionTest < ActiveSupport::TestCase
  # patrick_adherent_paris : rôle adhérent, rattaché au seul service service_paris,
  # et sans convention en fixture → support idéal pour des cas valides/invalides isolés.
  setup do
    @adherent = users(:patrick_adherent_paris)
    @service  = services(:service_paris)
  end

  def build_convention(attrs = {})
    Convention.new({ user: @adherent, service: @service, date_début: Date.new(2026, 1, 1) }.merge(attrs))
  end

  # --- Validations de base ---

  test "valide avec un user, un service de l'adhérent et une date de début" do
    assert build_convention.valid?
  end

  test 'invalide sans date de début' do
    convention = build_convention(date_début: nil)
    refute convention.valid?
    assert convention.errors[:date_début].any?
  end

  test 'invalide sans user (belongs_to requis)' do
    refute build_convention(user: nil).valid?
  end

  test 'invalide sans service (belongs_to requis)' do
    refute build_convention(service: nil).valid?
  end

  # --- Cohérence des dates (end_date_after_start_date) ---

  test 'valide quand la date de fin est postérieure à la date de début' do
    assert build_convention(date_fin_prévue: Date.new(2026, 12, 31)).valid?
  end

  test "valide quand il n'y a pas de date de fin" do
    assert build_convention(date_fin_prévue: nil).valid?
  end

  test 'valide quand début et fin tombent le même jour' do
    same = Date.new(2026, 6, 1)
    assert build_convention(date_début: same, date_fin_prévue: same).valid?
  end

  test 'invalide quand la date de fin précède la date de début' do
    convention = build_convention(date_début: Date.new(2026, 6, 1), date_fin_prévue: Date.new(2026, 1, 1))
    refute convention.valid?
    assert convention.errors[:date_fin_prévue].any?
  end

  # --- Le service doit appartenir à l'adhérent (service_must_belong_to_adherent) ---

  test "invalide quand le service n'appartient pas à l'adhérent" do
    convention = build_convention(service: services(:informatique)) # patrick n'a que service_paris
    refute convention.valid?
    assert convention.errors[:service].any?
  end

  # --- Une seule convention par couple (one_convention_per_service) ---

  test 'invalide en doublon sur le même couple (adhérent, service)' do
    build_convention.save!
    doublon = build_convention
    refute doublon.valid?
    assert doublon.errors[:base].any?
  end

  test 'un même adhérent peut avoir une convention sur un autre de ses services' do
    @adherent.services << services(:secretariat) # patrick a désormais service_paris + secretariat
    build_convention.save! # service_paris
    autre = build_convention(service: services(:secretariat))
    assert autre.valid?
  end

  test 'un autre adhérent peut avoir une convention sur le même service' do
    build_convention.save! # patrick + service_paris
    autre = build_convention(user: users(:hidalgo)) # hidalgo gère aussi service_paris
    assert autre.valid?
  end

  test "la contrainte d'unicité ignore la convention elle-même lors d'une mise à jour" do
    convention = build_convention
    convention.save!
    convention.date_fin_prévue = Date.new(2026, 12, 31)
    assert convention.valid?
  end

  # --- Associations / scope / périmètre ---

  test 'organisation dérivée du service' do
    convention = build_convention
    convention.save!
    assert_equal @service.organisation, convention.organisation
  end

  test 'ordered trie par date de début décroissante' do
    ancienne = build_convention(date_début: Date.new(2025, 1, 1))
    ancienne.save!
    recente = build_convention(user: users(:hidalgo), service: services(:technique), date_début: Date.new(2030, 1, 1))
    recente.save!
    ordered = Convention.ordered.to_a
    assert ordered.index(recente) < ordered.index(ancienne)
  end

  test 'visible_to un administrateur de la même organisation' do
    assert_includes Convention.visible_to(users(:administrateur_paris)), conventions(:convention_paris)
  end

  test "non visible pour un administrateur d'une autre organisation" do
    refute_includes Convention.visible_to(users(:administrateur_paris)), conventions(:convention_marseille)
  end

  test 'visible_to un manager qui gère le service' do
    # hidalgo gère le service informatique, sur lequel porte convention_paris
    assert_includes Convention.visible_to(users(:hidalgo)), conventions(:convention_paris)
  end

  test 'non visible pour un manager qui ne gère pas le service' do
    refute_includes Convention.visible_to(users(:manager_marseille)), conventions(:convention_paris)
  end

  test 'aucune convention visible pour un adhérent' do
    assert_empty Convention.visible_to(users(:weil))
  end

  test 'aucune convention visible pour un agent' do
    assert_empty Convention.visible_to(users(:agent_whatsapp))
  end

  # --- Audit trail (audited associated_with: :user) ---

  test 'auditée : création puis modification sont tracées' do
    convention = build_convention
    convention.save!
    assert_equal 1, convention.audits.count
    assert_equal 'create', convention.audits.last.action

    convention.update!(date_fin_prévue: Date.new(2026, 12, 31))
    assert_equal 2, convention.audits.count
    assert_equal 'update', convention.audits.last.action
    assert_includes convention.audits.last.audited_changes.keys, 'date_fin_prévue'
  end
end
