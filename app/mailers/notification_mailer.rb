# frozen_string_literal: true

class NotificationMailer < ApplicationMailer
  def workflow_changed(intervention, emails)
    @intervention = intervention
    @organisation = intervention.organisation

    mail(to: emails,
         bcc: ENV['BCC_NOTIFICATION_EMAILS'].presence,
         subject: '[COOPCOMM] Changement de statut').tap do |message|
      message.mailgun_options = {
        'tag' => ['changement de statut']
      }
    end
  end

  def relance(intervention)
    @intervention = intervention
    @user = intervention.adherent
    @organisation = intervention.organisation

    mail(to: intervention.adherent.email,
         bcc: ENV['BCC_NOTIFICATION_EMAILS'].presence,
         subject: '[COOPCOMM] Relance. Intervention à valider').tap do |message|
      message.mailgun_options = {
        'tag' => ['relance']
      }
    end
  end

  def intervention_pointage(intervention)
    @intervention = intervention
    @organisation = intervention.organisation

    mail(to: intervention.adherent.email,
         bcc: ENV['BCC_NOTIFICATION_EMAILS'].presence,
         subject: '[COOPCOMM] Pointage').tap do |message|
      message.mailgun_options = {
        'tag' => ['pointage']
      }
    end
  end

  def confirm_email_newsletter(email)
    mail(to: email,
         bcc: ENV['SUPER_ADMIN'].presence,
         subject: '[COOPCOMM] Confirmation de l\'inscription pour la newsletter')
  end

  def welcome_import(user, title, password)
    @user = user
    @password = password
    @organisation = user.organisation
    mail(to: @user.email, subject: title)
  end

  def new_absence(absence, user_email)
    @absence = absence
    @organisation = absence.user.organisation
    mail(to: user_email, subject: '[COOPCOMM] Nouvelle absence')
  end

  def absence_notification(action, resume, resume_avant, user_email, organisation_id)
    @action = action
    @resume = resume
    @resume_avant = resume_avant
    @organisation = Organisation.find_by(id: organisation_id)
    mail(to: user_email, subject: "[COOPCOMM] Absence #{action}")
  end

  def new_intervention_from_adherent(intervention, user_email, title)
    @intervention = intervention
    @organisation = intervention.organisation
    mail(to: user_email, subject: title)
  end

  def intervention_done_by_agent(intervention, user_email, title)
    @intervention = intervention
    @organisation = intervention.organisation
    mail(to: user_email, subject: title)
  end

  def avertissement_reservation(user, tool, date_reservation, date_panne, title)
    @user = user
    @tool = tool
    @date_reservation = date_reservation
    @date_panne = date_panne
    @organisation = tool.organisation

    mail(
      to: @user.email,
      subject: title
    )
  end

  def report_missed_clock_out(intervention_missed, user_email)
    @intervention = intervention_missed
    @agent = @intervention.agents.first
    @organisation = @intervention.organisation

    mail(
      to: user_email,
      subject: "[COOPCOMM] Rappel d'un pointage oublié"
    )
  end

  def cotation_envoyee(cotation, email, cc_email = nil)
    @cotation = cotation
    @organisation = cotation.organisation

    pdf = TransformToPdf::Cotation.call(cotation)

    attachments[cotation.pdf_filename] = pdf.render

    mail(to: email,
         cc: cc_email.presence,
         bcc: ENV['BCC_NOTIFICATION_EMAILS'].presence,
         subject: '[COOPCOMM] Votre cotation').tap do |message|
      message.mailgun_options = {
        'tag' => ['cotation envoyée']
      }
    end
  end

  def cotation_signee(cotation, email)
    @cotation = cotation
    @organisation = cotation.organisation

    mail(to: email,
         bcc: ENV['BCC_NOTIFICATION_EMAILS'].presence,
         subject: '[COOPCOMM] Cotation signée').tap do |message|
      message.mailgun_options = {
        'tag' => ['cotation signée']
      }
    end
  end

  def cotation_refusee(cotation, email, cc_email = nil)
    @cotation = cotation
    @organisation = cotation.organisation

    mail(to: email,
         cc: cc_email.presence,
         bcc: ENV['BCC_NOTIFICATION_EMAILS'].presence,
         subject: '[COOPCOMM] Cotation refusée').tap do |message|
      message.mailgun_options = {
        'tag' => ['cotation refusée']
      }
    end
  end

  def commande_envoyee(commande, email, cc_email = nil)
    @commande = commande
    @organisation = commande.organisation

    pdf = TransformToPdf::Commande.call(commande)

    attachments[commande.pdf_filename] = pdf.render

    mail(to: email,
         cc: cc_email.presence,
         bcc: ENV['BCC_NOTIFICATION_EMAILS'].presence,
         subject: '[COOPCOMM] Votre commande').tap do |message|
      message.mailgun_options = {
        'tag' => ['commande envoyée']
      }
    end
  end

  def facture_envoyee(facture, email, cc_email = nil)
    @facture = facture
    @organisation = facture.organisation

    pdf = TransformToPdf::Facture.call(facture)

    attachments[facture.pdf_filename] = pdf.render

    mail(to: email,
         cc: cc_email.presence,
         bcc: ENV['BCC_NOTIFICATION_EMAILS'].presence,
         subject: '[COOPCOMM] Votre facture').tap do |message|
      message.mailgun_options = {
        'tag' => ['facture envoyée']
      }
    end
  end

  def intervention_pointage_terminee_automatiquement(intervention, agent_email)
    @intervention = intervention
    @organisation = intervention.organisation

    mail(to: agent_email,
         bcc: ENV['BCC_NOTIFICATION_EMAILS'].presence,
         subject: '[COOPCOMM] Pointage terminé automatiquement').tap do |message|
      message.mailgun_options = {
        'tag' => ['pointage terminé']
      }
    end
  end

  def cotations_a_signer_relance(adherent, cotations, title)
    @adherent  = adherent
    @cotations = cotations
    @organisation = adherent.organisation

    mail(to: adherent.email,
         bcc: ENV['BCC_NOTIFICATION_EMAILS'].presence,
         subject: title).tap do |message|
      message.mailgun_options = {
        'tag' => ['relance cotation à signer']
      }
    end
  end

  def welcome_inscription(user)
    @user = user
    mail(to: @user.email, subject: '[COOPCOMM] Bienvenue !')
  end
end
