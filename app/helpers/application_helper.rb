module ApplicationHelper
  include Pagy::Frontend

  def prettify(audit)
    pretty_changes = []

    audit.audited_changes.each do |c|
      key = c.first.humanize
      case key
      when 'User', 'Agent', 'Adherent', 'Agent binome'
        ids = audit.audited_changes["#{key == "Agent binome" ? key.humanize.downcase.tr(' ', '_') : key.downcase}_id"]
        if User.exists?(id: ids)
          
          case key
          when "Agent binome"
            key = "Agent 2"
          when"Agent"
            key = "Agent 1"
          when "Adherent"
            key = "Adhérent"
          when "User"
            key = "Équipe" if audit.auditable_type == "Intervention"
          end

          case ids.class.name
          when 'Integer'
            pretty_changes << "#{key} initialisé à '#{User.find(ids).nom_prénom}'"
          when 'Array'
            pretty_changes << "#{key} changé de '#{User.find_by(id: ids.first).try(:nom_prénom) || "#{ids.first} (Utilisateur supprimé)" if ids.first}' à '#{User.find_by(id: ids.last).try(:nom_prénom) || "#{ids.last} (Utilisateur supprimé)" if ids.last}'"
          end 
        else
          case ids.class.name
          when 'NilClass'
            pretty_changes << "#{key} initialisé à vide"
          when 'Array'
            pretty_changes << "#{key} changé de '#{ids.first}' à '#{ids.last}' (Utilisateurs supprimés)"
          when 'Integer'
            pretty_changes << "#{key} initialisé à '#{ids}' (Utilisateur supprimé)"
          end
        end
      when 'Workflow state'
        if audit.action == 'update'
          unless c.last.first.blank? && c.last.last.blank?    
            pretty_changes << "Statut modifié de '#{c.last.first.humanize}' à '#{c.last.last.humanize}'"
          end
        else 
          unless c.last.blank?
            pretty_changes << "Statut #{audit.action == 'create' ? 'initialisé à' : 'était'} '#{c.last.humanize}'"
          end
        end
      when 'Rôle'
        rôles = User.rôles.invert
        if audit.action == 'update'
          unless c.last.first.blank? && c.last.last.blank?    
            pretty_changes << "#{key} modifié de '#{rôles[c.last.first].humanize}' à '#{rôles[c.last.last].humanize}'"
          end
        else 
          unless c.last.blank?
            pretty_changes << "#{key} #{audit.action == 'create' ? 'initialisé à' : 'était'} '#{rôles[c.last].humanize}'"
          end
        end
      when 'Discarded at'
        if audit.action == 'update'
          pretty_changes << "Utilisateur #{c.last.first.nil? ? 'désactivé' : 'réactivé'}"
        end
      else
        
        if audit.action == 'update'
          unless c.last.first.blank? && c.last.last.blank?    
            pretty_changes << "#{key} modifié de '#{c.last.first}' à '#{c.last.last}'"
          end
        else 
          unless c.last.blank?
            pretty_changes << "#{key} #{audit.action == 'create' ? 'initialisé à' : 'était'} '#{c.last}'"
          end
        end
      end
    end
    pretty_changes
  end

  def audited_view_path(audit)
    return if audit.auditable_type.blank? || !["Intervention", "Tool", "User", "WikiPage"].include?(audit.auditable_type) || audit.auditable_id.blank?

    model = audit.auditable_type.constantize
    record = model.find_by(id: audit.auditable_id)

    record ? polymorphic_path(record) : nil
  end

  def sort_link(column, title = nil)
    title ||= (@model_class ? @model_class.human_attribute_name(column) : column.titleize)
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    icon = sort_direction == "asc" ? "keyboard_arrow_down" : "keyboard_arrow_up"
    icon = column == sort_column ? icon : nil
    link_title = sort_direction == "asc" ? "Tri croissant" : "Tri décroissant"

    link_to "<span>#{h title}</span><span class='material-symbols-outlined text-primary'>#{icon}</span>".html_safe, url_for(request.parameters.merge(column: column, direction: direction)), class: 'flex items-center', 'data-turbo': false
  end

end
