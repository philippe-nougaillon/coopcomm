# frozen_string_literal: true

namespace :conventions do
  desc "Lire par l'IA une convention en PDF, ou chaque PDF d'un dossier, pour une organisation, sans rien enregistrer"
  task :analyser, %i[chemin organisation] => :environment do |_task, args|
    abort "Usage : bin/rails 'conventions:analyser[chemin,id de l’organisation]'" if args[:chemin].blank? || args[:organisation].blank?
    abort "L'IA n'est pas configurée : LLM_HOST est absent" unless InterrogerIa.configuree?

    organisation = Organisation.find(args[:organisation])
    adherents = organisation.users.adhérent.ordered.includes(:services)
    services = organisation.services.ordered
    fichiers = File.directory?(args[:chemin]) ? Dir[File.join(args[:chemin], '*')].select { |fichier| File.file?(fichier) }.sort : [args[:chemin]]
    ligne = lambda do |libelle, valeur, extrait, retrouve|
      puts format('   %-18s %-36s %s%s', libelle, valeur || '—', ("« #{extrait.squish} »" if extrait),
                  ('  ⚠ extrait introuvable dans le texte' if retrouve == false))
    end

    fichiers.each do |fichier|
      puts "== #{File.basename(fichier)}"
      lecture = LireDocument.call(fichier, Marcel::MimeType.for(Pathname.new(fichier), name: File.basename(fichier)))
      lue = "numérisation, #{lecture.pages_ocr} pages lues par OCR sur #{lecture.pages}" if lecture.pages_ocr
      lue ||= lecture.texte ? 'texte' : "numérisation, #{lecture.images.size} pages transcrites sur #{lecture.pages}"
      ligne.call('lecture', lue, nil, nil)
      resultat = AnalyserConvention.call(lecture, adherents: adherents, services: services)

      adherent = resultat[:user]
      ligne.call('adhérent', adherent.valeur ? "#{adherent.valeur.nom_prénom.strip} (##{adherent.valeur.id})" : resultat[:nom_adhérent].valeur&.then { |nom| "hors liste : #{nom}" },
                 adherent.extrait, adherent.extrait_retrouve)
      { 'date de début' => :date_début, 'date de signature' => :date_signature, 'date de fin' => :date_fin_prévue }.each do |libelle, champ|
        ligne.call(libelle, resultat[champ].valeur && I18n.l(resultat[champ].valeur), resultat[champ].extrait, resultat[champ].extrait_retrouve)
      end
      resultat[:services].each do |service|
        nom = service.service ? "#{service.service.nom} (##{service.service.id})" : 'hors liste'
        nom += ', adhérent non rattaché' if service.service && adherent.valeur&.services&.exclude?(service.service)
        ligne.call('service', "#{nom} : #{service.heures || '—'} h", service.extrait, service.extrait_retrouve)
      end
      ligne.call('résumé', resultat[:résumé].valeur, nil, nil)
    rescue InterrogerIa::Indisponible => e
      abort "IA injoignable : #{e.message}"
    rescue LireDocument::Illisible, InterrogerIa::Erreur => e
      puts "   ÉCHEC : #{e.message}"
    end
  end
end
