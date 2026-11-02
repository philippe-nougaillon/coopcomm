# frozen_string_literal: true

module DashboardHelper
  # Filtres des cartes du tableau de bord, au widget des index : sans `name`, rien n'est envoyé et le script relit
  # la valeur ; avec, le formulaire de la carte l'envoie au contrôleur. La première option est le choix par défaut.
  def filtre_graphe(carte, filtre, options, choix = nil, **html)
    tag.div(tag.select(options_for_select(options, choix),
                       **{ id: "filtre-#{filtre}-#{carte}", class: 'w-full h-10',
                           data: { carte: carte, filtre: filtre, controller: 'slim-select', placeholder: options.first.first } }.merge(html)),
            class: 'flex-1 sm:flex-none sm:w-48')
  end

  def filtre_services_graphe(carte, services, choix = nil, **html)
    return if services.size <= 1

    filtre_graphe(carte, 'services', [['Services : hérités', '']] + services.map { |nom| [nom, nom] }, choix, **html)
  end

  # Les « N derniers mois » s'arrêtent au mois courant : la fenêtre par défaut court sur trois mois à venir.
  def filtre_periode_graphe(carte, mois, choix = nil, **html)
    passes = mois.select { |m| m <= Date.current.strftime('%Y-%m') }.presence || mois
    filtre_graphe(carte, 'periode',
                  [['Période globale', '']] +
                  [12, 6, 3].select { |nombre| passes.size > nombre }.map { |nombre| ["#{nombre} derniers mois", nombre] },
                  choix, **html)
  end

  # Infobulles ApexCharts aux couleurs du thème, comme les gabarits daisyUI Charts.
  def classes_graphe
    '[&_.apexcharts-tooltip]:bg-base-100! [&_.apexcharts-tooltip]:border-base-content/10! ' \
      '[&_.apexcharts-tooltip]:shadow-xl! [&_.apexcharts-tooltip]:rounded-box! [&_.apexcharts-svg]:outline-none'
  end

  def classes_carte
    'bg-base-100 border border-base-200 rounded-2xl shadow-sm hover:shadow-md transition-shadow'
  end
end