# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  # Vrai lorsque l'application tourne sur l'instance de démonstration.
  # Piloté par la variable d'environnement APP_INSTANCE (= "demo" sur le serveur de démo).
  # Utilisé pour le badge « DÉMO » dans les navbars et le préfixe [DÉMO] du titre dans les layouts.
  def demo_instance?
    ENV['APP_INSTANCE'].to_s.strip.downcase == 'demo'
  end

  # Liste blanche des paramètres de filtre/tri réinjectables dans un url_for
  # (jamais params.permit! : un paramètre forgé — ex. host — se retrouverait
  # dans les liens générés).
  def intervention_filter_params
    params.permit(:service, :search, :workflow_state, :du, :au, :adherent_id, :equipe,
                  :archives, :vue, :column, :direction, :page,
                  tags: [], agent_ids: [], tool_ids: [])
  end


   # tab en parametres pour les diviser
   def safe_params
    params.permit(:search, :tab, user_id: [])
  end

  def prettify(audit, _current_user)
    pretty_changes = []

    audit.audited_changes.each do |c|
      raw_key = c.first
      key =
        case raw_key
        when 'workflow_state'
          'Statut'
        else
          raw_key.humanize
        end

      case key
      when 'Agent', 'Adherent', 'Agent binome'
        ids = audit.audited_changes["#{key == 'Agent binome' ? key.humanize.downcase.tr(' ', '_') : key.downcase}_id"]
        if User.exists?(id: ids)

          case key
          when 'Agent binome'
            key = 'Agent 2'
          when 'Agent'
            key = 'Agent 1'
          when 'Adherent'
            key = 'Adhérent'
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
          when 'Statut'
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
    return if audit.auditable_type.blank? || !%w[Intervention Tool User
                                                 WikiPage].include?(audit.auditable_type) || audit.auditable_id.blank?

    model = audit.auditable_type.constantize
    record = model.find_by(id: audit.auditable_id)

    record ? polymorphic_path(record) : nil
  end

  def sort_link(column, title = nil)
    title ||= (@model_class ? @model_class.human_attribute_name(column) : column.titleize)
    direction = column == sort_column && sort_direction == 'asc' ? 'desc' : 'asc'

    svg_icon = sort_direction == 'asc' ? 'keyboard_arrow_down.svg' : 'keyboard_arrow_up.svg'
    link_title = sort_direction == 'asc' ? 'Tri croissant' : 'Tri décroissant'

    icon_html = ''
    if column == sort_column
      icon_html = embedded_svg("icons/#{svg_icon}", class: 'w-4 h-4 fill-current text-primary shrink-0 ml-1')
    end

    link_to "<span>#{h title}</span>#{icon_html}".html_safe,
            url_for(request.parameters.merge(column: column, direction: direction)),
            class: 'flex items-center',
            title: link_title,
            'data-turbo': false
  end

  def message_time_format(time)
    return '' if time.blank?

    date = time.to_date
    today = Date.current

    if date == today
      time.strftime('%H:%M')
    elsif date >= (today - 6.days)
      I18n.l(time, format: '%A').capitalize
    else
      time.strftime('%d/%m/%Y')
    end
  end

  # 🌟 NUEVO HELPER: Inyecta el XML del archivo SVG permitiendo pasar clases dinámicas de Tailwind
  def embedded_svg(filename, options = {})
    # Prefer public assets when icons have been moved there
    file_path = Rails.root.join('public', filename)
    file_path = Rails.root.join('app', 'assets', 'images', filename) unless File.exist?(file_path)

    if File.exist?(file_path)
      file = File.read(file_path)
      doc = Nokogiri::HTML::DocumentFragment.parse(file)
      svg = doc.at_css('svg')

      # Si pasamos clases personalizadas en el helper, se las inyectamos al SVG en caliente
      svg['class'] = "#{svg['class']} #{options[:class]}" if options[:class].present?

      # Equivalent de l'attribut `title`/`alt` d'un <img> : <title> = tooltip natif au survol,
      # role/aria-label = nom accessible. Sans titre, le SVG est purement décoratif.
      if options[:title].present?
        svg['role'] = 'img'
        svg['aria-label'] = options[:title]
        title_node = Nokogiri::XML::Node.new('title', doc)
        title_node.content = options[:title]
        svg.prepend_child(title_node)
      else
        svg['aria-hidden'] = 'true'
      end

      doc.to_html.html_safe
    else
      # Fallback por si escribimos mal el nombre del archivo en desarrollo
      ''.html_safe
    end
  end
end


