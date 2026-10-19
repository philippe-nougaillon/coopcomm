# frozen_string_literal: true

module PagesHelper
  DEMO_URL    = "https://calendar.app.google/a52LSSCoXsdwz7A2A"
  BUTTON_BASE = "px-8 py-3 rounded-full text-base font-semibold transition"
  TAB_FOCUS   = "focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#691E9A]"

  def export_type_label(export_type)
    case export_type
    when "dashboard_manager"
      "Dashboard (Manager)"
    when "dashboard_adherent"
      "Dashboard (Adhérent)"
    else
      export_type.humanize
    end
  end

  def coopcomm_logo
    tag.span(class: "font-extrabold whitespace-nowrap") do
      safe_join([
        tag.span("Co",   class: "text-[#47b5db]"),
        tag.span("op",   class: "text-[#691E9A]"),
        tag.span("Comm", class: "text-[#47b5db]"),
        tag.span(".",    class: "text-[#691E9A]")
      ])
    end
  end
end