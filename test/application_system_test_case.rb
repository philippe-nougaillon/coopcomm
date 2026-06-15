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

  # Ceinture et bretelles : certains environnements Chrome ignorent screen_size
  # au lancement — les tests sont écrits pour la largeur mobile (544 px).
  setup do
    Capybara.current_session.current_window.resize_to(*self.class.taille_tel)
  end

  # Le toast de notification n'a plus de bouton de fermeture (il s'auto-masque
  # apres 5 s) ; on le retire du DOM pour qu'il ne masque pas la barre mobile.
  def fermer_notification
    page.execute_script("document.querySelectorAll('#notification > div').forEach(e => e.remove())")
  end

  # Pour cliquer sur le bouton d'ajout d'un element en fonction du format de l'écran
  def click_sur_boutton_ajouter(element)
    # Selon les pages : testid simple, ou variantes _mobile/_pc (le bouton _pc
    # reste visible en largeur mobile sur certaines pages, seul son libelle est masque)
    ["ajouter_#{element}", "ajouter_#{element}_mobile", "ajouter_#{element}_pc"].each do |tid|
      sel = "[data-testid=\"#{tid}\"]"
      return find(sel).click if has_css?(sel, wait: 0)
    end
    raise Capybara::ElementNotFound, "Aucun bouton d'ajout visible pour #{element}"
  end
end
