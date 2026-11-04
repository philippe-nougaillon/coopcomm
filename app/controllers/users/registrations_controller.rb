# frozen_string_literal: true

module Users
  class RegistrationsController < Devise::RegistrationsController
    before_action :demo_uniquement
    before_action :configure_sign_up_params, only: :create

    def create
      super do |user|
        next if params.dig(:user, :nom_organisation).present?

        user.errors.delete(:services)
        user.errors.add(:nom_organisation, 'doit être rempli(e)')
      end
    end

    private

    def demo_uniquement
      raise ActiveRecord::RecordNotFound unless helpers.demo_instance?
    end

    def configure_sign_up_params
      devise_parameter_sanitizer.permit(:sign_up, keys: %i[prénom nom])
    end

    def build_resource(hash = {})
      super
      resource.rôle = :administrateur
      nom_organisation = params.dig(:user, :nom_organisation).to_s.strip
      return if nom_organisation.blank?

      organisation = Organisation.new(nom: nom_organisation)
      noms_services = Array(params.dig(:user, :noms_services)).compact_blank
      noms_services.uniq { |nom| Service.normalize_value_for(:nom, nom) }.each do |nom|
        resource.user_services.build(service: organisation.services.build(nom: nom))
      end
    end
  end
end
