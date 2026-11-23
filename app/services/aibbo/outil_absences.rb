# frozen_string_literal: true

module Aibbo
  # Ce qu'AÏBBO lit des absences : celles des comptes dont l'utilisateur peut ouvrir la fiche.
  class OutilAbsences < Outil
    LIGNES = 50

    description "Donne les absences sur une période : à un manager ou à un administrateur, celles des personnes de ses services ; " \
                "à un agent, les siennes seules, jamais celles de ses collègues. Pour chacune : qui, du premier au dernier jour, " \
                "journée entière ou demi-journée, et le motif. Sans période, les #{LIGNES} premières absences connues. " \
                "Une clé « erreur » dit ce qu'il faut demander à l'utilisateur."

    parameters do
      string :du, required: false, description: 'Premier jour de la période, au format AAAA-MM-JJ'
      string :au, required: false, description: 'Dernier jour de la période, inclus, au format AAAA-MM-JJ'
      string :service, required: false, description: 'Nom du service, par exemple Technique'
      string :personne, required: false, description: "Nom, prénom ou les deux de la personne dont on veut les absences"
    end

    def name
      'absences'
    end

    def execute(du: nil, au: nil, service: nil, personne: nil)
      personnes = User.visible_to(@utilisateur)
      personnes = personnes.by_service(designe(@utilisateur.get_services_by_role, service, 'service')) if service.present?
      personnes = personnes.where(id: designe(personnes, personne, 'personne')) if personne.present?

      absences = Absence.where(user_id: personnes.select(:id))
      absences = absences.where(au: jour(du).to_date..) if du.present?
      absences = absences.where(du: ..jour(au).to_date) if au.present?
      total = absences.count
      { total: total, liste_complète: total <= LIGNES,
        absences: absences.includes(:user).order(:du, :id).limit(LIGNES).map do |absence|
          absence.résumé.except('observation').merge('personne' => absence.user.nom_prénom.strip, 'jours' => absence.nb_jours)
        end }
    end
  end
end
