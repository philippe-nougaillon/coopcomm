# frozen_string_literal: true

module TransformToPdf
  class Convention < BasePdfForCrm
    private

    def document_title
      'Convention'
    end

    def add_metadata
      consommes = @record.heures_consommees.round(1)
      prevus = @record.heures_conventionnees.to_f
      taux_consommation = prevus.positive? ? ((consommes / prevus) * 100).round : 0
      depasse = consommes > prevus
      surplus_heures = (consommes - prevus).round(1)

      heures_texte = if depasse
                      "La convention a consommé #{consommes} h sur les #{prevus} h prévues, soit un dépassement de #{surplus_heures} h (#{taux_consommation} %)."
                    else
                      "La convention a consommé #{consommes} h sur les #{prevus} h prévues (#{taux_consommation} %)."
                    end

      data = [
        ['Adhérent :', @record.user&.nom_prénom.to_s.capitalize],
        ['Service :', @record.service&.nom.to_s.capitalize],
        ['Période :', "Du #{I18n.l(@record.date_début, format: :long)} au #{@record.date_fin_prévue ? I18n.l(@record.date_fin_prévue, format: :long) : '—'}"],
        ['Statut de la convention :', periode_statut_texte],
        ['Heures consommées :', heures_texte]
      ]

      table(data, cell_style: { border_width: 0, padding: 4 }) do
        column(0).font_style = :bold
        column(0).width = 150
      end

      move_down 20
    end

    # Reproduit la logique de temps écoulé de convention_progress (helper de vue),
    # non disponible ici puisqu'on est dans un service, pas un contexte de vue.
    def periode_statut_texte
      début = @record.date_début
      fin = @record.date_fin_prévue

      return 'Dates non renseignées.' if début.blank? || fin.blank?

      today = Date.current

      return 'La convention est à venir.' if today < début.to_date
      return 'La convention est expirée.' if today > fin.to_date

      durée_totale = (fin.to_date - début.to_date).to_i
      durée_écoulée = (today - début.to_date).to_i

      percent = durée_totale.positive? ? ((durée_écoulée.to_f / durée_totale) * 100).round : 0

      "#{percent} % du temps total du contrat se sont écoulés."
    end

    def add_lignes
      text 'Interventions', size: 14, style: :bold
      move_down 10

      interventions = @record.interventions

      if interventions.blank?
        text 'Aucune intervention enregistrée sur cette période.', size: 10, style: :italic, color: '999999'
        return
      end

      header = [['Description', 'Début', 'Fin', 'Temps total (H)']]

      rows = interventions.map do |i|
        [
          i.description.to_s,
          i.début ? I18n.l(i.début, format: :long) : '—',
          i.fin ? I18n.l(i.fin, format: :long) : '—',
          number_with_precision(i.temps_total, precision: 2)
        ]
      end

      w = bounds.width

      table(header + rows, header: true, width: w, cell_style: { padding: 6, size: 9 }) do |t|
        t.row(0).font_style = :bold
        t.row(0).background_color = 'EEEEEE'

        t.column(3).align = :right

        t.column_widths = [w * 0.29, w * 0.28, w * 0.28, w * 0.15]
      end
    end
  end
end