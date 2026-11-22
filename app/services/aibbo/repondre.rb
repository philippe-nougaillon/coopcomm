# frozen_string_literal: true

module Aibbo
  # Fait répondre AÏBBO à un message : le modèle ne lit les données que par les outils, qui portent le périmètre de l'utilisateur.
  class Repondre < ApplicationService
    Reponse = Struct.new(:texte, :trace)

    MESSAGES_PRECEDENTS = 10
    PAS = 12
    PAS_DE_REPRISE = 6
    PANNE = 'Un problème est survenu avec AÏBBO, veuillez attendre quelques instants et rééssayer.'
    SANS_REPONSE = "Je suis désolé, je n'ai pas trouvé cette information dans CoopComm, ou je n'ai pas bien compris votre question. " \
                   'Pouvez-vous la reformuler ?'
    # Le niveau sans modèle prend celui par défaut, réglable par AIBBO_MODELE.
    NIVEAUX = { 'rapide' => 'mistral-small-2603', 'équilibré' => nil, 'approfondi' => 'mistral-large-4' }.freeze

    def initialize(utilisateur, message, niveau = nil)
      @utilisateur = utilisateur
      @message = message
      @niveau = niveau
    end

    def call
      outils = [OutilInterventions.new(@utilisateur), OutilPersonnes.new(@utilisateur)]
      outils += [OutilMateriel.new(@utilisateur), OutilUtilisationMateriel.new(@utilisateur)] unless @utilisateur.adhérent?
      outils << OutilCrm.new(@utilisateur) unless @utilisateur.agent?
      outils += [OutilDisponibilites.new(@utilisateur), OutilAbsences.new(@utilisateur), OutilFaisabilite.new(@utilisateur)] if @utilisateur.manager_or_admin?
      chat = ChatMistral.call(NIVEAUX[@niveau] || ENV.fetch('AIBBO_MODELE', ChatMistral::MODELE)).with_instructions(consigne).with_tools(*outils)
      messages_precedents.each do |precedent|
        chat.add_message(role: precedent.from_id == @utilisateur.id ? :user : :assistant, content: precedent.message)
      end
      chat.ask_later(@message.message)
      deja_la = chat.messages.size
      derouler(chat, PAS)
      inventions = inventions_de(chat, deja_la)
      if inventions.any?
        chat.add_message(role: :user, content: reprise(inventions))
        derouler(chat, PAS_DE_REPRISE)
        inventions = inventions_de(chat, deja_la)
      end
      gardee = chat.messages.last if chat.complete? && inventions.empty?
      trace = tracer("#{URI(ChatMistral::ADRESSE).host} #{chat.model.id}", chat.messages.drop(deja_la), gardee)
      return Reponse.new(gardee.content.to_s, trace) if gardee

      Reponse.new(SANS_REPONSE, "#{trace}\nréponse remplacée : #{inventions.presence&.to_sentence || 'aucune réponse du modèle'}")
    end

    private

    # Au bout des pas, le modèle doit conclure sans outil plutôt que de laisser l'utilisateur sans réponse.
    def derouler(chat, pas)
      pas.times { chat.step unless chat.complete? }
      return if chat.complete?

      chat.run_tools
      chat.with_tool_options(choice: :none).generate
    end

    def inventions_de(chat, deja_la)
      return [] unless chat.complete?

      echanges = chat.messages.drop(deja_la)
      lus = echanges.select { |message| message.role == :tool }.map(&:content)
      demandes = echanges.select(&:tool_call?).flat_map { |message| message.tool_calls.values.map { |appel| appel.arguments.to_json } }
      deja_dit = messages_precedents.map(&:message) << @message.message
      ReleverInventions.call(chat.messages.last.content, lus + demandes + deja_dit + [@utilisateur.nom_prénom, @utilisateur.rôle])
    end

    def reprise(inventions)
      <<~REPRISE
        Contrôle automatique : ta réponse n'a pas été envoyée. Elle contient des éléments qui ne figurent dans aucun résultat de tes outils : #{inventions.map { |invention| "« #{invention} »" }.to_sentence}.
        Réécris ta réponse en ne gardant que ce que tu as lu dans un résultat, cité tel quel. Si la question suppose une donnée qui n'existe pas, dis qu'il n'y en a pas. Si tu ne peux pas répondre, dis-le.
        Un calcul ou une déduction à partir de ce que tu as lu reste permis, sur une ligne à part qui commence par « Déduction : ».
      REPRISE
    end

    def consigne
      aujourd_hui = Date.current
      lundi = aujourd_hui.beginning_of_week
      mois_dernier = aujourd_hui.prev_month
      jours = ->(dates) { dates.map { |date| "#{I18n.l(date, format: '%A %-d %B')} = #{date}" }.join(' ; ') }
      avis = <<~AVIS if @utilisateur.manager_or_admin?
        - Quand on te demande si un travail est possible, ou qui est disponible pour le faire, appelle faisabilite_chantier sur la période, avec le matériel et le nombre de personnes que ce travail demande, puis réponds jour par jour et recommande les personnes les plus disponibles. Donne un avis franc — oui, oui sous réserve, ou non — et déconseille le travail quand la météo, les heures déjà faites par l'équipe, l'horaire ou la saison y poussent, même si des personnes sont libres. Passe en revue, en une ligne chacun : les personnes, le matériel, les heures de l'équipe, la météo, l'horaire et la saison.
        - Ce que tu sais du métier en général (saison, sécurité, nombre de personnes qu'il faut) s'écrit sur une ligne « Supposition : », sans date ni horaire en chiffres. Dis aussi ce que tu n'as pas pu vérifier.
        - Quand une personne disponible est manager ou administrateur, précise son rôle et préviens que, dans certains services, seuls les agents interviennent.
      AVIS
      <<~CONSIGNE
        Tu es AÏBBO, l'assistant de CoopComm, l'application de suivi des interventions d'une collectivité.
        Tu réponds à #{@utilisateur.nom_prénom.strip}, dont le rôle est #{@utilisateur.rôle}. Nous sommes le #{I18n.l(Time.current, format: '%A %-d %B %Y, %H h %M')}.

        Calendrier — ne calcule jamais une date de tête, lis-la ici :
        - aujourd'hui : #{jours.call([aujourd_hui])}
        - les sept derniers jours : #{jours.call((1..7).map { |n| aujourd_hui - n })}
        - les quatorze prochains jours : #{jours.call((1..14).map { |n| aujourd_hui + n })}
        - une semaine va du lundi au vendredi. Cette semaine, « la semaine » ou « dans la semaine » : du #{lundi} au #{lundi + 4} ; la semaine dernière : du #{lundi - 7} au #{lundi - 3} ; la semaine prochaine : du #{lundi + 7} au #{lundi + 11}
        - ce mois-ci : du #{aujourd_hui.beginning_of_month} au #{aujourd_hui.end_of_month} ; le mois dernier : du #{mois_dernier.beginning_of_month} au #{mois_dernier.end_of_month}
        - « lundi prochain », « mardi », « jeudi » sans autre précision : le premier jour de ce nom dans les quatorze prochains jours.
        - « dans la semaine » et « cette semaine » désignent toujours la semaine en cours, même quand elle s'achève : ne prends la semaine prochaine que si on te la demande.

        - Réponds en français, par des phrases complètes, en vouvoyant.
        - Ne donne jamais un chiffre, un nom ou une date que tu n'as pas lu dans le résultat d'un outil : rappelle l'outil pour chaque nouvelle donnée, même quand la question prolonge la précédente.
        - Tes outils ne rendent que ce que cette personne a le droit de voir dans CoopComm. Si aucun outil ne peut répondre, dis que tu n'as pas accès à cette information, sans la deviner.
        - Si un outil rend une erreur ou plusieurs possibilités, demande une précision au lieu de choisir.
        - Une question qui prolonge la précédente (« fais pareil pour… », « et le mois d'avant ? ») reprend ses filtres.
        - N'invente jamais rien : ni intervention, ni date, ni horaire, ni nom, ni nombre. Si la question suppose une donnée que le résultat ne contient pas (« la suivante », « l'autre »), dis qu'il n'y en a pas. Si tu ne comprends pas la question, dis-le et demande de la reformuler.
        - Cite les dates, les horaires, les nombres et les noms tels que tu les as lus. Ce que tu calcules, déduis ou supposes à partir de ce que tu as lu s'écrit sur une ligne à part, qui commence par « Déduction : » ou par « Supposition : ».
        - Chaque réponse est contrôlée avant d'être envoyée : une date, un horaire, un nombre ou un nom absent des résultats de tes outils la fait refuser.
        - Si on te demande ce que tu sais faire, décris en quelques phrases ce que tes outils permettent de consulter, sans exemple de nom, de date ni de chiffre.
        - Une commune, une ville, un village ou une mairie désigne un adhérent : le compte d'un adhérent porte le nom de sa commune. Cherche ce nom parmi les adhérents.
        - Le matériel n'est ni chez les adhérents ni dans les mairies : il est rangé dans les entrepôts de l'organisation, où les agents passent le prendre avant d'intervenir.
        #{avis}
      CONSIGNE
    end

    def messages_precedents
      aibbo = ENV['UUID_AIBOT']
      Message.where(from_id: @utilisateur.id, to_id: aibbo).or(Message.where(from_id: aibbo, to_id: @utilisateur.id))
             .message.where(created_at: ...@message.created_at).where.not(message: PANNE)
             .order(created_at: :desc).limit(MESSAGES_PRECEDENTS).reverse
    end

    def tracer(entete, echanges, gardee)
      lignes = echanges.flat_map do |message|
        if message.tool_call?
          message.tool_calls.values.map { |appel| "appel #{appel.name} #{appel.arguments.to_json}" }
        elsif message.role == :tool
          "résultat #{message.content.to_s.truncate(600)}"
        elsif message.role == :user
          "contrôle #{message.content.to_s.squish.truncate(600)}"
        elsif message.equal?(gardee)
          []
        else
          "réponse écartée #{message.content.to_s.squish.truncate(600)}"
        end
      end
      [entete, *lignes.presence || 'aucun outil appelé'].join("\n")
    end
  end
end
