# frozen_string_literal: true

require 'open3'

# Ce qu'un PDF donne à lire au modèle : son texte s'il en porte un, sinon celui d'un OCR, sinon l'image de ses pages. Outils des paquets poppler-utils et tesseract-ocr.
class LireDocument < ApplicationService
  class Illisible < StandardError; end

  Lecture = Struct.new(:texte, :images, :pages, :pages_ocr)

  DELAI = 60
  CARACTERES_PAR_PAGE = 200
  PAGES_MAX = 8
  RESOLUTION = 150
  RESOLUTION_OCR = 300
  PAGES_DE_FRONT = 4
  CONFIANCE_MINIMALE = 60
  INCERTAIN = /\[incertain : [^\]]*\]/

  def initialize(chemin, type)
    @chemin = chemin
    @type = type
  end

  def call
    raise Illisible, "format non pris en charge (#{@type})" unless @type == 'application/pdf'

    texte = executer('pdftotext', '-layout', '-enc', 'UTF-8', @chemin, '-').force_encoding('UTF-8').scrub('').delete("\u0000")
    pages = texte.count("\f")
    return Lecture.new(texte.delete("\f"), [], pages) if assez_de_texte?(texte, pages)

    lues = pages_lues_par_ocr
    return Lecture.new(lues.join("\n\n"), [], pages, lues.size) if lues.any? && assez_de_texte?(lues.join, lues.size)

    Lecture.new(nil, images_des_pages, pages)
  end

  private

  def images_des_pages
    Dir.mktmpdir do |dossier|
      executer('pdftoppm', '-r', RESOLUTION.to_s, '-jpeg', '-l', PAGES_MAX.to_s, @chemin, File.join(dossier, 'page'))
      Dir[File.join(dossier, 'page*.jpg')].sort.map { |image| File.binread(image) }
    end
  end

  def executer(*commande)
    Open3.popen2(*commande, err: File::NULL) do |_entree, sortie, attente|
      resultat = Timeout.timeout(DELAI) { sortie.read }
      raise Illisible, 'PDF illisible' unless attente.value.success?

      resultat
    rescue Timeout::Error
      Process.kill('KILL', attente.pid)
      raise Illisible, 'lecture du PDF trop longue'
    end
  end

  # Sans OMP_THREAD_LIMIT, les fils internes de tesseract se disputent les cœurs : quatre pages de front prennent trois fois plus de temps.
  def pages_lues_par_ocr
    Dir.mktmpdir do |dossier|
      executer('pdftoppm', '-r', RESOLUTION_OCR.to_s, '-gray', '-png', '-l', PAGES_MAX.to_s, @chemin, File.join(dossier, 'page'))
      Dir[File.join(dossier, 'page*.png')].sort.each_slice(PAGES_DE_FRONT).flat_map do |lot|
        lot.map do |image|
          Thread.new do
            Thread.current.report_on_exception = false
            texte_lu(executer({ 'OMP_THREAD_LIMIT' => '1' }, 'tesseract', image, 'stdout', '-l', 'fra', 'tsv'))
          end
        end.map(&:value)
      end
    end
  rescue Errno::ENOENT, Illisible
    []
  end

  # Sortie TSV de tesseract : une ligne par mot (niveau 5) ; colonnes 2 à 4 = bloc, paragraphe, ligne ; colonne 10 = confiance sur 100 ; colonne 11 = le mot.
  def texte_lu(tsv)
    mots = tsv.force_encoding('UTF-8').scrub('').lines(chomp: true).map { |ligne| ligne.split("\t", 12) }
    mots.select { |colonnes| colonnes[0] == '5' && colonnes[11].present? }.chunk { |colonnes| colonnes[2..4] }.map do |_ligne, de_la_ligne|
      de_la_ligne.chunk_while { |mot, suivant| mot[10].to_f < CONFIANCE_MINIMALE && suivant[10].to_f < CONFIANCE_MINIMALE }.map do |groupe|
        lu = groupe.map { |colonnes| colonnes[11] }.join(' ')
        groupe.first[10].to_f < CONFIANCE_MINIMALE ? "[incertain : #{lu}]" : lu
      end.join(' ')
    end.join("\n")
  end

  def assez_de_texte?(texte, pages)
    texte.gsub(INCERTAIN, '').gsub(/\s/, '').length >= CARACTERES_PAR_PAGE * pages
  end
end
