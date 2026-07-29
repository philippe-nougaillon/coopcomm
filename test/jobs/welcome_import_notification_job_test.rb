# frozen_string_literal: true

require 'test_helper'

class WelcomeImportNotificationJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @user         = users(:weil)
    @current_user = users(:administrateur_paris)
    @password     = 'MotDePasseImporté123!'
    @encrypted    = encrypt_import_password(@password)
  end

  test 'envoie le mail de bienvenue import avec le mot de passe déchiffré' do
    assert_emails 1 do
      WelcomeImportNotificationJob.perform_now(@user, @current_user.id, @encrypted)
    end

    mail = ActionMailer::Base.deliveries.last
    assert_equal [@user.email], mail.to
    assert_equal '[CoopComm] Bienvenue !', mail.subject
    # Le mot de passe en clair, déchiffré dans le job, doit figurer dans le mail.
    assert_includes mail.body.encoded, @password
  end

  test 'un jeton chiffré invalide fait échouer le job (aucun mail envoyé)' do
    assert_no_emails do
      assert_raises(ActiveSupport::MessageEncryptor::InvalidMessage) do
        WelcomeImportNotificationJob.perform_now(@user, @current_user.id, 'jeton-bidon')
      end
    end
  end

  test 'QUIRK : le MailLog n\'est pas tracé (organisation_id manquant)' do
    # Le job appelle MailLog.create SANS organisation_id ; la colonne est NOT NULL →
    # l'enregistrement échoue silencieusement (create, pas create!).
    assert_no_difference -> { MailLog.count } do
      WelcomeImportNotificationJob.perform_now(@user, @current_user.id, @encrypted)
    end
  end

  private

  # Reproduit le chiffrement attendu par le job (clé dérivée « import_password »).
  def encrypt_import_password(plain)
    key_len    = ActiveSupport::MessageEncryptor.key_len
    secret_key = Rails.application.key_generator.generate_key('import_password', key_len)
    ActiveSupport::MessageEncryptor.new(secret_key).encrypt_and_sign(plain)
  end
end
