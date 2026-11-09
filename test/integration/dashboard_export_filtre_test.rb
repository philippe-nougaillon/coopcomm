# frozen_string_literal: true

require 'test_helper'

class DashboardExportFiltreTest < ActionDispatch::IntegrationTest
  test "En tant qu'administrateur, je veux que l'export XLS du tableau de bord reprenne la période et le service filtrés" do
    sign_in users(:administrateur_paris)
    filtre = { du: '2023-01-01', au: '2023-02-28', service: [services(:technique).id.to_s] }

    get dashboard_url(filtre)

    assert_response :success
    assert_dom "a[href=?]", dashboard_path(filtre.merge(format: :xls)), text: /Exporter en XLS/

    get dashboard_url(filtre.merge(format: :xls))

    assert_response :success
    assert_equal 'application/xls', response.media_type
  end
end
