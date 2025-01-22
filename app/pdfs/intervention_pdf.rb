class InterventionPdf
  include Prawn::View
  include ActionView::Helpers::NumberHelper
  include Rails.application.routes.url_helpers

  require 'prawn/qrcode'
  
  # Taille et orientation du document par défaut
  # def document
  #   @document ||= Prawn::Document.new(page_size: 'A4', page_layout: :landscape)
  # end

  def initialize
    super()
    # Assests à récupérer si besoin dans un autre projet
    # self.font_families.update("OpenSans" => {
    #   :normal => Rails.root.join("vendor/assets/fonts/Open_Sans/static/OpenSans/OpenSans-Regular.ttf"),
    #   :italic => Rails.root.join("vendor/assets/fonts/Open_Sans/static/OpenSans/OpenSans-Italic.ttf"),
    #   :bold => Rails.root.join("vendor/assets/fonts/Open_Sans/static/OpenSans/OpenSans-Bold.ttf"),
    #   :bold_italic => Rails.root.join("vendor/assets/fonts/Open_Sans/static/OpenSans/OpenSans-BoldItalic.ttf")
    # })

    @margin_down = 15
    @image_path =  "#{Rails.root}/app/assets/images/"
  end

  def pointeuse_qrcode(intervention)
    qrcode_content = "#{pointer_intervention_url(intervention, host: Rails.application.config.default_url_options[:host])}"
    qrcode = RQRCode::QRCode.new(qrcode_content)

    move_down @margin_down * 15
    text "#{intervention.description.upcase}", align: :center
    move_down @margin_down
    text "#{intervention.agents.first.nom_prénom}", align: :center
    move_down @margin_down * 3

    qr_code_size = bounds.width / 2 # Taille du QR code (moitié de la largeur du conteneur)
    x_position = (bounds.width - qr_code_size) / 2 # Position horizontale pour centrer
    render_qr_code(qrcode, pos: [x_position, cursor], extent: qr_code_size)

  end
end