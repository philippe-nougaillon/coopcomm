require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase

  # Largeur / Hauteur
  def self.taille_pc
    [1400, 1400]
  end

  def self.taille_tel
    [544, 900] # 544 est le minimum en largeur
  end

  driven_by :selenium, using: :chrome, screen_size: taille_tel
  #driven_by :selenium, using: :headless_chrome, screen_size: taille_tel



  def click_ajout_intervention_selon_taille_ecran
    id_boutton_ajout_intervention_pc = '[data-test-id="ajouter_intervention_pc"]'
    id_boutton_ajout_intervention_mobile = '[data-test-id="ajouter_intervention_mobile"]'

    # TODO: Ne trouve pas les méthodes des tailles
    taille_pc = self.taille_pc
    taille_tel = self.taille_tel

    if Capybara.current_session.current_window.size == taille_pc
      find(id_boutton_ajout_intervention_pc).click
    elsif Capybara.current_session.current_window.size == taille_tel
      find(id_boutton_ajout_intervention_mobile).click
    end
  end
end