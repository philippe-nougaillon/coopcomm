# frozen_string_literal: true

# Partagé par UsersController (modification) et AdminController (création) : les deux
# doivent permettre exactement les mêmes attributs et borner les services de la même
# façon, sinon la création perd des champs en silence.
module UserParamsPermis
  extend ActiveSupport::Concern

  private

  # :rôle n'est accepté que d'un administrateur (seul à voir le sélecteur dans le
  # formulaire) ; service_ids est borné aux services assignables.
  def user_params
    permitted = params.require(:user).permit(
      :nom, :prénom, :téléphone, :email, :password, :password_confirmation, :memo,
      :address, :longitude, :latitude, :profile_picture, :color,
      tag_list: [], absences_attributes: %i[id du au motif observation matin après_midi _destroy], service_ids: []
    )

    rôle = params[:user][:rôle] || params[:user][:role]
    permitted[:rôle] = rôle if current_user.administrateur? && User.rôles.key?(rôle.to_s)

    permitted.delete(:absences_attributes) unless current_user.manager_or_admin?

    # service_ids= écrit immédiatement en base (has_many through) : on ne garde
    # que les services assignables, et on ne touche à rien si la demande est
    # entièrement hors périmètre (tentative de forgerie).
    demandés = Array(permitted[:service_ids]).compact_blank
    if demandés.any?
      valides = services_assignables.where(id: demandés).ids
      valides.any? ? permitted[:service_ids] = valides : permitted.delete(:service_ids)
    end

    permitted
  end

  # Un administrateur attribue n'importe quel service de son organisation, un
  # manager seulement les siens. Les services déjà portés par la fiche modifiée
  # restent assignables, sinon un manager au périmètre plus étroit les effacerait
  # en enregistrant le formulaire.
  def services_assignables
    base = current_user.administrateur? ? current_organisation&.services : current_user.services
    Service.where(id: Array(base&.ids) + Array(@user&.services&.ids))
  end
end
