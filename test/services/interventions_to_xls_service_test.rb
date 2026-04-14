require "test_helper"

class InterventionsToXlsServiceTest < ActionDispatch::IntegrationTest
  setup do
    @template_adherent = users(:weil)
    @interventions = create_interventions

    @service = InterventionsToXls.new(@interventions)
  end

  test "le service contient les bonnes interventions" do
    assert_equal @service.instance_variable_get(:@interventions), @interventions
  end

  test "retourne un fichier xls" do
    result = @service.call
    assert result.is_a?(String)
    assert_not_nil result
    assert_not result.empty?
  end

  test "retourne un fichier xls contenant aucune interventions" do
    result = InterventionsToXls.new(Intervention.where(id: nil)).call

    book = Spreadsheet.open(StringIO.new(result))
    sheet = book.worksheet(0)
    assert_equal 1, sheet.rows.count  # +1 pour la ligne d'en-tête
  end

  test "retourne un fichier xls contenant des interventions" do
    result = @service.call
    book = Spreadsheet.open(StringIO.new(result))
    sheet = book.worksheet(0)
    assert_equal @interventions.count + 1, sheet.rows.count  # +1 pour la ligne d'en-tête
  end

  def create_interventions(count = 3)
    count.times do |i|
      Intervention.create!(
        description: "Test intervention #{i}",
        organisation: organisations(:mairie_paris),
        workflow_state: "created",
        début: Time.current - 2.hours,
        fin: Time.current,
        temps_de_pause: 0,
        temps_total: 2,
        slug: SecureRandom.uuid,
        adherent: @template_adherent,
        service: @template_adherent.services.first 
      )
    end
    Intervention.where("description LIKE ?", "Test intervention%")
  end
end
