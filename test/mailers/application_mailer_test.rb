# frozen_string_literal: true

require 'test_helper'

# Le logo de l'en-tête vient du layout commun à tous les mails, ceux de Devise compris.
class ApplicationMailerTest < ActionMailer::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  DESTINATAIRE = 'destinataire@example.com'

  MAILS_D_UNE_ORGANISATION = {
    'de changement de statut' => -> { NotificationMailer.workflow_changed(interventions(:intervention_paris), [DESTINATAIRE]) },
    'de relance' => -> { NotificationMailer.relance(interventions(:intervention_paris)) },
    'de pointage' => -> { NotificationMailer.intervention_pointage(interventions(:intervention_paris)) },
    'de bienvenue' => -> { NotificationMailer.welcome_import(users(:weil), 'Bienvenue', 'mot-de-passe') },
    'de nouvelle absence' => -> { NotificationMailer.new_absence(absences(:one), DESTINATAIRE) },
    'd’absence' => lambda {
      résumé = { 'du' => Date.new(2030, 4, 2), 'au' => Date.new(2030, 4, 2), 'période' => 'Matin', 'motif' => 'Formation', 'observation' => nil }
      NotificationMailer.absence_notification('créée', résumé, nil, DESTINATAIRE, organisations(:mairie_paris).id)
    },
    'de nouvelle demande' => -> { NotificationMailer.new_intervention_from_adherent(interventions(:intervention_paris), DESTINATAIRE, 'Demande') },
    'd’intervention terminée' => -> { NotificationMailer.intervention_done_by_agent(interventions(:intervention_paris), DESTINATAIRE, 'Terminée') },
    'd’avertissement de réservation' => lambda {
      NotificationMailer.avertissement_reservation(users(:bond), tools(:tondeuse), Date.new(2026, 6, 2), Date.new(2026, 6, 1), 'Panne')
    },
    'de pointage oublié' => -> { NotificationMailer.report_missed_clock_out(interventions(:intervention_paris), DESTINATAIRE) },
    'de cotation envoyée' => -> { NotificationMailer.cotation_envoyee(cotations(:cotation_paris), DESTINATAIRE) },
    'de cotation signée' => -> { NotificationMailer.cotation_signee(cotations(:cotation_paris), DESTINATAIRE) },
    'de cotation refusée' => -> { NotificationMailer.cotation_refusee(cotations(:cotation_paris), DESTINATAIRE) },
    'de commande envoyée' => -> { NotificationMailer.commande_envoyee(commandes(:commande_paris), DESTINATAIRE) },
    'de facture envoyée' => -> { NotificationMailer.facture_envoyee(factures(:facture_paris), DESTINATAIRE) },
    'de pointage terminé automatiquement' => lambda {
      NotificationMailer.intervention_pointage_terminee_automatiquement(interventions(:intervention_paris), DESTINATAIRE)
    },
    'de relance des cotations à signer' => -> { NotificationMailer.cotations_a_signer_relance(users(:weil), [cotations(:cotation_paris)], 'Relance') }
  }.freeze

  setup do
    Rails.application.reload_routes_unless_loaded
    @paris = organisations(:mairie_paris)
  end

  # ==================== TESTS CRITIQUES ====================
  # Cloisonnement multi-organisations : un mail ne montre que le logo de l'organisation dont il parle.

  MAILS_D_UNE_ORGANISATION.each do |nom, mail|
    test "le mail #{nom} porte le logo de son organisation (critique)" do
      @paris.logo.attach(fixture_file_upload('logo_organisation.png', 'image/png'))

      src, alt = logo_du_mail(instance_exec(&mail))

      assert_includes src, '/logo_organisation.png'
      assert_equal @paris.nom, alt
    end
  end

  test 'tout nouveau mail de NotificationMailer rejoint la liste des mails portant le logo de leur organisation (critique)' do
    assert_equal NotificationMailer.action_methods.size - 2, MAILS_D_UNE_ORGANISATION.size,
                 'seules la confirmation de newsletter et la bienvenue à l’inscription ne posent pas d’organisation : un nouveau mail pose @organisation et rejoint la liste'
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'le logo d’un mail est servi par une adresse absolue, sans redirection' do
    @paris.logo.attach(fixture_file_upload('logo_organisation.png', 'image/png'))

    src, = logo_du_mail(NotificationMailer.relance(interventions(:intervention_paris)))

    assert_match %r{\Ahttp://www\.example\.com/rails/active_storage/representations/proxy/.+/logo_organisation\.png\z}, src
  end

  test 'le mail d’une organisation sans logo porte le logo de CoopComm' do
    src, alt = logo_du_mail(NotificationMailer.relance(interventions(:intervention_paris)))

    assert_includes src, '/CoopComm.png'
    assert_equal 'CoopComm', alt
  end

  test 'la confirmation de newsletter, sans organisation, porte le logo de CoopComm' do
    src, alt = logo_du_mail(NotificationMailer.confirm_email_newsletter(DESTINATAIRE))

    assert_includes src, '/CoopComm.png'
    assert_equal 'CoopComm', alt
  end

  test 'le mail d’une demande née sans service porte le logo de l’organisation de son adhérent' do
    demande = interventions(:demande_par_mail)
    demande.adherent.organisation.logo.attach(fixture_file_upload('logo_organisation.png', 'image/png'))

    src, = logo_du_mail(NotificationMailer.new_intervention_from_adherent(demande, DESTINATAIRE, 'Demande'))

    assert_includes src, '/logo_organisation.png'
  end

  test 'le mail de réinitialisation du mot de passe porte le logo de l’organisation de l’utilisateur' do
    @paris.logo.attach(fixture_file_upload('logo_organisation.png', 'image/png'))

    src, alt = logo_du_mail(Devise::Mailer.reset_password_instructions(users(:weil), 'jeton'))

    assert_includes src, '/logo_organisation.png'
    assert_equal @paris.nom, alt
  end

  test 'le mail de réinitialisation du mot de passe d’un compte sans service porte le logo de CoopComm' do
    compte_sans_service = users(:weil)
    UserService.where(user_id: compte_sans_service.id).delete_all

    src, alt = logo_du_mail(Devise::Mailer.reset_password_instructions(compte_sans_service.reload, 'jeton'))

    assert_includes src, '/CoopComm.png'
    assert_equal 'CoopComm', alt
  end

  test 'le mail de bienvenue à l’inscription porte le logo de CoopComm, même si l’organisation de l’inscrit a le sien' do
    @paris.logo.attach(fixture_file_upload('logo_organisation.png', 'image/png'))

    src, alt = logo_du_mail(NotificationMailer.welcome_inscription(users(:administrateur_paris)))

    assert_includes src, '/CoopComm.png'
    assert_equal 'CoopComm', alt
  end

  test 'le mail d’une organisation dont le logo n’est pas convertible porte le logo de CoopComm' do
    @paris.logo.attach(io: StringIO.new('pas une image'), filename: 'logo', content_type: 'image/jpg')
    assert_equal 'image/jpg', @paris.reload.logo.content_type

    src, alt = logo_du_mail(NotificationMailer.relance(interventions(:intervention_paris)))

    assert_includes src, '/CoopComm.png'
    assert_equal 'CoopComm', alt
  end

  test 'le logo d’un mail porte en attributs sa taille d’affichage, la seule que lise Outlook pour Windows' do
    @paris.logo.attach(fixture_file_upload('logo_trop_grand.png', 'image/png'))

    _, _, largeur, hauteur = logo_du_mail(NotificationMailer.relance(interventions(:intervention_paris)))

    assert_equal %w[180 90], [largeur, hauteur]
  end

  test 'un logo très large est borné à la largeur de l’en-tête du mail' do
    @paris.logo.attach(fixture_file_upload('logo_tres_large.png', 'image/png'))

    _, _, largeur, hauteur = logo_du_mail(NotificationMailer.relance(interventions(:intervention_paris)))

    assert_equal %w[550 45], [largeur, hauteur]
  end

  test 'le mail d’une organisation dont le logo n’a pas de dimensions porte le logo de CoopComm' do
    @paris.logo.attach(fixture_file_upload('logo_trop_grand.png', 'image/png'))
    @paris.logo.blob.update!(metadata: { identified: true, analyzed: true })

    src, alt = logo_du_mail(NotificationMailer.relance(interventions(:intervention_paris)))

    assert_includes src, '/CoopComm.png'
    assert_equal 'CoopComm', alt
  end

  test 'le logo de CoopComm porte en attributs sa taille d’affichage' do
    _, _, largeur, hauteur = logo_du_mail(NotificationMailer.relance(interventions(:intervention_paris)))

    assert_equal %w[471 90], [largeur, hauteur]
  end

  private

  # Le logo tel qu'un client de messagerie le lit : [src, alt, largeur, hauteur].
  def logo_du_mail(mail)
    image = Nokogiri::HTML((mail.html_part || mail).body.to_s).at_css('.email-header img')

    [image['src'], image['alt'], image['width'], image['height']]
  end
end
