# frozen_string_literal: true

module ExportToXls
  # Génère un fichier XLS des agents
  class Base < ApplicationService
    require 'spreadsheet'

    def initialize
      Spreadsheet.client_encoding = 'UTF-8'
      @book = Spreadsheet::Workbook.new

      # format jolie
      @header_format = Spreadsheet::Format.new(
        weight: :bold,
        size: 11,
        pattern: 1,
        pattern_fg_color: :gray,
        color: :white,
        horizontal_align: :center,
        vertical_align: :center
      )

      # text
      @data_format = Spreadsheet::Format.new(
        size: 10,
        vertical_align: :center
      )

      # números et IDs
      @center_format = Spreadsheet::Format.new(
        size: 10,
        horizontal_align: :center,
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
      @sheet.row(0).height = 26
      self
    end

    def setup_data(fields_to_export)
      index = 1

      fields_to_export.each do |data|
        @sheet.row(index).replace data
        @sheet.row(index).height = 20

        data.each_with_index do |value, col_index|
          if col_index.zero? || value.is_a?(Numeric)
            @sheet.row(index).set_format(col_index, @center_format)
          else
            @sheet.row(index).set_format(col_index, @data_format)
          end
        end

        index += 1
      end
      self
    end

    def build_file
      autofit_columns_with_gap

      file_contents = StringIO.new
      @book.write file_contents
      file_contents.string.force_encoding('binary')
    end

    private

    def autofit_columns_with_gap
      total_columns = @sheet.row(0).size

      (0...total_columns).each do |col_index|
        max_length = 0

        @sheet.each do |row|
          cell_value = row[col_index].to_s
          max_length = cell_value.length if cell_value.length > max_length
        end

        calculated_width = [max_length + 4, 10].max
        @sheet.column(col_index).width = calculated_width
      end
    end
  end
end