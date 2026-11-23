# frozen_string_literal: true

# Met un test de lecture de document à l'abri de l'OCR du poste : tesseract remplacé par un script qui rend
# les mots voulus, mis en panne, ou retiré du PATH.
module FauxOcr
  ENTETE_TSV = %w[level page_num block_num par_num line_num word_num left top width height conf text].join("\t")

  # Chaque ligne est une liste de mots, seuls ou avec leur confiance (['NES', 31]) ; le script ne connaît que la langue fra, comme un poste sans autre langue.
  def avec_faux_ocr(lignes, &)
    mots = lignes.each_with_index.flat_map do |ligne, rang|
      ligne.map { |mot, confiance| [5, 1, 1, 1, rang + 1, 0, 0, 0, 0, 0, confiance || 96, mot].join("\t") }
    end

    avec_tesseract("case \"$*\" in *'-l fra'*) ;; *) exit 1 ;; esac\ncat <<'TSV'\n#{[ENTETE_TSV, *mots].join("\n")}\nTSV", &)
  end

  def avec_ocr_en_panne(&)
    avec_tesseract('exit 1', &)
  end

  def sans_ocr(&)
    Dir.mktmpdir do |dossier|
      %w[pdftotext pdftoppm].each do |outil|
        File.symlink(ENV.fetch('PATH').split(':').map { |chemin| File.join(chemin, outil) }.find { |chemin| File.executable?(chemin) },
                     File.join(dossier, outil))
      end
      avec_path(dossier, &)
    end
  end

  private

  def avec_tesseract(script, &)
    Dir.mktmpdir do |dossier|
      File.write(File.join(dossier, 'tesseract'), "#!/bin/sh\n#{script}\n", perm: 0o755)
      avec_path("#{dossier}:#{ENV.fetch('PATH')}", &)
    end
  end

  def avec_path(path)
    ancien = ENV.fetch('PATH')
    ENV['PATH'] = path
    yield
  ensure
    ENV['PATH'] = ancien
  end
end
