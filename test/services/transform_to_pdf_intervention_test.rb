# frozen_string_literal: true

require 'test_helper'
require_relative '../support/lecture_pdf'

class TransformToPdfInterventionTest < ActiveSupport::TestCase
  include LecturePdf

  setup do
    @manager = users(:hidalgo)
    @agent = users(:martin_technique_paris)
    @intervention = interventions(:intervention_paris)
    @modele = interventions(:intervention_repete)
  end

  # Les trois images de test/fixtures/files sont vides ou factices : Prawn ne
  # peut rien en faire, et le repli passerait sans rien prouver.
  PNG_MINIMAL = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='

  # ==================== TESTS CRITIQUES ====================
  # L'évaluation d'un agent ne doit jamais lui parvenir : le CCTP la réserve aux
  # gestionnaires, et un PDF se transfère bien plus facilement qu'une page.

  test "l'avis et l'évaluation ne sont imprimés que sur une intervention validée ou refusée (critique)" do
    refute_includes fiche(@intervention, @manager), 'COMPTE-RENDU'

    @intervention.update_column(:workflow_state, Intervention::VALIDE)

    assert_includes fiche(@intervention, @manager), 'COMPTE-RENDU'
  end

  test "l'avis et l'évaluation ne sont jamais imprimés pour un agent (critique)" do
    @intervention.update_column(:workflow_state, Intervention::VALIDE)
    @intervention.update_column(:avis, 'Travail bâclé')

    texte = fiche(@intervention, users(:martin_technique_paris))

    refute_includes texte, 'COMPTE-RENDU'
    refute_includes texte, 'Travail bâclé'
  end

  test "une fiche produite pour un utilisateur d'une autre organisation ne porte aucune donnée (critique)" do
    etranger = users(:manager_marseille)

    texte = fiche(@modele, etranger)

    refute_includes texte, 'POINTAGES'
    refute_includes texte, 'ASSIGNATION'
    refute_includes texte, 'ACTIVITÉ'
  end

  test "l'historique d'un agent ne porte pas les changements de sa seule évaluation (critique)" do
    Audited::Audit.create!(auditable: @intervention, user: @manager, action: 'update',
                           audited_changes: { 'note' => [3, 5] })

    texte = fiche(@intervention, users(:martin_technique_paris))

    refute_includes texte, 'Note / Évaluation'
  end

  # ==================== /TESTS CRITIQUES ====================

  test 'la fiche imprime les sections demande, assignation, intervention et activité' do
    texte = fiche(@intervention, @manager)

    assert_includes texte, 'DEMANDE'
    assert_includes texte, 'ASSIGNATION'
    assert_includes texte, 'INTERVENTION'
    assert_includes texte, 'ACTIVITÉ'
  end

  test "la fiche n'imprime jamais les actions de workflow" do
    texte = fiche(@intervention, @manager)

    refute_includes texte, 'ACTIONS'
    refute_includes texte, 'Terminer'
  end

  test "la fiche porte l'adhérent, le service et le statut de l'intervention" do
    texte = fiche(@intervention, @manager)

    assert_includes texte, @intervention.adherent.nom_prénom
    assert_includes texte, @intervention.service.nom
    assert_includes texte, 'NOUVEAU'
  end

  test 'une description longue passe à la ligne sans rétrécir ni recouvrir le badge' do
    @intervention.update_column(:description,
                                'Remise en état complète des allées du parc municipal avec élagage des arbres')

    lignes = lignes_du_pdf(TransformToPdf::Intervention.call(@intervention, @manager))
    titre = lignes.select { |ligne| ligne[:taille] == TransformToPdf::Intervention::TAILLE_TITRE }
    badge = lignes.find { |ligne| ligne[:texte] == 'NOUVEAU' }

    assert_operator titre.size, :>, 1
    assert_operator titre.last[:y], :>, badge[:y]
  end

  test "le titre reprend la description et prend la couleur de l'état" do
    @intervention.update_column(:description, 'Élagage du square')

    document = TransformToPdf::Intervention.call(@intervention, @manager)

    assert_includes texte_pdf(document), 'Élagage du square'
    assert_includes couleurs_du_pdf(document), couleur_du_theme('secondary')
  end

  test 'un modèle de pointage imprime ses pointages à la place de la réalisation' do
    creer_pointage

    texte = fiche(@modele, @manager)

    assert_includes texte, 'POINTAGES'
    refute_includes texte, 'Temps passé'
  end

  test 'un modèle de pointage sans pointage le dit au lieu de laisser un tableau vide' do
    assert_includes fiche(@modele, @manager), 'Aucun pointage enregistré pour le moment.'
  end

  test "la colonne agent des pointages n'est imprimée que pour un gestionnaire" do
    creer_pointage

    refute_includes section_pointages(fiche(@modele, @agent)), 'Agent'
    assert_includes section_pointages(fiche(@modele, @manager)), 'Agent'
  end

  test "un adhérent reçoit les temps de l'intervention sans les commentaires ni le trajet" do
    intervention = interventions(:intervention_with_location)
    intervention.update_column(:commentaires, 'Mal tondre sur le bord des routes')

    texte = fiche(intervention, users(:adherent_with_location))

    assert_includes texte, 'Temps total'
    refute_includes texte, 'Commentaires'
    refute_includes texte, 'Trajet (AR)'
  end

  test 'le trajet est imprimé en texte, sans la carte' do
    intervention = interventions(:intervention_with_location)
    intervention.update_column(:trajet, 'Distance: 50 km, Durée: 1h 00min, Essence: 3.19 L, CO₂: 7.38 kg')

    texte = fiche(intervention, @manager)

    assert_includes texte, 'Trajet (AR)'
    assert_includes texte, 'Distance: 50 km'
  end

  test 'un caractère absent du jeu latin ne fait pas échouer la génération' do
    @intervention.update_column(:description, 'Tonte du parc ☀ terminée')

    assert_includes fiche(@intervention, @manager), 'Tonte du parc'
  end

  test "l'historique traduit les champs modifiés plutôt que d'imprimer leur nom technique" do
    Audited::Audit.create!(auditable: @intervention, user: @manager, action: 'update',
                           audited_changes: { 'workflow_state' => %w[nouveau terminé] })

    texte = fiche(@intervention, @manager)

    assert_includes texte, 'Statut : nouveau -> terminé'
  end

  test "l'historique nomme l'agent rattaché sans répéter le numéro de l'intervention" do
    Audited::Audit.create!(auditable_type: 'AgentIntervention', auditable_id: 1, action: 'create',
                           associated: @intervention, user: @manager,
                           audited_changes: { 'agent_id' => users(:martin_technique_paris).id,
                                              'intervention_id' => @intervention.id })

    texte = fiche(@intervention, @manager)

    assert_includes texte, "ajouté à l'intervention"
    refute_includes texte, "l'intervention n°#{@intervention.id}"
  end

  test "les photos de la réalisation ne sont pas imprimées pour un adhérent" do
    intervention = interventions(:intervention_with_location)

    texte = fiche(intervention, users(:adherent_with_location))

    assert_includes texte, 'PHOTOS DEMANDE'
    refute_includes texte, 'PHOTOS INTERVENTION'
  end

  test 'chaque page est numérotée à droite, sur la ligne du pied de page' do
    lignes = lignes_du_pdf(TransformToPdf::Intervention.call(@intervention, @manager))
    numeros = lignes.select { |ligne| ligne[:texte].match?(%r{\A\d+/\d+\z}) }
    date = lignes.find { |ligne| ligne[:texte].start_with?('Document généré') }

    assert_equal (1..numeros.size).map { |page| "#{page}/#{numeros.size}" }, numeros.map { |l| l[:texte] }
    assert_equal date[:y], numeros.first[:y]
    assert_operator numeros.first[:x], :>, date[:x]
  end

  test 'le pied de page porte la date de génération' do
    assert_includes fiche(@intervention, @manager), "Document généré le #{I18n.l(Time.current, format: :long)}"
  end

  test 'la bande du pied de page est réservée sous la zone de contenu' do
    document = TransformToPdf::Intervention.call(@intervention, @manager)
    document.render

    assert_operator document.page.margins[:bottom], :>, Prawn::Document.new.page.margins[:bottom]
  end

  test 'une photo dont le fichier est perdu ne fait pas échouer la génération' do
    attacher_photo
    blob = @intervention.photos.first.blob
    blob.service.delete(blob.key)

    assert_includes fiche(@intervention.reload, @manager), 'Aperçu indisponible'
  end

  test 'une photo lisible est convertie et intégrée au document' do
    attacher_photo

    document = TransformToPdf::Intervention.call(@intervention.reload, @manager)

    refute_includes texte_pdf(document), 'Aperçu indisponible'
    assert_operator document.render.scan('/Subtype /Image').size, :>=, 2
  end

  private

  def fiche(intervention, user)
    texte_pdf(TransformToPdf::Intervention.call(intervention, user))
  end

  def section_pointages(texte)
    texte.split('POINTAGES').last
  end

  def lignes_du_pdf(document)
    document.render.dup.force_encoding(Encoding::BINARY).scan(/BT(.*?)ET/m).filter_map do |(bloc)|
      position = bloc.match(/([\d.]+) ([\d.]+) Td/)
      next if position.nil?

      texte = bloc.scan(/<([0-9A-Fa-f]+)>/).map { |(hexa)| [hexa].pack('H*') }.join
      { x: position[1].to_f, y: position[2].to_f, taille: bloc[%r{/F[\w.]+ ([\d.]+) Tf}, 1].to_f,
        texte: texte.force_encoding('Windows-1252').encode('UTF-8') }
    end
  end

  def couleurs_du_pdf(document)
    document.render.scan(/([\d.]+) ([\d.]+) ([\d.]+) scn/).map { |canaux| canaux.map { |v| (v.to_f * 255).round } }
  end

  def couleur_du_theme(nom)
    TransformToPdf::Intervention::COULEURS_ETAT.fetch(nom).scan(/../).map { |octet| octet.to_i(16) }
  end

  def attacher_photo
    @intervention.photos.attach(io: StringIO.new(Base64.decode64(PNG_MINIMAL)),
                                filename: 'photo.png', content_type: 'image/png')
  end

  def creer_pointage
    Intervention.create!(adherent: @modele.adherent, service: @modele.service, agents: [@agent],
                         template_slug: @modele.slug, description: 'Pointage du jour',
                         début: 2.hours.ago, fin: 1.hour.ago, temps_de_pause: 0)
  end
end
