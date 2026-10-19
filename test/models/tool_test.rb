# frozen_string_literal: true

require 'test_helper'

class ToolTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  # Semaine de référence en dates absolues : la grille de disponibilités dépend
  # de l'ordre des jours et de l'état de panne reporté d'un jour au suivant.
  LUNDI = Date.new(2026, 6, 1)
  DIMANCHE = Date.new(2026, 6, 7)

  setup do
    @outil = tools(:cisaille)
    @moi   = users(:bond)
    @autre = users(:weil)
  end

  # Un attachement n'étant pas une colonne, audited n'écrit une ligne que si le
  # commentaire est renseigné : c'est ce commentaire qui fait exister l'audit.
  test 'un document ajouté sans autre modification produit un audit qui le mentionne' do
    outil = tools(:rateau)

    assert_difference -> { outil.audits.count }, 1 do
      outil.update!(document: pdf)
    end
    assert_match(/document ajouté/i, outil.audits.last.comment)
  end

  test 'deux pièces jointes ajoutées ensemble sont toutes deux mentionnées dans le même audit' do
    outil = tools(:rateau)

    outil.update!(photo: png, document: pdf)

    assert_match(/photo ajoutée/i, outil.audits.last.comment)
    assert_match(/document ajouté/i, outil.audits.last.comment)
  end

  test "une pièce jointe existante ré-émise par le formulaire ne produit aucun faux message d'ajout" do
    outil = tools(:rateau)
    outil.update!(document: pdf)
    existant = outil.document

    outil.update!(name: 'Rateau renommé', document: existant.signed_id)

    assert_equal existant.blob_id, outil.reload.document.blob_id
    refute_match(/ajouté/i, outil.audits.last.comment.to_s)
  end

  test 'un outil modifié sans pièce jointe ajoutée a un audit sans commentaire' do
    outil = tools(:rateau)

    outil.update!(description: 'Description modifiée')

    assert_nil outil.audits.last.comment
  end

  test 'le nom saisi pour un outil est mis en majuscules et détouré' do
    outil = Tool.create!(name: '  PERCEUSE à colonne ', organisation: organisations(:mairie_paris))

    assert_equal 'PERCEUSE À COLONNE', outil.name
  end

  test 'un outil dont le nom existe déjà dans la même organisation est refusé' do
    doublon = Tool.new(name: @outil.name, organisation: @outil.organisation)

    assert_not doublon.valid?
  end

  test 'un outil dont le nom existe dans une autre organisation est accepté' do
    homonyme = Tool.new(name: @outil.name, organisation: organisations(:mairie_marseille))

    assert homonyme.valid?
  end

  # ÉPINGLAGE d'un BUG SIGNALÉ (non corrigé) : le after_create appelle
  # `mouvements.create` sans utilisateur, or `belongs_to :user` est requis →
  # l'enregistrement échoue en silence et rien n'est posé. tool.rb:124.
  # À inverser quand le comportement voulu sera tranché (cf. registre).
  test 'un outil créé ne reçoit aucun mouvement' do
    outil = Tool.create!(name: 'Sonde', organisation: organisations(:mairie_paris))

    assert_equal 0, Mouvement.where(tool: outil).count
  end

  # ÉPINGLAGE B39 — `indisponibles_ids` filtre sur `interventions.organisation_id`,
  # colonne qui n'existe pas (l'organisation dérive du service). À inverser à la
  # correction.
  test 'la liste des outils indisponibles échoue sur une colonne organisation_id inexistante' do
    assert_raises(ActiveRecord::StatementInvalid) do
      Tool.indisponibles_ids(organisations(:mairie_paris).id, '2030-01-02 10:00')
    end
  end

  test 'un outil sans intervention planifiée est disponible' do
    assert @outil.disponible?(Time.zone.local(2030, 1, 1, 10))
  end

  test 'un outil est indisponible pendant une intervention planifiée' do
    quand = Time.zone.local(2030, 1, 2, 10)
    Intervention.create!(
      description: 'Chantier avec outil', adherent: users(:weil), service: services(:technique),
      workflow_state: 'nouveau', début_prévue: quand - 1.hour, fin_prévue: quand + 1.hour,
      tools: [@outil], slug: SecureRandom.uuid
    )

    assert_not @outil.disponible?(quand)
  end

  test "un outil retrouve l'intervention dont le créneau prévu couvre l'instant demandé" do
    intervention = interventions(:tonte_locaux)
    pendant = (intervention.début_prévue + 1.hour).to_s

    assert_equal intervention, tools(:tondeuse).intervention_at(pendant)
  end

  test 'un outil ne retrouve aucune intervention à un instant hors du créneau prévu' do
    intervention = interventions(:tonte_locaux)
    après = (intervention.fin_prévue + 1.day).to_s

    assert_nil tools(:tondeuse).intervention_at(après)
  end

  # ==================== TESTS CRITIQUES ====================
  # Grille de disponibilités : chaque lettre pilote l'action de la case dans
  # tools/_mouvement — L → lien « réserver », R → lien « libérer », I et P →
  # carré inerte. Une lettre fausse propose une action fausse, pas seulement
  # une couleur.

  test 'une semaine sans mouvement est entièrement libre (critique)' do
    assert_equal %w[L L L L L L L], grille
  end

  test 'une réservation à mon nom marque sa seule case comme réservée par moi (critique)' do
    reservation('2026-06-02', @moi)

    assert_equal %w[L R L L L L L], grille
  end

  test "la réservation d'un autre utilisateur rend sa case indisponible (critique)" do
    reservation('2026-06-04', @autre)

    assert_equal %w[L L L I L L L], grille
  end

  test 'une panne antérieure à la semaine met la semaine entière en panne (critique)' do
    panne('2026-05-28')

    assert_equal %w[P P P P P P P], grille
  end

  test "le jour de déclaration d'une panne est en panne (critique)" do
    panne('2026-06-02')

    assert_equal 'P', grille[1]
  end

  test 'les jours suivant une panne sont en panne (critique)' do
    panne('2026-06-02')

    assert_equal %w[P P P P P], grille[2..]
  end

  test 'un outil réparé est libre dès le jour de la fin de panne (critique)' do
    panne('2026-06-02')
    fin_de_panne('2026-06-04')

    assert_equal %w[L L L L], grille[3..]
  end

  test 'une panne, une réparation puis une rechute sont retracées jour par jour (critique)' do
    panne('2026-06-01')
    fin_de_panne('2026-06-03')
    panne('2026-06-05')

    assert_equal %w[P P L L P P P], grille
  end

  test 'une journée réservée nomme son réservataire (critique)' do
    reservation('2026-06-02', @moi)
    reservation('2026-06-04', @autre)

    assert_equal [nil, @moi.id, nil, @autre.id, nil, nil, nil], reservataires
  end

  test 'une journée libre ou en panne ne nomme aucun réservataire (critique)' do
    panne('2026-06-02')

    assert_equal [nil] * 7, reservataires
  end

  test "les mouvements d'un autre outil sont sans effet sur la grille (critique)" do
    reservation('2026-06-02', @moi, tools(:outil_paris))
    panne('2026-06-04', tools(:outil_paris))

    assert_equal %w[L L L L L L L], grille
  end

  test 'la grille rend une lettre par jour de la période demandée (critique)' do
    assert_equal 1, @outil.get_etats_from_mouvements(LUNDI, LUNDI, @moi.id).size
    assert_equal 31, @outil.get_etats_from_mouvements(LUNDI, LUNDI + 30, @moi.id).size
  end

  # ÉPINGLAGE : rien n'empêche deux réservations le même jour, et la grille n'en
  # retient qu'une. Ma propre réservation est alors masquée par celle d'un autre,
  # donc la case n'offre pas le lien « libérer ». À inverser si le métier tranche.
  test 'entre deux réservations le même jour, seule la dernière compte (critique)' do
    reservation('2026-06-02', @moi)
    reservation('2026-06-02', @autre)

    assert_equal 'I', grille[1]
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'un outil est encore en panne à une date postérieure à la déclaration' do
    panne('2026-06-02')

    assert @outil.est_encore_en_panne_le(Date.new(2026, 6, 4))
  end

  test "un outil n'est plus en panne à une date postérieure à la réparation" do
    panne('2026-06-02')
    fin_de_panne('2026-06-04')

    assert_not @outil.est_encore_en_panne_le(Date.new(2026, 6, 6))
  end

  test "un outil sans mouvement n'est pas en panne" do
    assert_not @outil.est_encore_en_panne_le(Date.new(2026, 6, 4))
  end

  test "un outil n'est pas en panne à une date antérieure à la déclaration" do
    panne('2026-06-06')

    assert_not @outil.est_encore_en_panne_le(Date.new(2026, 6, 4))
  end

  private

  def png
    fixture_file_upload('exemple.png', 'image/png')
  end

  def pdf
    fixture_file_upload('exemple.pdf', 'application/pdf')
  end

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

  def fin_de_panne(jour, outil = @outil)
    Mouvement.create!(tool: outil, user: @moi, état: :fin_de_panne, date: t(jour))
  end

  def reservation(jour, qui, outil = @outil)
    Mouvement.create!(tool: outil, user: qui, état: :réservé, date: t(jour))
  end
end
