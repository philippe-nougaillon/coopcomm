# frozen_string_literal: true

class ExportLog < ApplicationRecord
  belongs_to :organisation
  belongs_to :user

  triable_par 'export_logs.created_at' => :brut,
              'export_logs.user' => ColonnesTri.utilisateur('export_logs.user_id'),
              'export_logs.export_type' => :texte
end
