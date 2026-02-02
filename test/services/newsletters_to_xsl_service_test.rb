require "test_helper"

class NewslettersToXlsServiceTest < ActionDispatch::IntegrationTest
  setup do
    @newsletters = newsletters

    @service = NewslettersToXls.new(@newsletters)
  end

  test "contient les bonnes newsletters" do
    assert_equal @service.instance_variable_get(:@newsletters), @newsletters
  end

  test "retourne un fichier xsl" do
    result = @service.call
    assert result.is_a?(String)
    assert_not_nil result
    assert_not result.empty?
  end

  test "retourne un fichier xsl contenant aucune newsletters" do
    result = NewslettersToXls.new(Newsletter.where(id: nil)).call

    book = Spreadsheet.open(StringIO.new(result))
    sheet = book.worksheet(0)
    assert_equal 1, sheet.rows.count  # +1 pour la ligne d'en-tête
  end

  test "retourne un fichier xsl contenant des newsletters" do
    result = @service.call
    book = Spreadsheet.open(StringIO.new(result))
    sheet = book.worksheet(0)
    assert_equal @newsletters.count + 1, sheet.rows.count  # +1 pour la ligne d'en-tête
  end

end
