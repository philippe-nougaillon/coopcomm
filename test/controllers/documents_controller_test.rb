# frozen_string_literal: true

require 'test_helper'

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @document = documents(:carte_grise)
    sign_in users(:hidalgo)
  end

 
end