
# frozen_string_literal: true

require 'test_helper'

# Budget d'attente des assertions Capybara (défaut de la gem : 2 s).
# Ce n'est PAS un cache-misère : depuis que les assertions portent sur des états
# stables (URL d'arrivée, disparition du formulaire) et non sur des toasts qui
# s'auto-détruisent, une condition vraie le reste — attendre plus ne peut que
# rattraper une machine lente, jamais masquer une course. Or sous parallélisation
# chaque worker a son Chrome et son Puma : une navigation dépasse régulièrement
# 2 s sans que rien ne soit cassé.
Capybara.default_max_wait_time = ENV.fetch('CAPYBARA_MAX_WAIT', 5).to_i

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Largeur / Hauteur
  def self.taille_pc
    [1400, 1400]
  end

  def self.taille_tel
    [544, 900] # 544 est le minimum en largeur
  end

  # 💡 CORRECTION : On passe sur :headless_chrome et on configure les options du bloc
  driven_by :selenium, using: :headless_chrome, screen_size: taille_tel do |driver_options|
    driver_options.add_argument('--no-sandbox')
    driver_options.add_argument('--disable-dev-shm-usage')
    driver_options.add_argument('--disable-gpu')
  end

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

  # Clique un élément après l'avoir ramené au CENTRE de la fenêtre. Sans ça,
  # Selenium se contente de l'amener dans le champ de vision — typiquement collé
  # en bas — c'est-à-dire précisément sous le dock fixe de la largeur mobile, qui
  # reçoit le clic à sa place (ElementClickInterceptedError, vu sous forte charge).
  # Centré, l'élément est déjà visible : Selenium ne re-scrolle pas, et le clic porte.
  def cliquer_element(element)
    scroll_to(element, align: :center)
    element.click
  end

  def cliquer_bouton(locator)
    cliquer_element(find_button(locator))
  end

  def cliquer_lien(locator)
    cliquer_element(find_link(locator))
  end

  # Attend la fin EFFECTIVE d'une soumission : `click_on` rend la main dès le
  # clic, AVANT que le serveur ait traité la requête — une assertion posée juste
  # après lirait encore le formulaire. On attend donc que le bouton d'envoi ait
  # disparu (= on a quitté le formulaire). S'il est toujours là, c'est que la
  # soumission a échoué et re-rendu le formulaire : l'échec est net et lisible.
  #
  # À utiliser quand la page de destination n'est pas connue d'avance (création
  # d'un enregistrement) ; sinon `assert_current_path` dit la même chose en plus fort.
  def soumettre(locator)
    cliquer_bouton(locator)

    # Pourquoi `disabled: :all` ? Sans lui, ce helper ne synchronise RIEN.
    #
    # Nos boutons d'envoi portent `data-disable-with` (ex. dans le formulaire
    # outil : <input type="submit" id="enregistrer_tool" data-disable-with="…">).
    # Rails s'en sert pour empêcher le double-clic : dès qu'on clique, il pose
    # l'attribut `disabled` sur le bouton — qui reste dans le DOM.
    #
    # Or `assert_no_button` ne regarde QUE les boutons activés (`disabled: false`,
    # défaut de Capybara). Un bouton désactivé n'existe donc pas à ses yeux.
    #
    # Chronologie sans l'option, sur « Créer un outil » :
    #   t=0ms    clic → Rails désactive le bouton, la requête part
    #   t=1ms    assert_no_button → le bouton est désactivé donc « absent » → VRAI
    #            ...alors qu'on est TOUJOURS sur le formulaire !
    #   t=2ms    assert_text 'MX57SH3V' → lit la page « Nouveau matériel » → ÉCHEC
    #
    # Avec `disabled: :all`, Capybara compte aussi les boutons désactivés :
    # l'assertion ne devient vraie que quand le bouton quitte réellement le DOM,
    # c'est-à-dire quand le navigateur a rendu la page d'arrivée. C'est ce qu'on veut.
    assert_no_button locator, disabled: :all, wait: 10
  end
end