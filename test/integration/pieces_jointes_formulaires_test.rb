# frozen_string_literal: true

require 'test_helper'

# Ce que le formulaire propose doit être exactement ce que le modèle accepte :
# sinon l'utilisateur choisit un fichier que le serveur refuse ensuite.
class PiecesJointesFormulairesTest < ActionDispatch::IntegrationTest
  # --- Sentinelle : couvre aussi les formulaires qui n'existent pas encore ----

  test 'aucun champ de pièce jointe hors du partial file_dropzone' do
    partial = Rails.root.join('app/views/shared/_file_dropzone.html.erb').to_s

    fautifs = Dir.glob(Rails.root.join('app/views/**/*.erb')).sort.reject { |chemin| chemin == partial }
                 .select { |chemin| File.read(chemin).match?(/\.file_field\b/) }
                 .map { |chemin| chemin.sub("#{Rails.root}/", '') }

    assert_empty fautifs, <<~MESSAGE
      Ces formulaires posent un champ de pièce jointe à la main.
      Passer par `render "shared/file_dropzone", form: f, attribute: :nom` :
      lui seul dérive l'attribut accept des types validés par le modèle.
    MESSAGE
  end

  # --- Alignement réel, page par page ----------------------------------------

  test 'formulaire de convention' do
    sign_in users(:administrateur_paris)
    get new_convention_url

    assert_dropzone Convention, :document
  end

  test 'formulaire d’outil' do
    sign_in users(:hidalgo)
    get new_tool_url

    assert_dropzone Tool, :photo
    assert_dropzone Tool, :document
  end

  test 'formulaire de page wiki' do
    sign_in users(:administrateur_paris)
    get new_wiki_page_url

    assert_dropzone WikiPage, :document
  end

  test 'formulaire d’utilisateur' do
    sign_in users(:administrateur_paris)
    get edit_user_url(users(:martin_technique_paris))

    assert_dropzone User, :profile_picture
  end

  test 'formulaire d’intervention' do
    sign_in users(:hidalgo)
    get new_intervention_url

    assert_dropzone Intervention, :photos, multiple: true
  end

  test 'formulaire d’intervention : Photos pour l/intervention' do
    sign_in users(:hidalgo)
    get new_intervention_url

    assert_dropzone Intervention, :photos_demande, multiple: true
  end

  private

  def assert_dropzone(modèle, attribut, multiple: false)
    assert_response :success
    nom = "#{modèle.model_name.param_key}[#{attribut}]#{'[]' if multiple}"
    règle = modèle.regles_pieces_jointes[attribut.to_s]

    assert_select "input[type=file][name=?][data-dropzone-target=input]", nom do |champs|
      assert_equal PieceJointeValidable.accept(règle[:types]), champs.first['accept'],
                   "l'attribut accept de #{nom} ne correspond plus aux types validés par #{modèle}"
      assert_equal multiple, champs.first['multiple'].present?
    end

    formats = PieceJointeValidable.libellé_formats(règle[:types])
    taille = PieceJointeValidable.libellé_taille(règle[:max_octets])

    # Une annonce par zone de dépôt partageant ces formats : le formulaire
    # d'intervention en porte deux (photos de réalisation et de demande).
    zones = css_select("input[type=file][accept='#{PieceJointeValidable.accept(règle[:types])}']").size

    assert_select 'span', text: "Formats acceptés : #{formats} — #{taille} maximum par fichier.",
                  count: zones, message: "le formulaire n'annonce pas les formats et la taille validés par #{modèle}##{attribut}"
  end
end
