# frozen_string_literal: true

require 'test_helper'

# Tests de la configuration rack-attack (config/initializers/rack_attack.rb).
class RackAttackTest < ActionDispatch::IntegrationTest
  ROUTE_HINT = "— le throttle ne s'est pas déclenché : la route ou le nom du " \
               'paramètre a-t-il changé sans mettre à jour ' \
               'config/initializers/rack_attack.rb ?'

  setup do
    @previous_store = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    freeze_time
  end

  teardown do
    Rack::Attack.cache.store = @previous_store
  end

  # ----- Sentinelles de configuration -----

  test 'le middleware Rack::Attack est présent dans la pile' do
    noms = Rails.application.middleware.middlewares.map(&:name)

    assert_includes noms, 'Rack::Attack'
  end

  test 'les cinq règles de throttle sont déclarées avec leurs seuils' do
    regles = Rack::Attack.throttles

    assert_equal %w[devise/ip logins/email logins/ip password_resets/ip req/ip], regles.keys.sort
    assert_equal [300, 5.minutes.to_i], [regles['req/ip'].limit, regles['req/ip'].period]
    assert_equal [5, 20], [regles['logins/ip'].limit, regles['logins/ip'].period]
    assert_equal [5, 20], [regles['logins/email'].limit, regles['logins/email'].period]
    assert_equal [5, 15.minutes.to_i],
                 [regles['password_resets/ip'].limit, regles['password_resets/ip'].period]
    assert_equal [20, 1.minute.to_i], [regles['devise/ip'].limit, regles['devise/ip'].period]
  end

  test 'le throttle des connexions par email surveille le paramètre par lequel Devise authentifie réellement' do
    # Si l'authentification passait un jour à :login / :username, le throttle
    # lirait user[email] dans le vide et deviendrait inopérant.
    assert_includes Devise.authentication_keys, :email
  end

  # ----- logins/ip : brute-force depuis une même IP -----

  test 'la 6e tentative de connexion depuis la même IP est bloquée' do
    5.times do |i|
      post user_session_path, params: identifiants("essai#{i}@exemple.fr"), headers: ip('1.2.3.4')

      assert_not_equal 429, response.status, "la tentative n°#{i + 1} devrait encore passer"
    end

    post user_session_path, params: identifiants('essai5@exemple.fr'), headers: ip('1.2.3.4')

    assert_equal 429, response.status, "logins/ip #{ROUTE_HINT}"
  end

  test "le compteur des connexions est par IP : une autre IP n'est pas bloquée" do
    5.times { |i| post user_session_path, params: identifiants("essai#{i}@exemple.fr"), headers: ip('1.2.3.4') }

    post user_session_path, params: identifiants('essai5@exemple.fr'), headers: ip('9.9.9.9')

    assert_not_equal 429, response.status
  end

  test 'afficher la page de connexion ne compte pas comme une tentative de connexion' do
    7.times { get new_user_session_path, headers: ip('1.2.3.4') }

    assert_not_equal 429, response.status
  end

  # ----- logins/email : brute-force distribué sur un même compte -----

  test "la 6e tentative de connexion sur le même email est bloquée même en changeant d'IP" do
    5.times do |i|
      post user_session_path, params: identifiants('cible@exemple.fr'), headers: ip("10.0.0.#{i + 1}")

      assert_not_equal 429, response.status, "la tentative n°#{i + 1} devrait encore passer"
    end

    post user_session_path, params: identifiants('cible@exemple.fr'), headers: ip('10.0.0.99')

    assert_equal 429, response.status, "logins/email #{ROUTE_HINT}"
  end

  test "les variantes de casse et d'espaces d'un email alimentent le même compteur" do
    variantes = ['cible@exemple.fr', ' CIBLE@exemple.fr', 'cible@EXEMPLE.FR ',
                 'Cible@Exemple.fr', '  cible@exemple.fr  ']
    variantes.each_with_index do |email, i|
      post user_session_path, params: identifiants(email), headers: ip("10.0.1.#{i + 1}")
    end

    post user_session_path, params: identifiants('cible@exemple.fr'), headers: ip('10.0.1.99')

    assert_equal 429, response.status,
                 'les variantes de casse/espaces devraient alimenter le même compteur'
  end

  test "une tentative de connexion sans email n'alimente aucun compteur" do
    assert_nil discriminant('logins/email', user_session_path, params: { 'user' => { 'email' => '   ' } })
    assert_nil discriminant('logins/email', user_session_path, params: {})
  end

  # ----- password_resets/ip : rafale de demandes de reset (mails Mailgun) -----

  test 'la 6e demande de réinitialisation de mot de passe depuis la même IP est bloquée' do
    5.times do |i|
      post user_password_path, params: { user: { email: 'inconnu@exemple.fr' } }, headers: ip('1.2.3.4')

      assert_not_equal 429, response.status, "la demande n°#{i + 1} devrait encore passer"
    end

    post user_password_path, params: { user: { email: 'inconnu@exemple.fr' } }, headers: ip('1.2.3.4')

    assert_equal 429, response.status, "password_resets/ip #{ROUTE_HINT}"
  end

  # ----- devise/ip : anti-bots sur les pages Devise (remplace le rate_limit
  # natif retiré d'ApplicationController, mêmes seuils : 20/min par IP) -----

  test 'la 21e requête sur une page Devise depuis la même IP est bloquée' do
    20.times do |i|
      get new_user_session_path, headers: ip('5.6.7.8')

      assert_not_equal 429, response.status, "la requête n°#{i + 1} devrait encore passer"
    end

    get new_user_session_path, headers: ip('5.6.7.8')

    assert_equal 429, response.status, "devise/ip #{ROUTE_HINT}"
  end

  test "les pages de session, de mot de passe et d'invitation sont toutes comptées comme pages Devise" do
    assert_equal '1.2.3.4', discriminant('devise/ip', new_user_session_path, method: 'GET')
    assert_equal '1.2.3.4', discriminant('devise/ip', destroy_user_session_path, method: 'DELETE')
    assert_equal '1.2.3.4', discriminant('devise/ip', new_user_password_path, method: 'GET')
    assert_equal '1.2.3.4', discriminant('devise/ip', accept_user_invitation_path, method: 'GET')
  end

  test "la liste des utilisateurs n'est pas comptée comme une page Devise" do
    # Un manager qui navigue dans la liste des utilisateurs ne doit pas être limité à 20
    # pages/min.
    assert_nil discriminant('devise/ip', '/users', method: 'GET')
    assert_nil discriminant('devise/ip', '/users/42', method: 'GET')
  end

  # ----- req/ip : throttle global (discriminant seul : 301 requêtes full-stack
  # seraient prohibitives ; le moteur de comptage est déjà prouvé full-stack par les
  # règles login, qui partagent le même mécanisme)

  test 'une requête applicative est comptée dans le throttle global par IP' do
    assert_equal '1.2.3.4', discriminant('req/ip', '/', method: 'GET')
  end

  test 'les assets ne sont pas comptés dans le throttle global' do
    assert_nil discriminant('req/ip', '/assets/application-abc123.css', method: 'GET')
  end

  test 'les fichiers ActiveStorage ne sont pas comptés dans le throttle global' do
    assert_nil discriminant('req/ip', '/rails/active_storage/blobs/redirect/xyz/photo.jpg', method: 'GET')
  end

  # ----- fail2ban pentesters : bannissement automatique des scanners -----
  # (réponse = 403 Forbidden : c'est une blocklist, pas un throttle 429)

  test 'la blocklist fail2ban est déclarée' do
    assert_includes Rack::Attack.blocklists.keys, 'fail2ban pentesters'
  end

  test "dès la première sonde de scanner, la requête est bloquée et l'IP bannie pour tout le site" do
    get '/wp-admin/setup.php', headers: ip('66.66.66.66')

    assert_equal 403, response.status,
                 'un chemin wp-admin devrait être bloqué par la blocklist fail2ban'

    get root_path, headers: ip('66.66.66.66')

    assert_equal 403, response.status, "une seule sonde doit suffire à bannir l'IP partout (maxretry: 1)"
  end

  test 'toutes les familles de motifs de scanner sont reconnues' do
    scanners = ['/wp-admin', '/blog/wp-login.php', '/xmlrpc.php', '/index.php', '/login.aspx',
                '/cgi-bin/test-cgi', '/phpmyadmin/index', '/adminer', '/administrator/index',
                '/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php',
                '/actuator/health', '/telescope/requests', '/manager/html',
                '/owa/auth/logon.aspx', '/autodiscover/autodiscover.xml',
                '/boaform/admin/formlogin', '/HNAP1',
                '/.env', '/.git/config', '/.aws/credentials', '/backup.sql', '/dump.bak',
                '/dossier/etc/passwd', "/recherche?fichier=#{CGI.escape('/etc/passwd')}"]
    scanners.each do |cible|
      assert motif_scanner?(cible), "le motif #{cible} devrait être reconnu comme scanner"
    end
  end

  test "un chemin légitime de l'application n'est jamais pris pour une sonde de scanner" do
    legitimes = ['/', '/users/sign_in', '/interventions', '/messagerie', '/cotations',
                 '/admin/audits', '/admin/stats', '/admin/parametres', # routes réelles ≠ /adminer, /administrator
                 '/jobs', # Mission Control ≠ /jenkins
                 '/.well-known/security.txt', '/.well-known/acme-challenge/token',
                 '/rails/active_storage/blobs/redirect/abc/rapport.php', # URL = nom du fichier uploadé !
                 '/rails/active_storage/blobs/redirect/abc/sauvegarde.sql',
                 '/assets/application-abc123.css']
    legitimes.each do |cible|
      assert_not motif_scanner?(cible), "#{cible} ne doit JAMAIS être traité comme scanner"
    end
  end

  test "le bannissement est par IP : une autre IP n'est pas affectée" do
    get '/wp-admin', headers: ip('66.66.66.66')

    get root_path, headers: ip('9.9.9.9')

    assert_not_equal 403, response.status
  end

  test 'le bannissement tient deux semaines puis expire' do
    get '/wp-admin', headers: ip('66.66.66.66')

    travel 13.days

    get root_path, headers: ip('66.66.66.66')

    assert_equal 403, response.status, 'le ban devrait encore tenir avant les 2 semaines'

    travel 1.day + 1.second

    get root_path, headers: ip('66.66.66.66')

    assert_not_equal 403, response.status, 'le bantime de 2 semaines devrait avoir expiré'
  end

  test 'la commande console de débannissement lève le bannissement immédiatement' do
    # C'est la commande à utiliser en prod (avec l'IP publique concernée).
    get '/wp-admin', headers: ip('66.66.66.66')

    Rack::Attack::Fail2Ban.reset('pentesters-66.66.66.66', findtime: 10.minutes)

    get root_path, headers: ip('66.66.66.66')

    assert_not_equal 403, response.status, 'reset devrait débannir sans attendre le bantime'
  end

  private

  def identifiants(email)
    { user: { email: email, password: 'mauvais-mot-de-passe' } }
  end

  def ip(adresse)
    { 'REMOTE_ADDR' => adresse }
  end

  # Applique le bloc discriminant d'une règle à une requête forgée, sans traverser la pile
  # — pour tester le filtrage (chemin, méthode, param) indépendamment du comptage.
  def discriminant(regle, chemin, method: 'POST', params: nil)
    env = Rack::MockRequest.env_for(chemin, method: method, params: params, 'REMOTE_ADDR' => '1.2.3.4')
    Rack::Attack.throttles.fetch(regle).block.call(Rack::Attack::Request.new(env))
  end

  # Évalue le filtre fail2ban sur une requête forgée.
  def motif_scanner?(chemin)
    @ip_seq = (@ip_seq || 0) + 1
    env = Rack::MockRequest.env_for(chemin, method: 'GET', 'REMOTE_ADDR' => "203.0.113.#{@ip_seq}")
    !!Rack::Attack.blocklists.fetch('fail2ban pentesters').block.call(Rack::Attack::Request.new(env))
  end
end
