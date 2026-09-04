# frozen_string_literal: true

require 'test_helper'

# `audit_details` est le rendu unifié de la colonne « détails » des 7 tableaux d'audit.
class AuditsHelperTest < ActionView::TestCase
  # render_changes_list rend une icône via embedded_svg (ApplicationHelper) :
  # ActionView::TestCase ne charge que le helper testé.
  include ApplicationHelper

  def audit(comment: nil, changes: {}, type: 'Intervention', action: 'update', request_uuid: nil, associated: nil)
    Audited::Audit.new(auditable_type: type, action: action, comment: comment, audited_changes: changes,
                       request_uuid: request_uuid, associated_type: associated&.class&.name, associated_id: associated&.id)
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

  test 'un audit sans changement significatif n\'affiche que son commentaire' do
    html = audit_details(audit(comment: '2 photos ajoutées', changes: { 'updated_at' => %w[a b] }), nil)

    assert_match '2 photos ajoutées', html
    # Le tiret est le placeholder de render_changes_list : l'afficher sous le
    # commentaire donnerait une liste de changements vide et trompeuse.
    assert_no_match(/—/, html)
  end

  test 'un commentaire et des changements sont rendus tous les deux' do
    html = audit_details(audit(comment: '1 photo ajoutée',
                               changes: { 'description' => ['Ancienne', 'Nouvelle'] }), nil)

    assert_match '1 photo ajoutée', html
    assert_match 'Description', html
    assert_match 'Nouvelle', html
  end

  test 'un commentaire vide laisse la place aux changements' do
    html = audit_details(audit(comment: '', changes: { 'description' => ['Ancienne', 'Nouvelle'] }), nil)

    assert_match 'Description', html
  end

  test 'un audit sans commentaire affiche la liste de ses changements' do
    html = audit_details(audit(changes: { 'description' => ['Ancienne', 'Nouvelle'] }), nil)

    assert_match 'Description', html
    assert_match 'Nouvelle', html
  end

  test 'la suppression d\'une absence affiche sa période plutôt que ses changements' do
    html = audit_details(audit(type: 'Absence', action: 'destroy',
                               changes: { 'du' => '2026-07-01', 'au' => '2026-07-03' }), nil)

    assert_match '2026-07-01', html
    assert_match '→', html
  end

  test 'une invitation renvoyée affiche son résumé plutôt que la liste brute' do
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

  test 'chaque action sur une absence porte son propre libellé de badge' do
    assert_equal 'Absence ajoutée',   libellé_badge(audit(type: 'Absence', action: 'create'))
    assert_equal 'Absence modifiée',  libellé_badge(audit(type: 'Absence', action: 'update'))
    assert_equal 'Absence supprimée', libellé_badge(audit(type: 'Absence', action: 'destroy'))
  end

  test 'une action inattendue sur une absence porte un libellé générique' do
    assert_equal 'Absence', libellé_badge(audit(type: 'Absence', action: 'restore'))
  end

  test 'la désactivation et la réactivation d\'un compte sont badgées' do
    désactivé = audit(type: 'User', changes: { 'discarded_at' => [nil, '2026-07-01 10:00:00'] })
    réactivé  = audit(type: 'User', changes: { 'discarded_at' => ['2026-07-01 10:00:00', nil] })

    assert_equal 'Compte désactivé', libellé_badge(désactivé)
    assert_equal 'Compte réactivé',  libellé_badge(réactivé)
  end

  test 'le verrouillage et le déverrouillage d\'un compte sont badgés' do
    bloqué  = audit(type: 'User', changes: { 'locked_at' => [nil, '2026-07-01 10:00:00'] })
    débloqué = audit(type: 'User', changes: { 'locked_at' => ['2026-07-01 10:00:00', nil] })

    assert_equal 'Compte bloqué',   libellé_badge(bloqué)
    assert_equal 'Compte débloqué', libellé_badge(débloqué)
  end

  test 'une connexion est badgée' do
    assert_equal 'Connexion', libellé_badge(audit(type: 'User', changes: { 'sign_in_count' => [1, 2] }))
  end

  test 'un jeton de session effacé est badgé comme une déconnexion' do
    audit = audit(type: 'User', changes: { 'remember_created_at' => ['2026-07-01 10:00:00', nil] })

    assert_equal 'Déconnexion', libellé_badge(audit)
  end

  test 'un jeton de session posé est badgé comme un maintien de connexion' do
    audit = audit(type: 'User', changes: { 'remember_created_at' => [nil, '2026-07-01 10:00:00'] })

    assert_equal 'Session', libellé_badge(audit)
  end

  test 'une invitation relancée est badgée comme telle' do
    assert_equal 'Invitation relancée', libellé_badge(audit(type: 'User', changes: { 'invitation_token' => %w[abc def] }))
  end

  test 'une première invitation est badgée comme un envoi' do
    audit = audit(type: 'User', changes: { 'invitation_token' => [nil, 'abc'],
                                           'invitation_created_at' => [nil, '2026-07-01 10:00:00'] })

    assert_equal 'Invitation envoyée', libellé_badge(audit)
  end

  test 'une invitation acceptée est badgée comme telle' do
    audit = audit(type: 'User', changes: { 'invitation_token' => ['abc', nil],
                                           'invitation_accepted_at' => [nil, '2026-07-01 10:00:00'] })

    assert_equal 'Invitation acceptée', libellé_badge(audit)
  end

  # L'audit de création porte TOUTES les colonnes, invitation_token comprise.
  test 'une création de compte n\'est pas badgée comme une invitation' do
    audit = audit(type: 'User', action: 'create', changes: { 'email' => 'a@b.fr', 'invitation_token' => nil })

    assert_equal 'Compte créé', libellé_badge(audit)
    assert_equal tracé_fichier('add'), tracé_icône(audit)
  end

  test 'un changement d\'entrepôt est badgé' do
    assert_equal 'Logistique', libellé_badge(audit(type: 'User', changes: { 'warehouse_id' => [1, 2] }))
  end

  test 'la création, la modification et la suppression d\'un compte sont badgées' do
    assert_equal 'Compte créé',    libellé_badge(audit(type: 'User', action: 'create', changes: { 'email' => 'a@b.fr' }))
    assert_equal 'Profil modifié', libellé_badge(audit(type: 'User', changes: { 'nom' => %w[Dupont Durand] }))
    assert_equal 'Compte supprimé', libellé_badge(audit(type: 'User', action: 'destroy', changes: { 'nom' => 'Dupont' }))
  end

  test 'la désactivation prime sur une connexion enregistrée dans le même audit' do
    audit = audit(type: 'User', changes: { 'discarded_at' => [nil, '2026-07-01 10:00:00'], 'sign_in_count' => [1, 2] })

    assert_equal 'Compte désactivé', libellé_badge(audit)
  end

  test 'le rattachement et le retrait d\'un service sont badgés' do
    assert_equal 'Service ajouté',     libellé_badge(audit(type: 'UserService', action: 'create'))
    assert_equal 'Service retiré',     libellé_badge(audit(type: 'UserService', action: 'destroy'))
    assert_equal 'Services modifiés',  libellé_badge(audit(type: 'UserService', action: 'update'))
  end

  test 'les agents et les outils d\'une intervention portent leur propre badge' do
    assert_equal 'Agent ajouté', libellé_badge(audit(type: 'AgentIntervention', action: 'create'))
    assert_equal 'Agent retiré', libellé_badge(audit(type: 'AgentIntervention', action: 'destroy'))
    assert_equal 'Outil ajouté', libellé_badge(audit(type: 'ToolIntervention', action: 'create'))
    assert_equal 'Outil retiré', libellé_badge(audit(type: 'ToolIntervention', action: 'destroy'))
  end

  test 'les autres modèles sont badgés selon leur action' do
    assert_equal 'Création',     libellé_badge(audit(action: 'create'))
    assert_equal 'Modification', libellé_badge(audit(action: 'update'))
    assert_equal 'Suppression',  libellé_badge(audit(action: 'destroy'))
  end

  test 'une action inconnue est badgée humainement plutôt qu\'en erreur' do
    assert_equal 'Restore', libellé_badge(audit(action: 'restore'))
  end

  # ==================== BLOC B — icône du badge ====================

  test 'une création porte le pictogramme add' do
    assert_equal tracé_fichier('add'), tracé_icône(audit(type: 'Absence', action: 'create'))
  end

  test 'une action sans pictogramme rend le libellé seul' do
    assert_nil tracé_icône(audit(type: 'Absence', action: 'restore'))
  end

  test 'la désactivation et la réactivation d\'un compte ont chacune leur pictogramme' do
    assert_equal tracé_fichier('no_accounts'),
                 tracé_icône(audit(type: 'User', changes: { 'discarded_at' => [nil, '2026-07-01 10:00:00'] }))
    assert_equal tracé_fichier('account_circle'),
                 tracé_icône(audit(type: 'User', changes: { 'discarded_at' => ['2026-07-01 10:00:00', nil] }))
  end

  test 'l\'invitation, la connexion, la déconnexion et le maintien de session ont chacun leur pictogramme' do
    assert_equal tracé_fichier('mail'),   tracé_icône(audit(type: 'User', changes: { 'invitation_token' => %w[a b] }))
    assert_equal tracé_fichier('login'),  tracé_icône(audit(type: 'User', changes: { 'sign_in_count' => [1, 2] }))
    assert_equal tracé_fichier('logout'),
                 tracé_icône(audit(type: 'User', changes: { 'remember_created_at' => ['2026-07-01 10:00:00', nil] }))
    assert_equal tracé_fichier('key'),
                 tracé_icône(audit(type: 'User', changes: { 'remember_created_at' => [nil, '2026-07-01 10:00:00'] }))
  end

  test 'le retrait d\'un service a son propre pictogramme' do
    assert_equal tracé_fichier('delete'), tracé_icône(audit(type: 'UserService', action: 'destroy'))
  end

  # ==================== BLOC C — repli quand rien de significatif n'a changé ====================

  test 'un compte désactivé montre le passage de Réactivé à Désactivé' do
    html = audit_details(audit(type: 'User', changes: { 'discarded_at' => [nil, '2026-07-01 10:00:00'] }), nil)

    assert_match 'Statut du compte', html
    assert_match 'Désactivé', html
  end

  test 'un compte réactivé montre le passage de Désactivé à Réactivé' do
    html = audit_details(audit(type: 'User', changes: { 'discarded_at' => ['2026-07-01 10:00:00', nil] }), nil)

    assert_match 'Statut du compte', html
    assert_match 'Réactivé', html
  end

  test 'le détail d\'un audit de connexion annonce la connexion' do
    html = audit_details(audit(type: 'User', changes: { 'sign_in_count' => [1, 2] }), nil)

    assert_match "Connexion à l&#39;application", html
  end

  test 'le détail d\'un audit de déconnexion annonce la déconnexion' do
    html = audit_details(audit(type: 'User', changes: { 'remember_created_at' => ['2026-07-01 10:00:00', nil] }), nil)

    assert_match "Déconnexion de l&#39;application", html
  end

  test 'le détail d\'un jeton de session posé annonce le maintien de la connexion' do
    html = audit_details(audit(type: 'User', changes: { 'remember_created_at' => [nil, '2026-07-01 10:00:00'] }), nil)

    assert_match 'Maintien de la connexion (Cookie)', html
  end

  test 'un audit sans changement significatif est rendu par un tiret' do
    html = audit_details(audit(changes: { 'updated_at' => %w[a b] }), nil)

    assert_match '—', html
  end

  test 'un changement de profil invisible ne doit pas être présenté comme une déconnexion' do
    audit = audit(type: 'User', changes: { 'otp_secret' => %w[aaa bbb] })

    assert_no_match(/Déconnexion/, audit_details(audit, nil))
    assert_no_match(/Maintien de la connexion/, audit_details(audit, nil))
  end

  test 'une invitation datée affiche ses dates plutôt que le message générique' do
    html = audit_details(audit(type: 'User',
                               changes: { 'invitation_token' => %w[abc def],
                                          'invitation_sent_at' => [nil, '2026-07-01 10:00:00'] }), nil)

    assert_match 'Email envoyé', html
    assert_no_match(/renvoyé/, html)
  end

  test 'une création de compte affiche ses champs, pas le résumé d\'invitation' do
    html = audit_details(audit(type: 'User', action: 'create',
                               changes: { 'email' => 'a@b.fr', 'nom' => 'Dupont', 'invitation_token' => nil }), nil)

    assert_match 'a@b.fr', html
    assert_match 'Dupont', html
    assert_no_match(/renvoyé/, html)
  end

  test 'une invitation acceptée affiche son message dédié, pas « lien renvoyé »' do
    html = audit_details(audit(type: 'User', changes: { 'invitation_token' => ['abc', nil],
                                                        'invitation_accepted_at' => [nil, '2026-07-01 10:00:00'] }), nil)

    assert_match 'acceptée', html
    assert_no_match(/renvoyé/, html)
  end

  # ==================== BLOC D — formatage des valeurs ====================

  test 'les champs techniques ne sont jamais présentés à l\'utilisateur' do
    changes = { 'updated_at' => %w[a b], 'slug' => %w[a b], 'encrypted_password' => %w[a b], 'template_slug' => %w[a b] }

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

  test 'les heures réelles d\'une intervention affichent les secondes, les heures prévues non' do
    assert_equal '01/02/2026 à 14:30:45', format_audit_value('début', Time.zone.local(2026, 2, 1, 14, 30, 45))
    assert_equal '01/02/2026 à 14:30:45', format_audit_value('fin', '2026-02-01 14:30:45')
    assert_equal '01/02/2026 à 14:30', format_audit_value('début_prévue', Time.zone.local(2026, 2, 1, 14, 30, 45))
    assert_equal '01/02/2026 à 14:30', format_audit_value('fin_prévue', '2026-02-01 14:30:45')
  end

  test 'une chaîne qui ressemble à une date sans en être une est rendue telle quelle' do
    assert_equal '2026-13-45', format_audit_value('date', '2026-13-45')
  end

  test 'les demi-journées d\'absence sont rendues en oui / non' do
    assert_equal 'Oui', format_audit_value('matin', true)
    assert_equal 'Non', format_audit_value('apres_midi', false)
    assert_equal 'Oui', format_audit_value('journee', '1')
  end

  # Les libellés viennent des enums des modèles : une valeur ajoutée à l'enum est
  # traduite sans retoucher le helper.
  test 'le motif d\'absence est traduit, une valeur inconnue reste brute' do
    Absence.motifs.each do |nom, valeur|
      assert_equal nom.tr('_', ' ').humanize, format_audit_value('motif', valeur.to_s)
    end
    assert_equal '9', format_audit_value('motif', '9')
  end

  test 'l\'état d\'un mouvement est traduit, une valeur inconnue reste brute' do
    assert_equal 'Réservé',         format_audit_value('état', Mouvement.états[:réservé])
    assert_equal 'Panne',           format_audit_value('état', Mouvement.états[:panne])
    assert_equal 'Fin de panne',    format_audit_value('état', Mouvement.états[:fin_de_panne])
    assert_equal '9',               format_audit_value('état', 9)
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

  # ==================== BLOC F — tables de liaison ====================

  test 'un agent ajouté à une intervention se lit comme une phrase' do
    html = audit_details(audit(type: 'AgentIntervention', action: 'create',
                               changes: { 'agent_id' => users(:bond).id, 'intervention_id' => 42 }), nil)

    assert_match 'Bond James', html
    assert_match "ajouté à l&#39;intervention n°42", html
    # Les identifiants bruts et les libellés de colonne n'ont plus lieu d'être.
    assert_no_match(/Agent id|Intervention id/, html)
  end

  test 'un agent retiré d\'une intervention se lit comme une phrase' do
    html = audit_details(audit(type: 'AgentIntervention', action: 'destroy',
                               changes: { 'agent_id' => users(:bond).id, 'intervention_id' => 42 }), nil)

    assert_match "retiré de l&#39;intervention n°42", html
  end

  test 'un outil ajouté à une intervention se lit comme une phrase' do
    html = audit_details(audit(type: 'ToolIntervention', action: 'create',
                               changes: { 'tool_id' => tools(:tondeuse).id, 'intervention_id' => 7 }), nil)

    assert_match 'Tondeuse', html
    assert_match "ajouté à l&#39;intervention n°7", html
  end

  test 'un service rattaché à un utilisateur se lit comme une phrase' do
    ajout   = audit_details(audit(type: 'UserService', action: 'create',
                                  changes: { 'user_id' => users(:bond).id, 'service_id' => services(:technique).id }), nil)
    retrait = audit_details(audit(type: 'UserService', action: 'destroy',
                                  changes: { 'user_id' => users(:bond).id, 'service_id' => services(:technique).id }), nil)

    assert_match 'rattaché au service Technique', ajout
    assert_match 'retiré du service Technique', retrait
  end

  test 'les agents assignés dans la même requête tiennent sur une seule ligne' do
    intervention = interventions(:tonte_locaux)
    lot = [users(:bond), users(:martin_technique_paris)].map do |agent|
      audit(type: 'AgentIntervention', action: 'create', request_uuid: 'abc-123', associated: intervention,
            changes: { 'agent_id' => agent.id, 'intervention_id' => intervention.id })
    end

    groupes = grouper_audits(lot)

    assert_equal 1, groupes.size
    assert_equal 'Agents ajoutés', libellé_badge(groupes.first)
    html = audit_details(groupes.first, nil)
    assert_match 'Bond James', html
    assert_match 'Martin Michel', html
  end

  test 'un ajout et un retrait dans la même requête donnent une ligne « modifiés »' do
    intervention = interventions(:tonte_locaux)
    lot = [%w[create], %w[destroy]].flatten.map.with_index do |action, i|
      audit(type: 'AgentIntervention', action: action, request_uuid: 'abc-123', associated: intervention,
            changes: { 'agent_id' => [users(:bond).id, users(:martin_technique_paris).id][i], 'intervention_id' => intervention.id })
    end

    groupes = grouper_audits(lot)

    assert_equal 1, groupes.size
    assert_equal 'Agents modifiés', libellé_badge(groupes.first)
  end

  test 'deux requêtes distinctes ne sont jamais regroupées' do
    intervention = interventions(:tonte_locaux)
    lot = %w[uuid-1 uuid-2].map do |uuid|
      audit(type: 'AgentIntervention', action: 'create', request_uuid: uuid, associated: intervention,
            changes: { 'agent_id' => users(:bond).id, 'intervention_id' => intervention.id })
    end

    assert_equal 2, grouper_audits(lot).size
  end

  test 'deux interventions différentes ne sont jamais regroupées' do
    lot = [interventions(:tonte_locaux), interventions(:nouvelle_intervention)].map do |intervention|
      audit(type: 'AgentIntervention', action: 'create', request_uuid: 'abc-123', associated: intervention,
            changes: { 'agent_id' => users(:bond).id, 'intervention_id' => intervention.id })
    end

    assert_equal 2, grouper_audits(lot).size
  end

  test 'les audits ordinaires traversent le regroupement sans être touchés' do
    lot = [audit(changes: { 'description' => %w[a b] }), audit(changes: { 'description' => %w[b c] })]

    assert_equal lot, grouper_audits(lot)
  end

  # ==================== BLOC G — identifiants résolus en libellés ====================

  test 'les identifiants d\'association sont remplacés par le libellé de l\'enregistrement' do
    assert_equal organisations(:mairie_paris).nom, format_audit_value('organisation_id', organisations(:mairie_paris).id)
    assert_equal 'n°42', format_audit_value('intervention_id', 42)
    assert_equal prestations(:nettoyage_bureaux).libellé, format_audit_value('prestation_id', prestations(:nettoyage_bureaux).id)
  end

  test 'un compte désactivé reste nommé dans l\'historique' do
    users(:bond).discard

    assert_equal 'Bond James', format_audit_value('user_id', users(:bond).id)
  end

  test 'un enregistrement réellement supprimé est retrouvé dans sa trace d\'audit' do
    Audited::Audit.create!(auditable_type: 'Service', auditable_id: 999_999, action: 'destroy',
                           audited_changes: { 'nom' => 'Service dissous' })

    assert_equal 'Service dissous', format_audit_value('service_id', 999_999)
  end

  test 'le rôle d\'un utilisateur est traduit' do
    assert_equal 'Manager', format_audit_value('rôle', User.rôles[:manager])
  end

  test 'les booléens sont rendus en oui / non' do
    assert_equal 'Oui', format_audit_value('repeter', true)
    assert_equal 'Non', format_audit_value('repeter', false)
    assert_equal 'Non', format_audit_value('publiée', 'false')
  end

  test 'le compteur d\'invitations et le type d\'inviteur ne sont pas présentés' do
    changes = { 'invitations_count' => [0, 1], 'invited_by_type' => [nil, 'User'], 'invitation_limit' => [nil, 5] }

    assert_empty humanize_changes(changes)
  end

  # ==================== BLOC H — enregistrements supprimés ====================

  test 'un agent supprimé reste nommé dans l\'audit de liaison, grâce à sa propre trace' do
    Audited::Audit.create!(auditable_type: 'User', auditable_id: 999_999, action: 'destroy',
                           audited_changes: { 'nom' => 'DUPONT', 'email' => 'dupont@ccmm.fr' })

    html = audit_details(audit(type: 'AgentIntervention', action: 'destroy',
                               changes: { 'agent_id' => 999_999, 'intervention_id' => 42 }), nil)

    assert_match 'DUPONT', html
  end

  test 'un agent supprimé sans aucune trace n\'empêche pas l\'audit de s\'afficher' do
    html = audit_details(audit(type: 'AgentIntervention', action: 'destroy',
                               changes: { 'agent_id' => 999_999, 'intervention_id' => 42 }), nil)

    assert_match 'Utilisateur #999999', html
    assert_match "retiré de l&#39;intervention", html
  end

  test 'un outil supprimé reste nommé dans l\'audit de liaison' do
    Audited::Audit.create!(auditable_type: 'Tool', auditable_id: 999_999, action: 'destroy',
                           audited_changes: { 'name' => 'Débroussailleuse' })

    html = audit_details(audit(type: 'ToolIntervention', action: 'destroy',
                               changes: { 'tool_id' => 999_999, 'intervention_id' => 42 }), nil)

    assert_match 'Débroussailleuse', html
  end

  test 'un audit de liaison sans ses clés ne fait pas tomber la page' do
    html = audit_details(audit(type: 'AgentIntervention', action: 'create', changes: {}), nil)

    assert_match '—', html
    assert_match "ajouté à l&#39;intervention", html
  end

  test 'un lot groupé contenant un audit incomplet reste rendu' do
    intervention = interventions(:tonte_locaux)
    lot = [{ 'agent_id' => users(:bond).id, 'intervention_id' => intervention.id }, {}].map do |changes|
      audit(type: 'AgentIntervention', action: 'create', request_uuid: 'abc-123', associated: intervention, changes: changes)
    end

    groupes = grouper_audits(lot)

    assert_equal 1, groupes.size
    assert_match 'Bond James', audit_details(groupes.first, nil)
  end

  test 'un type auditable qui n\'existe plus ne fait pas tomber la page' do
    html = audit_details(audit(type: 'ModeleDisparu', changes: { 'motif' => [0, 1] }), nil)

    assert_match 'Motif', html
  end

  test 'les autres associations supprimées sont retrouvées dans leur trace d\'audit' do
    Audited::Audit.create!(auditable_type: 'Organisation', auditable_id: 999_999, action: 'destroy',
                           audited_changes: { 'nom' => 'Commune dissoute' })
    Audited::Audit.create!(auditable_type: 'Commande', auditable_id: 999_999, action: 'destroy',
                           audited_changes: { 'ref' => 'CM-2026-9' })

    assert_equal 'Commune dissoute', format_audit_value('organisation_id', 999_999)
    assert_equal 'CM-2026-9', format_audit_value('commande_id', 999_999)
    assert_equal 'Prestation #999999', format_audit_value('prestation_id', 999_999)
  end

  test 'une ligne de facture nomme sa facture par sa référence' do
    assert_equal factures(:facture_paris).ref, format_audit_value('facture_id', factures(:facture_paris).id)
  end

  test 'une facture supprimée est retrouvée dans sa trace d\'audit' do
    Audited::Audit.create!(auditable_type: 'Facture', auditable_id: 999_999, action: 'destroy',
                           audited_changes: { 'ref' => 'FA-2026-9' })

    assert_equal 'FA-2026-9', format_audit_value('facture_id', 999_999)
  end

  test 'sur la fiche d\'une intervention, la cible n\'est pas répétée' do
    changes = { 'agent_id' => users(:bond).id, 'intervention_id' => 42 }
    avec  = audit_details(audit(type: 'AgentIntervention', action: 'create', changes: changes), nil)
    sans  = audit_details(audit(type: 'AgentIntervention', action: 'create', changes: changes), nil, cible: false)

    assert_match 'n°42', avec
    assert_no_match(/n°42/, sans)
    assert_match "ajouté à l&#39;intervention", sans
  end

  # ==================== BLOC I — pièces jointes ====================

  test 'une pièce jointe ajoutée est présentée comme les autres informations' do
    html = audit_details(audit(comment: '2 photos ajoutées'), nil)

    assert_match 'Pièce jointe', html
    assert_match '2 photos ajoutées', html
    # Le commentaire n'est plus une phrase entre guillemets détachée du reste.
    assert_no_match(/"2 photos/, html)
    assert_not_nil Nokogiri::HTML::DocumentFragment.parse(html).at_css('ul li')
  end

  test 'une pièce jointe et un changement de colonne cohabitent dans la même liste' do
    html = audit_details(audit(comment: '1 photo ajoutée', changes: { 'description' => %w[Tonte Élagage] }), nil)
    items = Nokogiri::HTML::DocumentFragment.parse(html).css('ul li')

    assert_equal 2, items.size
    assert_match 'Pièce jointe', items.first.text
  end

  test 'un commentaire qui ne parle pas de pièce jointe n\'en revendique pas le libellé' do
    html = audit_details(audit(comment: 'Régularisation manuelle'), nil)

    assert_match 'Commentaire', html
    assert_no_match(/Pièce jointe/, html)
  end

  # La création d'un compte porte TOUTES les colonnes, dont warehouse_id.
  test 'une création de compte n\'est pas un changement d\'entrepôt' do
    audit = audit(type: 'User', action: 'create', changes: { 'email' => 'a@b.fr', 'warehouse_id' => nil })

    assert_equal 'Compte créé', libellé_badge(audit)
  end

  # ==================== BLOC J — mots clés ====================

  test 'un mot clé ajouté est nommé, pas résumé par une ligne vide' do
    html = audit_details(audit(changes: { 'tag_list' => [%w[urgence], %w[urgence plomberie]] }), nil)

    assert_match 'Mots clés', html
    assert_match 'urgence, plomberie', html
    assert_no_match(/—/, html)
  end

  test 'un mot clé retiré montre la liste d\'avant et celle d\'après' do
    changements = humanize_changes({ 'tag_list' => [%w[urgence peinture], %w[urgence]] })

    assert_equal 1, changements.size
    assert_equal 'Mots clés', changements.first[:label]
    assert_equal 'urgence, peinture', changements.first[:from]
    assert_equal 'urgence', changements.first[:to]
  end

  test 'des mots clés tous retirés donnent un tiret, pas un tableau vide' do
    changements = humanize_changes({ 'tag_list' => [%w[urgence], []] })

    assert_equal 'urgence', changements.first[:from]
    assert_equal '—', changements.first[:to]
  end

  # Sur une création, la valeur stockée est la liste elle-même : la lire comme un
  # couple avant/après annoncerait « urgence → plomberie ».
  test 'à la création, la liste des mots clés est une valeur, pas un avant/après' do
    changements = humanize_changes({ 'tag_list' => %w[urgence plomberie] })

    assert_equal '—', changements.first[:from]
    assert_equal 'urgence, plomberie', changements.first[:to]
  end

  test 'une création sans mot clé n\'ajoute aucune ligne' do
    assert_empty humanize_changes({ 'tag_list' => [] })
  end

  test 'une liste de mots clés inchangée est ignorée' do
    assert_empty humanize_changes({ 'tag_list' => [%w[urgence], %w[urgence]] })
  end

  test 'un changement de mots clés enregistré en base donne un audit lisible' do
    intervention = interventions(:tonte_locaux)
    intervention.update!(tag_list: 'urgence')
    intervention.update!(tag_list: 'urgence, plomberie')

    html = audit_details(intervention.audits.reload.last, nil)

    assert_match 'Mots clés', html
    assert_match 'urgence, plomberie', html
  end

  test 'les mots clés d\'un utilisateur sont rendus comme ceux d\'une intervention' do
    html = audit_details(audit(type: 'User', changes: { 'tag_list' => [[], ['Secteur Nord']] }), nil)

    assert_match 'Mots clés', html
    assert_match 'Secteur Nord', html
  end
end
