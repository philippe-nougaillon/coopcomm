
# frozen_string_literal: true

require 'test_helper'

# Défaut de la gem : 2 s, trop court sous parallélisation (un Chrome et un Puma
# par worker).
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

  # Certains environnements Chrome ignorent screen_size au lancement.
  setup do
    Capybara.current_session.current_window.resize_to(*self.class.taille_tel)
  end

  # Le toast masque la barre mobile : on le referme par sa croix, comme le fait
  # l'utilisateur. `hide` retire l'élément du DOM à la fin de sa transition.
  # Sans notification affichée, il n'y a rien à fermer : une notification vit 10 s
  # et un setup lent peut l'avoir vue disparaître d'elle-même.
  def fermer_notification
    croix = find("[data-testid='close_notification']", wait: 0)
    cliquer_element(croix)
    assert_no_selector '#notification > div', wait: 5
  rescue Capybara::ElementNotFound
    nil
  end

  # Vérifie le toast affiché après une action, puis le referme.
  def assert_notification(texte)
    within '#notification' do
      assert_text texte
    end
    fermer_notification
  end

  # Réservé aux boutons qui n'affichent qu'une icône. Selon les pages : testid
  # simple, ou variantes _mobile/_pc.
  def cliquer(testid)
    cliquer_element(element_testid(testid))
  end

  # Un seul sélecteur pour les trois variantes : `find` attend alors l'ouverture
  # d'un menu, là où un `has_css?(wait: 0)` par variante ne laisse aucune chance.
  def element_testid(testid)
    variantes = [testid, "#{testid}_mobile", "#{testid}_pc"]
    find(variantes.map { |tid| "[data-testid=\"#{tid}\"]" }.join(', '))
  end

  def click_sur_boutton_ajouter(element)
    cliquer("ajouter_#{element}")
  end

  # Centrer avant de cliquer : Selenium aligne sinon l'élément en bas, sous le
  # dock fixe qui intercepte le clic.
  def cliquer_element(element)
    scroll_to(element, align: :center)
    element.click
  end

  # Un bouton porteur de texte se pilote par son texte. Repli sur `role=button` :
  # daisyUI ouvre ses menus déroulants depuis un `div`, que `find_button` ignore.
  def cliquer_bouton(locator)
    cliquer_element(find_button(locator))
  rescue Capybara::ElementNotFound
    cliquer_element(find("[role='button']", text: locator))
  end

  def cliquer_lien(locator)
    cliquer_element(find_link(locator))
  end

  # Attend la fin effective d'une soumission — `click_on` rend la main dès le clic.
  # Quand la destination est connue d'avance, préférer `assert_current_path`.
  def soumettre(locator)
    cliquer_bouton(locator)

    # `disabled: :all` obligatoire : sans lui l'assertion est vraie dès le clic,
    # `data-disable-with` désactivant le bouton, et ne synchronise plus rien.
    assert_no_button locator, disabled: :all, wait: 10
  end

  # Création d'un fichier volumineux
  def fichier_volumineux(extension, taille)
    chemin = Rails.root.join('tmp', "gros_#{SecureRandom.hex(4)}#{extension}")
    chemin.dirname.mkpath
    chemin.binwrite('0' * taille)

    (@fichiers_volumineux ||= []) << chemin
    chemin.to_s
  end

  # Suppression des fichiers volumineux créés
  teardown do
    @fichiers_volumineux&.each { |chemin| FileUtils.rm_f(chemin) }
  end

  # Reproduit la transformation CSS `text-transform: capitalize` (majuscule
  # en début de chaque mot, sans toucher au reste) pour comparer avec le
  # texte tel qu'il est réellement affiché à l'écran.
  def css_capitalize(str)
    str.split(' ').map { |word| word.sub(/\A\p{L}/) { |c| c.upcase } }.join(' ')
  end

  # Clic JS : le clic Selenium natif tombe sur le SVG enfant du lien et n'émet
  # jamais le DELETE. Le confirm est stubé, et le clic re-tenté s'il se perd.
  def se_deconnecter(temoin_page_publique = 'Mutualisez mieux')
    3.times do
      # Stub reposé à chaque tour : une navigation entre deux tentatives (redirection
      # de connexion encore en vol sous charge) rend son `window.confirm` natif au
      # document, Chrome écarte alors la boîte et le DELETE n'est jamais émis.
      page.execute_script('window.confirm = () => true')
      page.execute_script("document.querySelector(\"[data-testid='fermer_session']\")?.click()")
      return if has_text?(temoin_page_publique, wait: 10)
    rescue Selenium::WebDriver::Error::UnexpectedAlertOpenError
      next
    end

    flunk "Déconnexion : #{temoin_page_publique.inspect} toujours absent après 3 tentatives de clic"
  end
end