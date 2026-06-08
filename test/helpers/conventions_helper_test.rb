require "test_helper"

class ConventionsHelperTest < ActionView::TestCase
  def convention(start_date, end_date)
    Convention.new(date_début: start_date, date_fin_prévue: end_date)
  end

  test "renvoie nil sans date de début" do
    assert_nil convention_progress(convention(nil, Date.new(2026, 12, 31)))
  end

  test "barre indéterminée quand pas de date de fin" do
    prog = convention_progress(convention(Date.new(2026, 1, 1), nil))
    assert prog[:indeterminate]
    assert_equal "En cours", prog[:label]
    assert_equal "progress-info", prog[:color]
    assert_nil prog[:percent]
  end

  test "convention à venir : 0 % et couleur info" do
    prog = convention_progress(convention(Date.new(2026, 7, 1), Date.new(2026, 12, 31)),
                               today: Date.new(2026, 6, 1))
    assert_equal 0, prog[:percent]
    assert_equal "À venir", prog[:label]
    assert_equal "progress-info", prog[:color]
  end

  test "convention à mi-parcours : ~50 % et couleur success" do
    prog = convention_progress(convention(Date.new(2026, 1, 1), Date.new(2026, 12, 31)),
                               today: Date.new(2026, 7, 1))
    assert_in_delta 50, prog[:percent], 1
    assert_equal "progress-success", prog[:color]
    refute prog[:indeterminate]
  end

  test "convention proche de l'échéance : couleur warning au-delà de 80 %" do
    prog = convention_progress(convention(Date.new(2026, 1, 1), Date.new(2026, 12, 31)),
                               today: Date.new(2026, 12, 1))
    assert_operator prog[:percent], :>=, 80
    assert_equal "progress-warning", prog[:color]
  end

  test "convention expirée : 100 % et couleur error" do
    prog = convention_progress(convention(Date.new(2026, 1, 1), Date.new(2026, 6, 30)),
                               today: Date.new(2026, 8, 1))
    assert_equal 100, prog[:percent]
    assert_equal "Expirée", prog[:label]
    assert_equal "progress-error", prog[:color]
  end

  test "début et fin le même jour ne lève pas de division par zéro" do
    same = Date.new(2026, 6, 8)
    assert_equal 100, convention_progress(convention(same, same), today: same)[:percent]
    assert_equal 0,   convention_progress(convention(same, same), today: same - 1)[:percent]
  end
end
