class NewslettersToXls < ApplicationService
  require 'spreadsheet'
  attr_reader :newsletters
  private :newsletters

  def initialize(newsletters)
    @newsletters = newsletters
  end

  def call
    Spreadsheet.client_encoding = 'UTF-8'
  
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet name: @newsletters.name
    bold = Spreadsheet::Format.new :weight => :bold, :size => 11

    headers = %w{Email Créé_le slug}

    sheet.row(0).concat headers
    sheet.row(0).default_format = bold
    
    index = 1

    @newsletters.each do |newsletter|
      fields_to_export = [
        newsletter.email,
        I18n.l(newsletter.created_at),
        newsletter.slug,
      ]
      sheet.row(index).replace fields_to_export
      index += 1
    end

    file_contents = StringIO.new
    book.write file_contents # => Now file_contents contains the rendered file output
    return file_contents.string.force_encoding('binary')

  end

end