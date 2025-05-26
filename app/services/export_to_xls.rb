class ExportToXls < ApplicationService
  require 'spreadsheet'

  def initialize
    Spreadsheet.client_encoding = 'UTF-8'
    @book = Spreadsheet::Workbook.new
    @bold = Spreadsheet::Format.new :weight => :bold, :size => 11
  end

  def add_worksheet(name)
    @sheet = @book.create_worksheet name: name
    @sheet.row(0).default_format = @bold
    self
  end

  def add_headers(array_of_headers)
    @sheet.row(0).concat array_of_headers
    self
  end

  def setup_data(fields_to_export)
    index = 1

    fields_to_export.each do |data|
      @sheet.row(index).replace data
      index += 1
    end
    self
  end

  def build_file
    file_contents = StringIO.new
    @book.write file_contents # => Now file_contents contains the rendered file output
    return file_contents.string.force_encoding('binary')
  end
end