# frozen_string_literal: true

require 'test_helper'

# `audit_details` est le rendu unifié de la colonne « détails » des 7 tableaux d'audit.
class AuditsHelperTest < ActionView::TestCase
  # render_changes_list rend une icône via embedded_svg (ApplicationHelper) :
  # ActionView::TestCase ne charge que le helper testé.
  include ApplicationHelper

  def audit(comment: nil, changes: {}, type: 'Intervention', action: 'update')
    Audited::Audit.new(auditable_type: type, action: action, comment: comment, audited_changes: changes)
  end

  test 'commentaire sans changement significatif : le commentaire seul, sans liste vide' do
    html = audit_details(audit(comment: '2 photos ajoutées', changes: { 'updated_at' => %w[a b] }), nil)

    assert_match '2 photos ajoutées', html
    # Le tiret est le placeholder de render_changes_list : l'afficher sous le
    # commentaire donnerait une liste de changements vide et trompeuse.
    assert_no_match(/—/, html)
  end

  test 'commentaire ET changements : les deux sont rendus (ils ne s\'excluent pas)' do
    html = audit_details(audit(comment: '1 photo ajoutée',
                               changes: { 'description' => ['Ancienne', 'Nouvelle'] }), nil)

    assert_match '1 photo ajoutée', html
    assert_match 'Description', html
    assert_match 'Nouvelle', html
  end

  test 'commentaire vide : on retombe sur les changements' do
    html = audit_details(audit(comment: '', changes: { 'description' => ['Ancienne', 'Nouvelle'] }), nil)

    assert_match 'Description', html
  end

  test 'sans commentaire : la liste des changements' do
    html = audit_details(audit(changes: { 'description' => ['Ancienne', 'Nouvelle'] }), nil)

    assert_match 'Description', html
    assert_match 'Nouvelle', html
  end

  test 'suppression d\'absence : la période remplace la liste des changements' do
    html = audit_details(audit(type: 'Absence', action: 'destroy',
                               changes: { 'du' => '2026-07-01', 'au' => '2026-07-03' }), nil)

    assert_match '2026-07-01', html
    assert_match '→', html
  end

  test 'invitation renvoyée : le résumé dédié, pas la liste brute' do
    html = audit_details(audit(type: 'User', changes: { 'invitation_token' => %w[abc def] }), nil)

    # L'apostrophe est échappée par content_tag (&#39;) : on n'asserte que la fin.
    assert_match 'accès renvoyé', html
    assert_no_match(/abc|def/, html)
  end

  test 'le commentaire est échappé (il peut contenir un paramètre de requête)' do
    html = audit_details(audit(comment: 'Photo n°<script>alert(1)</script> supprimée'), nil)

    assert_no_match(/<script>/, html)
    assert_match 'alert(1)', html
  end
end
