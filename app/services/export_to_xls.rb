class ExportToXls < ApplicationService
  require 'spreadsheet'

  def initialize
    Spreadsheet.client_encoding = 'UTF-8'
    @book = Spreadsheet::Workbook.new
    
    # 🎨 Formato jolie
    @header_format = Spreadsheet::Format.new(
      weight: :bold,
      size: 11,
      pattern: 1,
      pattern_fg_color: :gray,         
      color: :white,                  
      horizontal_align: :center,      
      vertical_align: :center
    )
    
    @data_format = Spreadsheet::Format.new(
      size: 20,
      vertical_align: :center
    )
  end

  def add_worksheet(name)
    @sheet = @book.create_worksheet name: name
    self
  end

  def add_headers(array_of_headers)
    @sheet.row(0).concat array_of_headers
    @sheet.row(0).default_format = @header_format
    @sheet.row(0).height = 26 # Altura elegante para la cabecera
    self
  end

  def setup_data(fields_to_export)
    index = 1

    fields_to_export.each do |data|
      @sheet.row(index).replace data
      @sheet.row(index).default_format = @data_format
      @sheet.row(index).height = 20 # Altura cómoda para leer los datos
      index += 1
    end
    self
  end

  def build_file
    file_contents = StringIO.new
    @book.write file_contents
    file_contents.string.force_encoding('binary')
  end
end