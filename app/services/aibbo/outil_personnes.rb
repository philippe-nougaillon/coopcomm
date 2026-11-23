# frozen_string_literal: true

module Aibbo
  # Ce qu'AÏBBO lit des comptes : ce que leur fiche montre à un manager ou à un administrateur, le nom seul aux autres, comme la messagerie.
  class OutilPersonnes < Outil
    LIGNES = 50

    description "Donne les personnes des services de l'utilisateur. À un manager ou à un administrateur : nom, rôle (adhérent, agent, manager, " \
                "administrateur), services, mail, téléphone, adresse d'un adhérent, étiquettes, mémo et évaluation d'un agent, avec les " \
                "effectifs par rôle et par service. Aux autres comptes : le nom seul des personnes de leurs services, comme dans la messagerie, " \
                "et leur propre fiche. Un nom partiel rend toutes les personnes qui le portent. " \
                "Une clé « erreur » dit ce qu'il faut demander à l'utilisateur."

    parameters do
      string :nom, required: false, description: 'Nom, prénom ou les deux, entiers ou partiels'
      string :service, required: false, description: 'Nom du service, par exemple Technique'
      string :role, required: false, enum: User.rôles.keys, description: 'Pour ne garder que les personnes de ce rôle'
    end

    def name
      'personnes'
    end

    def execute(nom: nil, service: nil, role: nil)
      raise Refus, "Le rôle « #{role} » n'existe pas : #{User.rôles.keys.to_sentence}." if role.present? && User.rôles.keys.exclude?(role)
      return contacts(nom, service, role) unless @utilisateur.manager_or_admin?

      services = @utilisateur.get_services_by_role
      personnes = User.visible_to(@utilisateur)
      personnes = personnes.by_service(designe(services, service, 'service')) if service.present?
      personnes = personnes.where(rôle: role) if role.present?
      personnes = nommees(personnes, nom) if nom.present?

      total = personnes.count
      { total: total, par_rôle: personnes.group(:rôle).count,
        par_service: UserService.where(user_id: personnes.select(:id), service_id: services.select(:id)).joins(:service).group('services.nom').count,
        liste_complète: total <= LIGNES,
        personnes: personnes.includes(:services).ordered.limit(LIGNES).map do |personne|
          fiche(personne).merge(étiquettes: personne.tag_list.presence, mémo: personne.memo.presence, évaluation: evaluation(personne)).compact
        end }
    end

    private

    def contacts(nom, service, role)
      if service.present? || role.present?
        raise Refus, 'Ce compte ne voit des autres personnes que leur nom, comme dans la messagerie : ni leur service, ni leur rôle.'
      end

      personnes = User.by_service(@utilisateur.services).or(User.where(id: @utilisateur.id))
      personnes = nommees(personnes, nom) if nom.present?
      total = personnes.count
      { total: total, liste_complète: total <= LIGNES,
        personnes: personnes.includes(:services).ordered.limit(LIGNES).map do |personne|
          personne == @utilisateur ? fiche(personne) : { nom: personne.nom_prénom.strip }
        end }
    end

    def nommees(personnes, nom)
      personnes = personnes.search_with_generic_name(nom)
      raise Refus, "« #{nom} » est introuvable parmi les personnes que l'utilisateur peut voir." if personnes.none?

      personnes
    end

    def fiche(personne)
      { nom: personne.nom_prénom.strip, rôle: personne.rôle, services: personne.services.map(&:nom).sort,
        mail: personne.email.presence, téléphone: personne.téléphone.presence,
        adresse: (personne.address.presence if personne.adhérent?) }.compact
    end

    def evaluation(personne)
      { moyenne: personne.moyenne.round(2), notes: personne.total_rating } if personne.agent? && personne.rated_interventions.any?
    end
  end
end
