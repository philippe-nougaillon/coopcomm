# frozen_string_literal: true

require 'test_helper'

# Le webhook WhatsApp est le seul chemin qui crée une intervention sans
# adhérent (TwilioController, save!(validate: false)) : l'agent écrit depuis le
# terrain sans savoir pour quelle commune. Ces tests figent le fait que ce
# brouillon reste consultable et complétable, au lieu d'être une ligne perdue.
class InterventionSansAdherentTest < ActionDispatch::IntegrationTest
  setup do
    @agent = users(:agent_whatsapp)
    @service = @agent.services.first
    @manager = users(:manager_paris)
    @brouillon = Intervention.new(description: '[WhatsApp] Fuite rue des Lilas',
                                  commentaires: 'Fuite constatée ce matin',
                                  service: @service, workflow_state: 'nouveau')
    @brouillon.save!(validate: false)
    @brouillon.agent_interventions.create(agent: @agent)
  end

  test 'le brouillon est bien dépourvu d’adhérent mais rattaché à une organisation' do
    assert_nil @brouillon.adherent_id
    assert_not @brouillon.valid?
    assert_equal @service.organisation, @brouillon.organisation
  end

  test 'le brouillon apparaît dans l’index du manager' do
    sign_in @manager
    get interventions_url

    assert_response :success
    assert_select "a[href=?]", intervention_path(@brouillon)
  end

  test 'la page du brouillon s’affiche pour le manager et pour l’agent' do
    [@manager, @agent].each do |utilisateur|
      sign_in utilisateur
      get intervention_url(@brouillon)

      assert_response :success, "show en erreur pour #{utilisateur.rôle}"
      sign_out utilisateur
    end
  end

  # Sans garde nil sur l'adhérent, le formulaire agent lève dans la vue.
  test 'l’agent peut ouvrir le formulaire d’édition du brouillon' do
    sign_in @agent
    get edit_intervention_url(@brouillon)

    assert_response :success
  end

  test 'le manager complète le brouillon et l’intervention devient valide' do
    adherent = users(:patrick_adherent_paris)

    assert_includes adherent.service_ids, @service.id

    sign_in @manager
    patch intervention_url(@brouillon), params: { intervention: { adherent_id: adherent.id } }

    @brouillon.reload

    assert_equal adherent.id, @brouillon.adherent_id
    assert_predicate @brouillon, :valid?
  end

  # Le contournement des validations doit rester cantonné au webhook : partout
  # ailleurs, une intervention sans service ni adhérent ne doit pas pouvoir naître.
  test 'aucun autre point du code ne contourne les validations d’une intervention' do
    connus = [%r{twilio_controller\.rb}, /associated_convention/]

    coupables = Dir.glob('{app,lib}/**/*.{rb,rake}').flat_map do |fichier|
      File.readlines(fichier).each_with_index.filter_map do |ligne, i|
        "#{fichier}:#{i + 1}" if ligne.match?(/validate:\s*false/) &&
                                 connus.none? { |connu| "#{fichier} #{ligne}".match?(connu) }
      end
    end

    assert_empty coupables,
                 "save(validate: false) hors du webhook : #{coupables.join(', ')}"
  end
end
