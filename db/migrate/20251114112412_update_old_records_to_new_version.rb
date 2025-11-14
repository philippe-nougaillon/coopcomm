class UpdateOldRecordsToNewVersion < ActiveRecord::Migration[8.0]
  def change
    Intervention.where(workflow_state: "attente").update_all(workflow_state: "pointage_activé")
    Tool.all.each do |tool|
      if tool.mouvements.none?
        tool.mouvements.create(état: 0, date: tool.created_at)
      end
    end
  end
end
