# frozen_string_literal: true

require 'test_helper'
require_relative '../support/faux_modele'

class AnalyserConventionTest < ActiveSupport::TestCase
  include FauxModele

  TEXTE = <<~TEXTE
    Entre la Communauté de Communes du Val Fictif et Ariel Weil, adhérent, il est convenu ce qui suit.
    Service technique | 350 heures
    Service informatique | 40 heures
    La présente convention prend effet le 1er janvier 2025. Elle est conclue pour une durée de trois ans.
    Le coût unitaire est fixé à 34,50 euros par heure.
    Fait à Valfictif, le 16 décembre 2024.
  TEXTE
  LECTURE = LireDocument::Lecture.new(TEXTE, [], 1).freeze
  NUMERISATION = LireDocument::Lecture.new(nil, %w[premiere seconde], 2).freeze

  setup do
    brancher_faux_modele
    @adherent = users(:weil)
    @technique = services(:technique)
    @informatique = services(:informatique)
    @secretariat = services(:secretariat)
    @reponse = {
      'adherent' => { 'extrait' => 'et Ariel Weil, adhérent', 'nom' => 'Ariel Weil', 'id' => @adherent.id },
      'date_debut' => { 'extrait' => 'prend effet le 1er janvier 2025', 'valeur' => '2025-01-01' },
      'date_signature' => { 'extrait' => 'Fait à Valfictif, le 16 décembre 2024', 'valeur' => '2024-12-16' },
      'date_fin' => { 'extrait' => nil, 'valeur' => nil },
      'services' => [{ 'extrait' => 'Service technique 350 heures', 'id' => @technique.id, 'heures' => 350 },
                     { 'extrait' => 'Service informatique 40 heures', 'id' => @informatique.id, 'heures' => 40 }],
      'resume' => 'La Communauté de Communes du Val Fictif met ses services technique et informatique à la disposition d’Ariel Weil.'
    }
  end

  teardown do
    debrancher_faux_modele
  end

  test 'une numérisation est transcrite page par page, puis analysée comme un texte' do
    stub_reponse_du_modele('Entre la Communauté et Ariel Weil, adhérent', 'Service technique | 350 heures', @reponse.to_json)

    resultat = analyser(NUMERISATION)

    transcriptions = corps_envoyes_au_modele.first(2).map { |corps| corps['messages'].last['content'] }
    assert_equal [1, 1], transcriptions.map { |parties| parties.count { |partie| partie['type'] == 'image_url' } }
    assert_includes corps_envoye_au_modele['messages'].last['content'],
                    "<document>\nEntre la Communauté et Ariel Weil, adhérent\n\nService technique | 350 heures\n</document>"
    assert_equal @adherent, resultat[:user].valeur
  end

  test 'les adhérents et les services proposés au modèle sont ceux fournis, avec leur numéro' do
    stub_reponse_du_modele(@reponse.to_json)

    analyser(LECTURE)

    contenu = corps_envoye_au_modele['messages'].last['content']
    assert_includes contenu, "- #{@adherent.id} : #{@adherent.nom_prénom} ("
    assert_includes contenu, "- #{@technique.id} : Technique"
    assert_not_includes contenu, users(:adherent_marseille).nom
  end

  test 'le texte du document est transmis au modèle' do
    stub_reponse_du_modele(@reponse.to_json)

    analyser(LECTURE)

    assert_includes corps_envoye_au_modele['messages'].last['content'], "<document>\n#{TEXTE}\n</document>"
  end

  test 'le modèle ne peut choisir qu’un adhérent et des services de la liste, ou aucun' do
    stub_reponse_du_modele(@reponse.to_json)

    analyser(LECTURE)

    proprietes = corps_envoye_au_modele['response_format']['json_schema']['schema']['properties']
    assert_equal [@adherent.id, users(:adherent_avec_adresse).id, nil], proprietes['adherent']['properties']['id']['enum']
    assert_equal [@technique.id, @informatique.id, @secretariat.id, nil], proprietes['services']['items']['properties']['id']['enum']
  end

  test 'le modèle doit citer le document avant de donner une valeur' do
    stub_reponse_du_modele(@reponse.to_json)

    analyser(LECTURE)

    proprietes = corps_envoye_au_modele['response_format']['json_schema']['schema']['properties']
    assert_equal %w[extrait nom id], proprietes['adherent']['properties'].keys
    assert_equal %w[extrait valeur], proprietes['date_debut']['properties'].keys
    assert_equal %w[extrait id heures], proprietes['services']['items']['properties'].keys
  end

  test 'le modèle doit rendre un résumé, ou dire qu’il n’en a pas' do
    stub_reponse_du_modele(@reponse.to_json)

    analyser(LECTURE)

    schema = corps_envoye_au_modele['response_format']['json_schema']['schema']
    assert_equal %w[string null], schema['properties']['resume']['type']
    assert_includes schema['required'], 'resume'
  end

  test 'le modèle n’est interrogé que sur l’adhérent, les dates, les services et le résumé' do
    stub_reponse_du_modele(@reponse.to_json)

    analyser(LECTURE)

    assert_equal %w[adherent date_debut date_signature date_fin services resume],
                 corps_envoye_au_modele['response_format']['json_schema']['schema']['required']
  end

  test 'une réponse hors du schéma demandé est refusée' do
    stub_reponse_du_modele(@reponse.merge('adherent' => 'Ariel Weil').to_json)

    erreur = assert_raises(InterrogerIa::Erreur) { analyser(LECTURE) }

    assert_equal 'réponse hors du schéma demandé', erreur.message
  end

  test 'l’adhérent choisi par le modèle est proposé avec l’extrait qui le nomme' do
    stub_reponse_du_modele(@reponse.to_json)

    proposition = analyser(LECTURE)[:user]

    assert_equal @adherent, proposition.valeur
    assert_equal 'et Ariel Weil, adhérent', proposition.extrait
  end

  test 'un adhérent est reconnu à la commune de son adresse quand l’extrait ne porte pas son nom' do
    adherent = users(:adherent_avec_adresse)
    stub_reponse_du_modele(@reponse.merge('adherent' => { 'extrait' => 'ET la commune de Testville-sur-Orne', 'id' => adherent.id }).to_json)

    assert_equal adherent, analyser(LECTURE)[:user].valeur
  end

  # ==================== TESTS CRITIQUES ====================
  # Une convention rattachée au mauvais adhérent fausse le suivi des heures de deux communes : le modèle ne doit
  # pouvoir proposer ni un adhérent hors de la liste fournie, ni un adhérent que son propre extrait ne nomme pas.
  test 'un adhérent absent de la liste fournie n’est jamais proposé (critique)' do
    stub_reponse_du_modele(@reponse.merge('adherent' => { 'extrait' => 'et Ariel Weil, adhérent', 'id' => users(:adherent_marseille).id }).to_json)

    assert_nil analyser(LECTURE)[:user].valeur
  end

  test 'un adhérent que son extrait ne nomme pas n’est pas proposé, et l’extrait lu est gardé (critique)' do
    stub_reponse_du_modele(@reponse.merge('adherent' => { 'extrait' => 'Fait à Valfictif, le 16 décembre 2024', 'id' => @adherent.id }).to_json)

    proposition = analyser(LECTURE)[:user]

    assert_nil proposition.valeur
    assert_equal 'Fait à Valfictif, le 16 décembre 2024', proposition.extrait
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'le nom que le document donne à un adhérent absent de la liste est proposé' do
    stub_reponse_du_modele(@reponse.merge('adherent' => { 'extrait' => 'ET la commune de Beaumont', 'nom' => 'Beaumont', 'id' => nil }).to_json)

    resultat = analyser(LECTURE)

    assert_nil resultat[:user].valeur
    assert_equal 'Beaumont', resultat[:nom_adhérent].valeur
  end

  test 'un nom laissé vide par le modèle n’est pas proposé' do
    stub_reponse_du_modele(@reponse.merge('adherent' => { 'extrait' => 'et Ariel Weil, adhérent', 'nom' => '', 'id' => @adherent.id }).to_json)

    assert_nil analyser(LECTURE)[:nom_adhérent].valeur
  end

  test 'les dates au format ISO sont proposées' do
    stub_reponse_du_modele(@reponse.merge('date_fin' => { 'extrait' => 'prend fin le 31 décembre 2027', 'valeur' => '2027-12-31' }).to_json)

    resultat = analyser(LECTURE)

    assert_equal Date.new(2025, 1, 1), resultat[:date_début].valeur
    assert_equal Date.new(2024, 12, 16), resultat[:date_signature].valeur
    assert_equal Date.new(2027, 12, 31), resultat[:date_fin_prévue].valeur
  end

  test 'une date qui n’est pas au format ISO n’est pas proposée' do
    stub_reponse_du_modele(@reponse.merge('date_debut' => { 'extrait' => 'prend effet le 1er janvier 2025', 'valeur' => '1er janvier 2025' }).to_json)

    assert_nil analyser(LECTURE)[:date_début].valeur
  end

  test 'une information absente du document est proposée sans valeur ni extrait' do
    stub_reponse_du_modele(@reponse.to_json)

    proposition = analyser(LECTURE)[:date_fin_prévue]

    assert_nil proposition.valeur
    assert_nil proposition.extrait
  end

  test 'une information que le modèle cite sans pouvoir la lire garde son extrait' do
    stub_reponse_du_modele(@reponse.merge('date_signature' => { 'extrait' => 'Le [manuscrit illisible]', 'valeur' => nil }).to_json)

    proposition = analyser(LECTURE)[:date_signature]

    assert_nil proposition.valeur
    assert_equal 'Le [manuscrit illisible]', proposition.extrait
  end

  test 'le résumé rédigé par le modèle est proposé' do
    stub_reponse_du_modele(@reponse.to_json)

    assert_equal 'La Communauté de Communes du Val Fictif met ses services technique et informatique à la disposition d’Ariel Weil.',
                 analyser(LECTURE)[:résumé].valeur
  end

  test 'un résumé laissé vide par le modèle n’est pas proposé' do
    stub_reponse_du_modele(@reponse.merge('resume' => '').to_json)

    assert_nil analyser(LECTURE)[:résumé].valeur
  end

  test 'chaque service de la convention est proposé avec ses heures, dans l’ordre du document' do
    stub_reponse_du_modele(@reponse.to_json)

    lignes = analyser(LECTURE)[:services]

    assert_equal [[@technique, 350], [@informatique, 40]], lignes.map { |ligne| [ligne.service, ligne.heures] }
  end

  test 'un service absent de la liste fournie n’est jamais proposé (critique)' do
    ligne = { 'extrait' => 'Service technique 350 heures', 'id' => services(:service_marseille).id, 'heures' => 90 }
    stub_reponse_du_modele(@reponse.merge('services' => [ligne]).to_json)

    ligne_proposee = analyser(LECTURE)[:services].sole

    assert_nil ligne_proposee.service
    assert_equal 90, ligne_proposee.heures
  end

  test 'un service lu reste proposé quand l’adhérent n’y est pas rattaché' do
    ligne = { 'extrait' => 'Service technique 350 heures', 'id' => @secretariat.id, 'heures' => 90 }
    stub_reponse_du_modele(@reponse.merge('services' => [ligne]).to_json)

    assert_equal @secretariat, analyser(LECTURE)[:services].sole.service
  end

  test 'des heures nulles ou négatives ne sont pas proposées' do
    lignes = [{ 'extrait' => 'Service technique', 'id' => @technique.id, 'heures' => 0 },
              { 'extrait' => 'Service informatique', 'id' => @informatique.id, 'heures' => -40 }]
    stub_reponse_du_modele(@reponse.merge('services' => lignes).to_json)

    assert_equal [nil, nil], analyser(LECTURE)[:services].map(&:heures)
  end

  test 'un extrait présent dans le texte est signalé retrouvé, aux espaces, à la casse et aux traits de tableau près' do
    stub_reponse_du_modele(@reponse.merge('adherent' => { 'extrait' => "ET ARIEL  Weil,\nadhérent", 'id' => @adherent.id }).to_json)

    resultat = analyser(LECTURE)

    assert resultat[:user].extrait_retrouve
    assert_equal [true, true], resultat[:services].map(&:extrait_retrouve)
  end

  test 'un extrait absent du texte est signalé introuvable' do
    stub_reponse_du_modele(@reponse.merge('date_debut' => { 'extrait' => 'à compter du premier janvier', 'valeur' => '2025-01-01' }).to_json)

    assert_equal false, analyser(LECTURE)[:date_début].extrait_retrouve
  end

  private

  def analyser(lecture)
    AnalyserConvention.call(lecture, adherents: [@adherent, users(:adherent_avec_adresse)], services: [@technique, @informatique, @secretariat])
  end
end
