# frozen_string_literal: true

require 'test_helper'
require_relative '../support/interventions_matrice'

# Matrice de caractérisation de la LISTE des interventions (vue normale et vue
# compacte) et de la page d'accueil, pour chaque acteur, chaque type et chaque
# état du workflow.
#
# Comparer avec InterventionMatriceVisibiliteTest (la page d'une intervention) :
# l'adhérent voit encore ici les agents, le matériel, les mots clés et les photos
# que la page détaillée lui cache. Cette incohérence est figée telle quelle et
# signalée.
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

  # La vue normale montre les mêmes huit données à TOUS les rôles, y compris à
  # l'adhérent — dont la page détaillée n'en montre aucune.
  DONNEES_VUE_NORMALE = %w[donnee:adherent donnee:service donnee:agent donnee:debut_fin
                           donnee:temps_passe donnee:temps_total donnee:pause
                           donnee:materiel].freeze
  DONNEES_VUE_COMPACTE = %w[donnee:dates_prevues].freeze
  EVALUATION = %w[donnee:evaluation donnee:avis].freeze

  ETATS_AVEC_EVALUATION = [Intervention::VALIDE, Intervention::REFUSE].freeze

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

  # Restreint l'analyse au fragment de l'intervention : la page porte des listes
  # de filtres qui contiennent les mêmes intitulés.

  private

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
    return (DONNEES_VUE_COMPACTE + boutons_attendus(nom_acteur, etat)).sort if vue == 'compact'

    sondes = DONNEES_VUE_NORMALE.dup
    # Les commentaires ne sont pas montrés à l'adhérent.
    sondes << 'donnee:commentaires' unless nom_acteur == 'adherent_proprietaire'
    # L'évaluation et l'avis ne sont jamais montrés à l'agent noté.
    sondes += EVALUATION if ETATS_AVEC_EVALUATION.include?(etat) && nom_acteur != 'agent_affecte'

    (sondes + boutons_attendus(nom_acteur, etat)).sort
  end

  # Un bouton n'est rendu que si la transition est réellement déclenchable — la
  # liste ne rend plus, comme avant, des boutons désactivés.
  def boutons_attendus(nom_acteur, etat)
    boutons = []
    boutons << 'action:terminer' if nom_acteur != 'adherent_proprietaire' && etat == Intervention::NOUVEAU
    if nom_acteur != 'agent_affecte' && etat == Intervention::TERMINE
      boutons << 'action:valider' << 'action:refuser'
    end

    boutons
  end
end
