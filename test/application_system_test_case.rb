# frozen_string_literal: true

require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Largeur / Hauteur
  def self.taille_pc
    [1400, 1400]
  end

  def self.taille_tel
    [544, 900] # 544 est le minimum en largeur
  end

  driven_by :selenium, using: :chrome, screen_size: taille_tel
  # driven_by :selenium, using: :headless_chrome, screen_size: taille_tel

  # Pour cliquer sur le bouton d'ajout d'un element en fonction du format de l'écran
  def click_sur_boutton_ajouter(element)
    id_boutton_ajout_element_pc = "[data-testid=\"ajouter_#{element}_pc\"]"
    id_boutton_ajout_element_mobile = "[data-testid=\"ajouter_#{element}_mobile\"]"

    taille_ecran_test = Capybara.current_session.current_window.size

    if taille_ecran_test == self.class.taille_pc
      find(id_boutton_ajout_element_pc).click
    elsif taille_ecran_test == self.class.taille_tel
      find(id_boutton_ajout_element_mobile).click
    end
  end
end
