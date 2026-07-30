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

  # ==========================================================================
  # ============ TESTS CRITIQUES : grille de disponibilités ==================
  # Chaque lettre pilote l'action de la case dans tools/_mouvement :
  # L → lien « réserver », R → lien « libérer », I et P → carré inerte.
  # Une lettre fausse propose donc une action fausse, pas seulement une couleur.
  # ==========================================================================

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

  # Le « R » du vendredi est le bug signalé ci-dessous : c'est le jour de la
  # seconde panne. À passer en « P » le jour où tool.rb:136 sera corrigé.
  test 'un cycle panne puis réparation puis nouvelle panne est retracé' do
    panne('2026-06-01')
    fin_panne('2026-06-03')
    panne('2026-06-05')

    assert_equal %w[P P L L R P P], grille
  end

  # BUG SIGNALÉ (non corrigé) : le jour où une panne est déclarée s'affiche « R »
  # (réservé par moi, cliquable pour libérer) au lieu de « P ».
  # tool.rb:136 pose current_state = "R" au lieu de "P". Cf. registre des bugs.
  test 'le jour de déclaration dune panne est marqué en panne' do
    skip 'Bug signalé : le jour de la panne est marqué « R » au lieu de « P » (tool.rb:136).'

    panne('2026-06-02')

    assert_equal 'P', grille[1]
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
  # B. dernier_mouvement_a
  # ==========================================================================

  test 'une panne en cours prime sur la dernière réservation' do
    en_panne = panne('2026-06-02')
    reservation('2026-06-03', @moi)

    assert_equal en_panne, @outil.dernier_mouvement_a(t('2026-06-04'))
  end

  test 'le dernier mouvement ignore ce qui vient après la date demandée' do
    ancienne = reservation('2026-06-02', @moi)
    reservation('2026-06-06', @autre)

    assert_equal ancienne, @outil.dernier_mouvement_a(t('2026-06-04'))
  end

  test 'une panne réparée ne prime plus sur la dernière réservation' do
    panne('2026-06-02')
    fin_panne('2026-06-03')
    derniere = reservation('2026-06-04', @moi)

    assert_equal derniere, @outil.dernier_mouvement_a(t('2026-06-05'))
  end

  # BUG SIGNALÉ (non corrigé) : la branche « mouvements déjà chargés » trie par
  # `m.date.to_i`, or mouvements.date est une colonne `date` → NoMethodError.
  # tool.rb:84. Cf. registre des bugs.
  test 'dernier_mouvement_a répond la même chose que les mouvements soient chargés ou non' do
    skip 'Bug signalé : dernier_mouvement_a lève NoMethodError sur une association chargée (tool.rb:84).'

    en_panne = panne('2026-06-02')
    reservation('2026-06-03', @moi)

    depuis_sql = @outil.dernier_mouvement_a(t('2026-06-04'))
    @outil.mouvements.load
    depuis_memoire = @outil.dernier_mouvement_a(t('2026-06-04'))

    assert_equal en_panne, depuis_sql
    assert_equal depuis_sql, depuis_memoire
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
    @outil.reload.get_etats_from_mouvements(LUNDI, DIMANCHE, @moi.id)
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

  # ÉPINGLAGE B37 — `dernier_mouvement_a` trie par `m.date.to_i`, or `mouvements.date`
  # est une colonne `date` : dès que l'association est chargée (un `includes`
  # suffirait), la méthode lève. À inverser à la correction.
  test 'dernier_mouvement_a lève quand les mouvements sont déjà chargés' do
    outil = tools(:tondeuse)
    outil.mouvements.load

    assert_raises(NoMethodError) { outil.dernier_mouvement_a(Time.current) }
  end
end
