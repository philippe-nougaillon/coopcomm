namespace :mouvements do
  
  desc "Créer les mouvements en fonction du passé"
  task :create_past_mouvements, [:enregistrer] => :environment do |task, args|
    Intervention.where(début: (DateTime.now-1.day..DateTime.now)).each do |intervention|
      intervention.tools.each do |tool|
        Mouvement.create(tool_id: tool.id, intervention_id: intervention.id, état: 3)
      end
    end
    Intervention.where(fin: (DateTime.now-1.day..DateTime.now)).each do |intervention|
      intervention.tools.each do |tool|
        Mouvement.create(tool_id: tool.id, état: 2)
      end
    end
  end

end