require "test_helper"

class NotifAgentsCommentairesChangedJobTest < ActiveJob::TestCase

  setup do

  end

  test "notifier les agents qu'un commentaire a été ajouté par l'adhérent" do
    # Récupérer une intervention avec un commentaire
    intervention = interventions(:tonte_locaux)

    # Se connecter avec un adhérent
    login(:weil)

    # Modifier le commentaire
    # Vérifier qu'un job a été performé
  end
end
