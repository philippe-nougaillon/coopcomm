# frozen_string_literal: true

require 'test_helper'

class TransformToPdfPolicesTest < ActiveSupport::TestCase
  setup do
    @document = Prawn::Document.new
  end

  test 'le document embarque Google Sans Flex dans ses quatre styles' do
    TransformToPdf::Polices.call(@document)
    %i[normal bold italic bold_italic].each { |style| @document.text 'Intervention', style: style }

    assert_equal %w[GoogleSansFlex-Bold GoogleSansFlex-BoldItalic GoogleSansFlex-Italic GoogleSansFlex-Regular],
                 polices_embarquées(@document)
  end

  test 'un caractère absent de Google Sans Flex est imprimé avec DejaVu Sans' do
    TransformToPdf::Polices.call(@document)
    @document.text 'Tonte → débroussaillage'

    assert_equal %w[DejaVuSans GoogleSansFlex-Regular], polices_embarquées(@document)
  end

  private

  # Prawn préfixe chaque sous-ensemble embarqué de six caractères et d'un « + ».
  def polices_embarquées(document)
    PDF::Reader.new(StringIO.new(document.render)).pages.flat_map { |page| page.fonts.values }
               .map { |police| police[:BaseFont].to_s.sub(/\A\w{6}\+/, '') }.uniq.sort
  end
end
