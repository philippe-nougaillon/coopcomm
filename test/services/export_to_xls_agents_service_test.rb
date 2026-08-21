# frozen_string_literal: true

require 'test_helper'

class ExportToXlsAgentsServiceTest < ActionDispatch::IntegrationTest
  setup do
    # Récupère tous les agents pour les tests
    @agents = User.agent
    @service = ExportToXls::Agents.new(@agents)
  end

  test 'contient les bons agents' do
    assert_equal @service.instance_variable_get(:@agents), @agents
  end

  test 'retourne un fichier xsl' do
    result = @service.call
    assert result.is_a?(String)
    assert_not_nil result
    assert_not result.empty?
  end

  test 'retourne un fichier xsl contenant aucun agents' do
    result = ExportToXls::Agents.call(User.none)

    book = Spreadsheet.open(StringIO.new(result))
    sheet = book.worksheet(0)
    assert_equal 1, sheet.rows.count # +1 pour la ligne d'en-tête
  end

  test 'retourne un fichier xsl contenant des agents' do
    result = @service.call
    book = Spreadsheet.open(StringIO.new(result))
    sheet = book.worksheet(0)
    assert_equal @agents.count + 1, sheet.rows.count # +1 pour la ligne d'en-tête
  end
end
