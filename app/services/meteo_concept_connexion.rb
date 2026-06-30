# frozen_string_literal: true

class MeteoConceptConnexion < ApplicationService
  def initialize
    # Route par défaut de l'API MeteoConcept
    api_url = 'https://api.meteo-concept.com/api/'

    # Valeur par défaut du code commune
    insee = ENV['METEO_INSEE_CODE']

    # Appel des setters pour pouvoir charger uniquement la requete que l'on veut.
    @url = "#{api_url}forecast/daily/periods?insee=#{insee}"

    Rails.logger.debug '[METEO] Nouvelle instance de MeteoConceptConnexion créée !'
  end

  def call
    # Cache de la réponse de l'api MeteoConcept pendant 10 minutes, après cela elle est refresh.
    # skip_nil : un échec de l'API ne doit pas être mis en cache (sinon la météo
    # reste « cassée » 10 minutes alors que l'API est peut-être déjà revenue).
    Rails.cache.fetch('daily_forecast', expires_in: 10.minutes, skip_nil: true) do
      Rails.logger.debug '[Meteo] Mise à jour du cache de la réponse pour la météo sur 14 jours'

      fetch_response
    end
  end

  def fetch_response
    response = Fetch::API.fetch(@url,
                                method: :get,
                                headers: {
                                  'authorization' => "Bearer #{ENV['METEO_API_KEY']}"
                                })

    if response.status == 200
      forecasts = response.json
      forecasts[:last_fetched_at] = response.headers.get('date')
      forecasts
    else
      Rails.logger.debug "Erreur lors de l'appel API Meteo Concept : status = #{response.status}, body = #{response.body}"
      nil
    end
  rescue StandardError => e
    # Une API météo en panne ne doit jamais faire tomber la page d'accueil
    Rails.logger.warn "[Meteo] API injoignable : #{e.class} #{e.message}"
    puts "probleme" + e.message
    nil
  end

  # Retourne l'icon météo en fonction du jour de la prévision
  def self.get_icon_meteo_by_date(date, forecasts_for_14_days)
    day_forecast = self.get_forecast_for_date(date, forecasts_for_14_days)
    return unless day_forecast

    get_icon_meteo(day_forecast['weather'])
  end

  # Retourne la prévision au jour J, à 13h (la troisième prévision)
  def self.get_forecast_for_date(date, forecasts_for_14_days)
    return unless forecasts_for_14_days

    # La date doit être sur les 14 prochains jours
    difference_of_day = (date - Date.today).to_i
    return unless difference_of_day >= 0 && difference_of_day < 14

    forecasts_for_14_days[difference_of_day].third
  end

  # Retourne le forecast sous forme de titre
  def self.get_title(date, forecasts_for_14_days)
    forecast = self.get_forecast_for_date(date, forecasts_for_14_days)
    "#{self.WEATHER[forecast["weather"]]} | Température : #{forecast["temp2m"]} °C | Probabilité de pluie : #{forecast["probarain"]}% | Vent : #{forecast["wind10m"]} km/h"
  end

  def self.WEATHER
    {
      0 => 'Soleil',
      1 => 'Peu nuageux',
      2 => 'Ciel voilé',
      3 => 'Nuageux',
      4 => 'Très nuageux',
      5 => 'Couvert',
      6 => 'Brouillard',
      7 => 'Brouillard givrant',
      10 => 'Pluie faible',
      11 => 'Pluie modérée',
      12 => 'Pluie forte',
      13 => 'Pluie faible verglaçante',
      14 => 'Pluie modérée verglaçante',
      15 => 'Pluie forte verglaçante',
      16 => 'Bruine',
      20 => 'Neige faible',
      21 => 'Neige modérée',
      22 => 'Neige forte',
      30 => 'Pluie et neige mêlées faibles',
      31 => 'Pluie et neige mêlées modérées',
      32 => 'Pluie et neige mêlées fortes',
      40 => 'Averses de pluie locales et faibles',
      41 => 'Averses de pluie locales',
      42 => 'Averses locales et fortes',
      43 => 'Averses de pluie faibles',
      44 => 'Averses de pluie',
      45 => 'Averses de pluie fortes',
      46 => 'Averses de pluie faibles et fréquentes',
      47 => 'Averses de pluie fréquentes',
      48 => 'Averses de pluie fortes et fréquentes',
      60 => 'Averses de neige localisées et faibles',
      61 => 'Averses de neige localisées',
      62 => 'Averses de neige localisées et fortes',
      63 => 'Averses de neige faibles',
      64 => 'Averses de neige',
      65 => 'Averses de neige fortes',
      66 => 'Averses de neige faibles et fréquentes',
      67 => 'Averses de neige fréquentes',
      68 => 'Averses de neige fortes et fréquentes',
      70 => 'Averses de pluie et neige mêlées localisées et faibles',
      71 => 'Averses de pluie et neige mêlées localisées',
      72 => 'Averses de pluie et neige mêlées localisées et fortes',
      73 => 'Averses de pluie et neige mêlées faibles',
      74 => 'Averses de pluie et neige mêlées',
      75 => 'Averses de pluie et neige mêlées fortes',
      76 => 'Averses de pluie et neige mêlées faibles et nombreuses',
      77 => 'Averses de pluie et neige mêlées fréquentes',
      78 => 'Averses de pluie et neige mêlées fortes et fréquentes',
      100 => 'Orages faibles et locaux',
      101 => 'Orages locaux',
      102 => 'Orages fort et locaux',
      103 => 'Orages faibles',
      104 => 'Orages',
      105 => 'Orages forts',
      106 => 'Orages faibles et fréquents',
      107 => 'Orages fréquents',
      108 => 'Orages forts et fréquents',
      120 => 'Orages faibles et locaux de neige ou grésil',
      121 => 'Orages locaux de neige ou grésil',
      122 => 'Orages locaux de neige ou grésil',
      123 => 'Orages faibles de neige ou grésil',
      124 => 'Orages de neige ou grésil',
      125 => 'Orages de neige ou grésil',
      126 => 'Orages faibles et fréquents de neige ou grésil',
      127 => 'Orages fréquents de neige ou grésil',
      128 => 'Orages fréquents de neige ou grésil',
      130 => 'Orages faibles et locaux de pluie et neige mêlées ou grésil',
      131 => 'Orages locaux de pluie et neige mêlées ou grésil',
      132 => 'Orages fort et locaux de pluie et neige mêlées ou grésil',
      133 => 'Orages faibles de pluie et neige mêlées ou grésil',
      134 => 'Orages de pluie et neige mêlées ou grésil',
      135 => 'Orages forts de pluie et neige mêlées ou grésil',
      136 => 'Orages faibles et fréquents de pluie et neige mêlées ou grésil',
      137 => 'Orages fréquents de pluie et neige mêlées ou grésil',
      138 => 'Orages forts et fréquents de pluie et neige mêlées ou grésil',
      140 => 'Pluies orageuses',
      141 => 'Pluie et neige mêlées à caractère orageux',
      142 => 'Neige à caractère orageux',
      210 => 'Pluie faible intermittente',
      211 => 'Pluie modérée intermittente',
      212 => 'Pluie forte intermittente',
      220 => 'Neige faible intermittente',
      221 => 'Neige modérée intermittente',
      222 => 'Neige forte intermittente',
      230 => 'Pluie et neige mêlées',
      231 => 'Pluie et neige mêlées',
      232 => 'Pluie et neige mêlées',
      235 => 'Averses de grêle'
    }
  end

  # Recherche de l'icon correspondant à la météo en fonction du code weather
  def self.get_icon_meteo(code)
    # Catégories orage et brouillard (prioritaires)
    case code
    when 100..142, 120..142, 130..142 # tout orage
      return 'meteo/animated/thunder.svg'
    when 6, 7                         # brouillard simple ou givrant
      return 'meteo/animated/cloudy.svg'
    end

    case code
      # --- Ciel clair / nuages ---
    when 0
      'meteo/animated/day.svg'
    when 1..2
      'meteo/animated/cloudy-day-3.svg'
    when 3..5
      'meteo/animated/cloudy.svg'
    when 6..7
      'meteo/animated/cloudy.svg'

      # --- Pluie continue ---
    when 10  # faible
      'meteo/animated/rainy-2.svg'
    when 11  # modérée
      'meteo/animated/rainy-3.svg'
    when 12  # forte
      'meteo/animated/rainy-4.svg'
    when 13  # pluie faible verglaçante
      'meteo/animated/rainy-3.svg'
    when 14  # modérée verglaçante
      'meteo/animated/rainy-4.svg'
    when 15  # forte verglaçante
      'meteo/animated/rainy-5.svg'
    when 16  # bruine
      'meteo/animated/rainy-1.svg'

      # --- Neige continue ---
    when 20  # faible
      'meteo/animated/snowy-2.svg'
    when 21  # modérée
      'meteo/animated/snowy-3.svg'
    when 22  # forte
      'meteo/animated/snowy-4.svg'

      # --- Pluie et neige mêlées ---
    when 30 # faible
      'meteo/animated/rainy-2.svg'
    when 31 # modérée
      'meteo/animated/rainy-3.svg'
    when 32 # forte
      'meteo/animated/rainy-4.svg'

      # --- Averses de pluie ---
    when 40, 43, 46       # faibles
      'meteo/animated/rainy-3.svg'
    when 41, 44, 47       # normales
      'meteo/animated/rainy-4.svg'
    when 42, 45, 48       # fortes
      'meteo/animated/rainy-5.svg'

      # --- Averses de neige ---
    when 60, 63, 66       # faibles
      'meteo/animated/snowy-3.svg'
    when 61, 64, 67       # normales
      'meteo/animated/snowy-4.svg'
    when 62, 65, 68       # fortes
      'meteo/animated/snowy-5.svg'

      # --- Averses pluie + neige mêlées ---
    when 70, 73, 76       # faibles
      'meteo/animated/rainy-3.svg'
    when 71, 74, 77       # normales
      'meteo/animated/rainy-4.svg'
    when 72, 75, 78       # fortes
      'meteo/animated/rainy-5.svg'

      # --- Pluie intermittente ---
    when 210            # faible
      'meteo/animated/rainy-1.svg'
    when 211            # modérée
      'meteo/animated/rainy-2.svg'
    when 212            # forte
      'meteo/animated/rainy-3.svg'

      # --- Neige intermittente ---
    when 220            # faible
      'meteo/animated/snowy-1.svg'
    when 221            # modérée
      'meteo/animated/snowy-2.svg'
    when 222            # forte
      'meteo/animated/snowy-3.svg'

      # --- Pluie et neige mêlées intermittentes ---
    when 230, 231, 232
      'meteo/animated/rainy-4.svg'

      # --- Grêle ---
    when 235
      'meteo/animated/snowy-6.svg'

    else
      'meteo/animated/day.svg'
    end
  end
end