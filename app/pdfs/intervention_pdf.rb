# frozen_string_literal: true

# TODO VU : déplacer dans un service
# OK, à mettre avec les autres fichier _pdf, dans un dossier "pdf" créé dans les services, pareil pour les "xls"

class InterventionPdf
  include Prawn::View
  include ActionView::Helpers::NumberHelper
  include Rails.application.routes.url_helpers

  require 'prawn/qrcode'

  # Taille et orientation du document par défaut
  # def document
  #   @document ||= Prawn::Document.new(page_size: 'A4', page_layout: :landscape)
  # end

  # Couleurs du dégradé du cadre (bleu → rouge, repris de la charte Mad & Moselle)
  FRAME_COLOR_START = '2E9BD6'
  FRAME_COLOR_END   = 'A01C2E'

  def initialize
    super()
    # Assests à récupérer si besoin dans un autre projet
    # self.font_families.update("OpenSans" => {
    #   :normal => Rails.root.join("vendor/assets/fonts/Open_Sans/static/OpenSans/OpenSans-Regular.ttf"),
    #   :italic => Rails.root.join("vendor/assets/fonts/Open_Sans/static/OpenSans/OpenSans-Italic.ttf"),
    #   :bold => Rails.root.join("vendor/assets/fonts/Open_Sans/static/OpenSans/OpenSans-Bold.ttf"),
    #   :bold_italic => Rails.root.join("vendor/assets/fonts/Open_Sans/static/OpenSans/OpenSans-BoldItalic.ttf")
    # })

    # Les polices intégrées de Prawn gèrent les accents français (Windows-1252) ;
    # on masque l'avertissement m17n non bloquant.
    Prawn::Fonts::AFM.hide_m17n_warning = true
    @margin_down = 15
    @image_path = "#{Rails.root}/app/assets/images"
    @logo_organisation = "#{@image_path}/Logo_CC_MAd_et_Moselle.jpg"
    @logo_coopcomm = "#{@image_path}/CoopComm.png"
  end

  def pointeuse_qrcode(intervention)
    @intervention = intervention
    add_logo
    add_title
    add_qr_code
    add_footer
  end

  private

  # Logo de l'organisation, centré en haut de la page.
  def add_logo
    move_down @margin_down
    image @logo_organisation, width: 90, position: :center if File.exist?(@logo_organisation)
    move_down @margin_down * 4
  end

  # Nom de l'intervention en gros et gras, suivi de l'invite « Scanner pour accéder ».
  def add_title
    text @intervention.description.to_s.upcase, align: :center, size: 30, style: :bold
    move_down 6
    text 'Scanner pour accéder', align: :center, size: 14, style: :bold, color: '888888'
    move_down @margin_down * 2
  end

  # QR code centré, entouré d'un cadre dégradé bleu → rouge avec marge blanche.
  def add_qr_code
    qrcode_content = pointer_intervention_url(@intervention,
                                              host: Rails.application.config.default_url_options[:host]).to_s
    qrcode = RQRCode::QRCode.new(qrcode_content)

    qr_size = 280       # Côté du QR code en points
    padding = 16        # Marge blanche entre le QR code et le cadre
    border  = 10        # Épaisseur du cadre dégradé
    inner   = qr_size + (2 * padding)
    outer   = inner + (2 * border)

    x_outer = (bounds.width - outer) / 2.0
    y_top   = cursor

    # Cadre dégradé (bleu à gauche → rouge à droite)
    fill_gradient from: [x_outer, y_top], to: [x_outer + outer, y_top],
                  stops: [FRAME_COLOR_START, FRAME_COLOR_END]
    fill_rectangle [x_outer, y_top], outer, outer

    # Fond blanc intérieur
    fill_color 'FFFFFF'
    fill_rectangle [x_outer + border, y_top - border], inner, inner
    fill_color '000000'

    # QR code centré sur le fond blanc
    qr_x = x_outer + border + padding
    qr_y = y_top - border - padding
    render_qr_code(qrcode, pos: [qr_x, qr_y], extent: qr_size, stroke: false, margin: 2)

    move_cursor_to y_top - outer
  end

  # Pied de page : date de création (gauche) et logo CoopComm (droite).
  def add_footer
    date = I18n.l(Date.current, format: :long)
    footer_height = 45
    bounding_box([0, footer_height], width: bounds.width, height: footer_height) do
      stroke_color 'CCCCCC'
      stroke_horizontal_rule
      move_down 12
      text_box "Créé le #{date}", at: [0, cursor], width: bounds.width / 2,
                                   size: 10, style: :bold, color: '888888'
      if File.exist?(@logo_coopcomm)
        logo_width = 130
        image @logo_coopcomm, at: [bounds.width - logo_width, cursor + 6], width: logo_width
      end
    end
  end
end
