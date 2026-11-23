# frozen_string_literal: true

module Aibbo
  # Ce qu'AÏBBO lit des conventions : la liste que l'utilisateur ouvre déjà, avec les heures du bloc « Suivi des heures » de l'accueil.
  class OutilConventions < Outil
    LIGNES = 30

    description "Donne les conventions que l'utilisateur voit dans CoopComm. Une convention fixe, pour un adhérent et un service, " \
                "un nombre d'heures conventionnées par année civile. Par convention : sa référence, l'adhérent, le service, la période " \
                "(sans « au » quand elle n'a pas de date de fin), l'année des heures, qui est l'année civile en cours comme sur la liste des conventions, " \
                "les heures conventionnées, les heures consommées (temps de travail des interventions commencées dans l'année), " \
                "les heures planifiées (interventions prévues dans l'année et pas encore commencées), les heures restantes ou le dépassement, " \
                'le taux de consommation, le nom du document et le mémo, avec les totaux des conventions retenues. ' \
                'Tous les filtres sont facultatifs et se cumulent ; la période garde les conventions qui la recouvrent, même en partie. ' \
                "Les #{LIGNES} conventions les plus récentes sont listées. Une clé « erreur » dit ce qu'il faut demander à l'utilisateur."

    parameters do
      string :du, required: false, description: 'Premier jour de la période, au format AAAA-MM-JJ'
      string :au, required: false, description: 'Dernier jour de la période, inclus, au format AAAA-MM-JJ'
      string :service, required: false, description: 'Nom du service, par exemple Technique'
      string :adherent, required: false, description: "Nom de l'adhérent : la commune ou la structure signataire de la convention"
      boolean :depassees, required: false,
                          description: 'Pour ne garder que les conventions dont les heures consommées dépassent les heures conventionnées'
    end

    def name
      'conventions'
    end

    def execute(du: nil, au: nil, service: nil, adherent: nil, depassees: nil)
      conventions = Convention.visible_to(@utilisateur)
      conventions = conventions.where(service: designe(@utilisateur.get_services_by_role, service, 'service')) if service.present?
      if adherent.present?
        adherents = User.where(id: conventions.select(:user_id)).or(User.visible_to(@utilisateur).adhérent)
        conventions = conventions.where(user: designe(adherents, adherent, 'adhérent'))
      end
      conventions = conventions.where(date_fin_prévue: [nil, jour(du).to_date..]) if du.present?
      conventions = conventions.where(date_début: ..jour(au).to_date) if au.present?

      mesurees = ConventionsDeLAnnee.avec_heures(conventions.ordered, Date.current.all_year).preload(document_attachment: :blob)
      mesurees = mesurees.having('COALESCE(SUM(interventions.temps_total), 0) > conventions.heures_conventionnees') if depassees
      retenues = mesurees.to_a
      { total: retenues.size, liste_complète: retenues.size <= LIGNES,
        heures_conventionnées: retenues.sum { |convention| convention.heures_conventionnees.to_f }.round(1),
        heures_consommées: retenues.sum { |convention| convention.consommees.to_f }.round(1),
        heures_planifiées: retenues.sum { |convention| convention.prevues.to_f }.round(1),
        conventions: retenues.first(LIGNES).map { |convention| ligne(convention) } }
    end

    private

    def ligne(convention)
      conventionnees = convention.heures_conventionnees.to_f
      consommees = convention.consommees.to_f.round(1)
      restantes = (conventionnees - consommees).round(1)
      { réf: convention.ref, adhérent: convention.user.nom_prénom.strip, service: convention.service.nom,
        du: convention.date_début.to_s, au: convention.date_fin_prévue&.to_s, année_des_heures: Date.current.year,
        heures_conventionnées: conventionnees, heures_consommées: consommees, heures_planifiées: convention.prevues.to_f.round(1),
        heures_restantes: (restantes unless restantes.negative?), dépassement: (-restantes if restantes.negative?),
        taux_de_consommation: conventionnees.positive? ? ((consommees / conventionnees) * 100).round : 0,
        document: (convention.document.filename.to_s if convention.document.attached?), mémo: convention.mémo.presence }.compact
    end
  end
end
