# frozen_string_literal: true

require 'test_helper'
require 'rake'
require_relative '../support/faux_modele'
require_relative '../support/fabrique_pdf'
require_relative '../support/faux_ocr'

class ConventionsAnalyserTaskTest < ActiveSupport::TestCase
  include FauxModele
  include FabriquePdf
  include FauxOcr

  TEXTE = 'Entre la Communauté de Communes du Val Fictif et Ariel Weil, adhérent, représenté par son Maire, il est ' \
          'convenu que le service technique intervient pour un volume annuel de 350 heures. La présente convention ' \
          'prend effet le 1er janvier 2025. Elle est conclue pour une durée de trois ans.'

  setup do
    unless Rake::Task.task_defined?('conventions:analyser')
      Rake::Task.define_task(:environment)
      load Rails.root.join('lib/tasks/conventions.rake')
    end
    @task = Rake::Task['conventions:analyser']
    @task.reenable
    brancher_faux_modele
    @organisation = organisations(:mairie_paris)
    @adherent = users(:weil)
    @technique = services(:technique)
    @reponse = {
      'adherent' => { 'extrait' => 'et Ariel Weil, adhérent', 'id' => @adherent.id },
      'date_debut' => { 'extrait' => 'prend effet le 1er janvier 2025', 'valeur' => '2025-01-01' },
      'date_signature' => { 'extrait' => nil, 'valeur' => nil },
      'date_fin' => { 'extrait' => nil, 'valeur' => nil },
      'services' => [{ 'extrait' => 'un volume annuel de 350 heures', 'id' => @technique.id, 'heures' => 350 }],
      'resume' => 'La Communauté de Communes du Val Fictif met son service technique à la disposition d’Ariel Weil.'
    }
  end

  teardown do
    debrancher_faux_modele
    fermer_pdf
  end

  test 'la tâche s’arrête sans chemin ni organisation' do
    _sortie, erreur = capture_io { assert_raises(SystemExit) { @task.invoke } }

    assert_includes erreur, 'Usage'
    assert_not_requested(:post, "#{ADRESSE_DU_MODELE}/v1/chat/completions")
  end

  test 'la tâche s’arrête quand l’IA n’est pas configurée' do
    ENV['LLM_HOST'] = nil

    _sortie, erreur = capture_io { assert_raises(SystemExit) { @task.invoke(pdf_de_texte([TEXTE]), @organisation.id) } }

    assert_includes erreur, 'LLM_HOST est absent'
  end

  test 'les adhérents et les services proposés au modèle sont ceux de l’organisation demandée (critique)' do
    stub_reponse_du_modele(@reponse.to_json)

    capture_io { @task.invoke(pdf_de_texte([TEXTE]), @organisation.id) }

    contenu = corps_envoye_au_modele['messages'].last['content']
    assert_includes contenu, "- #{@adherent.id} : #{@adherent.nom_prénom}"
    assert_includes contenu, "- #{@technique.id} : Technique"
    assert_not_includes contenu, users(:adherent_marseille).nom
    assert_not_includes contenu, services(:service_marseille).nom
  end

  test 'la tâche affiche ce que le modèle a lu dans la convention' do
    stub_reponse_du_modele(@reponse.to_json)

    sortie, _erreur = capture_io { @task.invoke(pdf_de_texte([TEXTE]), @organisation.id) }

    assert_match(/lecture\s+texte/, sortie)
    assert_match(/adhérent\s+#{@adherent.nom_prénom} \(##{@adherent.id}\)\s+« et Ariel Weil, adhérent »/, sortie)
    assert_match(%r{date de début\s+01/01/2025}, sortie)
    assert_match(/date de fin\s+—/, sortie)
    assert_match(/service\s+Technique \(##{@technique.id}\) : 350 h/, sortie)
    assert_match(/résumé\s+La Communauté de Communes du Val Fictif met son service technique à la disposition d’Ariel Weil\./, sortie)
  end

  test 'une numérisation est annoncée avec le nombre de pages transcrites' do
    stub_reponse_du_modele(TEXTE, 'Annexe', @reponse.to_json)

    sortie, _erreur = capture_io { sans_ocr { @task.invoke(pdf_numerise(2), @organisation.id) } }

    assert_match(/lecture\s+numérisation, 2 pages transcrites sur 2/, sortie)
    assert_match(/service\s+Technique \(##{@technique.id}\) : 350 h/, sortie)
  end

  test 'une numérisation lue par OCR est annoncée avec le nombre de pages lues' do
    stub_reponse_du_modele(@reponse.to_json)

    sortie, _erreur = capture_io { avec_faux_ocr([TEXTE.split]) { @task.invoke(pdf_numerise(2), @organisation.id) } }

    assert_match(/lecture\s+numérisation, 2 pages lues par OCR sur 2/, sortie)
    assert_match(/service\s+Technique \(##{@technique.id}\) : 350 h/, sortie)
  end

  test 'une numérisation lue par OCR part à l’analyse sans être transcrite par le modèle' do
    stub_reponse_du_modele(@reponse.to_json)

    capture_io { avec_faux_ocr([TEXTE.split]) { @task.invoke(pdf_numerise(2), @organisation.id) } }

    assert_requested(:post, "#{ADRESSE_DU_MODELE}/v1/chat/completions", times: 1)
    assert_includes corps_envoye_au_modele['messages'].last['content'], "<document>\n#{TEXTE}\n\n#{TEXTE}\n</document>"
  end

  test 'ce que le modèle a lu d’un adhérent qu’il ne reconnaît pas est affiché' do
    stub_reponse_du_modele(@reponse.merge('adherent' => { 'extrait' => 'La commune de Beaumont', 'nom' => 'Beaumont', 'id' => nil }).to_json)

    sortie, _erreur = capture_io { @task.invoke(pdf_de_texte([TEXTE]), @organisation.id) }

    assert_match(/adhérent\s+hors liste : Beaumont\s+« La commune de Beaumont »/, sortie)
  end

  test 'un adhérent que le modèle ne reconnaît ni ne nomme est affiché sans nom' do
    stub_reponse_du_modele(@reponse.merge('adherent' => { 'extrait' => 'La commune de Beaumont', 'nom' => nil, 'id' => nil }).to_json)

    sortie, _erreur = capture_io { @task.invoke(pdf_de_texte([TEXTE]), @organisation.id) }

    assert_match(/adhérent\s+—\s+« La commune de Beaumont »/, sortie)
  end

  test 'un service auquel l’adhérent n’est pas rattaché est signalé' do
    secretariat = services(:secretariat)
    ligne = { 'extrait' => 'un volume annuel de 350 heures', 'id' => secretariat.id, 'heures' => 350 }
    stub_reponse_du_modele(@reponse.merge('services' => [ligne]).to_json)

    sortie, _erreur = capture_io { @task.invoke(pdf_de_texte([TEXTE]), @organisation.id) }

    assert_match(/service\s+Secrétariat \(##{secretariat.id}\), adhérent non rattaché : 350 h/, sortie)
  end

  test 'la tâche n’enregistre aucune convention' do
    stub_reponse_du_modele(@reponse.to_json)

    assert_no_difference 'Convention.count' do
      capture_io { @task.invoke(pdf_de_texte([TEXTE]), @organisation.id) }
    end
  end

  test 'un extrait introuvable dans le texte est signalé' do
    stub_reponse_du_modele(@reponse.merge('date_debut' => { 'extrait' => 'à compter du premier janvier', 'valeur' => '2025-01-01' }).to_json)

    sortie, _erreur = capture_io { @task.invoke(pdf_de_texte([TEXTE]), @organisation.id) }

    assert_match(%r{date de début\s+01/01/2025\s+« à compter du premier janvier »\s+⚠ extrait introuvable dans le texte}, sortie)
  end

  test 'chaque document du dossier est analysé, et un document refusé n’arrête pas les suivants' do
    stub_reponse_du_modele(@reponse.to_json)

    Dir.mktmpdir do |dossier|
      File.write(File.join(dossier, '1-note.txt'), 'Courrier sans rapport.')
      FileUtils.cp(pdf_de_texte([TEXTE]), File.join(dossier, '2-convention.pdf'))

      sortie, _erreur = capture_io { @task.invoke(dossier, @organisation.id) }

      assert_match(/== 1-note\.txt\n\s+ÉCHEC : format non pris en charge \(text\/plain\)\n== 2-convention\.pdf\n/, sortie)
      assert_match(/service\s+Technique \(##{@technique.id}\) : 350 h/, sortie)
    end
  end

  test 'la tâche s’arrête dès que l’IA est injoignable' do
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_raise(Errno::ECONNREFUSED)

    _sortie, erreur = capture_io { assert_raises(SystemExit) { @task.invoke(pdf_de_texte([TEXTE]), @organisation.id) } }

    assert_includes erreur, 'IA injoignable'
  end
end
