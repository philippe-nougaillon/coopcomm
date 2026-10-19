# frozen_string_literal: true

# Pose l'adresse de support lue par ApplicationMailbox au routage, et la
# restaure : héritée de .env, elle marcherait en local et casserait en CI.
module AdresseSupport
  ADRESSE_SUPPORT = 'support-test@mg.exemple.fr'

  def self.included(base)
    base.setup do
      @support_email_avant = ENV.fetch('SUPPORT_EMAIL', nil)
      ENV['SUPPORT_EMAIL'] = ADRESSE_SUPPORT
    end

    base.teardown do
      ENV['SUPPORT_EMAIL'] = @support_email_avant
    end
  end
end
