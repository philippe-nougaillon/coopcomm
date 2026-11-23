# frozen_string_literal: true

module Aibbo
  # Relève dans une réponse les dates, les horaires, les nombres et les noms propres que rien n'a fournis au modèle.
  class ReleverInventions < ApplicationService
    Lecture = Struct.new(:dates, :horaires, :nombres, :telephones, :reste)

    MOIS = %w[janvier février mars avril mai juin juillet août septembre octobre novembre décembre].freeze
    ADMIS = (%w[coopcomm aibbo ht ttc tva ia qr pdf lundi mardi mercredi jeudi vendredi samedi dimanche] +
             MOIS.map { |mois| I18n.transliterate(mois) }).freeze
    DEDUCTION = /\A[\s>_#*-]*(?:déduction|supposition)\s*:/i
    JOUR = '(\d{1,2}|1er)'
    DATE_ISO = /\b(\d{4})-(\d{2})-(\d{2})\b/
    DATE_CHIFFREE = %r{\b(\d{1,2})/(\d{1,2})(?:/(\d{4}))?\b}
    DATE_ECRITE = /\b#{JOUR}(?:\s+(?:au|et)\s+#{JOUR})?\s+(#{MOIS.join('|')})(?:\s+(\d{4}))?/i
    MOIS_ET_ANNEE = /\b(#{MOIS.join('|')})\s+(\d{4})\b/i
    JOUR_SEUL = /\b(?:le|au|du)\s+#{JOUR}\b(?!\s?(?:h\b|heures?\b|%|[.,:]\d))/i
    TELEPHONE = /(?<!\d)(?:\+33\s?|0)\d(?:[\s.]?\d{2}){4}(?!\d)/
    HORAIRE = /(?<![\d,.])(\d{1,2})\s?(?:[hH]\s?|:)(\d{2})(?!\d)/
    HEURE_RONDE = /(?<![\d,.])(\d{1,2})\s?(?:heures?|[hH])(?![[:alnum:]])/
    NOMBRE = /(?<![[:alpha:]\d])(\d{1,3}(?: \d{3})+|\d+)(?:[.,](\d+))?(\s?%)?/
    MOT = /[[:alpha:]][[:alpha:]'’-]*/
    DEBUT_DE_PHRASE = /(?:\A[\s>#_•–—-]*|[.!?…:|«"“][\s_]*)\z/

    def initialize(reponse, sources, aujourd_hui: Date.current)
      @reponse = reponse.to_s
      @sources = sources.map { |source| source.to_s.lines.grep_v(DEDUCTION).join }
      @aujourd_hui = aujourd_hui
    end

    def call
      lues = @sources.map { |source| lire(source) }
      @dates = lues.flat_map(&:dates) << [@aujourd_hui.year, @aujourd_hui.month, @aujourd_hui.day]
      @horaires = lues.flat_map(&:horaires)
      @nombres = lues.flat_map(&:nombres).map(&:first) + @sources.flat_map { |source| tailles_des_listes(source) }
      @telephones = lues.flat_map(&:telephones)
      @mots = @sources.flat_map { |source| source.scan(/[[:alpha:]]+/) }.to_set { |mot| I18n.transliterate(mot).downcase }.merge(ADMIS)

      @reponse.lines.flat_map { |ligne| sans_source(ligne.tr('*`', ' ').sub(/\A[\s>#_-]*\d+[.)]\s+/, '')) }.uniq
    end

    private

    def sans_source(ligne)
      lue = lire(ligne)
      absents = lue.dates.reject { |annee, mois, jour| date_lue?(annee, mois, jour) }.map(&:last)
      absents += lue.telephones.reject { |numero, _| @telephones.any? { |lu, _| lu == numero } }.map(&:last)
      absents += lue.horaires.reject { |heure, minute, ronde| horaire_lu?(heure, minute, ronde) }.map(&:last)
      absents += lue.nombres.reject { |valeur, pourcentage| nombre_admis?(valeur, pourcentage) }.map(&:last) unless ligne.match?(DEDUCTION)
      absents + noms_absents(lue.reste)
    end

    def lire(texte)
      lecture = Lecture.new([], [], [], [], texte.tr("  ", '  '))
      relever(lecture, DATE_ISO) { |m| lecture.dates << [m[1].to_i, m[2].to_i, m[3].to_i, m[0]] }
      relever(lecture, DATE_CHIFFREE) { |m| lecture.dates << [m[3]&.to_i, m[2].to_i, m[1].to_i, m[0]] }
      relever(lecture, DATE_ECRITE) do |m|
        [m[1], m[2]].compact.each { |jour| lecture.dates << [m[4]&.to_i, numero_du_mois(m[3]), jour.to_i, m[0]] }
      end
      relever(lecture, MOIS_ET_ANNEE) { |m| lecture.dates << [m[2].to_i, numero_du_mois(m[1]), nil, m[0]] }
      relever(lecture, TELEPHONE) { |m| lecture.telephones << [m[0].sub(/\A\+33\s?/, '0').delete('^0-9'), m[0]] }
      relever(lecture, JOUR_SEUL) { |m| lecture.dates << [nil, nil, m[1].to_i, m[0]] }
      relever(lecture, HORAIRE) { |m| lecture.horaires << [m[1].to_i, m[2].to_i, false, m[0]] }
      relever(lecture, HEURE_RONDE) { |m| lecture.horaires << [m[1].to_i, 0, true, m[0]] }
      relever(lecture, NOMBRE) { |m| lecture.nombres << ["#{m[1].delete(' ')}.#{m[2] || 0}".to_f, m[3].present?, m[0].strip] }
      lecture
    end

    def relever(lecture, motif)
      lecture.reste = lecture.reste.gsub(motif) do
        yield Regexp.last_match
        ' '
      end
    end

    def numero_du_mois(nom)
      MOIS.index(nom.downcase) + 1
    end

    # Le modèle peut dire « trois agents » d'une liste de trois que l'outil n'a pas comptée.
    def tailles_des_listes(source)
      tailles(JSON.parse(source))
    rescue JSON::ParserError
      []
    end

    def tailles(valeur)
      filles = valeur.is_a?(Hash) ? valeur.values : valeur
      return [] unless filles.is_a?(Array)

      (valeur.is_a?(Array) ? [valeur.size.to_f] : []) + filles.flat_map { |fille| tailles(fille) }
    end

    def date_lue?(annee, mois, jour)
      @dates.any? do |annee_lue, mois_lu, jour_lu|
        (mois.nil? || mois_lu == mois) && (jour.nil? || jour_lu == jour) && (annee.nil? || annee_lue.nil? || annee_lue == annee)
      end
    end

    # Une durée lue en heures décimales peut être redite en heures et minutes : 2,72 heures, 2 h 43.
    def horaire_lu?(heure, minute, ronde)
      @horaires.any? { |heure_lue, minute_lue| heure_lue == heure && minute_lue == minute } ||
        nombre_lu?(heure + (minute / 60.0), ronde ? 0.005 : 0.01)
    end

    def nombre_admis?(valeur, pourcentage)
      nombre_lu?(valeur) || (pourcentage && nombre_lu?(valeur / 100)) ||
        ((1900..2100).cover?(valeur) && @dates.any? { |annee_lue, _| annee_lue == valeur })
    end

    def nombre_lu?(valeur, ecart = 0.005)
      @nombres.any? { |lu| (lu - valeur).abs < ecart }
    end

    def noms_absents(reste)
      absents = []
      reste.scan(MOT) do |mot|
        debut = Regexp.last_match.pre_match
        parties = mot.split(/['’-]/).select { |partie| partie.length > 1 && partie.match?(/\A[[:upper:]]/) }
        next if parties.empty? || (mot != mot.upcase && debut.match?(DEBUT_DE_PHRASE))

        absents << mot unless parties.all? { |partie| @mots.include?(I18n.transliterate(partie).downcase) }
      end
      absents
    end
  end
end
