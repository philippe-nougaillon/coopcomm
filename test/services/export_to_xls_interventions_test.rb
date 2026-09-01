# frozen_string_literal: true

require 'test_helper'

class ExportToXlsInterventionsTest < ActiveSupport::TestCase
  setup do
    @adherent = users(:weil)
    @interventions = creer_interventions
  end

  test 'aucune intervention donne un classeur réduit à sa ligne d’en-tête' do
    assert_equal 1, feuille_des_interventions(Intervention.none).rows.count
  end

  test 'chaque intervention occupe une ligne, sous l’en-tête' do
    assert_equal @interventions.count + 1, feuille_des_interventions(@interventions).rows.count
  end

  test 'le classeur des interventions porte quinze colonnes' do
    assert_equal 15, feuille_des_interventions(@interventions).row(0).size
  end

  test 'sans évaluation, les colonnes Évaluation et Avis sont absentes' do
    binaire = ExportToXls::Interventions.call(@interventions, include_evaluation: false)
    entetes = Spreadsheet.open(StringIO.new(binaire)).worksheet(0).row(0).to_a

    assert_equal 13, entetes.size
    assert_not_includes entetes, 'Évaluation'
    assert_not_includes entetes, 'Avis'
  end

  test 'le classeur porte autant de colonnes Agent que l’intervention la plus fournie' do
    interventions = Intervention.where(id: [interventions(:tonte_locaux).id, interventions(:intervention_fille).id])
    maximum = interventions.map { |intervention| intervention.agents.count }.max
    entetes = feuille_des_interventions(interventions).row(0).to_a

    assert_operator maximum, :>=, 1, 'garde : au moins une intervention avec un agent'
    assert_equal maximum, entetes.count { |entete| entete.to_s.start_with?('Agent ') }
  end

  test 'les mots clés de l’intervention sont joints dans leur colonne' do
    intervention = @interventions.first
    intervention.update!(tag_list: 'urgence, plomberie')

    feuille = feuille_des_interventions(Intervention.where(id: intervention.id))

    assert_equal 'urgence, plomberie', feuille.row(1)[feuille.row(0).index('Mots clés')]
  end

  private

  def feuille_des_interventions(interventions)
    Spreadsheet.open(StringIO.new(ExportToXls::Interventions.call(interventions))).worksheet(0)
  end

  def creer_interventions(count = 3)
    count.times do |i|
      Intervention.create!(
        description: "Test intervention #{i}",
        workflow_state: Intervention::NOUVEAU,
        début: 2.hours.ago,
        fin: Time.current,
        temps_de_pause: 0,
        slug: SecureRandom.uuid,
        adherent: @adherent,
        service: @adherent.services.first
      )
    end
    Intervention.where('description LIKE ?', 'Test intervention%')
  end
end
