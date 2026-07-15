# frozen_string_literal: true

module PagesHelper


  #  pour éviter de faire des else dans le view dans dashboard
def export_type_label(export_type)
    case export_type
    when 'dashboard_manager'
      'Dashboard (Manager)'
    when 'dashboard_adherent'
      'Dashboard (Adhérent)'
    else
      export_type.humanize
    end
  end
end