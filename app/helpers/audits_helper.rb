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
    consumed_timestep
    otp_required_for_login
    uid
    provider
    slug
    updated_at
    id
    template_slug
    tag_list
  ].freeze

  def field_label(key)
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
      'workflow_state' => 'Statut',
      'adherent_id' => 'Adhérent',
      'description' => 'Description',
      'temps_total' => 'Temps total',
      'temps_de_pause' => 'Temps de pause',
      'commentaires' => 'Commentaires',
      'note' => 'Note / Évaluation',
      'avis' => 'Avis',
      'repeter' => 'Répéter l\'action',
      'debut_prevue' => 'Début prévu',
      'fin_prevue' => 'Fin prévue',
      'meteo' => 'Météo',
      'co2' => 'Calcul CO₂',
      'trajet' => 'Détails du trajet',
      'service_id' => 'Service'
    }.fetch(key, key.humanize)
  end

  def audit_badge(audit)
    label, color_classes = badge_config(audit)
    content_tag(:span,
               class: "flex items-center justify-center gap-1.5 w-36 py-1 rounded-md text-xs font-medium #{color_classes}") do badge_icon(audit).to_s.html_safe + label
    end
  end

  def absence_period_badge(audit)
    du = audit.audited_changes['du']
    au = audit.audited_changes['au']
    content_tag(:span, "#{du} → #{au}",
                class: 'inline-flex items-center text-xs bg-slate-50/60 rounded-lg border border-slate-300  transition-colors duration-150 border text-slate-600 px-2 py-1 font-mono group-hover:bg-white ')
  end

  def invitation_changes_summary(audit)
    relevant = audit.audited_changes.slice('invitation_created_at', 'invitation_sent_at')
    return content_tag(:span, "Lien d'accès renvoyé", class: 'text-xs text-slate-500 italic') if relevant.blank?

    render_changes_list(humanize_changes(relevant))
  end

  def audit_changes_list(audit, _current_user)
    if audit.audited_changes.blank? || humanize_changes(audit.audited_changes).blank?
      
      if audit.auditable_type == 'User'
        # Prioridad: Control de desactivación/reactivación por descarte lógico
        if audit.audited_changes.key?('discarded_at')
          if audit.audited_changes['discarded_at']&.last.present?
            return content_tag(:span, "Désactivation du compte par un administrateur", class: 'text-red-600 font-medium text-xs')
          else
            return content_tag(:span, "Réhabilitation du compte par un administrateur", class: 'text-emerald-600 font-medium text-xs')
          end
        end

        # 1. Cas d'authentification réelle
        if (audit.audited_changes.keys & %w[sign_in_count current_sign_in_at]).any?
          return content_tag(:span, "Connexion à l'application", class: 'text-slate-600 font-medium text-xs')

        # 2. Cas de déconnexion réelle
        elsif audit.audited_changes['remember_created_at']&.last.nil?
          return content_tag(:span, "Déconnexion de l'application", class: 'text-slate-600 font-medium text-xs')

        elsif audit.audited_changes['remember_created_at'] &.first.nil?
          return content_tag(:span, "Maintien de la connexion (Cookie)", class: 'text-slate-600 font-medium text-xs')
        
        elsif audit.audited_changes.key?('warehouse_id')
          return content_tag(:span, "Mise à jour de l'affectation logistique (Entrepôt)", class: 'text-slate-600 font-medium text-xs')  
        end
      end

      return content_tag(:span, '—', class: 'text-slate-400')
    end

    render_changes_list(humanize_changes(audit.audited_changes))
  end

  def humanize_changes(changes)
    changes.filter_map do |key, value|
      next if FILTERED_FIELDS.include?(key)

      old_val, new_val = value.is_a?(Array) ? value : [nil, value]
      
      # Forzar formato legible antes de validar si están vacíos
      formatted_old = format_audit_value(key, old_val)
      formatted_new = format_audit_value(key, new_val)

      # FILTRO ESTRICTO: Si el campo no cambió nada real o está vacío/guión, se ignora por completo
      next if formatted_old == formatted_new
      next if (formatted_old.blank? || formatted_old == '—') && (formatted_new.blank? || formatted_new == '—')

      { label: field_label(key), from: formatted_old, to: formatted_new }
    end
  end

  def format_audit_value(key, value)
    case key
    when 'discarded_at'
      return (value.present? && value != '—') ? 'Désactivé' : 'Réactivé'
    when 'locked_at'
      return (value.present? && value != '—') ? 'Verrouillé' : 'Ouvert'
    end

    # 2. Regla general para el resto de los campos (si es nil, muestra un guión)
    return '—' if value.nil? || value.to_s.strip.empty? || value.to_s == '—'

    case key
    when 'apres_midi', 'matin', 'journee'
      value.to_s.match?(/true|1/) ? 'Oui' : 'Non'
    when 'motif'
      { '0' => 'Congé annuel', '1' => 'Maladie', '2' => 'RTT' }.fetch(value.to_s, value)
    when 'warehouse_id'
      warehouse_label(value)
    when 'adherent_id'
      User.find_by(id: value)&.email || "Utilisateur ##{value}"
    when /at$|_prevue$/
      if value.respond_to?(:strftime)
        l(value, format: :short)
      else
        begin
          parsed = Time.zone.parse(value.to_s)
          parsed ? l(parsed, format: :short) : value.to_s
        rescue
          value.to_s.sub(/ \+\d+/, '')
        end
      end
    else
      value.to_s
    end
  end

  def warehouse_label(id)
    Warehouse.find_by(id: id)&.name || deleted_warehouse_name(id) || id.to_s
  end

  def deleted_warehouse_name(id)
    audit = Audited::Audit
            .where(auditable_type: 'Warehouse', auditable_id: id)
            .order(version: :desc)
            .detect { |a| a.audited_changes.key?('name') }
    return nil unless audit

    raw = audit.audited_changes['name']
    name = raw.is_a?(Array) ? raw.compact.last : raw
    name.presence
  end

  def render_changes_list(items)
    return content_tag(:span, '—', class: 'text-slate-400') if items.blank?

    content_tag(:ul, class: 'space-y-1.5') do
      items.map do |item|
        content_tag(:li, class: 'flex flex-wrap items-baseline gap-1 text-xs') do
          label = content_tag(:span, "#{item[:label]} :", class: 'text-slate-400 font-medium shrink-0')
          body  = if item[:from].present? && item[:from] != '—'
                    content_tag(:span, item[:from], class: 'line-through text-slate-400') +
                      content_tag(:span, ' → ', class: 'text-slate-300') +
                      content_tag(:span, item[:to], class: 'text-slate-700 font-bold')
                  else
                    content_tag(:span, item[:to], class: 'text-slate-700 font-bold')
                  end
          label + ' '.html_safe + body
        end
      end.join.html_safe
    end
  end

  private

  def badge_icon(audit)
    icon_name = case audit.auditable_type
                when 'Absence'
                  case audit.action
                  when 'create'  then 'add'
                  when 'update'  then 'edit'
                  when 'destroy' then 'delete'
                  end
                when 'User'
                  # 1. Prioridad absoluta: Control de desactivación / reactivación
                  if audit.action == 'update' && audit.audited_changes.key?('discarded_at')
                    if audit.audited_changes['discarded_at']&.last.present?
                      'no_accounts' 
                    else
                      'account_circle'
                    end

                  # 2. Invitaciones de Devise
                  elsif audit.audited_changes.key?('invitation_token')
                    'mail'

                  # 3. Login legítimo
                  elsif audit.action == 'update' && (audit.audited_changes.keys & %w[current_sign_in_at sign_in_count]).any?
                    'login'

                  # 4. Logout legítimo
                  elsif audit.action == 'update' && audit.audited_changes.key?('remember_created_at') && audit.audited_changes['remember_created_at']&.last.nil?
                    'logout'

                  # 5. Persistance du cookie
                  elsif audit.action == 'update' && audit.audited_changes.keys == ['remember_created_at'] && audit.audited_changes['remember_created_at']&.first.nil?
                    'key'

                  # 6. Toute autre modification de profil
                  else
                    'edit'
                  end
                when 'UserService'
                  audit.action == 'create' ? 'add' : 'delete'
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

      # 3. Login legítimo
      elsif audit.action == 'update' && (audit.audited_changes.keys & %w[current_sign_in_at sign_in_count]).any?
        ['Connexion', 'bg-indigo-50 text-indigo-700 border border-indigo-200']
        
      # 4. Logout legítimo (Solo si NO se modificó al mismo tiempo el estado del usuario)
      elsif audit.action == 'update' && audit.audited_changes.key?('remember_created_at') && audit.audited_changes['remember_created_at']&.last.nil?
        ['Déconnexion', 'bg-slate-100 text-slate-600 border border-slate-200']
        
      # 5. Copie / persistance technique du cookie de session
      elsif audit.action == 'update' && audit.audited_changes.keys == ['remember_created_at'] && audit.audited_changes['remember_created_at']&.first.nil?
        ['Session', 'bg-slate-50 text-slate-400 border border-slate-200']

      # 6. Invitations de Devise
      elsif audit.audited_changes.key?('invitation_token')
        ['Invitation relancée', 'bg-blue-50 text-blue-700 border border-bleu-200']
        
      # 7. Vrai changement d'entrepôt / logistique
      elsif audit.audited_changes.key?('warehouse_id')
        ['Logistique', 'bg-orange-50 text-orange-700 border border-orange-200']
        
      else
        case audit.action
        when 'create'  then ['Compte créé',    'bg-emerald-50 text-emerald-700 border border-emerald-200']
        when 'update'  then ['Profil modifié', 'bg-amber-50 text-amber-700 border border-amber-200']
        else                ['Utilisateur',    'bg-slate-100 text-slate-600 border border-slate-200']
        end
      end
    when 'UserService'
      case audit.action
      when 'create'  then ['Service associé', 'bg-emerald-50 text-emerald-700 border border-emerald-200']
      when 'destroy' then ['Service retiré',  'bg-red-50 text-red-600 border border-red-200']
      else                ['Service',         'bg-slate-100 text-slate-600 border border-slate-200']
      end
    else
      case audit.action
      when 'create'  then ["Création", 'bg-emerald-50 text-emerald-700 border border-emerald-200']
      when 'update'  then ["Modification", 'bg-amber-50 text-amber-700 border border-amber-200']
      when 'destroy' then ["Suppression", 'bg-red-50 text-red-600 border border-red-200']
      else                [audit.action.humanize, 'bg-slate-100 text-slate-500 border border-slate-200']
      end
    end
  end
end
