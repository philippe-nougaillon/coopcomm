# frozen_string_literal: true

module Aibbo
  # Ce qu'AÏBBO lit pour dire si un travail est faisable : jour par jour, les personnes libres, le matériel demandé, la météo et la charge.
  class OutilFaisabilite < Outil
    JOURS = 14
    NOMS = 8
    CATALOGUE = 100

    description 'Dit, jour par jour sur une période, si un travail est faisable, et qui est disponible pour le faire : ' \
                'les intervenants libres toute la journée ou une demi-journée (agents, managers et administrateurs, avec leur rôle, ' \
                'et leur service quand plusieurs services sont regardés), ' \
                'ce qui retient les autres, le classement des personnes les plus disponibles sur la période, ' \
                "l'état de chaque matériel demandé (libre, réservé, en panne ou pris par une intervention) et ce que dit sa fiche, " \
                "la météo prévue le matin et l'après-midi, et les heures de travail de l'équipe par semaine. " \
                'Les jours déjà passés ne sont pas étudiés. Un matériel demandé sous un nom inconnu est signalé, avec le nom des matériels existants. ' \
                "Une clé « erreur » dit ce qu'il faut demander à l'utilisateur."

    parameters do
      string :du, required: false,
                  description: 'Premier jour de la période, au format AAAA-MM-JJ, même déjà passé : pour « dans la semaine » ou « cette semaine », ' \
                               "le lundi de la semaine en cours ; sans lui, aujourd'hui"
      string :au, required: false,
                  description: 'Dernier jour, inclus, au format AAAA-MM-JJ ; sans lui, le vendredi de la semaine du premier jour'
      integer :personnes, required: false, description: 'Nombre de personnes à réunir en même temps ; sans lui, une seule'
      array :materiels, of: :string, required: false,
                        description: "Noms, entiers ou partiels, des matériels nécessaires : l'un de ceux qui portent ce nom doit être libre"
      string :service, required: false,
                       description: "Nom du service qui ferait le travail, par exemple Technique ; sans lui, tous les services de l'utilisateur"
      string :adherent, required: false,
                        description: "Nom de l'adhérent — la commune, la mairie ou la structure — pour qui le travail se fait : " \
                                     'seuls les services auxquels il adhère sont regardés'
    end

    def name
      'faisabilite_chantier'
    end

    def execute(du: nil, au: nil, personnes: nil, materiels: nil, service: nil, adherent: nil)
      aujourd_hui = Date.current
      debut = du.present? ? jour(du).to_date : aujourd_hui
      fin = au.present? ? jour(au).to_date : [debut.beginning_of_week + 4, debut].max
      raise Refus, 'Le dernier jour ne peut pas précéder le premier.' if fin < debut
      raise Refus, "Cette période est passée : un travail se prévoit à partir d'aujourd'hui." if fin < aujourd_hui

      etudies = ([debut, aujourd_hui].max..fin).to_a
      raise Refus, "La période ne peut pas dépasser #{JOURS} jours." if etudies.size > JOURS

      services = @utilisateur.get_services_by_role
      services = services.where(id: designe(services, service, 'service')) if service.present?
      if adherent.present?
        commune = designe(User.visible_to(@utilisateur).adhérent, adherent, 'adhérent')
        services = services.where(id: commune.service_ids)
        raise Refus, "#{commune.nom_prénom.strip} n'adhère à aucun des services regardés." if services.none?
      end
      besoin = [personnes.to_i, 1].max
      intervenants = User.visible_to(@utilisateur).intervenants_pour(services).ordered.includes(:services).to_a
      regardes = services.map(&:nom)
      fiche = lambda do |personne|
        { nom: personne.nom_prénom.strip, rôle: personne.rôle, services: (personne.services.map(&:nom) & regardes if regardes.many?) }.compact
      end

      lundis = (etudies.first.beginning_of_week..etudies.last).step(7).to_a
      occupations = Intervention.joins(:agent_interventions).where(agent_interventions: { agent_id: intervenants.map(&:id) })
                                .where(Intervention::OVERLAP_SQL, debut: lundis.first.beginning_of_day, fin: (lundis.last + 6).end_of_day)
                                .select('interventions.*, agent_interventions.agent_id AS agent_occupe_id').group_by(&:agent_occupe_id)
      absences = Absence.where(user_id: intervenants.map(&:id)).where('du <= ? AND au >= ?', etudies.last, etudies.first).group_by(&:user_id)

      charge = Hash.new(0.0)
      occupations.each do |agent_id, interventions|
        interventions.each do |intervention|
          next unless intervention.effective_début && intervention.effective_fin

          charge[[agent_id, intervention.effective_début.to_date.beginning_of_week]] +=
            (intervention.effective_fin - intervention.effective_début).seconds.in_hours - (intervention.fin ? intervention.temps_de_pause.to_f : 0)
        end
      end
      heures = ->(personne) { lundis.sum { |lundi| charge[[personne.id, lundi]] }.round(1) }

      retenues = etudies.index_with do |quand|
        intervenants.index_with { |personne| retenues_du_jour(quand, occupations[personne.id].to_a, absences[personne.id].to_a) }
      end
      libres_le = ->(personne) { etudies.select { |quand| retenues[quand][personne].all?(&:empty?) } }
      a_demi_le = ->(personne) { etudies.select { |quand| retenues[quand][personne].one?(&:empty?) } }
      classes = intervenants.each_with_index.sort_by do |personne, rang|
        [-libres_le.call(personne).size, -a_demi_le.call(personne).size, heures.call(personne), rang]
      end.map(&:first)

      connus, inconnus = Array(materiels).compact_blank.uniq.partition { |nom| Tool.visible_to(@utilisateur).by_nom(nom).exists? }
      demandes = connus.index_with do |nom|
        OutilMateriel.new(@utilisateur).execute(du: etudies.first.to_s, au: etudies.last.to_s, nom: nom)[:matériel]
      end
      fiches = connus.flat_map { |nom| Tool.visible_to(@utilisateur).by_nom(nom).ordered.to_a }.uniq.select { |materiel| materiel.description.present? }
      previsions = MeteoConceptConnexion.call

      { du: debut.to_s, au: fin.to_s, jours_passés_non_étudiés: (etudies.first - debut).to_i.nonzero?,
        services: regardes, adhérent: commune&.nom_prénom&.strip, personnes_demandées: besoin, intervenants: intervenants.size,
        fiches_du_matériel: fiches.map { |materiel| { nom: materiel.name, fiche: materiel.description } }.presence,
        matériel_introuvable: ({ demandés: inconnus, matériel_existant: Tool.visible_to(@utilisateur).ordered.limit(CATALOGUE).pluck(:name) } if inconnus.any?),
        prévisions_météo_pour: previsions&.dig('city', 'name'),
        heures_de_l_équipe_par_semaine: lundis.map do |lundi|
          de_la_semaine = intervenants.map { |personne| charge[[personne.id, lundi]] }
          { semaine_du: lundi.to_s, heures_prévues_ou_réalisées: de_la_semaine.sum.round(1),
            moyenne_par_intervenant: (de_la_semaine.sum / [de_la_semaine.size, 1].max).round(1), maximum_pour_une_personne: de_la_semaine.max.to_f.round(1) }
        end,
        les_plus_disponibles: classes.first(NOMS).map do |personne|
          fiche.call(personne).merge(jours_libres: libres_le.call(personne).size,
                                     libre_les: libres_le.call(personne).map { |quand| I18n.l(quand, format: '%A %-d %B') },
                                     demi_journées_libres: a_demi_le.call(personne).size, heures_prévues_ou_réalisées: heures.call(personne))
        end,
        jours: etudies.map do |quand|
          libres = classes.select { |personne| retenues[quand][personne].all?(&:empty?) }
          a_demi = classes.select { |personne| retenues[quand][personne].one?(&:empty?) }
          materiel = demandes.map do |nom, lignes|
            du_jour = lignes.select { |ligne| ligne[:date] == quand.to_s }
            { demandé: nom, libre: du_jour.any? { |ligne| ligne[:état] == 'libre' }, matériels: du_jour.map { |ligne| ligne.except(:date) } }
          end
          { jour: I18n.l(quand, format: '%A %-d %B %Y'), date: quand.to_s, jour_ouvré: quand.on_weekday?,
            libres_toute_la_journée: { agents: libres.count(&:agent?), managers_et_administrateurs: libres.count(&:manager_or_admin?),
                                       les_plus_disponibles: libres.first(NOMS).map { |personne| fiche.call(personne) } },
            libres_une_demi_journée: a_demi.first(NOMS).map do |personne|
              matin, apres_midi = retenues[quand][personne]
              fiche.call(personne).merge(libre: matin.empty? ? 'le matin' : "l'après-midi", retenu_par: matin + apres_midi)
            end,
            indisponibles: intervenants.size - libres.size - a_demi.size,
            assez_de_personnes: libres.size >= besoin, assez_d_agents_sans_manager_ni_administrateur: libres.count(&:agent?) >= besoin,
            matériel: materiel.presence, tout_le_matériel_libre: (materiel.all? { |ligne| ligne[:libre] } if materiel.any?),
            météo: meteo(previsions, (quand - aujourd_hui).to_i) }.compact
        end }.compact
    end

    private

    # Ce qui retient une personne le matin, puis l'après-midi ; 12 h appartient à l'après-midi, comme pour une absence.
    def retenues_du_jour(quand, interventions, absences)
      absence = absences.find { |candidate| (candidate.du..candidate.au).cover?(quand) }
      [[quand.beginning_of_day, quand.middle_of_day], [quand.middle_of_day, quand.end_of_day]].map do |de, a|
        raisons = interventions.filter_map do |intervention|
          depart = intervention.effective_début
          arrivee = intervention.effective_fin || depart
          next unless depart == arrivee ? depart >= de && depart < a : depart < a && arrivee > de

          "intervention du #{horodatage(depart)} au #{horodatage(arrivee)}"
        end
        raisons << "absence (#{absence.résumé.values_at('période', 'motif').compact.join(', ')})" if absence&.couvre?(de, a)
        raisons
      end
    end

    def meteo(previsions, echeance)
      return 'prévision indisponible' unless previsions

      periodes = previsions.dig('forecast', echeance)
      return 'pas de prévision à cette échéance' unless periodes

      { matin: periodes[1], après_midi: periodes[2] }.compact.transform_values do |prevision|
        { temps: MeteoConceptConnexion.WEATHER[prevision['weather']], température_en_degrés: prevision['temp2m'],
          vent_en_km_h: prevision['wind10m'], rafales_en_km_h: prevision['gust10m'],
          risque_de_pluie_en_pourcent: prevision['probarain'], risque_de_gel_en_pourcent: prevision['probafrost'] }
      end
    end
  end
end
