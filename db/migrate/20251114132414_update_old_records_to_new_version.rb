# frozen_string_literal: true

class UpdateOldRecordsToNewVersion < ActiveRecord::Migration[8.0]
  def change
    Intervention.where(workflow_state: %w[attente pointage_activé]).update_all(workflow_state: 'pointage activé')
    Tool.all.each do |tool|
      tool.mouvements.create(état: 0, date: tool.created_at) if tool.mouvements.none?
    end
  end
end
