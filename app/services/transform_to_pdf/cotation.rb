# frozen_string_literal: true
# TODO : Unifier ce fichier avec celui des commandes et des factures
module TransformToPdf
  # Génère un PDF de la cotation
  class Cotation < ApplicationService
    include Prawn::View
    include ActionView::Helpers::NumberHelper

    require 'prawn/table'

    def initialize(cotation)
      super()

      @cotation = cotation

      # Les polices intégrées de Prawn gèrent les accents français (Windows-1252) ;
      # on masque l'avertissement m17n non bloquant.
      Prawn::Fonts::AFM.hide_m17n_warning = true
      @margin_down = 15
      @image_path = "#{Rails.root}/app/assets/images"
      @logo = "#{@image_path}/Logo_CC_MAd_et_Moselle.jpg"
    end

    # Construit le PDF du devis. Retourne self (render appelé par le contrôleur).
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

    def add_header
      image @logo, height: 80, position: :right if File.exist?(@logo)
      text "Cotation / Devis n°#{@cotation.ref}", size: 16, style: :bold
      move_down 10
      stroke_horizontal_rule
      move_down 20
    end

    # Informations d'en-tête
    def add_metadata
      livraison = @cotation.date_livraison_souhaitée ? I18n.l(@cotation.date_livraison_souhaitée, format: :long).capitalize : '—'

      data = [
        ['Le :', I18n.l(@cotation.updated_at, format: :long).capitalize],
        ['Réf :', @cotation.ref.to_s],
        ['Statut :', @cotation.workflow_state.to_s.humanize],
        ['Adhérent :', @cotation.adherent&.nom_prénom.to_s.capitalize],
        ['Service :', @cotation.service&.nom.to_s.capitalize],
        ['Intitulé :', @cotation.intitulé.to_s.capitalize],
        ['Livraison souhaitée :', livraison],
        ['Total HT :', number_to_currency(@cotation.total_ht || 0)]
      ]

      table(data, cell_style: { border_width: 0, padding: 4 }) do
        column(0).font_style = :bold
        column(0).width = 150
      end

      move_down 20
    end

    # Détail des prestations
    def add_lignes
      text 'Prestations', size: 14, style: :bold
      move_down 10

      header = [['Code', 'Intitulé', 'Prix HT', 'Qté', 'Total HT']]
      rows = @cotation.cotation_lignes.includes(:prestation).map do |ligne|
        # 1. On récupère le texte d'abord
        intitule_texte = ligne.intitulé.presence || ligne.prestation&.libellé

        [
          # 2. Safe operator &.capitalize pour le code (si jamais code est nil)
          ligne.prestation&.code,

          # 3. .to_s.capitalize pour l'intitulé
          intitule_texte.to_s.capitalize,

          number_to_currency(ligne.prix_ht),
          ligne.qté,
          number_to_currency(ligne.total_ht)
        ]
      end

      w = bounds.width

      table(header + rows, header: true, width: w, cell_style: { padding: 6, size: 9 }) do |t|
        t.row(0).font_style = :bold
        t.row(0).background_color = 'EEEEEE'

        # Alignements
        t.column(3).align = :center
        t.columns(2..4).align = :right

        # Répartition des largeurs via l'argument du bloc `t`
        t.column_widths = [w * 0.30, w * 0.30, w * 0.15, w * 0.10, w * 0.15]

        # Sécurité pour les codes très longs
        t.column(0).style do |cell|
          cell.overflow = :shrink_to_fit
          cell.min_font_size = 6
        end
      end

      move_down 10
      text "Total HT : #{number_to_currency(@cotation.total_ht || 0)}", size: 12, style: :bold, align: :right
    end

    def add_memo
      return if @cotation.mémo.blank?

      move_down 20
      text 'Mémo', size: 14, style: :bold
      move_down 5
      text @cotation.mémo.to_s, align: :justify, size: 10
    end

    def add_signature
      return if @cotation.signature.blank?

      move_down 25
      text 'Signature', size: 14, style: :bold
      move_down 5

      svg Base64.decode64(@cotation.signature.split(',')[1]), width: 100

      move_down 5
      mention = "Signé par #{@cotation.adherent&.nom_prénom}"
      mention += " le #{I18n.l(@cotation.signee_le.to_date, format: :long)}" if @cotation.signee_le.present?
      text mention, size: 10, style: :italic
    end

    # Pied de page
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