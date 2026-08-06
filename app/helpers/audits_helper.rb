# frozen_string_literal: true

module AuditsHelper
  FILTERED_FIELDS = %w[
    invitation_token
    encrypted_password
    reset_password_token
    reset_password_sent_at
    remember_created_at
    sign_in_count
    current_sign_in_at
    last_sign_in_at
    current_sign_in_ip
    last_sign_in_ip
    failed_attempts
    otp_secret
    signature
    ip
    consumed_timestep
    otp_required_for_login
    uid
    provider
    slug
    updated_at
    id
    template_slug
    tag_list
    invited_by_type
    invitations_count
    invitation_limit
  ].freeze

  # Tables de liaison : leur audit ne se lit pas comme une liste de colonnes mais
  # comme une phrase (« X ajouté à l'intervention »).
  LIAISONS = %w[AgentIntervention ToolIntervention UserService].freeze

  # Le modèle qui porte l'enum, quand l'audit ne dit pas de quel type il parle.
  MODELES_ENUM = {
    'motif' => 'Absence',
    'état' => 'Mouvement',
    'rôle' => 'User'
  }.freeze

  LIBELLES_ENUM = {
    'fin_panne' => 'Fin de la panne',
    'faq' => 'FAQ'
  }.freeze

  NOMS_LIAISONS = {
    'AgentIntervention' => %w[Agent Agents],
    'ToolIntervention' => %w[Outil Outils],
    'UserService' => %w[Service Services]
  }.freeze

  # Les audits de liaison d'une même requête (assignation des agents d'une
  # intervention, par exemple) sont rendus sur une seule ligne du tableau.
  class GroupeLiaisons
    attr_reader :audits

    delegate :created_at, :user, :user_id, :auditable_type, :comment, to: :premier

    def initialize(audits)
      @audits = audits
    end

    def premier
      audits.first
    end

    def actions
      audits.map(&:action).uniq
    end

    def action
      actions.size == 1 ? actions.first : 'update'
    end

    def audited_changes
      {}
    end
  end

  def grouper_audits(audits)
    audits.to_a.chunk_while { |a, b| groupables?(a, b) }
          .map { |lot| lot.size > 1 ? GroupeLiaisons.new(lot) : lot.first }
  end

  def audit_field_label(key)
    {
      'discarded_at' => 'Statut du compte',
      'locked_at' => 'Verrouillage',
      'du' => 'Début',
      'au' => 'Fin',
      'motif' => 'Motif',
      'apres_midi' => 'Après-midi',
      'matin' => 'Matin',
      'journee' => 'Journée',
      'invitation_created_at' => 'Invité le',
      'invitation_sent_at' => 'Email envoyé',
      'email' => 'Email',
      'nom' => 'Nom',
      'prenom' => 'Prénom',
      'role' => 'Rôle',
      'telephone' => 'Téléphone',
      'memo' => 'Mémo',
      'warehouse_id' => 'Entrepôt',
      'adherent_id' => 'Adhérent',
      'workflow_state' => 'Statut',
      'tool_id' => 'Outil',
      'user_id' => 'Utilisateur',
      'état' => 'État',
      'date' => 'Date',
      'intervention_id' => 'Intervention',
      'description' => 'Description',
      'temps_total' => 'Temps total',
      'temps_de_pause' => 'Temps de pause',
      'commentaires' => 'Commentaires',
      'note' => 'Note / Évaluation',
      'avis' => 'Avis',
      'repeter' => "Répéter l'action",
      'debut_prevue' => 'Début prévu',
      'fin_prevue' => 'Fin prévue',
      'meteo' => 'Météo',
      'co2' => 'Calcul CO₂',
      'trajet' => 'Détails du trajet',
      'service_id' => 'Service',
      'agent_id' => 'Agent',
      'organisation_id' => 'Organisation',
      'commande_id' => 'Commande',
      'cotation_id' => 'Devis',
      'facture_id' => 'Facture',
      'prestation_id' => 'Prestation',
      'invited_by_id' => 'Invité par',
      'ref' => 'Référence',
      'name' => 'Nom',
      'address' => 'Adresse',
      'latitude' => 'Latitude',
      'longitude' => 'Longitude',
      'private' => 'Page privée',
      'qté' => 'Quantité',
      'prix_ht' => 'Prix HT',
      'total_ht' => 'Total HT'
    }.fetch(key, key.humanize)
  end

  def audit_badge(audit)
    label, color_classes = badge_config(audit)
    content_tag(:span, class: "flex items-center justify-center gap-1.5 w-36 py-1 rounded-md text-xs font-medium #{color_classes}") do
      badge_icon(audit).to_s.html_safe + label
    end
  end

  def absence_period_badge(audit)
    du = audit.audited_changes['du']
    au = audit.audited_changes['au']
    content_tag(
      :span,
      "#{du} → #{au}",
      class: 'inline-flex items-center text-xs bg-slate-50/60 rounded-lg border border-slate-300 transition-colors duration-150 text-slate-600 px-2 py-1 font-mono group-hover:bg-white'
    )
  end

  def invitation_changes_summary(audit)
    relevant = audit.audited_changes.slice('invitation_created_at', 'invitation_sent_at')
    if relevant.blank?
      message = invitation_acceptée?(audit) ? "Invitation acceptée par l'utilisateur" : "Lien d'accès renvoyé"
      return content_tag(:span, message, class: 'text-xs text-slate-500 italic')
    end

    render_changes_list(humanize_changes(relevant, 'User'))
  end

  def audit_changes_list(audit, _current_user)
    changements = humanize_changes(audit.audited_changes, audit.auditable_type)
    changements.unshift(label: libellé_commentaire(audit), to: audit.comment) if audit.comment.present?
    return render_changes_list(changements) if changements.any?

    if audit.auditable_type == 'User'
      # Priorité : Contrôle de désactivation/réhabilitation par suppression logique
      if audit.audited_changes.key?('discarded_at')
        if audit.audited_changes['discarded_at']&.last.present?
          return content_tag(:span, 'Désactivation du compte par un administrateur', class: 'text-red-600 font-medium text-xs')
        else
          return content_tag(:span, 'Réhabilitation du compte par un administrateur', class: 'text-emerald-600 font-medium text-xs')
        end
      end

      # 1. Cas d'authentification réelle
      if (audit.audited_changes.keys & %w[sign_in_count current_sign_in_at]).any?
        return content_tag(:span, "Connexion à l'application", class: 'text-slate-600 font-medium text-xs')

      # 2. Cas de déconnexion réelle
      elsif audit.audited_changes.key?('remember_created_at') && audit.audited_changes['remember_created_at']&.last.nil?
        return content_tag(:span, "Déconnexion de l'application", class: 'text-slate-600 font-medium text-xs')

      elsif audit.audited_changes.key?('remember_created_at') && audit.audited_changes['remember_created_at']&.first.nil?
        return content_tag(:span, 'Maintien de la connexion (Cookie)', class: 'text-slate-600 font-medium text-xs')

      elsif audit.audited_changes.key?('warehouse_id')
        return content_tag(:span, "Mise à jour de l'affectation logistique (Entrepôt)", class: 'text-slate-600 font-medium text-xs')
      end
    end

    content_tag(:span, '—', class: 'text-slate-400')
  end

  # Les seuls commentaires d'audit du projet décrivent une pièce jointe ; un
  # commentaire d'une autre nature resterait annoncé honnêtement.
  def libellé_commentaire(audit)
    audit.comment.to_s.match?(/photo|document|fichier|pièce jointe/i) ? 'Pièce jointe' : 'Commentaire'
  end

  def humanize_changes(changes, auditable_type = nil)
    changes.filter_map do |key, value|
      next if FILTERED_FIELDS.include?(key)

      old_val, new_val = value.is_a?(Array) ? value : [nil, value]

      # Force le format lisible avant de vérifier s'ils sont vides
      formatted_old = format_audit_value(key, old_val, auditable_type)
      formatted_new = format_audit_value(key, new_val, auditable_type)

      # FILTRE STRICT : Si le champ n'a rien changé de réel ou est vide/tiret, il est totalement ignoré
      next if formatted_old == formatted_new
      next if (formatted_old.blank? || formatted_old == '—') && (formatted_new.blank? || formatted_new == '—')

      { label: audit_field_label(key), from: formatted_old, to: formatted_new }
    end
  end

  def format_audit_value(key, value, auditable_type = nil)
    case key
    when 'discarded_at'
      return (value.present? && value != '—') ? 'Désactivé' : 'Réactivé'

    when 'locked_at'
      return (value.present? && value != '—') ? 'Verrouillé' : 'Ouvert'
    end

    # 2. Règle générale pour le reste des champs (si nil, affiche un tiret)
    return '—' if value.nil? || value.to_s.strip.empty? || value.to_s == '—'
    return value.to_s == 'true' ? 'Oui' : 'Non' if [true, false].include?(value) || %w[true false].include?(value.to_s)

    # Détection générique des dates/heures — indépendante du nom de la clé,
    # évite les bugs d'accents (ex: "prévue" vs "prevue")
    if value.respond_to?(:strftime)
      return value.is_a?(Date) && !value.is_a?(DateTime) ? l(value, format: '%d/%m/%Y') : l(value, format: '%d/%m/%Y à %H:%M')
    elsif value.to_s.match?(/\A\d{4}-\d{2}-\d{2}([ T]\d{2}:\d{2})?/)
      begin
        if value.to_s.length > 10
          parsed = Time.zone.parse(value.to_s)
          return parsed ? l(parsed, format: '%d/%m/%Y à %H:%M') : value.to_s
        else
          parsed = Date.parse(value.to_s)
          return parsed ? l(parsed, format: '%d/%m/%Y') : value.to_s
        end
      rescue StandardError
        return value.to_s.sub(/\s?\+\d{4}\z/, '')
      end
    end

    libellé_enum = enum_value_label(key, value, auditable_type)
    return libellé_enum if libellé_enum

    case key
    when 'apres_midi', 'matin', 'journee'
      value.to_s.match?(/true|1/) ? 'Oui' : 'Non'

    when 'warehouse_id'
      warehouse_label(value)

    when 'adherent_id'
      User.with_discarded.find_by(id: value)&.email || nom_dans_audits('User', value, %w[email nom]) || "Utilisateur ##{value}"

    when 'tool_id'
      Tool.find_by(id: value)&.name || nom_dans_audits('Tool', value, %w[name]) || "Outil ##{value}"

    when 'user_id', 'agent_id', 'invited_by_id'
      utilisateur_label(value)

    when 'service_id'
      Service.find_by(id: value)&.nom || nom_dans_audits('Service', value, %w[nom]) || "Service ##{value}"

    when 'organisation_id'
      Organisation.find_by(id: value)&.nom || nom_dans_audits('Organisation', value, %w[nom]) || "Organisation ##{value}"

    when 'intervention_id'
      "n°#{value}"

    when 'commande_id'
      Commande.find_by(id: value)&.ref || nom_dans_audits('Commande', value, %w[ref]) || "Commande ##{value}"

    when 'cotation_id'
      Cotation.find_by(id: value)&.ref || nom_dans_audits('Cotation', value, %w[ref]) || "Devis ##{value}"

    when 'facture_id'
      Facture.find_by(id: value)&.ref || nom_dans_audits('Facture', value, %w[ref]) || "Facture ##{value}"

    when 'prestation_id'
      Prestation.find_by(id: value)&.libellé || nom_dans_audits('Prestation', value, %w[libellé code]) || "Prestation ##{value}"

    else
      value.to_s
    end
  end

  # Un compte désactivé (`discard`) sort du default_scope : sans `with_discarded`,
  # l'historique n'afficherait plus que son identifiant.
  def utilisateur_label(id)
    utilisateur = User.with_discarded.find_by(id: id)
    return nom_dans_audits('User', id, %w[nom email]) || "Utilisateur ##{id}" if utilisateur.nil?

    utilisateur.nom_prénom.strip.presence || utilisateur.email
  end

  # Les enums sont stockés en base sous forme d'entier : sans cette traduction,
  # l'historique affiche « État : 1 ».
  def enum_value_label(key, value, auditable_type = nil)
    return nil unless value.to_s.match?(/\A\d+\z/)

    modèle = (auditable_type.presence || MODELES_ENUM[key]).to_s.safe_constantize
    return nil unless modèle.respond_to?(:defined_enums)

    nom = modèle.defined_enums[key]&.key(value.to_i)
    return nil if nom.blank?

    LIBELLES_ENUM.fetch(nom, nom.tr('_', ' ').humanize)
  end

  def warehouse_label(id)
    Warehouse.find_by(id: id)&.name || nom_dans_audits('Warehouse', id, %w[name]) || id.to_s
  end

  # Un enregistrement réellement supprimé ne se retrouve que dans sa propre
  # trace d'audit : sans ça l'historique n'affiche plus qu'un identifiant.
  def nom_dans_audits(type, id, clés)
    return nil if id.blank?

    audit = Audited::Audit
            .where(auditable_type: type, auditable_id: id)
            .order(version: :desc)
            .detect { |a| clés.any? { |clé| a.audited_changes.key?(clé) } }
    return nil unless audit

    clés.filter_map { |clé| liaison_value_brute(audit.audited_changes[clé]) }.first
  end

  def liaison_value_brute(valeur)
    (valeur.is_a?(Array) ? valeur.compact.last : valeur).presence
  end

  def render_changes_list(items)
    return content_tag(:span, '—', class: 'text-slate-400') if items.blank?

    content_tag(:ul, class: 'space-y-1.5') do
      items.map do |item|
        content_tag(:li, class: 'flex flex-wrap items-center gap-1.5 text-xs') do
          label = content_tag(:span, "#{item[:label]} :", class: 'text-slate-400 font-medium shrink-0')

          body = if item[:from].present? && item[:from] != '—'
                   content_tag(:div, class: 'inline-flex items-center gap-1') do
                     content_tag(:span, item[:from], class: 'line-through text-slate-400') +
                       embedded_svg('icons/arrow_forward.svg', class: 'w-3 h-3 fill-current text-neutral shrink-0') +
                       content_tag(:span, item[:to], class: 'text-slate-700 font-bold')
                   end
                 else
                   content_tag(:span, item[:to], class: 'text-slate-700 font-bold')
                 end

          label + body
        end
      end.join.html_safe
    end
  end

  # `cible` : les pages qui affichent déjà l'enregistrement concerné (le show
  # d'une intervention) n'ont pas besoin qu'on le nomme à chaque ligne.
  def audit_details(audit, current_user, cible: true)
    return absence_period_badge(audit) if audit.auditable_type == 'Absence' && audit.action == 'destroy'

    audit_changes_block(audit, current_user, cible: cible)
  end

  def audit_changes_block(audit, current_user, cible: true)
    contenu =
      if audit.is_a?(GroupeLiaisons)
        liaisons_list(audit.audits, cible: cible)
      elsif LIAISONS.include?(audit.auditable_type)
        liaisons_list([audit], cible: cible)
      elsif audit.auditable_type == 'User' && invitation_audit?(audit)
        invitation_changes_summary(audit)
      else
        audit_changes_list(audit, current_user)
      end

    content_tag(:div, contenu, class: 'bg-slate-50/60 rounded-lg p-2 border border-slate-300 group-hover:bg-white transition-colors duration-150')
  end

  private

  def groupables?(premier, second)
    LIAISONS.include?(premier.auditable_type) &&
      premier.auditable_type == second.auditable_type &&
      premier.request_uuid.present? && premier.request_uuid == second.request_uuid &&
      premier.associated_type == second.associated_type &&
      premier.associated_id == second.associated_id
  end

  def liaisons_list(audits, cible: true)
    phrases = audits.filter_map { |audit| liaison_phrase(audit, cible: cible) }
    return content_tag(:span, '—', class: 'text-slate-400') if phrases.empty?

    content_tag(:ul, class: 'space-y-1.5') do
      safe_join(phrases.map do |sujet, complément|
        content_tag(:li, class: 'flex flex-wrap items-center gap-1.5 text-xs') do
          content_tag(:span, sujet, class: 'text-slate-700 font-bold') +
            content_tag(:span, complément, class: 'text-slate-500')
        end
      end)
    end
  end

  def liaison_phrase(audit, cible: true)
    changes = audit.audited_changes
    ajout = audit.action != 'destroy'
    intervention = cible ? " #{liaison_value('intervention_id', changes)}" : ''

    case audit.auditable_type
    when 'AgentIntervention'
      [liaison_value('agent_id', changes), "#{ajout ? 'ajouté à' : 'retiré de'} l'intervention#{intervention}"]
    when 'ToolIntervention'
      [liaison_value('tool_id', changes), "#{ajout ? 'ajouté à' : 'retiré de'} l'intervention#{intervention}"]
    when 'UserService'
      [liaison_value('user_id', changes), "#{ajout ? 'rattaché au' : 'retiré du'} service #{liaison_value('service_id', changes)}"]
    end
  end

  def liaison_value(clé, changes)
    valeur = changes[clé]
    format_audit_value(clé, valeur.is_a?(Array) ? valeur.compact.last : valeur)
  end

  def liaison_badge(audit)
    singulier, pluriel = NOMS_LIAISONS[audit.auditable_type]
    groupe = audit.is_a?(GroupeLiaisons)
    actions = groupe ? audit.actions : [audit.action]

    case actions
    when ['create']
      [groupe ? "#{pluriel} ajoutés" : "#{singulier} ajouté", 'bg-emerald-50 text-emerald-700 border border-emerald-200']
    when ['destroy']
      [groupe ? "#{pluriel} retirés" : "#{singulier} retiré", 'bg-red-50 text-red-600 border border-red-200']
    else
      ["#{pluriel} modifiés", 'bg-amber-50 text-amber-700 border border-amber-200']
    end
  end

  def invitation_audit?(audit)
    audit.action == 'update' && audit.audited_changes.key?('invitation_token')
  end

  def invitation_acceptée?(audit)
    audit.audited_changes['invitation_accepted_at']&.last.present?
  end

  def première_invitation?(audit)
    audit.audited_changes.key?('invitation_created_at') && audit.audited_changes['invitation_created_at']&.first.nil?
  end

  def invitation_badge(audit)
    if invitation_acceptée?(audit)
      ['Invitation acceptée', 'bg-emerald-50 text-emerald-700 border border-emerald-200']
    elsif première_invitation?(audit)
      ['Invitation envoyée', 'bg-blue-50 text-blue-700 border border-blue-200']
    else
      ['Invitation relancée', 'bg-blue-50 text-blue-700 border border-blue-200']
    end
  end

  def badge_icon(audit)
    icon_name = case audit.auditable_type
                when 'Absence'
                  case audit.action
                  when 'create'  then 'add'
                  when 'update'  then 'edit'
                  when 'destroy' then 'delete'
                  end
                when 'User'
                  # 1. Priorité absolue : Contrôle de désactivation / réhabilitation
                  if audit.action == 'update' && audit.audited_changes.key?('discarded_at')
                    if audit.audited_changes['discarded_at']&.last.present?
                      'no_accounts'
                    else
                      'account_circle'
                    end

                  # 2. Invitations Devise
                  elsif invitation_audit?(audit)
                    'mail'

                  # 3. Connexion légitime
                  elsif audit.action == 'update' && (audit.audited_changes.keys & %w[current_sign_in_at sign_in_count]).any?
                    'login'

                  # 4. Déconnexion légitime
                  elsif audit.action == 'update' && audit.audited_changes.key?('remember_created_at') && audit.audited_changes['remember_created_at']&.last.nil?
                    'logout'

                  # 5. Persistance du cookie
                  elsif audit.action == 'update' && audit.audited_changes.keys == ['remember_created_at'] && audit.audited_changes['remember_created_at']&.first.nil?
                    'key'

                  # 6. Toute autre modification de profil
                  else
                    case audit.action
                    when 'create'  then 'add'
                    when 'destroy' then 'delete'
                    else                'edit'
                    end
                  end
                when *LIAISONS
                  case audit.action
                  when 'create'  then 'add'
                  when 'destroy' then 'delete'
                  else                'edit'
                  end
                else
                  case audit.action
                  when 'create'  then 'add'
                  when 'update'  then 'edit'
                  when 'destroy' then 'delete'
                  end
                end

    return '' unless icon_name

    embedded_svg("icons/#{icon_name}.svg", class: 'w-3.5 h-3.5 inline-block fill-current text-current')
  end

  def badge_config(audit)
    return liaison_badge(audit) if audit.is_a?(GroupeLiaisons) || LIAISONS.include?(audit.auditable_type)

    case audit.auditable_type
    when 'Absence'
      case audit.action
      when 'create'  then ['Absence ajoutée',   'bg-emerald-50 text-emerald-700']
      when 'update'  then ['Absence modifiée',  'bg-amber-50 text-amber-700']
      when 'destroy' then ['Absence supprimée', 'bg-red-50 text-red-600']
      else                ['Absence',           'bg-slate-100 text-slate-600']
      end
    when 'User'
      # 1. Cas de désactivation / suppression logique
      if audit.action == 'update' && audit.audited_changes.key?('discarded_at')
        if audit.audited_changes['discarded_at']&.last.present?
          ['Compte désactivé', 'bg-red-50 text-red-700 border border-red-200']
        else
          ['Compte réactivé', 'bg-emerald-50 text-emerald-700 border border-emerald-200']
        end

      # 2. Cas alternatif si vous utilisez 'locked_at' de Devise
      elsif audit.action == 'update' && audit.audited_changes.key?('locked_at')
        if audit.audited_changes['locked_at']&.last.present?
          ['Compte bloqué', 'bg-red-50 text-red-700 border border-red-200']
        else
          ['Compte débloqué', 'bg-emerald-50 text-emerald-700 border border-emerald-200']
        end

      # 3. Connexion légitime
      elsif audit.action == 'update' && (audit.audited_changes.keys & %w[current_sign_in_at sign_in_count]).any?
        ['Connexion', 'bg-indigo-50 text-indigo-700 border border-indigo-200']

      # 4. Déconnexion légitime (Seulement si l'état de l'utilisateur n'a pas changé en même temps)
      elsif audit.action == 'update' && audit.audited_changes.key?('remember_created_at') && audit.audited_changes['remember_created_at']&.last.nil?
        ['Déconnexion', 'bg-slate-100 text-slate-600 border border-slate-200']

      # 5. Copie / persistance technique du cookie de session
      elsif audit.action == 'update' && audit.audited_changes.keys == ['remember_created_at'] && audit.audited_changes['remember_created_at']&.first.nil?
        ['Session', 'bg-slate-50 text-slate-400 border border-slate-200']

      # 6. Invitations Devise
      elsif invitation_audit?(audit)
        invitation_badge(audit)

      # 7. Vrai changement d'entrepôt / logistique
      elsif audit.action == 'update' && audit.audited_changes.key?('warehouse_id')
        ['Logistique', 'bg-orange-50 text-orange-700 border border-orange-200']

      else
        case audit.action
        when 'create'  then ['Compte créé',     'bg-emerald-50 text-emerald-700 border border-emerald-200']
        when 'update'  then ['Profil modifié',  'bg-amber-50 text-amber-700 border border-amber-200']
        when 'destroy' then ['Compte supprimé', 'bg-red-50 text-red-600 border border-red-200']
        else                ['Utilisateur',     'bg-slate-100 text-slate-600 border border-slate-200']
        end
      end
    else
      case audit.action
      when 'create'  then ['Création', 'bg-emerald-50 text-emerald-700 border border-emerald-200']
      when 'update'  then ['Modification', 'bg-amber-50 text-amber-700 border border-amber-200']
      when 'destroy' then ['Suppression', 'bg-red-50 text-red-600 border border-red-200']
      else                [audit.action.humanize, 'bg-slate-100 text-slate-500 border border-slate-200']
      end
    end
  end
end