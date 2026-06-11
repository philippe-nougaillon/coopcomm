# frozen_string_literal: true

class ExportLog < ApplicationRecord
  belongs_to :organisation
  belongs_to :user
end
