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

  # ==================== TESTS CRITIQUES ====================
  # Cohérence des pannes : une panne mal enregistrée laisse un outil réservable
  # alors qu'il est hors service, ou l'immobilise indéfiniment.

  test "déclarer une panne sur un outil déjà en panne est refusé" do
    panne(@outil, '2026-06-02')

    doublon = Mouvement.new(tool: @outil, user: @declarant, état: :panne, date: t('2026-06-03'))

    assert_not doublon.valid?
    assert_includes doublon.errors[:état], "Impossible : l'outil est déjà en panne à ce moment-là."
  end

  test 'déclarer une panne juste avant une panne non réparée est refusé' do
    panne(@outil, '2026-06-05')

    anterieure = Mouvement.new(tool: @outil, user: @declarant, état: :panne, date: t('2026-06-03'))

    assert_not anterieure.valid?
    assert_includes anterieure.errors[:état],
                    'Impossible : une autre panne est déjà déclarée juste après sans avoir été réparée.'
  end

  test 'déclarer une panne après une réparation est accepté' do
    panne(@outil, '2026-06-02')
    fin_panne(@outil, '2026-06-04')

    rechute = Mouvement.new(tool: @outil, user: @declarant, état: :panne, date: t('2026-06-06'))

    assert rechute.valid?
  end

  test "déclarer une fin de panne sur un outil qui n'est pas en panne est refusé" do
    reparation = Mouvement.new(tool: @outil, user: @declarant, état: :fin_panne, date: t('2026-06-04'))

    assert_not reparation.valid?
    assert_includes reparation.errors[:état], "Impossible : l'outil n'était pas déclaré en panne à cette date."
  end

  test 'déclarer une fin de panne après une autre fin de panne est refusé' do
    panne(@outil, '2026-06-02')
    fin_panne(@outil, '2026-06-04')

    doublon = Mouvement.new(tool: @outil, user: @declarant, état: :fin_panne, date: t('2026-06-06'))

    assert_not doublon.valid?
    assert_includes doublon.errors[:état], "Impossible : l'outil n'était pas déclaré en panne à cette date."
  end

  test 'déclarer une fin de panne alors quune réparation est déjà prévue plus tard est refusé' do
    panne(@outil, '2026-06-02')
    fin_panne(@outil, '2026-06-06')

    intercalee = Mouvement.new(tool: @outil, user: @declarant, état: :fin_panne, date: t('2026-06-04'))

    assert_not intercalee.valid?
    assert_includes intercalee.errors[:état], 'Impossible : une fin de panne est déjà prévue pour plus tard.'
  end

  test 'déclarer une fin de panne après une panne est accepté' do
    panne(@outil, '2026-06-02')

    reparation = Mouvement.new(tool: @outil, user: @declarant, état: :fin_panne, date: t('2026-06-04'))

    assert reparation.valid?
  end

  test 'les règles de cohérence sont bornées à un seul outil' do
    panne(@outil, '2026-06-02')

    autre_outil = Mouvement.new(tool: tools(:outil_paris), user: @declarant, état: :panne, date: t('2026-06-03'))

    assert autre_outil.valid?
  end

  test 'modifier une panne ne la fait pas entrer en conflit avec elle-même' do
    existante = panne(@outil, '2026-06-02')

    assert existante.update(date: t('2026-06-03'))
  end

  # ÉPINGLAGE : aucune règle n'interdit de réserver un outil en panne.
  # À inverser si le métier décide de bloquer la réservation d'un outil hors service.
  test 'réserver un outil en panne reste possible' do
    panne(@outil, '2026-06-02')

    reservation = Mouvement.new(tool: @outil, user: @reserviste, état: :réservé, date: t('2026-06-03'))

    assert reservation.valid?
  end

  # ==================== /TESTS CRITIQUES ====================

  # ==================== TESTS CRITIQUES ====================
  # Réparation et réservations : la fin de panne détruit des réservations
  # d'autres utilisateurs, le périmètre détruit doit être exactement la durée
  # de la panne.

  test 'la réparation supprime les réservations posées pendant la panne' do
    panne(@outil, '2026-06-02')
    pendant = reservation(@outil, '2026-06-03', @reserviste)

    fin_panne(@outil, '2026-06-05')

    assert_not Mouvement.exists?(pendant.id)
  end

  test 'la réparation conserve les réservations postérieures à la panne' do
    panne(@outil, '2026-06-02')
    apres = reservation(@outil, '2026-06-09', @reserviste)

    fin_panne(@outil, '2026-06-05')

    assert Mouvement.exists?(apres.id)
  end

  test 'la réparation conserve les réservations antérieures à la panne' do
    avant = reservation(@outil, '2026-05-28', @reserviste)
    panne(@outil, '2026-06-02')

    fin_panne(@outil, '2026-06-05')

    assert Mouvement.exists?(avant.id)
  end

  test 'la réparation conserve la panne et la fin de panne' do
    debut = panne(@outil, '2026-06-02')
    fin = fin_panne(@outil, '2026-06-05')

    assert_equal [debut.id, fin.id].sort, @outil.mouvements.reload.pluck(:id).sort
  end

  test 'la réparation ne détruit rien si la panne dorigine a disparu' do
    debut = panne(@outil, '2026-06-02')
    fin = fin_panne(@outil, '2026-06-05')
    debut.destroy
    rescapee = reservation(@outil, '2026-06-03', @reserviste)

    # Sans la panne d'origine la fin de panne n'est plus valide : seul un
    # enregistrement sans validation permet d'atteindre la garde du nettoyage.
    fin.save!(validate: false)

    assert Mouvement.exists?(rescapee.id)
  end

  # ==================== /TESTS CRITIQUES ====================

  # ==========================================================================
  # A. resolue?
  # ==========================================================================

  test 'une panne suivie dune réparation est résolue' do
    debut = panne(@outil, '2026-06-02')
    fin_panne(@outil, '2026-06-04')

    assert debut.resolue?
  end

  test 'une panne sans réparation nest pas résolue' do
    debut = panne(@outil, '2026-06-02')

    assert_not debut.resolue?
  end

  test 'une réparation antérieure ne résout pas une panne' do
    panne(@outil, '2026-06-02')
    fin_panne(@outil, '2026-06-04')
    rechute = panne(@outil, '2026-06-06')

    assert_not rechute.resolue?
  end

  test 'une réservation nest jamais résolue' do
    assert_not reservation(@outil, '2026-06-02', @reserviste).resolue?
  end

  test 'resolue? répond la même chose que les mouvements soient chargés ou non' do
    debut = panne(@outil, '2026-06-02')
    fin_panne(@outil, '2026-06-04')

    depuis_sql = debut.resolue?
    debut.tool.mouvements.load
    depuis_memoire = debut.resolue?

    assert_equal depuis_sql, depuis_memoire
    assert depuis_memoire
  end

  # ==========================================================================
  # B. Attributs dérivés
  # ==========================================================================

  test 'chaque état a son style de badge' do
    assert_equal 'primary', Mouvement.new(état: :réservé).style
    assert_equal 'warning', Mouvement.new(état: :panne).style
    assert_equal 'secondary', Mouvement.new(état: :fin_panne).style
  end

  test 'un mouvement sans date est invalide' do
    assert_not Mouvement.new(tool: @outil, user: @declarant, état: :réservé).valid?
  end

  test "l'organisation d'un mouvement est celle de son outil" do
    assert_equal @outil.organisation, reservation(@outil, '2026-06-02', @reserviste).organisation
  end

  # ==========================================================================
  # C. Notification des réservations futures à la déclaration d'une panne
  # ==========================================================================

  test "déclarer une panne enqueue NotifPanneJob pour la réservation future d'un autre utilisateur" do
    réservation = Mouvement.create!(tool: @tool, user: @reserviste, état: :réservé, date: 2.days.from_now)

    panne = nil
    assert_enqueued_jobs 1, only: NotifPanneJob do
      panne = Mouvement.create!(tool: @tool, user: @declarant, état: :panne, date: Time.current)
    end

    # Le job reçoit des ids bruts (pas de GlobalID) : (mouvement_panne_id, réservation_id).
    assert_enqueued_with(job: NotifPanneJob, args: [panne.id, réservation.id])
  end

  test 'déclarer une panne enqueue un NotifPanneJob par réservation future' do
    résa_1 = Mouvement.create!(tool: @tool, user: @reserviste, état: :réservé, date: 2.days.from_now)
    résa_2 = Mouvement.create!(tool: @tool, user: users(:patrick_adherent_paris), état: :réservé, date: 3.days.from_now)

    panne = nil
    assert_enqueued_jobs 2, only: NotifPanneJob do
      panne = Mouvement.create!(tool: @tool, user: @declarant, état: :panne, date: Time.current)
    end

    couples = enqueued_jobs.select { |j| j[:job] == NotifPanneJob }.map { |j| j[:args] }
    assert_equal [[panne.id, résa_1.id], [panne.id, résa_2.id]].sort, couples.sort
  end

  test 'les réservations futures du déclarant lui-même ne sont pas notifiées' do
    Mouvement.create!(tool: @tool, user: @declarant, état: :réservé, date: 2.days.from_now)

    assert_no_enqueued_jobs only: NotifPanneJob do
      Mouvement.create!(tool: @tool, user: @declarant, état: :panne, date: Time.current)
    end
  end

  test 'les réservations passées ne sont pas notifiées' do
    Mouvement.create!(tool: @tool, user: @reserviste, état: :réservé, date: 2.days.ago)

    assert_no_enqueued_jobs only: NotifPanneJob do
      Mouvement.create!(tool: @tool, user: @declarant, état: :panne, date: Time.current)
    end
  end

  test "la réservation future d'un utilisateur supprimé (discard) n'est pas notifiée" do
    # Le default_scope :kept de User s'applique à l'association : réservation.user
    # renvoie nil pour un réserviste soft-deleted, la garde `user.present?` l'exclut.
    Mouvement.create!(tool: @tool, user: @reserviste, état: :réservé, date: 2.days.from_now)
    @reserviste.discard

    assert_no_enqueued_jobs only: NotifPanneJob do
      Mouvement.create!(tool: @tool, user: @declarant, état: :panne, date: Time.current)
    end
  end

  test "créer un mouvement qui n'est pas une panne ne notifie personne" do
    Mouvement.create!(tool: @tool, user: @reserviste, état: :réservé, date: 3.days.from_now)

    assert_no_enqueued_jobs only: NotifPanneJob do
      Mouvement.create!(tool: @tool, user: @declarant, état: :réservé, date: 2.days.from_now)
    end
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

  def fin_panne(outil, jour)
    Mouvement.create!(tool: outil, user: @declarant, état: :fin_panne, date: t(jour))
  end

  def reservation(outil, jour, qui)
    Mouvement.create!(tool: outil, user: qui, état: :réservé, date: t(jour))
  end

  test 'un mouvement sans état retombe sur le style neutre' do
    assert_equal 'info', Mouvement.new.style
  end
end
