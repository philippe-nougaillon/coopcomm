class Rack::Attack

  ### Configure Cache ###

  # If you don't want to use Rails.cache (Rack::Attack's default), then
  # configure it here.
  #
  # Note: The store is only used for throttling (not blocklisting and
  # safelisting). It must implement .increment and .write like
  # ActiveSupport::Cache::Store

  # Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new 

  ### Throttle Spammy Clients ###

  # If any single client IP is making tons of requests, then they're
  # probably malicious or a poorly-configured scraper. Either way, they
  # don't deserve to hog all of the app server's CPU. Cut them off!
  #
  # Note: If you're serving assets through rack, those requests may be
  # counted by rack-attack and this throttle may be activated too
  # quickly. If so, enable the condition to exclude them from tracking.
  #
  # Assets et fichiers ActiveStorage exclus du compteur : une IP de mairie
  # partagée épuiserait la limite en chargeant quelques pages.

  # Throttle all requests by IP (60rpm)
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
  throttle('req/ip', limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?('/assets', '/rails/active_storage')
  end

  ### Prevent Brute-Force Login Attacks ###

  # The most common brute-force login attack is a brute-force password
  # attack where an attacker simply tries a large number of emails and
  # passwords to see if any credentials match.
  #
  # Another common method of attack is to use a swarm of computers with
  # different IPs to try brute-forcing a password for a specific account.

  # Throttle POST requests to /users/sign_in by IP address
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:logins/ip:#{req.ip}"
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/users/sign_in' && req.post?
      req.ip
    end
  end

  # Throttle POST requests to /users/sign_in by email param
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:logins/email:#{normalized_email}"
  #
  # Note: This creates a problem where a malicious user could intentionally
  # throttle logins for another user and force their login requests to be
  # denied, but that's not very common and shouldn't happen to you. (Knock
  # on wood!)
  throttle('logins/email', limit: 5, period: 20.seconds) do |req|
    if req.path == '/users/sign_in' && req.post?
      # Normalize the email, using the same logic as your authentication process, to
      # protect against rate limit bypasses. Return the normalized email if present, nil otherwise.
      req.params.dig('user', 'email').to_s.downcase.gsub(/\s+/, "").presence
    end
  end

  # Throttle POST requests to /users/password by IP address — chaque demande
  # part en mail réel.
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:password_resets/ip:#{req.ip}"
  throttle('password_resets/ip', limit: 5, period: 15.minutes) do |req|
    if req.path == '/users/password' && req.post?
      req.ip
    end
  end

  ### Throttle Devise Pages (anti-bots) ###

  # Reprend le `rate_limit` historique d'ApplicationController.
  #
  # Key: "rack::attack:#{Time.now.to_i/:period}:devise/ip:#{req.ip}"
  throttle('devise/ip', limit: 20, period: 1.minute) do |req|
    if req.path.start_with?('/users/sign_in', '/users/sign_out', '/users/password', '/users/invitation')
      req.ip
    end
  end

  ### Fail2Ban : bannissement automatique des scanners ###

  # Une seule sonde bannit l'IP pour tout le site. Débannir en console :
  #   Rack::Attack::Fail2Ban.reset("pentesters-IP", findtime: 10.minutes)
  #
  # bantime = 2 semaines = le maximum que Solid Cache honore (son `max_age`).
  #
  # ⚠ Ce ban ne pardonne aucun faux positif, et l'URL ActiveStorage se termine
  # par le nom du fichier uploadé : un adhérent ouvrant son « rapport.php »
  # serait banni. D'où les exemptions /rails/, /assets/ et /.well-known.

  # Extensions de fichiers qu'une app Rails ne sert jamais.
  SCANNER_EXTENSIONS = %w[.php .php7 .phtml .asp .aspx .jsp .jspx .cgi .sql .bak].freeze

  # Préfixes sondés par les scanners, en minuscules.
  SCANNER_PREFIXES = %w[
    /wp- /wordpress /xmlrpc /joomla /drupal /administrator /typo3 /magento
    /phpmyadmin /pma /adminer /mysql /sqlite /webdav /phpinfo
    /cgi-bin /vendor/phpunit /laravel /telescope /_ignition /_profiler
    /actuator /manager/html /jenkins /solr /struts /wls-wsat /console/login
    /owa/ /autodiscover /ews/ /remote/fgt_lang /boaform /hnap1 /gponform
  ].freeze

  blocklist('fail2ban pentesters') do |req|
    Rack::Attack::Fail2Ban.filter("pentesters-#{req.ip}", maxretry: 1, findtime: 10.minutes, bantime: 2.weeks) do
      chemin = req.path.downcase
      if chemin.start_with?('/rails/', '/assets/')
        false
      else
        chemin.end_with?(*SCANNER_EXTENSIONS) ||
          chemin.start_with?(*SCANNER_PREFIXES) ||
          (chemin.start_with?('/.') && !chemin.start_with?('/.well-known')) ||
          chemin.include?('wp-admin') ||
          chemin.include?('wp-login') ||
          chemin.include?('/etc/passwd') ||
          CGI.unescape(req.query_string) =~ %r{/etc/passwd}
      end
    end
  end

  ### Custom Throttle Response ###

  # By default, Rack::Attack returns an HTTP 429 for throttled responses,
  # which is just fine.
  #
  # If you want to return 503 so that the attacker might be fooled into
  # believing that they've successfully broken your app (or you just want to
  # customize the response), then uncomment these lines.
  # self.throttled_responder = lambda do |env|
  #  [ 503,  # status
  #    {},   # headers
  #    ['']] # body
  # end
end