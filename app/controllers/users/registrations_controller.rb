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

    def destroy
      authorize resource, :desactiver_compte?
      resource.discard!
      sign_out
      set_flash_message! :notice, :destroyed
      redirect_to new_user_session_path, status: :see_other
    end

    private

    def configure_sign_up_params
      devise_parameter_sanitizer.permit(:sign_up, keys: %i[prénom nom])
    end

    def build_resource(hash = {})
      super
      resource.rôle = :administrateur
      resource.confirmed_at = nil
      # nil vaut le défaut de la colonne : sans changement forcé, Rails l'omet de l'INSERT et la base confirme le compte.
      resource.confirmed_at_will_change!
      nom_organisation = params.dig(:user, :nom_organisation).to_s.strip
      return if nom_organisation.blank?

      organisation = Organisation.new(nom: nom_organisation)
      noms_services = Array(params.dig(:user, :noms_services)).compact_blank
      noms_services.uniq { |nom| Service.normalize_value_for(:nom, nom) }.each do |nom|
        resource.user_services.build(service: organisation.services.build(nom: nom))
      end
    end

    def after_inactive_sign_up_path_for(_resource)
      new_user_session_path
    end
  end
end
