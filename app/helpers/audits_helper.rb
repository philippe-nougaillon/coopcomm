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
    locked_at
    otp_secret
    consumed_timestep
    otp_required_for_login
    uid
    provider
    slug
    discarded_at
    updated_at
  ].freeze

  def audit_badge(audit)
    label, color_classes = badge_config(audit)
    content_tag(:span, class: "inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium #{color_classes}") do
      badge_icon(audit).to_s.html_safe + label
    end
  end

  def absence_period_badge(audit)
    du = audit.audited_changes["du"]
    au = audit.audited_changes["au"]
    content_tag(:span, "#{du} → #{au}",
      class: "inline-flex items-center gap-1 text-xs bg-slate-100 text-slate-600 px-2 py-1 rounded-md font-mono")
  end

  def invitation_changes_summary(audit)
    relevant = audit.audited_changes.slice("invitation_created_at", "invitation_sent_at")
    return content_tag(:span, "Lien d'accès renvoyé", class: "text-xs text-slate-500 italic") if relevant.blank?
    render_changes_list(humanize_changes(relevant))
  end

  def audit_changes_list(audit, _current_user)
    return content_tag(:span, "—", class: "text-slate-400") if audit.audited_changes.blank?
    render_changes_list(humanize_changes(audit.audited_changes))
  end

  private

  def badge_icon(audit)
    icon_name = case audit.auditable_type
    when "Absence"
      case audit.action
      when "create"  then "add"
      when "update"  then "edit"
      when "destroy" then "delete"
      end
    when "User"
      audit.audited_changes.key?("invitation_token") ? "mail" : "edit"
    when "UserService"
      audit.action == "create" ? "add" : "delete"
    end

    return "" unless icon_name

    embedded_svg("icons/#{icon_name}.svg", class: "w-3.5 h-3.5 inline-block fill-current text-current")
  end

  def badge_config(audit)
    case audit.auditable_type
    when "Absence"
      case audit.action
      when "create"  then ["Absence ajoutée",   "bg-emerald-50 text-emerald-700"]
      when "update"  then ["Absence modifiée",  "bg-amber-50 text-amber-700"]
      when "destroy" then ["Absence supprimée", "bg-red-50 text-red-600"]
      else                ["Absence",           "bg-slate-100 text-slate-600"]
      end
    when "User"
      if audit.audited_changes.key?("invitation_token")
        ["Invitation relancée", "bg-blue-50 text-blue-700"]
      else
        case audit.action
        when "create"  then ["Compte créé",    "bg-emerald-50 text-emerald-700"]
        when "update"  then ["Profil modifié", "bg-amber-50 text-amber-700"]
        else                ["Utilisateur",    "bg-slate-100 text-slate-600"]
        end
      end
    when "UserService"
      case audit.action
      when "create"  then ["Service associé", "bg-emerald-50 text-emerald-700"]
      when "destroy" then ["Service retiré",  "bg-red-50 text-red-600"]
      else                ["Service",         "bg-slate-100 text-slate-600"]
      end
    else
      ["#{audit.auditable_type} #{audit.action}", "bg-slate-100 text-slate-500"]
    end
  end

  def humanize_changes(changes)
    changes.filter_map do |key, value|
      next if FILTERED_FIELDS.include?(key)

      label = field_label(key)
      old_val, new_val = value.is_a?(Array) ? value : [nil, value]
      { label: label, from: format_audit_value(key, old_val), to: format_audit_value(key, new_val) }
    end
  end

  def field_label(key)
    {
      "du"                    => "Début",
      "au"                    => "Fin",
      "motif"                 => "Motif",
      "apres_midi"            => "Après-midi",
      "matin"                 => "Matin",
      "journee"               => "Journée",
      "invitation_created_at" => "Invité le",
      "invitation_sent_at"    => "Email envoyé",
      "email"                 => "Email",
      "nom"                   => "Nom",
      "prenom"                => "Prénom",
      "role"                  => "Rôle",
      "telephone"             => "Téléphone",
      "memo"                  => "Mémo",
    }.fetch(key, key.humanize)
  end

  def format_audit_value(key, value)
    return "—" if value.nil?

    case key
    when "apres_midi", "matin", "journee"
      value.in?(["true", true]) ? "Oui" : "Non"
    when "motif"
      { "0" => "Congé annuel", "1" => "Maladie", "2" => "RTT" }.fetch(value.to_s, value)
    when /at$/
      value.respond_to?(:strftime) ? l(value, format: :short) : value.to_s.sub(" +0200", "").sub(" +0100", "")
    else
      value.to_s
    end
  end

  def render_changes_list(items)
    return content_tag(:span, "—", class: "text-slate-400") if items.blank?

    content_tag(:ul, class: "space-y-1") do
      items.map do |item|
        content_tag(:li, class: "flex flex-wrap items-baseline gap-1 text-xs") do
          label = content_tag(:span, "#{item[:label]} :", class: "text-slate-400 shrink-0")
          body  = if item[:from].present? && item[:from] != "—"
            content_tag(:span, item[:from], class: "line-through text-slate-400") +
            content_tag(:span, " → ", class: "text-slate-300") +
            content_tag(:span, item[:to], class: "text-slate-700 font-medium")
          else
            content_tag(:span, item[:to], class: "text-slate-700 font-medium")
          end
          label + " ".html_safe + body
        end
      end.join.html_safe
    end
  end

end