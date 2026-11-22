# frozen_string_literal: true

module Aibbo
  # Ce qu'AÏBBO lit des devis, des commandes et des factures : les listes que l'utilisateur ouvre déjà, aux règles de montant du tableau de bord.
  class OutilCrm < Outil
    LIGNES = 30
    TYPES = { 'devis' => Cotation, 'commande' => Commande, 'facture' => Facture }.freeze
    ETATS = Cotation.workflow_spec.state_names.map(&:to_s).freeze
    REGROUPEMENTS = %w[type etat service adherent mois].freeze

    description "Donne les devis, les commandes et les factures que l'utilisateur voit dans CoopComm, avec leur montant hors taxes. " \
                'Tous les filtres sont facultatifs et se cumulent ; la période porte sur la date de saisie du document. ' \
                "Le résultat porte le nombre et le montant de chaque type, et, comme le tableau de bord, le chiffre d'affaires " \
                '(factures envoyées ou validées) et le prévisionnel (devis et commandes ni brouillons ni refusés). ' \
                "Sans regrouper_par : les #{LIGNES} documents les plus récents ; un document à l'état envoyé porte le jour de son envoi " \
                "et le nombre de jours écoulés depuis. Avec regrouper_par : le nombre et le montant de chaque groupe, le plus élevé d'abord. " \
                "Une clé « erreur » dit ce qu'il faut demander à l'utilisateur."

    parameters do
      string :type, required: false, enum: TYPES.keys, description: 'devis, commande ou facture ; sans lui, les trois'
      string :du, required: false, description: 'Premier jour de saisie, au format AAAA-MM-JJ'
      string :au, required: false, description: 'Dernier jour de saisie, inclus, au format AAAA-MM-JJ'
      string :service, required: false, description: 'Nom du service, par exemple Technique'
      string :adherent, required: false, description: "Nom de l'adhérent : la commune ou la structure destinataire du document"
      string :etat, required: false, enum: ETATS,
                    description: "État du document : « créé » est un brouillon, « envoyé » attend la réponse de l'adhérent"
      integer :envoye_depuis, required: false,
                              description: "Pour ne garder que les documents à l'état envoyé dont l'envoi date d'au moins ce nombre de jours"
      string :regrouper_par, required: false, enum: REGROUPEMENTS, description: 'Regroupement du décompte'
    end

    def name
      'devis_commandes_factures'
    end

    def execute(type: nil, du: nil, au: nil, service: nil, adherent: nil, etat: nil, envoye_depuis: nil, regrouper_par: nil)
      raise Refus, "Le type « #{type} » n'existe pas : #{TYPES.keys.to_sentence}." if type.present? && TYPES.exclude?(type)
      raise Refus, "L'état « #{etat} » n'existe pas : #{ETATS.to_sentence}." if etat.present? && ETATS.exclude?(etat)
      raise Refus, 'Un adhérent ne voit pas les brouillons : ils restent au service qui les prépare.' if etat == Cotation::CREE && @utilisateur.adhérent?
      if regrouper_par.present? && REGROUPEMENTS.exclude?(regrouper_par)
        raise Refus, "Le regroupement « #{regrouper_par} » n'existe pas : #{REGROUPEMENTS.to_sentence}."
      end

      visibles = TYPES.transform_values { |modele| modele.visible_to(@utilisateur).kept }
      service_retenu = designe(Service.where(id: identifiants(visibles, :service_id)), service, 'service') if service.present?
      if adherent.present?
        adherent_retenu = designe(User.where(id: identifiants(visibles, :adherent_id)).or(User.visible_to(@utilisateur).adhérent), adherent, 'adhérent')
      end
      debut = jour(du)&.beginning_of_day
      fin = jour(au)&.end_of_day

      documents = visibles.slice(*(type.presence ? [type] : TYPES.keys)).transform_values do |scope|
        scope = scope.where(created_at: debut..fin) if debut || fin
        scope = scope.where(service: service_retenu) if service_retenu
        scope = scope.where(adherent: adherent_retenu) if adherent_retenu
        etat.present? ? scope.where(workflow_state: etat) : scope
      end
      envois = documents.transform_values { |scope| dates_d_envoi(scope.where(workflow_state: Cotation::ENVOYE)) }
      if envoye_depuis.present?
        limite = Date.current - envoye_depuis.to_i
        documents = documents.to_h do |cle, scope|
          [cle, scope.where(workflow_state: Cotation::ENVOYE, id: envois[cle].select { |_, envoi| envoi <= limite }.keys)]
        end
      end

      resultat = { du: debut&.to_date&.to_s, au: fin&.to_date&.to_s,
                   par_type: documents.transform_values { |scope| { nombre: scope.count, montant_ht: scope.sum(:total_ht).to_f.round(2) } },
                   prévisionnel_devis_ht: documents['devis']&.where&.not(workflow_state: [Cotation::CREE, Cotation::REFUSE])&.sum(:total_ht),
                   prévisionnel_commandes_ht: documents['commande']&.where&.not(workflow_state: [Commande::CREE, Commande::REFUSE])&.sum(:total_ht),
                   chiffre_d_affaires_ht: documents['facture']&.where(workflow_state: [Facture::ENVOYE, Facture::VALIDE])&.sum(:total_ht) }.compact
      %i[prévisionnel_devis_ht prévisionnel_commandes_ht chiffre_d_affaires_ht].each { |cle| resultat[cle] &&= resultat[cle].to_f.round(2) }

      if regrouper_par.present?
        resultat.merge(groupes: groupes(regrouper_par, documents))
      else
        recents = documents.flat_map { |cle, scope| scope.includes(:service, :adherent).order(created_at: :desc).limit(LIGNES).map { |document| [cle, document] } }
                           .max_by(LIGNES) { |_, document| document.created_at }
        resultat.merge(liste_complète: resultat[:par_type].values.sum { |compte| compte[:nombre] } <= LIGNES,
                       documents: recents.map { |cle, document| ligne(cle, document, envois[cle][document.id]) })
      end
    end

    private

    def identifiants(visibles, colonne)
      visibles.values.flat_map { |scope| scope.distinct.pluck(colonne) }
    end

    # Jour de la dernière entrée de chaque document dans l'état envoyé, lu dans son historique : aucune colonne ne le garde.
    def dates_d_envoi(documents)
      Audited::Audit.where(auditable_type: documents.klass.name, auditable_id: documents.select(:id)).order(:created_at)
                    .each_with_object({}) do |audit, envois|
        envois[audit.auditable_id] = audit.created_at.to_date if Array(audit.audited_changes['workflow_state']).last == Cotation::ENVOYE
      end
    end

    def groupes(regrouper_par, documents)
      lignes = documents.flat_map do |cle, scope|
        next [[cle, scope.count, scope.sum(:total_ht).to_f]] if regrouper_par == 'type'

        groupes = case regrouper_par
                  when 'etat' then scope.group(:workflow_state)
                  when 'service' then scope.group(:service_id)
                  when 'adherent' then scope.group(:adherent_id)
                  else scope.group("to_char(#{scope.table_name}.created_at AT TIME ZONE 'UTC' AT TIME ZONE '#{Time.zone.tzinfo.name}', 'YYYY-MM')")
                  end
        montants = groupes.sum(:total_ht)
        groupes.count.map { |groupe, nombre| [groupe, nombre, montants[groupe].to_f] }
      end
      noms = case regrouper_par
             when 'service' then Service.where(id: lignes.map(&:first)).to_h { |service| [service.id, service.nom] }
             when 'adherent' then User.where(id: lignes.map(&:first)).to_h { |personne| [personne.id, personne.nom_prénom.strip] }
             end
      lignes.group_by { |groupe, _, _| noms ? noms[groupe] || 'Compte désactivé' : groupe }.map do |nom, membres|
        { regrouper_par => nom, nombre: membres.sum { |_, nombre, _| nombre }, montant_ht: membres.sum { |_, _, montant| montant }.round(2) }
      end.sort_by { |groupe| regrouper_par == 'mois' ? groupe['mois'] : -groupe[:montant_ht] }
    end

    def ligne(type, document, envoi)
      { type: type, réf: document.ref, intitulé: document.intitulé, état: document.workflow_state, service: document.service&.nom,
        adhérent: document.adherent&.nom_prénom&.strip, montant_ht: document.total_ht.to_f, saisi_le: document.created_at.to_date.to_s,
        livraison_souhaitée: document.date_livraison_souhaitée&.to_s, envoyé_le: envoi&.to_s,
        jours_depuis_l_envoi: envoi && (Date.current - envoi).to_i }.compact
    end
  end
end
