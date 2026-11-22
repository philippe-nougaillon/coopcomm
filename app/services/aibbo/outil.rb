# frozen_string_literal: true

module Aibbo
  # Socle des outils d'AÏBBO : l'utilisateur qui pose la question, et les refus que le modèle doit lui renvoyer.
  class Outil < RubyLLM::Tool
    class Refus < StandardError; end

    DEJA_DEMANDE = "Cette demande a déjà reçu sa réponse dans cette conversation, elle ne changera pas. Réponds à l'utilisateur avec ce " \
                   "que tu as lu, ou dis-lui que tu n'as rien trouvé."

    def initialize(utilisateur)
      super()
      @utilisateur = utilisateur
    end

    def call(tool_call: nil, **demande)
      return { deja_demande: DEJA_DEMANDE } if (@demandes ||= []).include?(demande)

      @demandes << demande
      super
    rescue Refus => e
      { erreur: e.message }
    end

    private

    def jour(texte)
      Date.iso8601(texte).in_time_zone if texte.present?
    rescue Date::Error
      raise Refus, "La date « #{texte} » est illisible : le format attendu est AAAA-MM-JJ."
    end

    def instant(texte)
      Time.zone.parse(texte.to_s) || raise(ArgumentError)
    rescue ArgumentError
      raise Refus, "L'horaire « #{texte} » est illisible : le format attendu est AAAA-MM-JJ HH:MM."
    end

    def horodatage(instant)
      instant&.in_time_zone&.strftime('%Y-%m-%d %H:%M')
    end

    def designe(candidats, texte, quoi)
      trouves = if candidats.klass == User
                  candidats.search_with_generic_name(texte)
                else
                  candidats.where('unaccent(services.nom) ILIKE unaccent(?)', "%#{Service.sanitize_sql_like(texte.strip)}%")
                end.to_a
      exacts = trouves.select { |trouve| I18n.transliterate(libelle(trouve)).casecmp?(I18n.transliterate(texte.strip)) }
      trouves = exacts if exacts.one?
      return trouves.first if trouves.one?
      raise Refus, "« #{texte} » est introuvable parmi les #{quoi}s que l'utilisateur peut voir." if trouves.empty?

      raise Refus, "Plusieurs #{quoi}s correspondent à « #{texte} » : #{trouves.map { |trouve| libelle(trouve) }.sort.to_sentence}. " \
                   "Demandez à l'utilisateur de préciser."
    end

    def libelle(enregistrement)
      enregistrement.is_a?(User) ? enregistrement.nom_prénom.strip : enregistrement.nom
    end
  end
end
