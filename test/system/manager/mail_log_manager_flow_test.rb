# frozen_string_literal: true

require 'application_system_test_case'

class MailLogManagerFlowTest < ApplicationSystemTestCase
  setup do
    @manager = users(:hidalgo)
    login(@manager)
  end

  # test "Les filtres fonctionnent dans la liste des mail_logs" do
  # end
end
