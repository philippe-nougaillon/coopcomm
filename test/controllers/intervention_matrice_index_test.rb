# frozen_string_literal: true

require 'test_helper'
require_relative '../support/interventions_matrice'

# Matrice de caractérisation de la LISTE des interventions (vue normale et vue
# compacte) et de la page d'accueil, pour chaque acteur, chaque type et chaque
# état du workflow.
#
# Comparer avec InterventionMatriceVisibiliteTest (la page d'une intervention) :
# l'adhérent voit ici neuf données que la page détaillée lui cache, et la liste
# affiche des boutons DÉSACTIVÉS là où la page détaillée les masque. Ces deux
# incohérences sont figées telles quelles et signalées.
class InterventionMatriceIndexTest < ActionDispatch::IntegrationTest
  include InterventionsMatrice

  ACTEURS = {
    'administrateur' => :administrateur_paris,
    'manager' => :hidalgo,
    'agent_affecte' => :martin_technique_paris,
    'adherent_proprietaire' => :weil
  }.freeze

  SONDES = {
    'donnee:adherent' => 'Adhérent',
    'donnee:service' => 'Service',
    'donnee:agent' => 'Martin Michel',
    'donnee:debut_fin' => 'Début / Fin',
    'donnee:dates_prevues' => 'Du:',
    'donnee:temps_passe' => 'Temps passé',
    'donnee:temps_total' => 'Temps total',
    'donnee:pause' => 'Pause',
    'donnee:materiel' => 'Matériel',
    'donnee:commentaires' => InterventionsMatrice::SONDE_COMMENTAIRES,
    'donnee:evaluation' => 'Évaluation',
    'donnee:avis' => InterventionsMatrice::SONDE_AVIS
  }.freeze

  # La vue normale montre les mêmes neuf données à TOUS les rôles, y compris à
  # l'adhérent — dont la page détaillée n'en montre aucune.
  DONNEES_VUE_NORMALE = %w[donnee:adherent donnee:service donnee:agent donnee:debut_fin
                           donnee:temps_passe donnee:temps_total donnee:pause donnee:materiel
                           donnee:commentaires].freeze
  DONNEES_VUE_COMPACTE = %w[donnee:dates_prevues].freeze
  EVALUATION = %w[donnee:evaluation donnee:avis].freeze

  ETATS_SANS_ACTIONS = [Intervention::VALIDE, Intervention::REFUSE].freeze

  setup { mere_matrice }

  ACTEURS.each_key do |nom_acteur|
    %w[normal compact].each do |vue|
      test "#{nom_acteur} / vue #{vue} : contenu de la ligne, type par type et état par état" do
        InterventionsMatrice::TYPES.each do |type|
          InterventionsMatrice::ETATS.each do |etat|
            jeton = "SONDEIDX#{SecureRandom.hex(4)}"
            intervention = intervention_matrice(type: type, etat: etat, complete: true, description: jeton)

            sign_in users(ACTEURS[nom_acteur])
            get interventions_url(search: jeton, vue: vue,
                                  archives: (1 if etat == Intervention::ARCHIVE))

            assert_response :success
            assert_equal attendu(nom_acteur, vue, etat), contenu_ligne(intervention, vue),
                         "#{nom_acteur} / #{vue} / #{type} / #{etat}"
          end
        end
      end
    end
  end

  test "accueil : le manager peut terminer, l'agent aussi, l'adhérent valide et refuse" do
    attendus = {
      hidalgo: [Intervention::NOUVEAU, services(:technique), %w[action:terminer]],
      martin_technique_paris: [Intervention::NOUVEAU, services(:technique), %w[action:terminer]],
      weil: [Intervention::TERMINE, services(:informatique), %w[action:valider action:refuser]]
    }

    attendus.each do |fixture, (etat, service, boutons)|
      intervention_matrice(type: :classique, etat: etat, service: service, complete: true,
                           adherent: users(:weil), agent: users(:martin_technique_paris))

      sign_in users(fixture)
      get root_url

      assert_response :success
      assert_equal boutons, boutons_presents(Nokogiri::HTML(response.body)), fixture.to_s
    end
  end

  private

  # Restreint l'analyse au fragment de l'intervention : la page porte des listes
  # de filtres qui contiennent les mêmes intitulés.
  def fragment(intervention, vue)
    doc = Nokogiri::HTML(response.body)
    return doc.at_css("##{ActionView::RecordIdentifier.dom_id(intervention)}") if vue == 'normal'

    doc.at_css("a[href='#{intervention_path(intervention)}']")&.ancestors('tr')&.first
  end

  def contenu_ligne(intervention, vue)
    bloc = fragment(intervention, vue)
    flunk "l'intervention n'apparaît pas dans la liste" if bloc.nil?

    donnees = SONDES.select { |_, sonde| bloc.text.include?(sonde) }.keys
    (donnees + boutons_presents(bloc)).sort
  end

  def boutons_presents(bloc)
    %w[Terminer Valider Refuser].filter_map do |libelle|
      bouton = bloc.css('button, input[type=submit]').find do |element|
        (element.text.presence || element['value'].to_s).strip == libelle
      end
      next if bouton.nil?

      "action:#{libelle.downcase}#{bouton['disabled'] ? '(inactif)' : ''}"
    end
  end

  def attendu(nom_acteur, vue, etat)
    sondes = vue == 'normal' ? DONNEES_VUE_NORMALE.dup : DONNEES_VUE_COMPACTE.dup
    sondes += EVALUATION if vue == 'normal' && ETATS_SANS_ACTIONS.include?(etat) &&
                            nom_acteur != 'agent_affecte'

    (sondes + boutons_attendus(nom_acteur, etat)).sort
  end

  # Aux états validé et refusé, la liste masque tout le bloc d'actions. Ailleurs,
  # « Terminer » n'apparaît que s'il est réellement déclenchable, tandis que
  # « Valider » et « Refuser » sont TOUJOURS rendus, désactivés le cas échéant.
  def boutons_attendus(nom_acteur, etat)
    return [] if ETATS_SANS_ACTIONS.include?(etat)

    boutons = []
    boutons << 'action:terminer' if nom_acteur != 'adherent_proprietaire' && etat == Intervention::NOUVEAU

    if nom_acteur != 'agent_affecte'
      inactif = etat == Intervention::TERMINE ? '' : '(inactif)'
      boutons << "action:valider#{inactif}" << "action:refuser#{inactif}"
    end

    boutons
  end
end
