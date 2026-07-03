# frozen_string_literal: true

require 'test_helper'

class DocumentTest < ActiveSupport::TestCase
  setup do
    @tool = Tool.create(name: 'Débroussailleuse', organisation: organisations(:mairie_paris))
  end

  test 'un document peut être créé avec succès' do
    document = Document.new(tool: @tool)
    assert document.valid?
  end
end