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

  # Le libellé du badge sans son icône ni ses classes : un renommage de classe
  # Tailwind ne doit pas faire échouer un test de libellé.
  def libellé_badge(audit)
    Nokogiri::HTML::DocumentFragment.parse(audit_badge(audit)).text.strip
  end

  # Identifie l'icône rendue par son tracé, comparé au fichier source.
  def tracé_icône(audit)
    Nokogiri::HTML::DocumentFragment.parse(audit_badge(audit)).at_css('svg path')&.[]('d')
  end

  def tracé_fichier(nom)
    svg = File.read(Rails.root.join('public/icons', "#{nom}.svg"))
    Nokogiri::HTML::DocumentFragment.parse(svg).at_css('path')['d']
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

  # ==================== BLOC A — libellé du badge ====================

  test 'badge Absence : un libellé par action' do
    assert_equal 'Absence ajoutée',   libellé_badge(audit(type: 'Absence', action: 'create'))
    assert_equal 'Absence modifiée',  libellé_badge(audit(type: 'Absence', action: 'update'))
    assert_equal 'Absence supprimée', libellé_badge(audit(type: 'Absence', action: 'destroy'))
  end

  test 'badge Absence : action inattendue → libellé générique' do
    assert_equal 'Absence', libellé_badge(audit(type: 'Absence', action: 'restore'))
  end

  test 'badge User : désactivation et réactivation du compte' do
    désactivé = audit(type: 'User', changes: { 'discarded_at' => [nil, '2026-07-01 10:00:00'] })
    réactivé  = audit(type: 'User', changes: { 'discarded_at' => ['2026-07-01 10:00:00', nil] })

    assert_equal 'Compte désactivé', libellé_badge(désactivé)
    assert_equal 'Compte réactivé',  libellé_badge(réactivé)
  end

  test 'badge User : verrouillage et déverrouillage du compte' do
    bloqué  = audit(type: 'User', changes: { 'locked_at' => [nil, '2026-07-01 10:00:00'] })
    débloqué = audit(type: 'User', changes: { 'locked_at' => ['2026-07-01 10:00:00', nil] })

    assert_equal 'Compte bloqué',   libellé_badge(bloqué)
    assert_equal 'Compte débloqué', libellé_badge(débloqué)
  end

  test 'badge User : connexion' do
    assert_equal 'Connexion', libellé_badge(audit(type: 'User', changes: { 'sign_in_count' => [1, 2] }))
  end

  test 'badge User : déconnexion quand le jeton de session est effacé' do
    audit = audit(type: 'User', changes: { 'remember_created_at' => ['2026-07-01 10:00:00', nil] })

    assert_equal 'Déconnexion', libellé_badge(audit)
  end

  test 'badge User : maintien de session quand le jeton est posé' do
    audit = audit(type: 'User', changes: { 'remember_created_at' => [nil, '2026-07-01 10:00:00'] })

    assert_equal 'Session', libellé_badge(audit)
  end

  test 'badge User : invitation relancée' do
    assert_equal 'Invitation relancée', libellé_badge(audit(type: 'User', changes: { 'invitation_token' => %w[abc def] }))
  end

  test 'badge User : changement d\'entrepôt' do
    assert_equal 'Logistique', libellé_badge(audit(type: 'User', changes: { 'warehouse_id' => [1, 2] }))
  end

  test 'badge User : création, modification de profil et suppression' do
    assert_equal 'Compte créé',    libellé_badge(audit(type: 'User', action: 'create', changes: { 'email' => 'a@b.fr' }))
    assert_equal 'Profil modifié', libellé_badge(audit(type: 'User', changes: { 'nom' => %w[Dupont Durand] }))
    assert_equal 'Utilisateur',    libellé_badge(audit(type: 'User', action: 'destroy', changes: { 'nom' => 'Dupont' }))
  end

  test 'badge User : la désactivation prime sur la connexion simultanée' do
    audit = audit(type: 'User', changes: { 'discarded_at' => [nil, '2026-07-01 10:00:00'], 'sign_in_count' => [1, 2] })

    assert_equal 'Compte désactivé', libellé_badge(audit)
  end

  test 'badge UserService : association, retrait et cas restant' do
    assert_equal 'Service associé', libellé_badge(audit(type: 'UserService', action: 'create'))
    assert_equal 'Service retiré',  libellé_badge(audit(type: 'UserService', action: 'destroy'))
    assert_equal 'Service',         libellé_badge(audit(type: 'UserService', action: 'update'))
  end

  test 'badge des autres modèles : création, modification, suppression' do
    assert_equal 'Création',     libellé_badge(audit(action: 'create'))
    assert_equal 'Modification', libellé_badge(audit(action: 'update'))
    assert_equal 'Suppression',  libellé_badge(audit(action: 'destroy'))
  end

  test 'badge : action inconnue rendue humainement plutôt qu\'en erreur' do
    assert_equal 'Restore', libellé_badge(audit(action: 'restore'))
  end

  # ==================== BLOC B — icône du badge ====================

  test 'icône : une création porte le pictogramme add' do
    assert_equal tracé_fichier('add'), tracé_icône(audit(type: 'Absence', action: 'create'))
  end

  test 'icône : une action sans pictogramme rend le libellé seul' do
    assert_nil tracé_icône(audit(type: 'Absence', action: 'restore'))
  end

  test 'icône : désactivation et réactivation de compte' do
    assert_equal tracé_fichier('no_accounts'),
                 tracé_icône(audit(type: 'User', changes: { 'discarded_at' => [nil, '2026-07-01 10:00:00'] }))
    assert_equal tracé_fichier('account_circle'),
                 tracé_icône(audit(type: 'User', changes: { 'discarded_at' => ['2026-07-01 10:00:00', nil] }))
  end

  test 'icône : invitation, connexion, déconnexion et maintien de session' do
    assert_equal tracé_fichier('mail'),   tracé_icône(audit(type: 'User', changes: { 'invitation_token' => %w[a b] }))
    assert_equal tracé_fichier('login'),  tracé_icône(audit(type: 'User', changes: { 'sign_in_count' => [1, 2] }))
    assert_equal tracé_fichier('logout'),
                 tracé_icône(audit(type: 'User', changes: { 'remember_created_at' => ['2026-07-01 10:00:00', nil] }))
    assert_equal tracé_fichier('key'),
                 tracé_icône(audit(type: 'User', changes: { 'remember_created_at' => [nil, '2026-07-01 10:00:00'] }))
  end

  test 'icône : retrait de service' do
    assert_equal tracé_fichier('delete'), tracé_icône(audit(type: 'UserService', action: 'destroy'))
  end

  # ==================== BLOC C — repli quand rien de significatif n'a changé ====================

  test 'User désactivé : le détail montre le passage de Réactivé à Désactivé' do
    html = audit_details(audit(type: 'User', changes: { 'discarded_at' => [nil, '2026-07-01 10:00:00'] }), nil)

    assert_match 'Statut du compte', html
    assert_match 'Désactivé', html
  end

  test 'User réactivé : le détail montre le passage de Désactivé à Réactivé' do
    html = audit_details(audit(type: 'User', changes: { 'discarded_at' => ['2026-07-01 10:00:00', nil] }), nil)

    assert_match 'Statut du compte', html
    assert_match 'Réactivé', html
  end

  test 'User connecté : le détail annonce la connexion' do
    html = audit_details(audit(type: 'User', changes: { 'sign_in_count' => [1, 2] }), nil)

    assert_match "Connexion à l&#39;application", html
  end

  test 'User déconnecté : le détail annonce la déconnexion' do
    html = audit_details(audit(type: 'User', changes: { 'remember_created_at' => ['2026-07-01 10:00:00', nil] }), nil)

    assert_match "Déconnexion de l&#39;application", html
  end

  test 'User avec jeton de session posé : le détail annonce le maintien de connexion' do
    html = audit_details(audit(type: 'User', changes: { 'remember_created_at' => [nil, '2026-07-01 10:00:00'] }), nil)

    assert_match 'Maintien de la connexion (Cookie)', html
  end

  test 'autre modèle sans changement significatif : un tiret' do
    html = audit_details(audit(changes: { 'updated_at' => %w[a b] }), nil)

    assert_match '—', html
  end

  test 'un changement de profil invisible ne doit pas être présenté comme une déconnexion' do
    audit = audit(type: 'User', changes: { 'otp_secret' => %w[aaa bbb] })

    assert_no_match(/Déconnexion/, audit_details(audit, nil))
    assert_no_match(/Maintien de la connexion/, audit_details(audit, nil))
  end

  test 'invitation datée : les dates remplacent le message générique' do
    html = audit_details(audit(type: 'User',
                               changes: { 'invitation_token' => %w[abc def],
                                          'invitation_sent_at' => [nil, '2026-07-01 10:00:00'] }), nil)

    assert_match 'Email envoyé', html
    assert_no_match(/renvoyé/, html)
  end

  # ==================== BLOC D — formatage des valeurs ====================

  test 'les champs techniques ne sont jamais présentés à l\'utilisateur' do
    changes = { 'updated_at' => %w[a b], 'slug' => %w[a b], 'encrypted_password' => %w[a b], 'tag_list' => %w[a b] }

    assert_empty humanize_changes(changes)
  end

  test 'un champ dont la valeur n\'a pas bougé est ignoré' do
    assert_empty humanize_changes({ 'nom' => %w[Dupont Dupont] })
  end

  test 'un champ vide avant et après est ignoré' do
    assert_empty humanize_changes({ 'nom' => [nil, ''] })
  end

  test 'statut du compte et verrouillage sont traduits' do
    assert_equal 'Désactivé', format_audit_value('discarded_at', '2026-07-01 10:00:00')
    assert_equal 'Réactivé',  format_audit_value('discarded_at', nil)
    assert_equal 'Verrouillé', format_audit_value('locked_at', '2026-07-01 10:00:00')
    assert_equal 'Ouvert',     format_audit_value('locked_at', nil)
  end

  test 'une valeur absente est rendue par un tiret' do
    assert_equal '—', format_audit_value('description', nil)
    assert_equal '—', format_audit_value('description', '   ')
  end

  test 'une date est rendue au format français, une date-heure avec l\'heure' do
    assert_equal '01/02/2026', format_audit_value('date', Date.new(2026, 2, 1))
    assert_equal '01/02/2026 à 14:30', format_audit_value('début_prévue', Time.zone.local(2026, 2, 1, 14, 30))
  end

  test 'une date reçue sous forme de chaîne ISO est reformatée' do
    assert_equal '01/02/2026', format_audit_value('date', '2026-02-01')
    assert_equal '01/02/2026 à 14:30', format_audit_value('début_prévue', '2026-02-01 14:30:00')
  end

  test 'une chaîne qui ressemble à une date sans en être une est rendue telle quelle' do
    assert_equal '2026-13-45', format_audit_value('date', '2026-13-45')
  end

  test 'les demi-journées d\'absence sont rendues en oui / non' do
    assert_equal 'Oui', format_audit_value('matin', true)
    assert_equal 'Non', format_audit_value('apres_midi', false)
    assert_equal 'Oui', format_audit_value('journee', '1')
  end

  test 'le motif d\'absence est traduit, une valeur inconnue reste brute' do
    assert_equal 'Congé annuel', format_audit_value('motif', '0')
    assert_equal 'Maladie',      format_audit_value('motif', '1')
    assert_equal 'RTT',          format_audit_value('motif', '2')
    assert_equal '9',            format_audit_value('motif', '9')
  end

  test 'l\'état d\'un mouvement est traduit, une valeur inconnue reste brute' do
    assert_equal 'Panne',             format_audit_value('état', 2)
    assert_equal 'Fin de la panne',   format_audit_value('état', 3)
    assert_equal 'Réservé',           format_audit_value('état', 4)
    assert_equal 9,                   format_audit_value('état', 9)
  end

  test 'un adhérent est identifié par son email, un identifiant orphelin par son numéro' do
    assert_equal users(:weil).email, format_audit_value('adherent_id', users(:weil).id)
    assert_equal 'Utilisateur #999999', format_audit_value('adherent_id', 999_999)
  end

  test 'un outil est identifié par son nom, un identifiant orphelin par son numéro' do
    assert_equal 'Tondeuse', format_audit_value('tool_id', tools(:tondeuse).id)
    assert_equal 'Outil #999999', format_audit_value('tool_id', 999_999)
  end

  test 'un utilisateur est identifié par nom et prénom' do
    assert_equal 'Bond James', format_audit_value('user_id', users(:bond).id)
    assert_equal 'Utilisateur #999999', format_audit_value('user_id', 999_999)
  end

  test 'un service est identifié par son nom, un identifiant orphelin par son numéro' do
    assert_equal 'Technique', format_audit_value('service_id', services(:technique).id)
    assert_equal 'Service #999999', format_audit_value('service_id', 999_999)
  end

  test 'le changement de service d\'une intervention est rendu en clair' do
    changement = { 'service_id' => [services(:informatique).id, services(:technique).id] }

    assert_equal [{ label: 'Service', from: 'Informatique', to: 'Technique' }],
                 humanize_changes(changement)
  end

  test 'un entrepôt est identifié par son nom' do
    assert_equal 'Entrepôt de Paris', format_audit_value('warehouse_id', warehouses(:entrepot_paris).id)
  end

  test 'un entrepôt supprimé retrouve son nom dans l\'historique des audits' do
    Audited::Audit.create!(auditable_type: 'Warehouse', auditable_id: 999_999, action: 'update',
                           audited_changes: { 'name' => ['Ancien dépôt', 'Dépôt du canal'] }, version: 1)

    assert_equal 'Dépôt du canal', format_audit_value('warehouse_id', 999_999)
  end

  test 'un entrepôt inconnu et sans historique retombe sur son identifiant' do
    assert_equal '999999', format_audit_value('warehouse_id', 999_999)
  end

  test 'une clé sans libellé métier est rendue lisiblement' do
    assert_equal 'Statut', audit_field_label('workflow_state')
    assert_equal 'Ancienne colonne', audit_field_label('ancienne_colonne')
  end

  test 'une valeur unicode traverse le rendu sans dommage' do
    html = audit_details(audit(changes: { 'description' => ['Tonte', 'Élagage à Sète — 30 m²'] }), nil)

    assert_match 'Élagage à Sète — 30 m²', html
  end

  test 'une valeur contenant du HTML est échappée' do
    html = audit_details(audit(changes: { 'description' => ['Tonte', '<script>alert(1)</script>'] }), nil)

    assert_no_match(/<script>/, html)
  end

  # ==================== BLOC E — liste des changements ====================

  test 'un changement de valeur affiche l\'ancienne et la nouvelle' do
    html = audit_details(audit(changes: { 'description' => %w[Tonte Élagage] }), nil)

    assert_match 'Tonte', html
    assert_match 'Élagage', html
  end

  test 'une initialisation affiche la valeur seule, sans flèche de transition' do
    initialisation = audit_details(audit(action: 'create', changes: { 'description' => 'Tonte' }), nil)
    changement     = audit_details(audit(changes: { 'description' => %w[Tonte Élagage] }), nil)

    assert_match 'Tonte', initialisation
    assert_nil Nokogiri::HTML::DocumentFragment.parse(initialisation).at_css('li svg')
    assert_not_nil Nokogiri::HTML::DocumentFragment.parse(changement).at_css('li svg')
  end

  test 'une liste de changements vide rend un tiret' do
    assert_match '—', render_changes_list([])
  end
end
