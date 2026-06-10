# frozen_string_literal: true

require 'application_system_test_case'

class AuditAgentFlowTest < ApplicationSystemTestCase
  setup do
    @agent = users(:bond)
    login(@agent)
  end

  test 'Ne peut pas visiter la liste des activités (audits)' do
    visit admin_audits_url
    assert_text "Vous n'êtes pas autorisé à effectuer cette action."
    assert_no_text 'Activité'
  end
end
