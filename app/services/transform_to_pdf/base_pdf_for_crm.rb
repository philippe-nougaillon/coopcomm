# frozen_string_literal: true

module TransformToPdf
  # Classe mère générique pour tous les documents PDF (Cotation, Commande, Facture)
  class BasePdfForCrm < ApplicationService
    include Prawn::View
    include ActionView::Helpers::NumberHelper

    require 'prawn/table'

    def initialize(record)
      super()

      # Renommé en @record pour éviter tout conflit de nom avec le document Prawn de Prawn::View
      @record = record

      # Les polices intégrées de Prawn gèrent les accents français (Windows-1252)
      Prawn::Fonts::AFM.hide_m17n_warning = true
      
      # Chemin vers le logo officiel de l'établissement
      @logo = Rails.root.join('app/assets/images/Logo_CC_MAd_et_Moselle.jpg').to_s
    end

    def call
      add_header
      add_metadata
      add_lignes
      add_memo
      add_signature
      add_footer
      self
    end

    private

    # Doit être surchargé dans les classes filles (ex: "Cotation / Devis", "Commande", "Facture")
    def document_title
      raise NotImplementedError, "#{self.class} doit implémenter la méthode #document_title"
    end

    # Doit être surchargé dans les classes filles (ex: :cotation_lignes, :commande_lignes, :facture_lignes)
    def document_lignes_association
      raise NotImplementedError, "#{self.class} doit implémenter la méthode #document_lignes_association"
    end

    # En-tête du document avec le logo à droite et le titre avec référence
    def add_header
      image @logo, height: 80, position: :right if File.exist?(@logo)
      text "#{document_title} n°#{@record.ref}", size: 16, style: :bold
      move_down 10
      stroke_horizontal_rule
      move_down 20
    end

    # Section des métadonnées (dates, statut, adhérent, service, total)
    def add_metadata
      livraison = @record.date_livraison_souhaitée ? I18n.l(@record.date_livraison_souhaitée, format: :long).humanize : '—'

      data = [
        ['Le :', I18n.l(@record.updated_at, format: :long).humanize],
        ['Réf :', @record.ref.to_s],
        ['Statut :', @record.workflow_state.to_s.humanize],
        ['Adhérent :', @record.adherent&.nom_prénom.to_s.humanize],
        ['Service :', @record.service&.nom.to_s.humanize],
        ['Intitulé :', @record.intitulé.to_s.humanize],
        ['Livraison souhaitée :', livraison],
        ['Total HT :', number_to_currency(@record.total_ht || 0)]
      ]

      table(data, cell_style: { border_width: 0, padding: 4 }) do
        column(0).font_style = :bold
        column(0).width = 150
      end

      move_down 20
    end

    # Tableau des prestations/lignes du document
    def add_lignes
      text 'Prestations', size: 14, style: :bold
      move_down 10

      header = [['Code', 'Intitulé', 'Prix HT', 'Qté', 'Total HT']]
      
      # Appel dynamique de l'association (:cotation_lignes, :commande_lignes, etc.)
      lignes = @record.public_send(document_lignes_association).includes(:prestation)

      rows = lignes.map do |ligne|
        intitule_texte = ligne.intitulé.presence || ligne.prestation&.libellé

        [
          ligne.prestation&.code,
          intitule_texte.to_s.humanize,
          number_to_currency(ligne.prix_ht),
          ligne.qté,
          number_to_currency(ligne.total_ht)
        ]
      end

      w = bounds.width

      table(header + rows, header: true, width: w, cell_style: { padding: 6, size: 9 }) do |t|
        t.row(0).font_style = :bold
        t.row(0).background_color = 'EEEEEE'

        # Alignements des colonnes
        t.column(3).align = :center
        t.columns(2..4).align = :right

        # Répartition des largeurs sur la largeur totale du document
        t.column_widths = [w * 0.30, w * 0.30, w * 0.15, w * 0.10, w * 0.15]

        # Sécurité pour ajuster la taille de police des codes très longs
        t.column(0).style do |cell|
          cell.overflow = :shrink_to_fit
          cell.min_font_size = 6
        end
      end

      move_down 10
      text "Total HT : #{number_to_currency(@record.total_ht || 0)}", size: 12, style: :bold, align: :right
    end

    # Section Mémo optionnelle (masquée si vide)
    def add_memo
      return if @record.mémo.blank?

      move_down 20
      text 'Mémo', size: 14, style: :bold
      move_down 5
      text @record.mémo.to_s, align: :justify, size: 10
    end

    # Section Signature optionnelle (rendue uniquement si une signature SVG est présente)
    def add_signature
      return unless @record.respond_to?(:signature) && @record.signature.present?

      move_down 25
      text 'Signature', size: 14, style: :bold
      move_down 5

      # Décodage du string Base64 transmis par le canvas HTML/JS
      svg Base64.decode64(@record.signature.split(',')[1]), width: 100

      move_down 5

      # Utilisation de la balise HTML <br/> combinée à inline_format: true pour forcer le saut de ligne
      date_str = @record.try(:signee_le).present? ? "<br/>Le #{I18n.l(@record.signee_le.to_date, format: :long)}" : ''

      text "Signé par #{@record.adherent&.nom_prénom}#{date_str}",
           size: 10,
           style: :italic,
           inline_format: true
    end

    # Pied de page répété sur toutes les pages du PDF
    def add_footer
      repeat(:all) do
        move_cursor_to 20
        stroke_horizontal_rule
        move_down 5
        text "Document généré le #{I18n.l(Time.current, format: :long)}", size: 8, align: :center
      end
    end
  end
end