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
  test 'pièce jointe : un document ajouté sans changement de colonne → un audit portant le libellé' do
    outil = tools(:rateau)

    assert_difference -> { outil.audits.count }, 1 do
      outil.update!(document: pdf)
    end
    assert_match(/document ajouté/i, outil.audits.last.comment)
  end

  test 'pièce jointe : deux attachements dans le même save → les deux sont mentionnés' do
    outil = tools(:rateau)

    outil.update!(photo: png, document: pdf)

    assert_match(/photo ajoutée/i, outil.audits.last.comment)
    assert_match(/document ajouté/i, outil.audits.last.comment)
  end

  test 'pièce jointe : pièce existante ré-émise par le formulaire → aucun faux message d\'ajout' do
    outil = tools(:rateau)
    outil.update!(document: pdf)
    existant = outil.document

    outil.update!(name: 'Rateau renommé', document: existant.signed_id)

    assert_equal existant.blob_id, outil.reload.document.blob_id
    refute_match(/ajouté/i, outil.audits.last.comment.to_s)
  end

  test 'pièce jointe : aucune pièce jointe ajoutée → aucun commentaire sur l\'audit' do
    outil = tools(:rateau)

    outil.update!(description: 'Description modifiée')

    assert_nil outil.audits.last.comment
  end

  test 'normalisation du nom : espaces et casse → humanisé et détouré' do
    outil = Tool.create!(name: '  PERCEUSE à colonne ', organisation: organisations(:mairie_paris))

    assert_equal 'Perceuse à colonne', outil.name
  end

  test 'unicité du nom : doublon dans la même organisation → refusé' do
    doublon = Tool.new(name: @outil.name, organisation: @outil.organisation)

    assert_not doublon.valid?
  end

  test 'unicité du nom : même nom dans une autre organisation → accepté' do
    homonyme = Tool.new(name: @outil.name, organisation: organisations(:mairie_marseille))

    assert homonyme.valid?
  end

  # ÉPINGLAGE d'un BUG SIGNALÉ (non corrigé) : le after_create appelle
  # `mouvements.create` sans utilisateur, or `belongs_to :user` est requis →
  # l'enregistrement échoue en silence et rien n'est posé. tool.rb:124.
  # À inverser quand le comportement voulu sera tranché (cf. registre).
  test 'create_mouvement : outil créé → aucun mouvement posé' do
    outil = Tool.create!(name: 'Sonde', organisation: organisations(:mairie_paris))

    assert_equal 0, Mouvement.where(tool: outil).count
  end

  # ÉPINGLAGE B39 — `indisponibles_ids` filtre sur `interventions.organisation_id`,
  # colonne qui n'existe pas (l'organisation dérive du service). À inverser à la
  # correction.
  test 'indisponibles_ids : appel → échoue sur une colonne organisation_id inexistante' do
    assert_raises(ActiveRecord::StatementInvalid) do
      Tool.indisponibles_ids(organisations(:mairie_paris).id, '2030-01-02 10:00')
    end
  end

  test 'disponible? : aucune intervention planifiée → vrai' do
    assert @outil.disponible?(Time.zone.local(2030, 1, 1, 10))
  end

  test 'disponible? : pendant une intervention planifiée → faux' do
    quand = Time.zone.local(2030, 1, 2, 10)
    Intervention.create!(
      description: 'Chantier avec outil', adherent: users(:weil), service: services(:technique),
      workflow_state: 'nouveau', début_prévue: quand - 1.hour, fin_prévue: quand + 1.hour,
      tools: [@outil], slug: SecureRandom.uuid
    )

    assert_not @outil.disponible?(quand)
  end

  test 'intervention_at : instant dans le créneau prévu → l\'intervention en cours' do
    intervention = interventions(:tonte_locaux)
    pendant = (intervention.début_prévue + 1.hour).to_s

    assert_equal intervention, tools(:tondeuse).intervention_at(pendant)
  end

  test 'intervention_at : instant hors du créneau prévu → rien' do
    intervention = interventions(:tonte_locaux)
    après = (intervention.fin_prévue + 1.day).to_s

    assert_nil tools(:tondeuse).intervention_at(après)
  end

  # ==================== TESTS CRITIQUES ====================
  # Grille de disponibilités : chaque lettre pilote l'action de la case dans
  # tools/_mouvement — L → lien « réserver », R → lien « libérer », I et P →
  # carré inerte. Une lettre fausse propose une action fausse, pas seulement
  # une couleur.

  test 'get_etats_from_mouvements : semaine sans mouvement → entièrement libre (critique)' do
    assert_equal %w[L L L L L L L], grille
  end

  test 'get_etats_from_mouvements : ma réservation → seule case marquée réservée par moi (critique)' do
    reservation('2026-06-02', @moi)

    assert_equal %w[L R L L L L L], grille
  end

  test 'get_etats_from_mouvements : réservation d\'un autre → case indisponible (critique)' do
    reservation('2026-06-04', @autre)

    assert_equal %w[L L L I L L L], grille
  end

  test 'get_etats_from_mouvements : panne antérieure à la semaine → semaine entière en panne (critique)' do
    panne('2026-05-28')

    assert_equal %w[P P P P P P P], grille
  end

  test 'get_etats_from_mouvements : jour de déclaration d\'une panne → en panne (critique)' do
    panne('2026-06-02')

    assert_equal 'P', grille[1]
  end

  test 'get_etats_from_mouvements : jours suivant une panne → en panne (critique)' do
    panne('2026-06-02')

    assert_equal %w[P P P P P], grille[2..]
  end

  test 'get_etats_from_mouvements : réparation → libre dès le jour de la fin de panne (critique)' do
    panne('2026-06-02')
    fin_panne('2026-06-04')

    assert_equal %w[L L L L], grille[3..]
  end

  test 'get_etats_from_mouvements : panne, réparation puis rechute → cycle retracé (critique)' do
    panne('2026-06-01')
    fin_panne('2026-06-03')
    panne('2026-06-05')

    assert_equal %w[P P L L P P P], grille
  end

  test 'get_etats_from_mouvements : journées réservées → le réservataire est nommé (critique)' do
    reservation('2026-06-02', @moi)
    reservation('2026-06-04', @autre)

    assert_equal [nil, @moi.id, nil, @autre.id, nil, nil, nil], reservataires
  end

  test 'get_etats_from_mouvements : journées libres ou en panne → aucun réservataire (critique)' do
    panne('2026-06-02')

    assert_equal [nil] * 7, reservataires
  end

  test 'get_etats_from_mouvements : mouvements d\'un autre outil → sans effet sur la grille (critique)' do
    reservation('2026-06-02', @moi, tools(:outil_paris))
    panne('2026-06-04', tools(:outil_paris))

    assert_equal %w[L L L L L L L], grille
  end

  test 'get_etats_from_mouvements : intervalle demandé → une lettre par jour (critique)' do
    assert_equal 1, @outil.get_etats_from_mouvements(LUNDI, LUNDI, @moi.id).size
    assert_equal 31, @outil.get_etats_from_mouvements(LUNDI, LUNDI + 30, @moi.id).size
  end

  # ÉPINGLAGE : rien n'empêche deux réservations le même jour, et la grille n'en
  # retient qu'une. Ma propre réservation est alors masquée par celle d'un autre,
  # donc la case n'offre pas le lien « libérer ». À inverser si le métier tranche.
  test 'get_etats_from_mouvements : deux réservations le même jour → seule la dernière compte (critique)' do
    reservation('2026-06-02', @moi)
    reservation('2026-06-02', @autre)

    assert_equal 'I', grille[1]
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'est_encore_en_panne_le : après la déclaration → vrai' do
    panne('2026-06-02')

    assert @outil.est_encore_en_panne_le(Date.new(2026, 6, 4))
  end

  test 'est_encore_en_panne_le : après la réparation → faux' do
    panne('2026-06-02')
    fin_panne('2026-06-04')

    assert_not @outil.est_encore_en_panne_le(Date.new(2026, 6, 6))
  end

  test 'est_encore_en_panne_le : outil sans mouvement → faux' do
    assert_not @outil.est_encore_en_panne_le(Date.new(2026, 6, 4))
  end

  test 'est_encore_en_panne_le : panne postérieure à la date demandée → faux' do
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

  def fin_panne(jour, outil = @outil)
    Mouvement.create!(tool: outil, user: @moi, état: :fin_panne, date: t(jour))
  end

  def reservation(jour, qui, outil = @outil)
    Mouvement.create!(tool: outil, user: qui, état: :réservé, date: t(jour))
  end
end
