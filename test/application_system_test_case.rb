
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
  # Risque d'erreur: 
  # La notification peut apparaitre après le within 
  # et fait remonter une erreur car elle n'est pas trouvée.
  # `assert_selector` rejoue toute la requête à chaque tentative, là où un
  # `within` fige le conteneur de la page courante : quand l'action navigue,
  # l'assertion resterait accrochée au `#notification` vide de la page quittée.
  def assert_notification(texte)
    assert_selector '#notification', text: texte

    fermer_notification
  end

  # Un seul sélecteur pour les trois variantes : `find` attend alors l'ouverture
  # d'un menu, là où un `has_css?(wait: 0)` par variante ne laisse aucune chance.
  def element_testid(testid)
    variantes = [testid, "#{testid}_mobile", "#{testid}_pc"]
    find(variantes.map { |tid| "[data-testid=\"#{tid}\"]" }.join(', '))
  end

  def click_sur_boutton_ajouter(element)
    cliquer_element(element_testid("ajouter_#{element}"))
  end

  # Centrer avant de cliquer : Selenium aligne sinon l'élément en bas, sous le
  # dock fixe qui intercepte le clic.
  def cliquer_element(element)
    scroll_to(element, align: :center)
    element.click
  end

  def cliquer_bouton(locator)
    cliquer_element(find_button(locator))
  end

  # daisyUI ouvre ses menus depuis une `div` focusable et non depuis un `<button>` :
  # `find_button` ne la voit pas, d'où un chemin distinct.
  def cliquer_div_bouton(texte)
    cliquer_element(find("[role='button'][tabindex]", text: texte))
  end

  # Sous 1024 px la navbar du haut disparaît et ses rubriques passent dans le dock
  # du bas, toutes derrière une même icône sans libellé : le nom du menu n'a plus
  # de sens à cette largeur.
  def ouvrir_dropdown(nom)
    # Si en mode pc
    return cliquer_div_bouton(nom) if has_css?("[role='button'][tabindex]", text: nom, wait: 0)

    # Sinon en mode mobile
    cliquer_element(element_testid('dropdown_mobile'))
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

  # Le menu du haut se replie derrière une icône en largeur téléphone : on l'ouvre
  # si ce qu'on vise n'est pas déjà à l'écran.
  def ouvrir_dropdown_mobile
    cliquer_element(element_testid('dropdown_mobile'))
  end

  # Cliquer sur le bouton de la navbar en mobile ou en pc
  def cliquer_lien_navbar(texte)
    # Si le texte n'existe pas, alors on ouvre le dropdown_mobile
    ouvrir_dropdown_mobile unless has_link?(texte, wait: 0)
    cliquer_lien(texte)
  end

  # Ouvre la modale de déconnexion sans rien confirmer.
  def cliquer_bouton_deconnexion
    ouvrir_dropdown_mobile unless has_css?("[data-testid='se_deconnecter']", wait: 0)
    cliquer_element(element_testid('se_deconnecter'))

    assert_selector '#logout_modal', text: 'Êtes-vous certain(e) de vouloir fermer cette session ?'
  end

  def se_deconnecter
    cliquer_bouton_deconnexion
    cliquer_lien 'Oui, se déconnecter'

    assert_text 'Mutualisez mieux'
  end

  # Cherche si le bloc d'erreur du formulaire existe, sinon le test échoue
  def find_error_form
    find("#error_explanation")
  rescue Capybara::ElementNotFound
    fail "Le bloc d'erreur du formulaire doit apparaitre"
  end
end