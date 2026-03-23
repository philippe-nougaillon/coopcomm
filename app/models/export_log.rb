class ExportLog < ApplicationRecord
  belongs_to :organisation
  belongs_to :user
end
