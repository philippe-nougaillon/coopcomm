# frozen_string_literal: true

require 'test_helper'

class MouvementTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @tool       = tools(:rateau)
    @declarant  = users(:bond)
    @reserviste = users(:weil)
    @outil      = tools(:cisaille)
  end

  test 'les mouvements sont triés du plus récent au plus ancien' do
    ancien = reservation(@outil, '2026-06-02', @reserviste)
    récent = reservation(@outil, '2026-06-09', @reserviste)

    ordonnés = @outil.mouvements.ordered.to_a

    assert_operator ordonnés.index(récent), :<, ordonnés.index(ancien)
  end

  # ==================== TESTS CRITIQUES ====================
  # Cohérence des pannes : une panne mal enregistrée laisse un outil réservable
  # alors qu'il est hors service, ou l'immobilise indéfiniment.

  test 'une panne déclarée sur un outil déjà en panne est refusée (critique)' do
    panne(@outil, '2026-06-02')

    doublon = Mouvement.new(tool: @outil, user: @declarant, état: :panne, date: t('2026-06-03'))

    assert_not doublon.valid?
    assert_includes doublon.errors[:état], "Impossible : l'outil est déjà en panne à ce moment-là."
  end

  test 'une panne déclarée juste avant une panne non réparée est refusée (critique)' do
    panne(@outil, '2026-06-05')

    antérieure = Mouvement.new(tool: @outil, user: @declarant, état: :panne, date: t('2026-06-03'))

    assert_not antérieure.valid?
    assert_includes antérieure.errors[:état],
                    'Impossible : une autre panne est déjà déclarée juste après sans avoir été réparée.'
  end

  test 'une panne déclarée après une réparation est acceptée (critique)' do
    panne(@outil, '2026-06-02')
    fin_de_panne(@outil, '2026-06-04')

    rechute = Mouvement.new(tool: @outil, user: @declarant, état: :panne, date: t('2026-06-06'))

    assert rechute.valid?
  end

  test "une réparation sur un outil qui n'est pas en panne est refusée (critique)" do
    réparation = Mouvement.new(tool: @outil, user: @declarant, état: :fin_de_panne, date: t('2026-06-04'))

    assert_not réparation.valid?
    assert_includes réparation.errors[:état], "Impossible : l'outil n'était pas déclaré en panne à cette date."
  end

  test 'une réparation après une autre réparation est refusée (critique)' do
    panne(@outil, '2026-06-02')
    fin_de_panne(@outil, '2026-06-04')

    doublon = Mouvement.new(tool: @outil, user: @declarant, état: :fin_de_panne, date: t('2026-06-06'))

    assert_not doublon.valid?
    assert_includes doublon.errors[:état], "Impossible : l'outil n'était pas déclaré en panne à cette date."
  end

  test 'une réparation intercalée avant une réparation déjà prévue plus tard est refusée (critique)' do
    panne(@outil, '2026-06-02')
    fin_de_panne(@outil, '2026-06-06')

    intercalée = Mouvement.new(tool: @outil, user: @declarant, état: :fin_de_panne, date: t('2026-06-04'))

    assert_not intercalée.valid?
    assert_includes intercalée.errors[:état], 'Impossible : une fin de panne est déjà prévue pour plus tard.'
  end

  test 'une réparation après une panne est acceptée (critique)' do
    panne(@outil, '2026-06-02')

    réparation = Mouvement.new(tool: @outil, user: @declarant, état: :fin_de_panne, date: t('2026-06-04'))

    assert réparation.valid?
  end

  test 'une panne sur un autre outil au même moment est acceptée (critique)' do
    panne(@outil, '2026-06-02')

    autre_outil = Mouvement.new(tool: tools(:outil_paris), user: @declarant, état: :panne, date: t('2026-06-03'))

    assert autre_outil.valid?
  end

  test 'une panne déplacée dans le temps est acceptée, jamais en conflit avec elle-même (critique)' do
    existante = panne(@outil, '2026-06-02')

    assert existante.update(date: t('2026-06-03'))
  end

  # ÉPINGLAGE : aucune règle n'interdit de réserver un outil en panne.
  # À inverser si le métier décide de bloquer la réservation d'un outil hors service.
  test "la réservation d'un outil en panne est acceptée (critique)" do
    panne(@outil, '2026-06-02')

    réservation = Mouvement.new(tool: @outil, user: @reserviste, état: :réservé, date: t('2026-06-03'))

    assert réservation.valid?
  end

  # ==================== /TESTS CRITIQUES ====================

  test "le réservataire à venir d'un outil tombé en panne est averti, avec la panne et sa réservation" do
    réservation = Mouvement.create!(tool: @tool, user: @reserviste, état: :réservé, date: 2.days.from_now)

    panne = nil
    assert_enqueued_jobs 1, only: NotifPanneJob do
      panne = Mouvement.create!(tool: @tool, user: @declarant, état: :panne, date: Time.current)
    end

    assert_enqueued_with(job: NotifPanneJob, args: [panne.id, réservation.id])
  end

  test 'chaque réservation à venir d’un outil tombé en panne reçoit son propre avertissement' do
    résa_1 = Mouvement.create!(tool: @tool, user: @reserviste, état: :réservé, date: 2.days.from_now)
    résa_2 = Mouvement.create!(tool: @tool, user: users(:patrick_adherent_paris), état: :réservé,
                               date: 3.days.from_now)

    panne = nil
    assert_enqueued_jobs 2, only: NotifPanneJob do
      panne = Mouvement.create!(tool: @tool, user: @declarant, état: :panne, date: Time.current)
    end

    couples = enqueued_jobs.select { |j| j[:job] == NotifPanneJob }.map { |j| j[:args] }

    assert_equal [[panne.id, résa_1.id], [panne.id, résa_2.id]].sort, couples.sort
  end

  test 'le déclarant d’une panne n’est pas averti pour sa propre réservation' do
    Mouvement.create!(tool: @tool, user: @declarant, état: :réservé, date: 2.days.from_now)

    assert_no_enqueued_jobs only: NotifPanneJob do
      Mouvement.create!(tool: @tool, user: @declarant, état: :panne, date: Time.current)
    end
  end

  test 'une réservation passée ne reçoit aucun avertissement de panne' do
    Mouvement.create!(tool: @tool, user: @reserviste, état: :réservé, date: 2.days.ago)

    assert_no_enqueued_jobs only: NotifPanneJob do
      Mouvement.create!(tool: @tool, user: @declarant, état: :panne, date: Time.current)
    end
  end

  # Le default_scope :kept de User s'applique à l'association : réservation.user
  # renvoie nil pour un réserviste soft-deleted, la garde `user.present?` l'exclut.
  test 'un réservataire désactivé ne reçoit aucun avertissement de panne' do
    Mouvement.create!(tool: @tool, user: @reserviste, état: :réservé, date: 2.days.from_now)
    @reserviste.discard

    assert_no_enqueued_jobs only: NotifPanneJob do
      Mouvement.create!(tool: @tool, user: @declarant, état: :panne, date: Time.current)
    end
  end

  test "un mouvement qui n'est pas une panne n'avertit personne" do
    Mouvement.create!(tool: @tool, user: @reserviste, état: :réservé, date: 3.days.from_now)

    assert_no_enqueued_jobs only: NotifPanneJob do
      Mouvement.create!(tool: @tool, user: @declarant, état: :réservé, date: 2.days.from_now)
    end
  end

  # ==================== TESTS CRITIQUES ====================
  # Réparation et réservations : la fin de panne détruit des réservations
  # d'autres utilisateurs, le périmètre détruit doit être exactement la durée
  # de la panne.

  test 'une réparation supprime la réservation posée pendant la panne (critique)' do
    panne(@outil, '2026-06-02')
    pendant = reservation(@outil, '2026-06-03', @reserviste)

    fin_de_panne(@outil, '2026-06-05')

    assert_not Mouvement.exists?(pendant.id)
  end

  test 'une réparation conserve une réservation qui lui est postérieure (critique)' do
    panne(@outil, '2026-06-02')
    après = reservation(@outil, '2026-06-09', @reserviste)

    fin_de_panne(@outil, '2026-06-05')

    assert Mouvement.exists?(après.id)
  end

  test 'une réparation conserve une réservation antérieure à la panne (critique)' do
    avant = reservation(@outil, '2026-05-28', @reserviste)
    panne(@outil, '2026-06-02')

    fin_de_panne(@outil, '2026-06-05')

    assert Mouvement.exists?(avant.id)
  end

  test 'une réparation ne supprime ni la panne ni elle-même (critique)' do
    début = panne(@outil, '2026-06-02')
    fin = fin_de_panne(@outil, '2026-06-05')

    assert_equal [début.id, fin.id].sort, @outil.mouvements.reload.pluck(:id).sort
  end

  test "une réparation dont la panne d'origine a disparu ne supprime rien (critique)" do
    début = panne(@outil, '2026-06-02')
    fin = fin_de_panne(@outil, '2026-06-05')
    début.destroy
    rescapée = reservation(@outil, '2026-06-03', @reserviste)

    # Sans la panne d'origine la fin de panne n'est plus valide : seul un
    # enregistrement sans validation permet d'atteindre la garde du nettoyage.
    fin.save!(validate: false)

    assert Mouvement.exists?(rescapée.id)
  end

  # ==================== /TESTS CRITIQUES ====================

  test "chaque état de mouvement a la couleur de badge qui le distingue à l'écran" do
    assert_equal 'primary', Mouvement.new(état: :réservé).style
    assert_equal 'warning', Mouvement.new(état: :panne).style
    assert_equal 'secondary', Mouvement.new(état: :fin_de_panne).style
  end

  test 'un mouvement sans état a une couleur de badge neutre' do
    assert_equal 'info', Mouvement.new.style
  end

  test "une panne suivie d'une réparation est résolue" do
    début = panne(@outil, '2026-06-02')
    fin_de_panne(@outil, '2026-06-04')

    assert début.resolue?
  end

  test "une panne sans réparation n'est pas résolue" do
    début = panne(@outil, '2026-06-02')

    assert_not début.resolue?
  end

  test "une panne n'est pas résolue par une réparation qui lui est antérieure" do
    panne(@outil, '2026-06-02')
    fin_de_panne(@outil, '2026-06-04')
    rechute = panne(@outil, '2026-06-06')

    assert_not rechute.resolue?
  end

  test 'une réservation ne se résout jamais' do
    assert_not reservation(@outil, '2026-06-02', @reserviste).resolue?
  end

  test 'une panne est résolue de la même façon que les mouvements soient chargés en mémoire ou lus en base' do
    début = panne(@outil, '2026-06-02')
    fin_de_panne(@outil, '2026-06-04')

    depuis_sql = début.resolue?
    début.tool.mouvements.load
    depuis_mémoire = début.resolue?

    assert_equal depuis_sql, depuis_mémoire
    assert depuis_mémoire
  end

  private

  # Dates absolues : ancrer un mouvement sur l'heure réelle rend les règles de
  # voisinage panne/réparation dépendantes du moment où la suite tourne.
  def t(jour)
    Time.zone.parse("#{jour} 09:00")
  end

  def panne(outil, jour)
    Mouvement.create!(tool: outil, user: @declarant, état: :panne, date: t(jour))
  end

  def fin_de_panne(outil, jour)
    Mouvement.create!(tool: outil, user: @declarant, état: :fin_de_panne, date: t(jour))
  end

  def reservation(outil, jour, qui)
    Mouvement.create!(tool: outil, user: qui, état: :réservé, date: t(jour))
  end
end
