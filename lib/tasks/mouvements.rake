namespace :mouvements do
  
  desc "Créer les mouvements en fonction du passé à lancer le soir"
  task :create_past_mouvements, [:enregistrer] => :environment do |task, args|
    # Créer les états OUT
    Intervention.where(début: (DateTime.now-1.day..DateTime.now)).each do |intervention|
      intervention.tools.each do |tool|
        Mouvement.create(tool_id: tool.id, intervention_id: intervention.id, état: 3)
      end
    end
    # Créer les états IN
    Intervention.where(fin: (DateTime.now-1.day..DateTime.now)).each do |intervention|
      intervention.tools.each do |tool|
        Mouvement.create(tool_id: tool.id, intervention_id: intervention.id, état: 2)
      end
    end
  end

end