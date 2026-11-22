# frozen_string_literal: true

require 'test_helper'
require_relative '../support/compte_aibbo'

class AibboRepondreTest < ActiveSupport::TestCase
  include CompteAibbo

  VARIABLES_ENV = %w[MISTRAL_AI_API_KEY AIBBO_MODELE].freeze
  # La seule adresse que WebMock laisse répondre : toute autre requête fait tomber le test.
  ADRESSE_DU_MODELE = 'https://api.eu.mistral.ai/v1/chat/completions'

  setup do
    @env_initial = ENV.to_h.slice(*VARIABLES_ENV)
    ENV['MISTRAL_AI_API_KEY'] = 'cle-de-test'
    ENV.delete('AIBBO_MODELE')
    @agent = users(:bond)
  end

  teardown do
    VARIABLES_ENV.each { |cle| @env_initial.key?(cle) ? ENV[cle] = @env_initial[cle] : ENV.delete(cle) }
  end

  # ==================== TESTS CRITIQUES ====================
  # La question et ce que les outils ont lu partent chez un tiers : uniquement au point d'accès européen,
  # et sans rien qui sorte du périmètre de l'utilisateur.
  test 'la question n’est envoyée qu’au point d’accès européen du modèle (critique)' do
    modele_repondant('responseMistralReponse.json')

    Aibbo::Repondre.call(@agent, question_de(@agent))

    assert_requested :post, ADRESSE_DU_MODELE, times: 1
  end

  test 'ce qui est envoyé au modèle pour un agent ne contient aucune intervention d’un autre agent (critique)' do
    modele_repondant('responseMistralAppelOutil.json', 'responseMistralReponse.json')

    Aibbo::Repondre.call(@agent, question_de(@agent))

    assert_includes @envois.last, interventions(:intervention_terminée).description
    assert_not_includes @envois.join, interventions(:intervention_autre_agent).description
  end

  test 'un agent ne se voit proposer que les interventions, le matériel, son emploi et les personnes (critique)' do
    modele_repondant('responseMistralReponse.json')

    Aibbo::Repondre.call(@agent, question_de(@agent))

    assert_equal %w[interventions materiel personnes utilisation_materiel], outils_proposes.sort
  end

  test 'un adhérent ne se voit proposer que les interventions, les personnes et ses devis, commandes et factures (critique)' do
    modele_repondant('responseMistralReponse.json')

    Aibbo::Repondre.call(users(:weil), question_de(users(:weil)))

    assert_equal %w[devis_commandes_factures interventions personnes], outils_proposes.sort
  end

  test 'une suite d’appels d’outils sans fin est interrompue, et l’utilisateur reçoit le message de repli (critique)' do
    modele_repondant('responseMistralAppelOutil.json')

    reponse = Aibbo::Repondre.call(@agent, question_de(@agent))

    assert_equal Aibbo::Repondre::SANS_REPONSE, reponse.texte
    assert_requested :post, ADRESSE_DU_MODELE, times: (Aibbo::Repondre::PAS / 2) + 1
  end

  test 'une réponse qui cite ce qu’aucun outil n’a rendu n’est pas envoyée : le modèle la refait (critique)' do
    modele_repondant('responseMistralAppelOutil.json', 'responseMistralInvention.json', 'responseMistralReponse.json')

    reponse = Aibbo::Repondre.call(@agent, question_de(@agent))

    assert_equal 'Vous avez des interventions terminées.', reponse.texte
    assert_match(/« 18 novembre 2026 ».*« Charey »/, JSON.parse(@envois.last)['messages'].last['content'])
    assert_match(/réponse écartée Votre intervention suivante est celle du 18 novembre 2026 à Charey/, reponse.trace)
  end

  test 'une réponse inventée deux fois de suite est remplacée par le message de repli (critique)' do
    modele_repondant('responseMistralAppelOutil.json', 'responseMistralInvention.json')

    reponse = Aibbo::Repondre.call(@agent, question_de(@agent))

    assert_equal Aibbo::Repondre::SANS_REPONSE, reponse.texte
    assert_match(/réponse remplacée : 18 novembre 2026.*Charey/, reponse.trace)
    assert_requested :post, ADRESSE_DU_MODELE, times: 3
  end

  test 'la question posée au niveau approfondi n’est envoyée qu’au point d’accès européen du modèle (critique)' do
    modele_repondant('responseMistralReponse.json')

    Aibbo::Repondre.call(@agent, question_de(@agent), 'approfondi')

    assert_requested :post, ADRESSE_DU_MODELE, times: 1
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'la réponse du modèle est rendue avec la trace de l’outil appelé' do
    modele_repondant('responseMistralAppelOutil.json', 'responseMistralReponse.json')

    reponse = Aibbo::Repondre.call(@agent, question_de(@agent))

    assert_equal 'Vous avez des interventions terminées.', reponse.texte
    assert_match(/api\.eu\.mistral\.ai mistral-medium-2604/, reponse.trace)
    assert_match(/appel interventions \{"etat":"terminé"\}/, reponse.trace)
    assert_match(/résultat \{"total":2/, reponse.trace)
  end

  test 'un manager se voit proposer aussi la disponibilité des agents, les absences et la faisabilité d’un chantier' do
    modele_repondant('responseMistralReponse.json')

    Aibbo::Repondre.call(users(:hidalgo), question_de(users(:hidalgo)))

    assert_equal %w[absences devis_commandes_factures disponibilite_agents faisabilite_chantier interventions materiel personnes utilisation_materiel],
                 outils_proposes.sort
  end

  test 'la consigne donne au modèle la date de chaque jour à venir, pour qu’il ne la calcule pas' do
    modele_repondant('responseMistralReponse.json')

    travel_to Time.zone.local(2026, 11, 17, 10, 0) do
      Aibbo::Repondre.call(@agent, question_de(@agent))
    end

    consigne = messages_envoyes.first.last
    assert_includes consigne, 'lundi 23 novembre = 2026-11-23'
    assert_includes consigne, '« dans la semaine » : du 2026-11-16 au 2026-11-20'
    assert_includes consigne, 'la semaine prochaine : du 2026-11-23 au 2026-11-27'
    assert_includes consigne, 'le mois dernier : du 2026-10-01 au 2026-10-31'
  end

  test 'la trace dit qu’aucun outil n’a été appelé lorsque le modèle répond seul' do
    modele_repondant('responseMistralReponse.json')

    assert_match(/aucun outil appelé/, Aibbo::Repondre.call(@agent, question_de(@agent)).trace)
  end

  test 'les messages précédents de la conversation sont rejoués au modèle avant la question' do
    Message.create!(from_user: @agent, to_user: users(:AIBBO), message: 'Je veux la durée totale réalisée par Michel Martin',
                    created_at: Time.zone.local(2026, 3, 10, 9, 0))
    Message.create!(from_user: users(:AIBBO), to_user: @agent, message: 'Michel Martin a réalisé 12 heures.',
                    created_at: Time.zone.local(2026, 3, 10, 9, 1))
    modele_repondant('responseMistralReponse.json')

    Aibbo::Repondre.call(@agent, question_de(@agent))

    assert_equal [['user', 'Je veux la durée totale réalisée par Michel Martin'],
                  ['assistant', 'Michel Martin a réalisé 12 heures.'],
                  ['user', 'Maintenant fais pareil pour James Bond']],
                 messages_envoyes.last(3)
  end

  test 'seuls les dix derniers messages de la conversation sont rejoués' do
    12.times do |rang|
      Message.create!(from_user: @agent, to_user: users(:AIBBO), message: "Question #{rang + 1}",
                      created_at: Time.zone.local(2026, 3, 10, 9, rang))
    end
    modele_repondant('responseMistralReponse.json')

    Aibbo::Repondre.call(@agent, question_de(@agent))

    assert_equal ['Question 3', 'Question 12', 'Maintenant fais pareil pour James Bond'],
                 messages_envoyes.reject { |role, _| role == 'system' }.map(&:last).values_at(0, 9, 10)
  end

  test 'un message de panne de la conversation n’est pas rejoué au modèle' do
    Message.create!(from_user: users(:AIBBO), to_user: @agent, message: Aibbo::Repondre::PANNE, created_at: Time.zone.local(2026, 3, 10, 9, 1))
    modele_repondant('responseMistralReponse.json')

    Aibbo::Repondre.call(@agent, question_de(@agent))

    assert_empty(messages_envoyes.select { |_, texte| texte == Aibbo::Repondre::PANNE })
  end

  test 'au bout des pas, le modèle conclut sans outil et sa réponse est rendue' do
    modele_repondant(*(['responseMistralAppelOutil.json'] * (Aibbo::Repondre::PAS / 2)), 'responseMistralReponse.json')

    reponse = Aibbo::Repondre.call(@agent, question_de(@agent))

    assert_equal 'Vous avez des interventions terminées.', reponse.texte
    assert_equal 'none', JSON.parse(@envois.last)['tool_choice']
  end

  test 'ce qu’AÏBBO a déjà dit dans la conversation peut être redit sans nouvel appel d’outil' do
    deja_dit = 'Votre intervention suivante est celle du 18 novembre 2026 à Charey, de 9h00 à 11h30.'
    Message.create!(from_user: users(:AIBBO), to_user: @agent, message: deja_dit, created_at: Time.zone.local(2026, 3, 10, 9, 1))
    modele_repondant('responseMistralInvention.json')

    assert_equal deja_dit, Aibbo::Repondre.call(@agent, question_de(@agent)).texte
  end

  test 'la consigne fait annoncer les déductions par le mot que le contrôle reconnaît' do
    modele_repondant('responseMistralReponse.json')

    Aibbo::Repondre.call(@agent, question_de(@agent))

    assert_match Aibbo::ReleverInventions::DEDUCTION, messages_envoyes.first.last[/« (Déduction :) »/, 1]
  end

  test 'le niveau approfondi interroge son propre modèle' do
    modele_repondant('responseMistralReponse.json')

    Aibbo::Repondre.call(@agent, question_de(@agent), 'approfondi')

    assert_equal 'mistral-large-4', JSON.parse(@envois.first)['model']
  end

  test 'un niveau inconnu interroge le modèle par défaut' do
    modele_repondant('responseMistralReponse.json')

    Aibbo::Repondre.call(@agent, question_de(@agent), 'inconnu')

    assert_equal ChatMistral::MODELE, JSON.parse(@envois.first)['model']
  end

  test 'le niveau équilibré interroge le modèle réglé par AIBBO_MODELE' do
    ENV['AIBBO_MODELE'] = 'mistral-large-2512'
    modele_repondant('responseMistralReponse.json')

    Aibbo::Repondre.call(@agent, question_de(@agent), 'équilibré')

    assert_equal 'mistral-large-2512', JSON.parse(@envois.first)['model']
  end

  test 'la consigne ne nomme l’outil de faisabilité qu’à qui le reçoit' do
    modele_repondant('responseMistralReponse.json')

    Aibbo::Repondre.call(@agent, question_de(@agent))
    consigne_de_l_agent = messages_envoyes.first.last
    Aibbo::Repondre.call(users(:hidalgo), question_de(users(:hidalgo)))
    consigne_du_manager = JSON.parse(@envois.last)['messages'].first['content']

    assert_not_includes consigne_de_l_agent, 'faisabilite_chantier'
    assert_includes consigne_du_manager, 'faisabilite_chantier'
  end

  private

  def question_de(utilisateur)
    Message.create!(from_user: utilisateur, to_user: users(:AIBBO), message: 'Maintenant fais pareil pour James Bond')
  end

  # Chaque requête au modèle reçoit le fichier suivant, le dernier indéfiniment, avec un identifiant d'appel d'outil
  # propre à la requête comme le fait le vrai modèle ; les corps envoyés sont gardés dans @envois.
  def modele_repondant(*fichiers)
    @envois = []
    stub_request(:post, ADRESSE_DU_MODELE).to_return do |requete|
      @envois << requete.body
      fichier = fichiers.size > 1 ? fichiers.shift : fichiers.first
      { status: 200, headers: { 'Content-Type' => 'application/json' },
        body: file_fixture(fichier).read.sub('appel0001', format('appel%04d', @envois.size)) }
    end
  end

  # Noms des outils décrits au modèle dans la première requête.
  def outils_proposes
    JSON.parse(@envois.first)['tools'].map { |outil| outil.dig('function', 'name') }
  end

  # Rôle et texte de chaque message de la première requête envoyée au modèle.
  def messages_envoyes
    JSON.parse(@envois.first)['messages'].map { |message| [message['role'], message['content']] }
  end
end
