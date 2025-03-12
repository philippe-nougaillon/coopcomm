class Document < ApplicationRecord
  belongs_to :tool

  has_one_attached :fichier

  def style
    "badge-primary"
  end
end
