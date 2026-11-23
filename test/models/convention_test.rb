# frozen_string_literal: true

require 'test_helper'
require 'turbo/broadcastable/test_helper'

class ConventionTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include Turbo::Broadcastable::TestHelper

  setup do
    @adherent = users(:patrick_adherent_paris)
    @service  = services(:service_paris)
    @hidalgo = users(:hidalgo)
    @analyse = conventions(:analyse_de_weil)
    travel_to Time.zone.local(2026, 10, 26, 12)
  end

  DANS_LA_PÉRIODE_DE_CONVENTION_PARIS = Time.zone.parse('2026-03-02 09:00:00')

  test 'une analyse sans adhérent, sans service, sans date de début ni heures est acceptée' do
    assert build_analyse.valid?
  end

  test 'une convention validée sans adhérent, sans service, sans date de début ni heures est refusée' do
    convention = Convention.new

    assert_not convention.valid?
    assert_equal %i[user service date_début heures_conventionnees], convention.errors.attribute_names
  end

  test 'une seconde convention du même adhérent sur le même service et la même période est refusée' do
    build_convention.save!

    doublon = build_convention

    assert_not doublon.valid?
    assert doublon.errors[:base].any?
  end

  test 'deux conventions du même adhérent sur le même service à des périodes disjointes sont acceptées' do
    build_convention.save!

    suivante = build_convention(date_début: Date.new(2027, 1, 1), date_fin_prévue: Date.new(2027, 12, 31))

    assert suivante.valid?
  end

  test 'une convention qui chevauche une autre convention du même adhérent sur le même service est refusée' do
    build_convention.save!

    chevauchante = build_convention(date_début: Date.new(2026, 12, 31), date_fin_prévue: Date.new(2027, 6, 30))

    assert_not chevauchante.valid?
    assert chevauchante.errors[:base].any?
  end

  test 'une convention sur un autre service du même adhérent est acceptée' do
    @adherent.services << services(:secretariat)
    build_convention.save!

    autre = build_convention(service: services(:secretariat))

    assert autre.valid?
  end

  test "une convention d'un autre adhérent sur le même service est acceptée" do
    build_convention.save!

    autre = build_convention(user: users(:hidalgo))

    assert autre.valid?
  end

  test "une convention modifiée n'est pas comptée comme son propre doublon" do
    convention = build_convention
    convention.save!

    convention.date_fin_prévue = Date.new(2026, 12, 31)

    assert convention.valid?
  end

  test 'une convention sans date de fin est refusée lorsqu’une autre convention du même adhérent sur le même service se termine après son début' do
    build_convention.save!

    sans_fin = build_convention(date_début: Date.new(2026, 6, 1), date_fin_prévue: nil)

    assert_not sans_fin.valid?
    assert sans_fin.errors[:base].any?
  end

  test 'une convention sans date de fin est acceptée lorsqu’elle commence après la fin de la précédente' do
    build_convention.save!

    sans_fin = build_convention(date_début: Date.new(2027, 1, 1), date_fin_prévue: nil)

    assert sans_fin.valid?
  end

  test 'une convention est refusée lorsqu’une convention sans date de fin du même adhérent sur le même service a commencé avant sa fin' do
    build_convention(date_fin_prévue: nil).save!

    suivante = build_convention(date_début: Date.new(2027, 1, 1), date_fin_prévue: Date.new(2027, 12, 31))

    assert_not suivante.valid?
    assert suivante.errors[:base].any?
  end

  test 'une convention qui se termine avant le début d’une convention sans date de fin est acceptée' do
    build_convention(date_fin_prévue: nil).save!

    précédente = build_convention(date_début: Date.new(2025, 1, 1), date_fin_prévue: Date.new(2025, 12, 31))

    assert précédente.valid?
  end

  test 'une analyse qui répète une convention validée est acceptée' do
    build_convention.save!

    assert build_analyse(user: @adherent, service: @service, date_début: Date.new(2026, 1, 1), date_fin_prévue: Date.new(2026, 12, 31)).valid?
  end

  test 'une convention validée n’est pas refusée à cause d’une analyse qui la répète' do
    build_analyse(user: @adherent, service: @service, date_début: Date.new(2026, 1, 1), date_fin_prévue: Date.new(2026, 12, 31)).save!

    assert build_convention.valid?
  end

  test "une convention sur un service de l'adhérent est acceptée" do
    assert build_convention.valid?
  end

  test "une convention sur un service étranger à l'adhérent est refusée" do
    convention = build_convention(service: services(:informatique))

    assert_not convention.valid?
    assert convention.errors[:service].any?
  end

  test "une analyse sur un service étranger à l'adhérent est acceptée" do
    assert build_analyse(user: @adherent, service: services(:informatique)).valid?
  end

  test 'une convention dont la fin est postérieure au début est acceptée' do
    assert build_convention(date_fin_prévue: Date.new(2026, 12, 31)).valid?
  end

  test 'une convention qui commence et finit le même jour est acceptée' do
    même_jour = Date.new(2026, 6, 1)

    assert build_convention(date_début: même_jour, date_fin_prévue: même_jour).valid?
  end

  test 'une convention dont la fin est antérieure au début est refusée' do
    convention = build_convention(date_début: Date.new(2026, 6, 1), date_fin_prévue: Date.new(2026, 1, 1))

    assert_not convention.valid?
    assert convention.errors[:date_fin_prévue].any?
  end

  test 'une convention sans date de fin est acceptée' do
    assert build_convention(date_fin_prévue: nil).valid?
  end

  test 'un document déposé pour être analysé est accepté en PDF' do
    assert convention_deposee('exemple.pdf').valid?
  end

  test 'un document déposé pour être analysé qui n’est pas un PDF est refusé' do
    convention = convention_deposee('page_numerisee.png')

    assert_not convention.valid?
    assert_equal ['format non pris en charge (image/png)'], convention.errors[:document]
  end

  test 'un dépôt sans document est refusé' do
    convention = Convention.new(deposant: @hidalgo, workflow_state: Convention::EN_ATTENTE)

    assert_not convention.valid?
    assert_equal ['doit être rempli(e)'], convention.errors[:document]
  end

  test 'une convention saisie à la main accepte la photo du document signé' do
    assert build_convention(document: { io: file_fixture('page_numerisee.png').open, filename: 'page.png' }).valid?
  end

  test 'une convention créée reçoit une référence au format CONV-AAAA-N' do
    convention = build_convention

    convention.save!

    assert_match(/\ACONV-#{Date.current.year}-\d+\z/, convention.ref)
  end

  test "la référence d'une convention ne change pas à la mise à jour" do
    convention = build_convention
    convention.save!
    ref = convention.ref

    convention.update!(mémo: 'Précision ajoutée')

    assert_equal ref, convention.ref
  end

  test 'une référence de convention fournie explicitement est conservée' do
    convention = build_convention(ref: 'CONV-MANUELLE')

    convention.save!

    assert_equal 'CONV-MANUELLE', convention.ref
  end

  test 'une analyse enregistrée ne reçoit pas de référence' do
    analyse = build_analyse(user: @adherent, service: @service)

    analyse.save!

    assert_nil analyse.ref
  end

  test 'une analyse reçoit sa référence au format CONV-AAAA-N à la validation' do
    @analyse.valider!

    assert_match(/\ACONV-2026-\d+\z/, @analyse.ref)
  end

  test 'la numérotation des références ne compte pas les analyses' do
    première = build_convention
    première.save!
    build_analyse(user: @adherent, service: @service).save!
    seconde = build_convention(date_début: Date.new(2027, 1, 1), date_fin_prévue: Date.new(2027, 12, 31))

    seconde.save!

    assert_equal première.ref.split('-').last.to_i + 1, seconde.ref.split('-').last.to_i
  end

  test 'une convention déposée est mise en file pour être analysée' do
    convention = convention_deposee('exemple.pdf')

    assert_enqueued_with(job: AnalyserConventionJob) { convention.save! }

    assert_equal [convention], enqueued_jobs.last[:args].map { |argument| GlobalID::Locator.locate(argument['_aj_globalid']) }
  end

  test 'une convention déposée est annoncée à son déposant et à son organisation' do
    convention = convention_deposee('exemple.pdf')

    assert_turbo_stream_broadcasts [@hidalgo, :analyses], count: 1 do
      assert_turbo_stream_broadcasts [@hidalgo.organisation, :analyses], count: 1 do
        convention.save!
      end
    end
  end

  test 'une convention sœur créée par une analyse est annoncée sans être mise en file' do
    assert_turbo_stream_broadcasts [@hidalgo, :analyses], count: 1 do
      assert_no_enqueued_jobs(only: AnalyserConventionJob) { build_analyse(user: @adherent, service: @service).save! }
    end
  end

  test 'une convention saisie à la main n’est ni annoncée ni mise en file' do
    assert_no_enqueued_jobs only: AnalyserConventionJob do
      build_convention.save!
    end

    assert_no_turbo_stream_broadcasts [@hidalgo, :analyses]
    assert_no_turbo_stream_broadcasts [@hidalgo.organisation, :analyses]
  end

  test 'un changement d’état d’une analyse est annoncé à son déposant et à son organisation' do
    assert_turbo_stream_broadcasts [@hidalgo, :analyses], count: 1 do
      assert_turbo_stream_broadcasts [@hidalgo.organisation, :analyses], count: 1 do
        conventions(:analyse_en_attente).analyser!
      end
    end
  end

  test 'un changement d’état d’une analyse recharge sa page' do
    analyse = conventions(:analyse_en_attente)

    assert_turbo_stream_broadcasts analyse, count: 1 do
      analyse.analyser!
    end
  end

  test 'une analyse validée quitte la liste des analyses' do
    diffusions = capture_turbo_stream_broadcasts([@hidalgo, :analyses]) { @analyse.valider! }

    assert_equal ['remove'], diffusions.map { |diffusion| diffusion['action'] }
  end

  test 'une modification d’une convention validée née d’une analyse n’est pas annoncée' do
    @analyse.valider!

    assert_empty capture_turbo_stream_broadcasts([@hidalgo, :analyses]) { @analyse.update!(mémo: 'Précision ajoutée') }
  end

  test 'une analyse supprimée est retirée de la liste de son déposant et de son organisation' do
    assert_turbo_stream_broadcasts [@hidalgo, :analyses], count: 1 do
      assert_turbo_stream_broadcasts [@hidalgo.organisation, :analyses], count: 1 do
        @analyse.destroy!
      end
    end
  end

  test 'supprimer une analyse laisse son document aux conventions sœurs' do
    convention = Convention.create!(deposant: @hidalgo, workflow_state: Convention::EN_ATTENTE,
                                    document: { io: file_fixture('exemple.pdf').open, filename: 'convention.pdf' })
    sœur = build_analyse(document: convention.document.blob)
    sœur.save!

    perform_enqueued_jobs(only: ActiveStorage::PurgeJob) { convention.destroy! }

    assert_equal file_fixture('exemple.pdf').binread, sœur.reload.document.download
  end

  test 'la convention la plus récente est listée en tête' do
    ancienne = build_convention(date_début: Date.new(2025, 1, 1))
    ancienne.save!
    récente = build_convention(user: users(:hidalgo), service: services(:technique),
                               date_début: Date.new(2030, 1, 1), date_fin_prévue: Date.new(2030, 12, 31))
    récente.save!

    ordonnées = Convention.ordered.to_a

    assert ordonnées.index(récente) < ordonnées.index(ancienne)
  end

  test 'seules les analyses en attente, en attente de l’IA ou en cours sont en analyse' do
    en_attente_de_l_ia = conventions(:analyse_de_manager_paris)
    en_attente_de_l_ia.attendre_l_ia!
    en_cours = conventions(:analyse_de_l_administrateur_paris)
    en_cours.analyser!

    assert_equal [conventions(:analyse_en_attente), en_attente_de_l_ia, en_cours, conventions(:analyse_d_un_compte_desactive),
                  conventions(:analyse_de_marseille)].sort_by(&:id), Convention.en_analyse.sort_by(&:id)
  end

  # ==================== TESTS CRITIQUES ====================
  # Une convention suit les services de l'utilisateur ; une analyse, que l'IA a pu lire de travers, ne sort pas de son
  # déposant et des administrateurs de son organisation tant qu'elle n'est pas validée.
  test 'un administrateur voit les conventions de son organisation (critique)' do
    assert_includes Convention.visible_to(users(:administrateur_paris)), conventions(:convention_paris)
  end

  test "un administrateur ne voit pas les conventions d'une autre organisation (critique)" do
    assert_not_includes Convention.visible_to(users(:administrateur_paris)), conventions(:convention_marseille)
  end

  test 'un manager voit les conventions de ses services (critique)' do
    assert_includes Convention.visible_to(users(:hidalgo)), conventions(:convention_paris)
  end

  test 'un manager ne voit pas les conventions des autres services (critique)' do
    assert_not_includes Convention.visible_to(users(:manager_marseille)), conventions(:convention_paris)
  end

  test "un adhérent voit ses conventions, jamais celles d'un autre adhérent (critique)" do
    convention_de_patrick = build_convention
    convention_de_patrick.save!

    visibles = Convention.visible_to(users(:weil))

    assert_includes visibles, conventions(:convention_paris)
    assert_not_includes visibles, convention_de_patrick
  end

  test 'un agent ne voit aucune convention (critique)' do
    assert_empty Convention.visible_to(users(:agent_whatsapp))
  end

  test 'un administrateur voit les analyses déposées dans son organisation, compte désactivé compris, et aucune d’une autre (critique)' do
    visibles = Convention.visible_to(users(:administrateur_paris))

    assert_includes visibles, @analyse
    assert_includes visibles, conventions(:analyse_de_manager_paris)
    assert_includes visibles, conventions(:analyse_d_un_compte_desactive)
    assert_includes visibles, conventions(:analyse_citant_un_service_de_marseille)
    assert_not_includes visibles, conventions(:analyse_de_marseille)
  end

  test 'un manager ne voit que les analyses qu’il a déposées (critique)' do
    visibles = Convention.visible_to(@hidalgo)

    assert_includes visibles, @analyse
    assert_includes visibles, conventions(:analyse_en_attente)
    assert_not_includes visibles, conventions(:analyse_de_manager_paris)
  end

  test 'un manager ne voit pas l’analyse qu’un autre a déposée sur son service (critique)' do
    assert_not_includes Convention.visible_to(users(:manager_paris)), conventions(:analyse_de_patrick)
  end

  test 'un adhérent ne voit pas l’analyse qui le nomme (critique)' do
    assert_not_includes Convention.visible_to(@adherent), conventions(:analyse_de_patrick)
  end

  test 'une analyse validée est vue de son adhérent et des managers de son service (critique)' do
    analyse = conventions(:analyse_de_patrick)

    analyse.valider!

    assert_includes Convention.visible_to(@adherent), analyse
    assert_includes Convention.visible_to(users(:manager_paris)), analyse
  end

  # ==================== /TESTS CRITIQUES ====================

  test "les interventions d'une convention sont celles de l'adhérent dans sa période, pas celles en dehors" do
    convention = conventions(:convention_paris)
    dans_la_période = Intervention.create!(
      description: 'Intervention sous convention',
      adherent_id: convention.user_id, service_id: convention.service_id,
      workflow_state: 'nouveau', début: convention.date_début.beginning_of_day + 9.hours,
      slug: SecureRandom.uuid
    )
    hors_période = Intervention.create!(
      description: 'Intervention hors convention',
      adherent_id: convention.user_id, service_id: convention.service_id,
      workflow_state: 'nouveau', début: convention.date_début.beginning_of_day - 2.days,
      slug: SecureRandom.uuid
    )

    interventions = convention.interventions

    assert_includes interventions, dans_la_période
    assert_not_includes interventions, hors_période
  end

  test "les interventions d'une convention sans date de fin sont celles de l'adhérent depuis son début, pas celles d'avant" do
    convention = conventions(:convention_sans_fin)
    des_mois_après = Intervention.create!(
      description: 'Intervention sous convention',
      adherent_id: convention.user_id, service_id: convention.service_id,
      workflow_state: 'nouveau', début: convention.date_début.beginning_of_day + 17.months,
      slug: SecureRandom.uuid
    )
    avant_le_début = Intervention.create!(
      description: 'Intervention hors convention',
      adherent_id: convention.user_id, service_id: convention.service_id,
      workflow_state: 'nouveau', début: convention.date_début.beginning_of_day - 2.days,
      slug: SecureRandom.uuid
    )

    interventions = convention.interventions

    assert_includes interventions, des_mois_après
    assert_not_includes interventions, avant_le_début
  end

  test "les heures consommées d'une convention sont la somme du temps total de ses interventions" do
    convention = conventions(:convention_paris)
    intervention_conventionnee(heures: 3)
    intervention_conventionnee(heures: 5, début: DANS_LA_PÉRIODE_DE_CONVENTION_PARIS + 4.hours)

    assert_equal 8, convention.heures_consommees
  end

  test "les heures consommées d'une convention sans intervention valent zéro" do
    assert_equal 0, conventions(:convention_paris).heures_consommees
  end

  test "une intervention d'un autre service n'est pas comptée dans les heures consommées" do
    convention = conventions(:convention_paris)
    intervention_conventionnee(heures: 4, service: services(:technique))

    assert_equal 0, convention.heures_consommees
  end

  test "une intervention d'un autre adhérent n'est pas comptée dans les heures consommées" do
    convention = conventions(:convention_paris)
    intervention_conventionnee(heures: 4, adherent_id: users(:adhérent_sans_intervention).id)

    assert_equal 0, convention.heures_consommees
  end

  test "une intervention hors période n'est pas comptée dans les heures consommées" do
    convention = conventions(:convention_paris)
    intervention_conventionnee(heures: 4, début: convention.date_début.beginning_of_day - 2.days)

    assert_equal 0, convention.heures_consommees
  end

  test "les heures consommées sont recalculées lorsque le temps d'une intervention est modifié" do
    convention = conventions(:convention_paris)
    intervention = intervention_conventionnee(heures: 3)

    intervention.update!(fin: intervention.début + 5.hours)

    assert_equal 5, convention.heures_consommees
  end

  test "les heures consommées sont recalculées lorsqu'une intervention est supprimée" do
    convention = conventions(:convention_paris)
    intervention_conventionnee(heures: 3).destroy!

    assert_equal 0, convention.heures_consommees
  end

  test "les heures consommées d'une convention sans date de fin sont celles de l'année en cours, pas celles des années précédentes" do
    convention = conventions(:convention_sans_fin)
    intervention_conventionnee(heures: 4, adherent_id: convention.user_id, service: convention.service,
                               agents: [users(:john_wick)], début: Time.zone.local(2025, 6, 2, 9))
    intervention_conventionnee(heures: 3, adherent_id: convention.user_id, service: convention.service,
                               agents: [users(:john_wick)])

    assert_equal 3, convention.heures_consommees
  end

  test 'la couleur du badge distingue les six états' do
    couleurs = Convention.workflow_spec.states.keys.map { |etat| Convention.new(workflow_state: etat).style }

    assert_equal %w[badge-success badge-ghost badge-warning badge-info badge-primary badge-error], couleurs
  end

  test 'l’organisation d’une analyse est celle de son déposant' do
    assert_equal organisations(:mairie_paris), @analyse.organisation_du_deposant
    assert_equal organisations(:mairie_marseille), conventions(:analyse_de_marseille).organisation_du_deposant
  end

  test 'la concurrente d’une analyse est la convention validée du même adhérent pour le même service sur la même période' do
    assert_equal conventions(:convention_paris), conventions(:analyse_deja_conventionnee).concurrente
  end

  test 'une analyse sans adhérent n’a pas de concurrente' do
    assert_nil conventions(:analyse_sans_adherent).concurrente
  end

  test 'une autre analyse n’est jamais une concurrente' do
    build_analyse(user: @adherent, service: @service, date_début: Date.new(2026, 1, 1)).save!

    assert_nil build_analyse(user: @adherent, service: @service, date_début: Date.new(2026, 1, 1)).concurrente
  end

  test 'les erreurs de validation d’une analyse disent ce qui manque, sans rien changer à l’analyse' do
    analyse = conventions(:analyse_sans_adherent)

    erreurs = analyse.erreurs_de_validation

    assert_equal ['Adhérent doit être rempli(e)'], erreurs.full_messages
    assert analyse.analysé?
    assert_empty analyse.errors
  end

  test 'une analyse complète n’a aucune erreur de validation' do
    assert_empty @analyse.erreurs_de_validation
  end

  test 'une analyse en échec garde la raison de l’échec' do
    analyse = conventions(:analyse_en_attente)

    analyse.echouer!('IA injoignable')

    assert_equal [Convention::ECHEC, { 'erreur' => 'IA injoignable' }], [analyse.reload.workflow_state, analyse.analyse]
  end

  test 'une analyse relancée repasse en attente sans la raison de son échec' do
    analyse = conventions(:analyse_en_echec)

    analyse.relancer!

    assert_equal [Convention::EN_ATTENTE, {}], [analyse.reload.workflow_state, analyse.analyse]
  end

  private

  def intervention_conventionnee(heures:, **attrs)
    convention = conventions(:convention_paris)
    début = attrs.delete(:début) || DANS_LA_PÉRIODE_DE_CONVENTION_PARIS
    Intervention.create!({ description: 'Intervention sous convention',
                           adherent_id: convention.user_id,
                           service: convention.service,
                           agents: [users(:hidalgo)],
                           temps_de_pause: 0,
                           début: début,
                           fin: début + heures.hours,
                           slug: SecureRandom.uuid }.merge(attrs))
  end

  def build_convention(attrs = {})
    Convention.new({ user: @adherent, service: @service, heures_conventionnees: 100,
                     date_début: Date.new(2026, 1, 1), date_fin_prévue: Date.new(2026, 12, 31) }.merge(attrs))
  end

  # Une convention lue par l'IA, en attente de validation.
  def build_analyse(attrs = {})
    Convention.new({ deposant: @hidalgo, workflow_state: Convention::ANALYSE, heures_conventionnees: nil }.merge(attrs))
  end

  # Une convention déposée pour être analysée, comme le fait la page d'analyse.
  def convention_deposee(fichier)
    Convention.new(deposant: @hidalgo, workflow_state: Convention::EN_ATTENTE, document: { io: file_fixture(fichier).open, filename: fichier })
  end
end
