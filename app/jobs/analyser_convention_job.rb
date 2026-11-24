# frozen_string_literal: true

class AnalyserConventionJob < ApplicationJob
  queue_as :default
  # Après les notifications, qui n'attendent pas une analyse ; quatre de front au plus, comme les emplacements du serveur du modèle.
  queue_with_priority 10
  limits_concurrency to: 4, key: 'analyse_des_conventions'
  discard_on ActiveJob::DeserializationError

  ATTENTE_DE_L_IA = 5.minutes
  ABANDON = 2.hours

  # Tâche rejouée par la file : analyse coupée en route, échec à relancer ; convention déjà traitée, rien ; deux exécutions de front, une seule analyse, sous verrou.
  def perform(convention)
    return finir(convention) { convention.echouer!("l'analyse a été interrompue") } if convention.en_cours?
    return unless convention.can_analyser?
    return attendre_l_ia(convention) if InstanceIa.pilotable? && !InterrogerIa.disponible?

    AnnoncerEtatIa.call('ACTIVE') if convention.attente_ia?
    return unless convention.with_lock { convention.can_analyser? && convention.analyser! }

    organisation = convention.organisation_du_deposant
    convention.document.open do |fichier|
      lecture = LireDocument.call(fichier.path, convention.document.content_type)
      lu = AnalyserConvention.call(lecture, adherents: organisation.users.adhérent.ordered, services: organisation.services.ordered)
      finir(convention) { ImporterConvention.call(convention, lu, lecture) }
    end
  rescue LireDocument::Illisible, InterrogerIa::Erreur => e
    finir(convention) { convention.echouer!(e.message) }
  rescue StandardError
    finir(convention.reload) { convention.echouer!('erreur inattendue') if convention.can_echouer? }
    raise
  end

  private

  # Une IA en pause est réveillée au premier passage d'un document ; mise en pause pendant qu'il l'attendait, quelqu'un l'a
  # décidé : le document passe en échec. Tant qu'OVH ne dit pas son état, le document attend.
  def attendre_l_ia(convention)
    etat = InstanceIa.etat
    en_pause = InstanceIa::EN_PAUSE.include?(etat)
    if convention.attente_ia? && (en_pause || convention.updated_at < ABANDON.ago)
      AnnoncerEtatIa.call(etat) if en_pause
      return finir(convention) { convention.echouer!(en_pause ? "l'IA a été mise en pause" : "l'IA n'a pas répondu") }
    end

    convention.attendre_l_ia! if convention.en_attente?
    refus = reveiller_l_ia if en_pause
    return finir(convention) { convention.echouer!("l'IA n'a pas pu être réveillée : #{refus}") } if refus

    self.class.set(wait: ATTENTE_DE_L_IA).perform_later(convention)
  rescue InstanceIa::Erreur
    return finir(convention) { convention.echouer!("l'IA n'a pas répondu") } if convention.updated_at < ABANDON.ago

    self.class.set(wait: ATTENTE_DE_L_IA).perform_later(convention)
  end

  # Rend le refus d'OVH si l'IA est restée en pause : deux documents peuvent la réveiller au même instant. Sans réponse
  # d'OVH, la demande a pu partir : la surveillance est lancée avant elle, et le document attend.
  def reveiller_l_ia
    SurveillerIaJob.set(wait: SurveillerIaJob::CADENCE).perform_later
    InstanceIa.reveiller
    AnnoncerEtatIa.call('UNSHELVING')
    nil
  rescue InstanceIa::SansReponse
    nil
  rescue InstanceIa::Erreur => e
    e.message if InstanceIa::EN_PAUSE.include?(InstanceIa.etat)
  end

  # Le déposant est prévenu quand plus aucune de ses analyses n'attend ; sous verrou, pour que deux analyses qui finissent au
  # même instant n'envoient ni deux mails ni aucun.
  def finir(convention)
    deposant = convention.deposant
    reste = deposant.with_lock do
      yield
      Convention.en_analyse.exists?(deposant: deposant)
    end
    NotificationMailer.analyses_terminees(deposant).deliver_later unless reste
  end
end
