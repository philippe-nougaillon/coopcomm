# frozen_string_literal: true

require 'test_helper'

class ImporterConventionTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @adherent = users(:weil)
    @technique = services(:technique)
    @informatique = services(:informatique)
    @convention = Convention.create!(deposant: users(:hidalgo), workflow_state: Convention::EN_ATTENTE,
                                     document: { io: file_fixture('exemple.pdf').open, filename: 'convention.pdf' })
    @convention.analyser!
    @lecture = LireDocument::Lecture.new('texte', [], 6, 6)
  end

  test 'la première ligne de service lue remplit la convention déposée, qui attend d’être validée' do
    ImporterConvention.call(@convention, lu, @lecture)

    @convention.reload
    assert_equal [Convention::ANALYSE, @adherent, @technique, 350, Date.new(2025, 1, 1), Date.new(2024, 12, 16), nil,
                  'La Communauté met son service technique à la disposition d’Ariel Weil.'],
                 [@convention.workflow_state, @convention.user, @convention.service, @convention.heures_conventionnees, @convention.date_début,
                  @convention.date_signature, @convention.date_fin_prévue, @convention.résumé]
  end

  test 'chaque ligne de service suivante devient une convention sœur, même document et même déposant, qui attend d’être validée' do
    assert_difference 'Convention.count', 2 do
      ImporterConvention.call(@convention, lu, @lecture)
    end

    sœurs = Convention.where.not(id: @convention.id).order(:id).last(2)
    assert_equal [[@informatique, 100, Convention::ANALYSE, users(:hidalgo)], [nil, nil, Convention::ANALYSE, users(:hidalgo)]],
                 sœurs.map { |sœur| [sœur.service, sœur.heures_conventionnees, sœur.workflow_state, sœur.deposant] }
    assert_equal [@convention.document.blob] * 2, sœurs.map { |sœur| sœur.document.blob }
    assert_equal [@adherent] * 2, sœurs.map(&:user)
  end

  test 'sans ligne de service lue, la convention déposée reste sans service ni heures' do
    ImporterConvention.call(@convention, lu(services: []), @lecture)

    assert_equal [@adherent, nil, nil], [@convention.reload.user, @convention.service, @convention.heures_conventionnees]
  end

  test 'sans adhérent reconnu, la convention reste sans adhérent et garde le nom lu' do
    ImporterConvention.call(@convention, lu(user: AnalyserConvention::Proposition.new(nil, 'ET la commune de Beaumont', true),
                                            nom_adhérent: AnalyserConvention::Proposition.new('Beaumont')), @lecture)

    assert_nil @convention.reload.user
    assert_equal 'Beaumont', @convention.analyse['nom_adherent']
  end

  test 'les extraits lus sont notés avec la convention de chaque ligne' do
    ImporterConvention.call(@convention, lu, @lecture)

    analyse = @convention.reload.analyse
    assert_equal({ 'extrait' => 'et Ariel Weil, adhérent', 'retrouve' => true }, analyse['adherent'])
    assert_equal({ 'extrait' => 'prend effet le 1er janvier 2025', 'retrouve' => true }, analyse['date_debut'])
    assert_equal({ 'extrait' => 'Le [incertain : 16] décembre 2024', 'retrouve' => false }, analyse['date_signature'])
    assert_equal({ 'extrait' => nil, 'retrouve' => nil }, analyse['date_fin'])
    assert_equal({ 'extrait' => 'un volume annuel de 350 heures', 'retrouve' => true }, analyse['service'])
    assert_equal({ 'extrait' => 'Service informatique 100 heures', 'retrouve' => true },
                 Convention.where.not(id: @convention.id).order(:id).last(2).first.analyse['service'])
  end

  test 'les services reconnus dans tout le document sont notés, pour créer l’adhérent qui manque' do
    ImporterConvention.call(@convention, lu, @lecture)

    assert_equal [@technique.id, @informatique.id], @convention.reload.analyse['services']
  end

  test 'la façon dont le document a été lu est notée' do
    ImporterConvention.call(@convention, lu, LireDocument::Lecture.new(nil, %w[page-1 page-2], 3, nil))

    assert_equal [3, nil, 2], @convention.reload.analyse.values_at('pages', 'pages_ocr', 'pages_transcrites')
  end

  test 'sans date de début lue, la convention commence à la date de signature' do
    ImporterConvention.call(@convention, lu(date_début: AnalyserConvention::Proposition.new), @lecture)

    assert_equal Date.new(2024, 12, 16), @convention.reload.date_début
  end

  test 'sans date de début ni de signature lues, la convention commence au 1ᵉʳ janvier de l’année en cours' do
    travel_to Time.zone.local(2026, 10, 26, 12) do
      ImporterConvention.call(@convention, lu(date_début: AnalyserConvention::Proposition.new, date_signature: AnalyserConvention::Proposition.new), @lecture)
    end

    assert_equal Date.new(2026, 1, 1), @convention.reload.date_début
  end

  private

  # Ce qu'AnalyserConvention rend d'une convention de trois lignes de service, dont la dernière hors liste.
  def lu(**autres)
    { user: AnalyserConvention::Proposition.new(@adherent, 'et Ariel Weil, adhérent', true),
      nom_adhérent: AnalyserConvention::Proposition.new('Ariel Weil'),
      date_début: AnalyserConvention::Proposition.new(Date.new(2025, 1, 1), 'prend effet le 1er janvier 2025', true),
      date_signature: AnalyserConvention::Proposition.new(Date.new(2024, 12, 16), 'Le [incertain : 16] décembre 2024', false),
      date_fin_prévue: AnalyserConvention::Proposition.new(nil),
      résumé: AnalyserConvention::Proposition.new('La Communauté met son service technique à la disposition d’Ariel Weil.'),
      services: [AnalyserConvention::Ligne.new(@technique, 350, 'un volume annuel de 350 heures', true),
                 AnalyserConvention::Ligne.new(@informatique, 100, 'Service informatique 100 heures', true),
                 AnalyserConvention::Ligne.new(nil, nil, 'Service de balayage', true)] }.merge(autres)
  end
end
