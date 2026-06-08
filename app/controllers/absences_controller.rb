# app/controllers/absences_controller.rb
class AbsencesController < ApplicationController
  def destroy
    @absence = Absence.find(params[:id])
    @absence.destroy

    respond_to do |format|
      # Si por alguna razón no usa Turbo, redirige al perfil del usuario
      format.html { redirect_to user_path(@absence.user), notice: "L'absence a été supprimée." }
      
      # ⚡ Esto buscará el id="absence_XX" de tu <tr> en la tabla y lo borrará en vivo
      format.turbo_stream do
        render turbo_stream: turbo_stream.remove("absence_#{@absence.id}")
      end
    end
  end
end