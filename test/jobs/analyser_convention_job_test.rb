# frozen_string_literal: true

require 'test_helper'
require 'turbo/broadcastable/test_helper'
require_relative '../support/faux_modele'
require_relative '../support/faux_ovh'
require_relative '../support/fabrique_pdf'

class AnalyserConventionJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper
  include Turbo::Broadcastable::TestHelper
  include FauxModele
  include FauxOvh
  include FabriquePdf

  TEXTE = 'Entre la Communauté de Communes du Val Fictif et Ariel Weil, adhérent, représenté par son Maire, il est ' \
          'convenu que le service technique intervient pour un volume annuel de 350 heures. La présente convention ' \
          'prend effet le 1er janvier 2025. Elle est conclue pour une durée de trois ans.'

  setup do
    brancher_faux_modele
    @deposant = users(:hidalgo)
    @adherent = users(:weil)
    @technique = services(:technique)
    @reponse = {
      'adherent' => { 'extrait' => 'et Ariel Weil, adhérent', 'nom' => 'Ariel Weil', 'id' => @adherent.id },
      'date_debut' => { 'extrait' => 'prend effet le 1er janvier 2025', 'valeur' => '2025-01-01' },
      'date_signature' => { 'extrait' => nil, 'valeur' => nil },
      'date_fin' => { 'extrait' => nil, 'valeur' => nil },
      'services' => [{ 'extrait' => 'un volume annuel de 350 heures', 'id' => @technique.id, 'heures' => 350 }],
      'resume' => 'Le service technique est mis à la disposition d’Ariel Weil pour 350 heures par an.'
    }
    @convention = convention_deposee(File.read(pdf_de_texte([TEXTE])))
  end

  teardown do
    debrancher_faux_ovh
    debrancher_faux_modele
    fermer_pdf
  end

  test 'une convention déjà analysée n’est pas analysée une seconde fois' do
    stub_reponse_du_modele(@reponse.to_json)
    AnalyserConventionJob.perform_now(@convention)

    AnalyserConventionJob.perform_now(@convention.reload)

    assert_requested(:post, "#{ADRESSE_DU_MODELE}/v1/chat/completions", times: 1)
    assert_predicate @convention.reload, :analysé?
  end

  test 'une convention passée en cours d’analyse depuis le chargement de la tâche n’est pas analysée deux fois' do
    stub_reponse_du_modele(@reponse.to_json)
    Convention.find(@convention.id).analyser!

    AnalyserConventionJob.perform_now(@convention)

    assert_not_requested(:post, "#{ADRESSE_DU_MODELE}/v1/chat/completions")
    assert_predicate @convention.reload, :en_cours?
  end

  test 'une analyse coupée en route passe en échec quand la file rejoue sa tâche, sans rappeler le modèle (critique)' do
    stub_reponse_du_modele(@reponse.to_json)
    @convention.analyser!

    AnalyserConventionJob.perform_now(@convention)

    assert_equal [Convention::ECHEC, "l'analyse a été interrompue"], [@convention.reload.workflow_state, @convention.analyse&.dig('erreur')]
    assert_not_requested(:post, "#{ADRESSE_DU_MODELE}/v1/chat/completions")
  end

  test 'une convention attend l’IA qui démarre, et son analyse est reprogrammée' do
    brancher_faux_ovh('UNSHELVING')
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_raise(Errno::ECONNREFUSED)

    freeze_time do
      AnalyserConventionJob.perform_now(@convention)

      assert_predicate @convention.reload, :attente_ia?
      assert_enqueued_with(job: AnalyserConventionJob, args: [@convention], at: 5.minutes.from_now)
    end
    assert_not_requested(:post, "#{ADRESSE_DU_MODELE}/v1/chat/completions")
  end

  test 'une convention qui attend l’IA depuis plus de deux heures passe en échec, sans être reprogrammée' do
    brancher_faux_ovh('UNSHELVING')
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_raise(Errno::ECONNREFUSED)
    @convention.attendre_l_ia!
    clear_enqueued_jobs

    travel 121.minutes do
      AnalyserConventionJob.perform_now(@convention)
    end

    assert_equal [Convention::ECHEC, "l'IA n'a pas répondu"], [@convention.reload.workflow_state, @convention.analyse['erreur']]
    assert_no_enqueued_jobs only: AnalyserConventionJob
  end

  # ==================== TESTS CRITIQUES ====================
  # Réveiller l'IA engage une dépense : seule une convention qui passe pour la première fois la réveille, et une IA mise
  # en pause pendant qu'une convention l'attendait l'a été par décision de ses propriétaires, jamais rallumée.
  test 'au premier passage d’une convention, l’IA en pause est réveillée et sa surveillance lancée (critique)' do
    brancher_faux_ovh('SHELVED_OFFLOADED')
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_raise(Errno::ECONNREFUSED)

    freeze_time do
      AnalyserConventionJob.perform_now(@convention)

      assert_requested(:post, "#{INSTANCE_OVH}/unshelve", times: 1)
      assert_enqueued_with(job: SurveillerIaJob, at: 1.minute.from_now)
      assert_enqueued_with(job: AnalyserConventionJob, args: [@convention], at: 5.minutes.from_now)
      assert_predicate @convention.reload, :attente_ia?
    end
  end

  test 'une IA mise en pause pendant qu’une convention l’attendait n’est pas rallumée, la convention passe en échec (critique)' do
    brancher_faux_ovh('SHELVED_OFFLOADED')
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_raise(Errno::ECONNREFUSED)
    @convention.attendre_l_ia!
    clear_enqueued_jobs

    AnalyserConventionJob.perform_now(@convention)

    assert_equal [Convention::ECHEC, "l'IA a été mise en pause"], [@convention.reload.workflow_state, @convention.analyse['erreur']]
    assert_not_requested(:post, "#{INSTANCE_OVH}/unshelve")
    assert_no_enqueued_jobs
  end

  test 'un réveil refusé par OVH, l’IA restée en pause, passe la convention en échec (critique)' do
    brancher_faux_ovh('SHELVED_OFFLOADED')
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_raise(Errno::ECONNREFUSED)
    stub_request(:post, "#{INSTANCE_OVH}/unshelve").to_return(status: 500)
    clear_enqueued_jobs

    AnalyserConventionJob.perform_now(@convention)

    assert_equal [Convention::ECHEC, "l'IA n'a pas pu être réveillée : l'API OVH répond 500"],
                 [@convention.reload.workflow_state, @convention.analyse['erreur']]
    assert_no_enqueued_jobs only: AnalyserConventionJob
  end

  test 'un réveil refusé par OVH parce qu’un autre dépôt l’a déjà demandé laisse la convention attendre (critique)' do
    brancher_faux_ovh('SHELVED_OFFLOADED')
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_raise(Errno::ECONNREFUSED)
    stub_request(:get, INSTANCE_OVH).to_return({ status: 200, headers: { 'Content-Type' => 'application/json' }, body: { status: 'SHELVED_OFFLOADED' }.to_json },
                                               { status: 200, headers: { 'Content-Type' => 'application/json' }, body: { status: 'UNSHELVING' }.to_json })
    stub_request(:post, "#{INSTANCE_OVH}/unshelve").to_return(status: 409)

    AnalyserConventionJob.perform_now(@convention)

    assert_predicate @convention.reload, :attente_ia?
    assert_enqueued_with(job: AnalyserConventionJob, args: [@convention])
  end

  test 'un réveil resté sans réponse d’OVH laisse la convention attendre, sa surveillance déjà lancée (critique)' do
    brancher_faux_ovh('SHELVED_OFFLOADED')
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_raise(Errno::ECONNREFUSED)
    stub_request(:post, "#{INSTANCE_OVH}/unshelve").to_timeout

    freeze_time do
      AnalyserConventionJob.perform_now(@convention)

      assert_predicate @convention.reload, :attente_ia?
      assert_enqueued_with(job: SurveillerIaJob, at: 1.minute.from_now)
      assert_enqueued_with(job: AnalyserConventionJob, args: [@convention], at: 5.minutes.from_now)
    end
  end

  test 'un réveil refusé par OVH, qui ne dit plus ensuite l’état de l’IA, laisse la convention attendre (critique)' do
    brancher_faux_ovh('SHELVED_OFFLOADED')
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_raise(Errno::ECONNREFUSED)
    stub_request(:get, INSTANCE_OVH).to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: { status: 'SHELVED_OFFLOADED' }.to_json)
                                    .then.to_timeout
    stub_request(:post, "#{INSTANCE_OVH}/unshelve").to_return(status: 500)

    AnalyserConventionJob.perform_now(@convention)

    assert_predicate @convention.reload, :attente_ia?
    assert_enqueued_with(job: AnalyserConventionJob, args: [@convention])
  end

  test 'une tâche rejouée pour une convention en échec ne réveille pas l’IA (critique)' do
    brancher_faux_ovh('SHELVED_OFFLOADED')
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_raise(Errno::ECONNREFUSED)
    @convention.echouer!('IA injoignable')
    clear_enqueued_jobs

    AnalyserConventionJob.perform_now(@convention)

    assert_not_requested(:post, "#{INSTANCE_OVH}/unshelve")
    assert_no_enqueued_jobs
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'une API OVH injoignable pendant l’attente reprogramme l’analyse sans la passer en échec' do
    brancher_faux_ovh('UNSHELVING')
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_raise(Errno::ECONNREFUSED)
    @convention.attendre_l_ia!
    clear_enqueued_jobs
    stub_request(:get, INSTANCE_OVH).to_return(status: 500)

    AnalyserConventionJob.perform_now(@convention)

    assert_predicate @convention.reload, :attente_ia?
    assert_enqueued_with(job: AnalyserConventionJob, args: [@convention])
  end

  test 'une API OVH injoignable au premier passage laisse la convention en attente, son analyse reprogrammée sans réveil ni surveillance' do
    brancher_faux_ovh('SHELVED_OFFLOADED')
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_raise(Errno::ECONNREFUSED)
    stub_request(:get, INSTANCE_OVH).to_timeout
    clear_enqueued_jobs

    freeze_time do
      AnalyserConventionJob.perform_now(@convention)

      assert_predicate @convention.reload, :en_attente?
      assert_enqueued_with(job: AnalyserConventionJob, args: [@convention], at: 5.minutes.from_now)
    end
    assert_not_requested(:post, "#{INSTANCE_OVH}/unshelve")
    assert_no_enqueued_jobs only: SurveillerIaJob
  end

  test 'une convention dont OVH ne dit pas l’état de l’IA depuis plus de deux heures passe en échec, sans être reprogrammée' do
    brancher_faux_ovh('UNSHELVING')
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_raise(Errno::ECONNREFUSED)
    stub_request(:get, INSTANCE_OVH).to_timeout
    clear_enqueued_jobs

    travel 121.minutes do
      AnalyserConventionJob.perform_now(@convention)
    end

    assert_equal [Convention::ECHEC, "l'IA n'a pas répondu"], [@convention.reload.workflow_state, @convention.analyse['erreur']]
    assert_no_enqueued_jobs only: AnalyserConventionJob
  end

  test 'le réveil de l’IA est annoncé sur la page d’analyse' do
    brancher_faux_ovh('SHELVED_OFFLOADED')
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_raise(Errno::ECONNREFUSED)

    annonces = capture_turbo_stream_broadcasts(:etat_ia) { AnalyserConventionJob.perform_now(@convention) }

    assert_equal 1, annonces.size
    assert_match "L'IA démarre", annonces.first.to_html
  end

  test 'une convention qui attendait l’IA est analysée dès qu’elle répond, et l’annonce de son démarrage est effacée' do
    brancher_faux_ovh('ACTIVE')
    stub_reponse_du_modele(@reponse.to_json)
    @convention.attendre_l_ia!

    annonces = capture_turbo_stream_broadcasts(:etat_ia) { AnalyserConventionJob.perform_now(@convention) }

    assert_predicate @convention.reload, :analysé?
    assert_equal %w[replace etat_ia], [annonces.sole['action'], annonces.sole['target']]
  end

  test 'une convention déposée est analysée : ce que l’IA y a lu la remplit, mémo excepté, et elle attend d’être validée' do
    stub_reponse_du_modele(@reponse.to_json)

    AnalyserConventionJob.perform_now(@convention)

    @convention.reload
    assert_predicate @convention, :analysé?
    assert_equal [@adherent, @technique, 350, Date.new(2025, 1, 1), nil],
                 [@convention.user, @convention.service, @convention.heures_conventionnees, @convention.date_début, @convention.mémo]
    assert_equal({ 'extrait' => 'un volume annuel de 350 heures', 'retrouve' => true }, @convention.analyse['service'])
  end

  test 'les adhérents et les services proposés au modèle sont ceux de l’organisation du déposant (critique)' do
    stub_reponse_du_modele(@reponse.to_json)

    AnalyserConventionJob.perform_now(@convention)

    contenu = corps_envoye_au_modele['messages'].last['content']
    assert_includes contenu, "- #{@adherent.id} : #{@adherent.nom_prénom}"
    assert_includes contenu, "- #{@technique.id} : Technique"
    assert_not_includes contenu, users(:adherent_marseille).nom
    assert_not_includes contenu, services(:service_marseille).nom
  end

  test 'un document illisible passe la convention en échec avec la raison' do
    convention = convention_deposee('%PDF-1.4 ceci n’est pas un PDF')

    AnalyserConventionJob.perform_now(convention)

    assert_equal [Convention::ECHEC, 'PDF illisible'], [convention.reload.workflow_state, convention.analyse['erreur']]
  end

  test 'une IA injoignable passe la convention en échec avec la raison' do
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_raise(Errno::ECONNREFUSED)

    AnalyserConventionJob.perform_now(@convention)

    assert @convention.reload.échec?
    assert_match(/Connection refused/, @convention.analyse['erreur'])
  end

  test 'une erreur inattendue passe la convention en échec, et remonte' do
    AnalyserConvention.stub(:call, ->(*, **) { raise 'boum' }) do
      assert_raises(RuntimeError) { AnalyserConventionJob.perform_now(@convention) }
    end

    assert_equal [Convention::ECHEC, 'erreur inattendue'], [@convention.reload.workflow_state, @convention.analyse['erreur']]
  end

  test 'une convention supprimée avant son tour est abandonnée sans erreur' do
    @convention.destroy!

    assert_nothing_raised { perform_enqueued_jobs }
  end

  test 'le déposant est prévenu par mail quand sa dernière analyse se termine, même si d’autres déposants attendent' do
    stub_reponse_du_modele(@reponse.to_json)
    conventions(:analyse_en_attente).destroy!

    assert_enqueued_email_with NotificationMailer, :analyses_terminees, args: [@deposant] do
      AnalyserConventionJob.perform_now(@convention)
    end
  end

  test 'le déposant est prévenu par mail quand sa dernière analyse passe en échec' do
    stub_request(:get, "#{ADRESSE_DU_MODELE}/health").to_raise(Errno::ECONNREFUSED)
    conventions(:analyse_en_attente).destroy!

    assert_enqueued_email_with NotificationMailer, :analyses_terminees, args: [@deposant] do
      AnalyserConventionJob.perform_now(@convention)
    end
  end

  test 'le déposant n’est pas prévenu tant qu’une autre de ses analyses attend' do
    stub_reponse_du_modele(@reponse.to_json)

    assert_no_enqueued_emails do
      AnalyserConventionJob.perform_now(@convention)
    end
  end

  private

  def convention_deposee(contenu)
    Convention.create!(deposant: @deposant, workflow_state: Convention::EN_ATTENTE,
                       document: { io: StringIO.new(contenu), filename: 'convention.pdf', content_type: 'application/pdf', identify: false })
  end
end
