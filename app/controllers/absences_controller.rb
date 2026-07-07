# frozen_string_literal: true

class AbsencesController < ApplicationController
  skip_before_action :return_security

  def destroy
    @absence = Absence.find(params[:id])
    authorize @absence

    @user = @absence.user
    @absence.destroy

    respond_to do |format|
      format.html { redirect_to user_path(@user), notice: "L'absence a été supprimée avec succès." }
      format.json { head :no_content }

      format.turbo_stream do
        flash.now[:notice] = "L'absence a été supprimée avec succès."
        @absences = @user.absences
        render turbo_stream: [
          turbo_stream.update('absences_section', partial: 'users/absences_section',
                                                  locals: { user: @user, absences: @absences }),
          turbo_stream.update('notification', partial: 'partials/notification')
        ]
      end
    end
  end
end
