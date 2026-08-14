# frozen_string_literal: true

require 'test_helper'

class ToolTest < ActiveSupport::TestCase
  # Semaine de référence en dates absolues : la grille de disponibilités dépend
  # de l'ordre des jours et de l'état de panne reporté d'un jour au suivant.
  LUNDI = Date.new(2026, 6, 1)
  DIMANCHE = Date.new(2026, 6, 7)

  setup do
    @outil = tools(:cisaille)
    @moi   = users(:bond)
    @autre = users(:weil)
  end

  # ==================== TESTS CRITIQUES ====================
  # Grille de disponibilités : chaque lettre pilote l'action de la case dans
  # tools/_mouvement — L → lien « réserver », R → lien « libérer », I et P →
  # carré inerte. Une lettre fausse propose une action fausse, pas seulement
  # une couleur.

  test 'une semaine sans mouvement est entièrement libre' do
    assert_equal %w[L L L L L L L], grille
  end

  test 'ma réservation est la seule case marquée réservée par moi' do
    reservation('2026-06-02', @moi)

    assert_equal %w[L R L L L L L], grille
  end

  test "la réservation d'un autre utilisateur est marquée indisponible" do
    reservation('2026-06-04', @autre)

    assert_equal %w[L L L I L L L], grille
  end

  test 'une panne antérieure à la semaine la couvre en entier' do
    panne('2026-05-28')

    assert_equal %w[P P P P P P P], grille
  end

  test 'les jours qui suivent la déclaration dune panne sont en panne' do
    panne('2026-06-02')

    assert_equal %w[P P P P P], grille[2..]
  end

  test 'la réparation rend loutil libre dès le jour de la fin de panne' do
    panne('2026-06-02')
    fin_panne('2026-06-04')

    assert_equal %w[L L L L], grille[3..]
  end

  test 'un cycle panne puis réparation puis nouvelle panne est retracé' do
    panne('2026-06-01')
    fin_panne('2026-06-03')
    panne('2026-06-05')

    assert_equal %w[P P L L P P P], grille
  end

  test 'le jour de déclaration dune panne est marqué en panne' do
    panne('2026-06-02')

    assert_equal 'P', grille[1]
  end

  test 'la grille nomme le réservataire des journées réservées' do
    reservation('2026-06-02', @moi)
    reservation('2026-06-04', @autre)

    assert_equal [nil, @moi.id, nil, @autre.id, nil, nil, nil], reservataires
  end

  test 'la grille ne nomme aucun réservataire pour les journées libres ou en panne' do
    panne('2026-06-02')

    assert_equal [nil] * 7, reservataires
  end

  test 'la grille ne tient compte que des mouvements de son propre outil' do
    reservation('2026-06-02', @moi, tools(:outil_paris))
    panne('2026-06-04', tools(:outil_paris))

    assert_equal %w[L L L L L L L], grille
  end

  test 'la grille rend une lettre par jour de lintervalle demandé' do
    assert_equal 1, @outil.get_etats_from_mouvements(LUNDI, LUNDI, @moi.id).size
    assert_equal 31, @outil.get_etats_from_mouvements(LUNDI, LUNDI + 30, @moi.id).size
  end

  # ÉPINGLAGE : rien n'empêche deux réservations le même jour, et la grille n'en
  # retient qu'une. Ma propre réservation est alors masquée par celle d'un autre,
  # donc la case n'offre pas le lien « libérer ». À inverser si le métier tranche.
  test 'deux réservations le même jour : seule la dernière compte' do
    reservation('2026-06-02', @moi)
    reservation('2026-06-02', @autre)

    assert_equal 'I', grille[1]
  end

  # ==================== /TESTS CRITIQUES ====================

  # ==========================================================================
  # A. est_encore_en_panne_le
  # ==========================================================================

  test 'un outil est encore en panne après la déclaration' do
    panne('2026-06-02')

    assert @outil.est_encore_en_panne_le(Date.new(2026, 6, 4))
  end

  test "un outil n'est plus en panne après la réparation" do
    panne('2026-06-02')
    fin_panne('2026-06-04')

    assert_not @outil.est_encore_en_panne_le(Date.new(2026, 6, 6))
  end

  test "un outil sans mouvement n'est pas en panne" do
    assert_not @outil.est_encore_en_panne_le(Date.new(2026, 6, 4))
  end

  test 'une panne postérieure à la date demandée ne compte pas' do
    panne('2026-06-06')

    assert_not @outil.est_encore_en_panne_le(Date.new(2026, 6, 4))
  end

  # ==========================================================================
  # C. intervention_at
  # ==========================================================================

  test "l'intervention en cours à une heure donnée est retrouvée" do
    intervention = interventions(:tonte_locaux)
    pendant = (intervention.début_prévue + 1.hour).to_s

    assert_equal intervention, tools(:tondeuse).intervention_at(pendant)
  end

  test "aucune intervention n'est retrouvée hors du créneau prévu" do
    intervention = interventions(:tonte_locaux)
    apres = (intervention.fin_prévue + 1.day).to_s

    assert_nil tools(:tondeuse).intervention_at(apres)
  end

  # ==========================================================================
  # D. Validations et création
  # ==========================================================================

  test 'un outil sans nom est invalide' do
    assert_not Tool.new(organisation: organisations(:mairie_paris)).valid?
  end

  test 'deux outils de la même organisation ne peuvent pas porter le même nom' do
    doublon = Tool.new(name: @outil.name, organisation: @outil.organisation)

    assert_not doublon.valid?
  end

  test 'deux organisations peuvent avoir un outil du même nom' do
    homonyme = Tool.new(name: @outil.name, organisation: organisations(:mairie_marseille))

    assert homonyme.valid?
  end

  test 'le nom est normalisé à la sauvegarde' do
    outil = Tool.create!(name: '  PERCEUSE à colonne ', organisation: organisations(:mairie_paris))

    assert_equal 'Perceuse à colonne', outil.name
  end

  # ÉPINGLAGE d'un BUG SIGNALÉ (non corrigé) : le after_create appelle
  # `mouvements.create` sans utilisateur, or `belongs_to :user` est requis →
  # l'enregistrement échoue en silence et rien n'est posé. tool.rb:160.
  # À inverser quand le comportement voulu sera tranché (cf. registre).
  test 'créer un outil ne pose aucun mouvement' do
    outil = Tool.create!(name: 'Sonde', organisation: organisations(:mairie_paris))

    assert_equal 0, Mouvement.where(tool: outil).count
  end

  test 'supprimer un outil supprime ses mouvements' do
    reservation('2026-06-02', @moi)

    assert_difference('Mouvement.count', -1) { @outil.destroy }
  end

  private

  def grille
    @outil.reload.get_etats_from_mouvements(LUNDI, DIMANCHE, @moi.id).map(&:etat)
  end

  def reservataires
    @outil.reload.get_etats_from_mouvements(LUNDI, DIMANCHE, @moi.id).map(&:reservataire_id)
  end

  def t(jour)
    Time.zone.parse("#{jour} 09:00")
  end

  def panne(jour, outil = @outil)
    Mouvement.create!(tool: outil, user: @moi, état: :panne, date: t(jour))
  end

  def fin_panne(jour, outil = @outil)
    Mouvement.create!(tool: outil, user: @moi, état: :fin_panne, date: t(jour))
  end

  def reservation(jour, qui, outil = @outil)
    Mouvement.create!(tool: outil, user: qui, état: :réservé, date: t(jour))
  end

  # --- Disponibilité ---

  test 'disponible? est vrai hors de toute intervention planifiée' do
    assert @outil.disponible?(Time.zone.local(2030, 1, 1, 10))
  end

  test 'disponible? est faux pendant une intervention planifiée' do
    quand = Time.zone.local(2030, 1, 2, 10)
    Intervention.create!(
      description: 'Chantier avec outil', adherent: users(:weil), service: services(:technique),
      workflow_state: 'nouveau', début_prévue: quand - 1.hour, fin_prévue: quand + 1.hour,
      tools: [@outil], slug: SecureRandom.uuid
    )

    assert_not @outil.disponible?(quand)
  end

  # ÉPINGLAGE B39 — `indisponibles_ids` filtre sur `interventions.organisation_id`,
  # colonne qui n'existe pas (l'organisation dérive du service). À inverser à la
  # correction.
  test 'indisponibles_ids échoue sur une colonne organisation_id inexistante' do
    assert_raises(ActiveRecord::StatementInvalid) do
      Tool.indisponibles_ids(organisations(:mairie_paris).id, '2030-01-02 10:00')
    end
  end
end
