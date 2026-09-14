# frozen_string_literal: true

module TransformToPdf
  # Fiche détaillée d'une intervention, calquée sur les sections de sa page.
  class Intervention < ApplicationService
    include Prawn::View
    include ActionView::Helpers::TranslationHelper
    include AuditsHelper

    require 'prawn/table'

    LARGEUR_LIBELLE = 120
    TAILLE_VIGNETTE = 120
    VIGNETTES_PAR_LIGNE = 4
    ESPACE_VIGNETTE = 10
    TAILLE_TITRE = 20
    HAUTEUR_TITRE = 26
    TAILLE_BADGE = 8
    HAUTEUR_BADGE = 15
    ESPACE_BADGE = 8

    COULEURS_ETAT = {
      'primary' => '0082CE',
      'secondary' => '61738D',
      'success' => '00A43B',
      'error' => 'FF6266',
      'warning' => 'FDC700',
      'neutral' => '000000'
    }.freeze

    # Les polices intégrées de Prawn ne connaissent que Windows-1252 et lèvent
    # sur tout le reste. Le texte du trajet porte « CO₂ », et une saisie mobile
    # peut porter n'importe quoi.
    SUBSTITUTIONS = { '₂' => '2', '→' => '->' }.freeze

    def initialize(intervention, user)
      super()

      @intervention = intervention
      @user = user
      @policy = InterventionPolicy.new(user, intervention)

      Prawn::Fonts::AFM.hide_m17n_warning = true
      @logo = Rails.root.join('app/assets/images/Logo_CC_MAd_et_Moselle.jpg').to_s
    end

    def call
      add_header
      add_demande
      add_assignation
      add_realisation
      add_compte_rendu
      add_activite
      add_footer
      self
    end

    private

    def add_header
      image @logo, height: 80, position: :right if File.exist?(@logo)

      add_titre_et_badge
      mention = mention_pointage
      text mention, size: 10, style: :italic if mention

      move_down 10
      stroke_horizontal_rule
      move_down 20
    end

    # Le titre porte la couleur de l'état et le badge le suit sur la même ligne,
    # comme sur la page. Le titre est borné pour laisser sa place au badge.
    def add_titre_et_badge
      libellé = texte_sûr(@intervention.description.to_s.humanize)
      état = texte_sûr(@intervention.workflow_state.to_s.humanize.upcase)
      couleur = couleur_état

      haut = cursor
      place_badge = largeur_badge(état) + ESPACE_BADGE
      largeur = [width_of(libellé, size: TAILLE_TITRE, style: :bold), bounds.width - place_badge].min

      # `text_box` ignore l'option `color:` ; seul `fill_color` teinte le texte.
      fill_color couleur
      text_box libellé, at: [0, haut], width: largeur, height: HAUTEUR_TITRE,
                        size: TAILLE_TITRE, style: :bold, overflow: :shrink_to_fit
      fill_color '000000'

      dessiner_badge(état, couleur, largeur + ESPACE_BADGE, centre_optique(TAILLE_TITRE, haut))

      move_cursor_to haut - HAUTEUR_TITRE
    end

    # `centre` est l'axe vertical du texte à côté duquel le badge se pose : la
    # pilule et son libellé s'y centrent, faute de quoi le badge pend sous le titre.
    def dessiner_badge(texte, couleur, gauche, centre)
      largeur = largeur_badge(texte)

      haut = centre + (HAUTEUR_BADGE / 2.0)

      fill_color couleur
      fill_rounded_rectangle [gauche, haut], largeur, HAUTEUR_BADGE, HAUTEUR_BADGE / 2.0
      fill_color 'FFFFFF'
      text_box texte, at: [gauche, haut], width: largeur, height: HAUTEUR_BADGE,
                      size: TAILLE_BADGE, style: :bold, align: :center, valign: :center
      fill_color '000000'
    end

    # Milieu de la ligne de texte, descendantes comprises — ce que centre le
    # `items-center` de la page.
    # ⚠ Les métriques ne suivent la taille que si `font_size` est assignée : dans
    # un bloc `font_size(t) { font.ascender }`, Prawn rend toujours la même valeur.
    def centre_optique(taille, haut)
      ancienne = document.font_size
      document.font_size = taille
      milieu = (document.font.ascender + document.font.descender) / 2.0
      document.font_size = ancienne

      haut - milieu
    end

    def largeur_badge(texte)
      width_of(texte, size: TAILLE_BADGE, style: :bold) + 16
    end

    def couleur_état
      COULEURS_ETAT.fetch(@intervention.style.to_s.split.first.to_s.split('-').last, COULEURS_ETAT['neutral'])
    end

    def mention_pointage
      return 'Modèle pour le pointage' if @intervention.repeter?
      return nil if @intervention.template_slug.blank?

      mère = @intervention.intervention_mère
      mère ? "Pointage du modèle n°#{mère.id}" : 'Pointage'
    end

    def add_demande
      titre_section('Demande')

      lignes = [
        ['Adhérent', @intervention.adherent&.nom_prénom.presence || '—'],
        ['Service', @intervention.service&.nom.to_s],
        ['Météo', @intervention.meteo.presence&.split('|')&.map(&:strip)&.join(', ') || 'Non renseignée']
      ]

      if @policy.voir_dates_prevues?
        lignes << ['Début prévu', date_ou(@intervention.début_prévue, 'Non renseigné')]
        lignes << ['Fin prévue', date_ou(@intervention.fin_prévue, 'Non renseignée')]
      end

      table_infos(lignes)
      ajouter_photos(@intervention.photos_demande, "Aucune photo n'est attachée à la demande.")
    end

    def add_assignation
      return unless @policy.voir_assignation?

      titre_section('Assignation')
      table_infos([
                    ['Agents', liste_ou(@intervention.agents.map(&:nom_prénom), 'Aucun agent assigné')],
                    ['Matériel(s)', liste_ou(@intervention.tools.map(&:name), 'Aucun matériel')],
                    ['Mots clés', liste_ou(@intervention.tags.map { |tag| tag.name.humanize }, 'Aucun mot clé')]
                  ])
    end

    # Chaîne exclusive, comme sur la page : sans le `elsif`, un adhérent
    # recevrait deux sections « Intervention ».
    def add_realisation
      if @policy.voir_pointages?
        add_pointages
      elsif @policy.voir_realisation?
        add_intervention_complete
      elsif @policy.voir_temps?
        add_temps_seuls
      end
    end

    def add_intervention_complete
      titre_section('Intervention')
      table_infos(lignes_dates_et_temps + lignes_trajet)

      move_down 10
      text 'Commentaires', size: 10, style: :bold
      move_down 4
      text texte_sûr(@intervention.commentaires.presence || 'Aucun commentaire.'), size: 10

      ajouter_photos(@intervention.photos, "Aucune photo n'est attachée à cette intervention.")
    end

    def add_temps_seuls
      titre_section('Intervention')
      table_infos(lignes_dates_et_temps)
    end

    def lignes_dates_et_temps
      [
        ['Début', date_ou(@intervention.début, 'Non renseigné', format: @intervention.format_date)],
        ['Fin', date_ou(@intervention.fin, 'Non renseignée', format: @intervention.format_date)],
        ['Temps passé', "#{@intervention.temps_par_agent} h"],
        ['Temps total', "#{@intervention.temps_total} h"],
        ['Pause', "#{@intervention.temps_de_pause} h"]
      ]
    end

    # Le texte du trajet porte déjà la distance, la durée et le CO₂ ; la carte
    # de la page n'a pas d'équivalent imprimable.
    def lignes_trajet
      return [] unless @intervention.service&.calculate_distance?

      texte = @intervention.trajet.presence || routes_response&.dig('routes_info').presence
      [['Trajet (AR)', texte || 'Trajet non disponible.']]
    end

    def routes_response
      return @routes_response if defined?(@routes_response)

      @routes_response =
        if @intervention.nouveau? || @intervention.trajet.blank?
          @intervention.get_routes_info_from_location
        end
    end

    def add_pointages
      titre_section('Pointages')

      entetes = ['Début', 'Fin', 'Temps total', 'Statut', 'Commentaires']
      entetes.unshift('Agent') if @policy.voir_agent_des_pointages?

      lignes = pointages_visibles.map { |pointage| ligne_pointage(pointage) }

      if lignes.empty?
        text 'Aucun pointage enregistré pour le moment.', size: 10, style: :italic
        return
      end

      table_donnees([entetes] + lignes)
    end

    def ligne_pointage(pointage)
      ligne = [
        date_ou(pointage.début, '—', format: pointage.format_date),
        date_ou(pointage.fin, '—', format: pointage.format_date),
        "#{pointage.temps_total} h",
        pointage.workflow_state.to_s.humanize,
        pointage.commentaires.presence || '—'
      ]
      ligne.unshift(pointage.agents.first&.nom_prénom || '—') if @policy.voir_agent_des_pointages?
      ligne
    end

    # Un agent ne voit que ses propres pointages, comme sur la page.
    def pointages_visibles
      return @intervention.pointages unless @user.agent?

      @user.interventions.where(template_slug: @intervention.slug, repeter: false).order(updated_at: :desc)
    end

    def add_compte_rendu
      return unless @policy.voir_compte_rendu?

      titre_section('Compte-rendu')
      table_infos([
                    ['Avis', @intervention.avis.presence || 'Aucun avis renseigné.'],
                    ['Évaluation', @intervention.note.present? ? "#{@intervention.note} / 5" : '—']
                  ])
    end

    def add_activite
      return unless @policy.voir_activite?

      titre_section('Activité')

      lignes = grouper_audits(audits_visibles).map { |audit| ligne_audit(audit) }

      if lignes.empty?
        text "Aucun historique d'activité disponible.", size: 10, style: :italic
        return
      end

      largeur = bounds.width
      table_donnees([%w[Date Utilisateur Action Modifications]] + lignes,
                    colonnes: [largeur * 0.16, largeur * 0.24, largeur * 0.18, largeur * 0.42])
    end

    def ligne_audit(audit)
      [
        l(audit.created_at, format: '%d/%m/%Y à %H:%M'),
        audit.user&.email || 'System Console',
        badge_config(audit).first,
        modifications_texte(audit)
      ]
    end

    # Un agent ne voit jamais sa propre évaluation.
    def audits_visibles
      audits = @intervention.own_and_associated_audits.includes(:user).reorder(created_at: :desc).to_a
      return audits unless @user.agent?

      audits.reject { |audit| audit.audited_changes.keys.map(&:to_s) == ['note'] }
    end

    # Équivalent textuel d'`audit_changes_block`, qui rend du HTML.
    def modifications_texte(audit)
      return phrases_liaison(audit.audits) if audit.is_a?(AuditsHelper::GroupeLiaisons)
      return phrases_liaison([audit]) if AuditsHelper::LIAISONS.include?(audit.auditable_type)

      changements = humanize_changes(audit.audited_changes, audit.auditable_type)
      changements.unshift(label: libellé_commentaire(audit), to: audit.comment) if audit.comment.present?
      return '—' if changements.empty?

      changements.map { |item| ligne_changement(item) }.join("\n")
    end

    def ligne_changement(item)
      return "#{item[:label]} : #{item[:to]}" if item[:from].blank? || item[:from] == '—'

      "#{item[:label]} : #{item[:from]} → #{item[:to]}"
    end

    def phrases_liaison(audits)
      phrases = audits.filter_map { |audit| liaison_phrase(audit, cible: false) }
      return '—' if phrases.empty?

      phrases.map { |sujet, complément| "#{sujet} #{complément}" }.join("\n")
    end

    def ajouter_photos(pieces, message_vide)
      move_down 10
      text 'Photos', size: 10, style: :bold
      move_down 4

      return text(message_vide, size: 10, style: :italic) unless pieces.attached?

      pieces.each_slice(VIGNETTES_PAR_LIGNE) { |lot| ligne_de_vignettes(lot) }
    end

    def ligne_de_vignettes(lot)
      start_new_page if cursor < TAILLE_VIGNETTE + 20
      haut = cursor

      lot.each_with_index do |piece, index|
        gauche = index * (TAILLE_VIGNETTE + ESPACE_VIGNETTE)

        bounding_box([gauche, haut], width: TAILLE_VIGNETTE, height: TAILLE_VIGNETTE) do
          donnees = image_jpeg(piece)
          if donnees
            image donnees, fit: [TAILLE_VIGNETTE, TAILLE_VIGNETTE]
          else
            text texte_sûr("Aperçu indisponible (#{piece.filename})"), size: 7, style: :italic
          end
        end
      end

      move_cursor_to haut - TAILLE_VIGNETTE - ESPACE_VIGNETTE
    end

    # Prawn ne lit que le JPEG et le PNG, là où l'application accepte aussi
    # gif, webp, avif, heic et heif. Le repli évite qu'une seule photo
    # illisible fasse échouer tout le document.
    def image_jpeg(piece)
      StringIO.new(piece.variant(format: :jpg, resize_to_limit: [800, 800]).processed.download)
    rescue StandardError
      nil
    end

    def titre_section(texte)
      move_down 15
      text texte.upcase, size: 13, style: :bold
      move_down 4
      stroke_horizontal_rule
      move_down 8
    end

    def table_infos(lignes)
      return if lignes.empty?

      table(assainir(lignes), width: bounds.width, cell_style: { border_width: 0, padding: 4, size: 10 }) do
        column(0).font_style = :bold
        column(0).width = LARGEUR_LIBELLE
      end
    end

    def table_donnees(lignes, colonnes: nil)
      table(assainir(lignes), header: true, width: bounds.width, cell_style: { padding: 5, size: 8 }) do |t|
        t.row(0).font_style = :bold
        t.row(0).background_color = 'EEEEEE'
        t.column_widths = colonnes if colonnes
      end
    end

    def assainir(lignes)
      lignes.map { |ligne| ligne.map { |cellule| texte_sûr(cellule) } }
    end

    # Traduit les caractères connus puis remplace par « ? » tout ce qui reste
    # hors Windows-1252 : Prawn ne dégrade pas ces caractères, il lève, et toute
    # la génération tombe avec eux.
    def texte_sûr(valeur)
      texte = valeur.to_s
      SUBSTITUTIONS.each { |source, cible| texte = texte.gsub(source, cible) }
      texte.encode('Windows-1252', invalid: :replace, undef: :replace, replace: '?').encode('UTF-8')
    end

    def date_ou(valeur, defaut, format: :long)
      valeur.present? ? l(valeur, format: format) : defaut
    end

    def liste_ou(valeurs, defaut)
      valeurs.compact_blank.join("\n").presence || defaut
    end

    def add_footer
      repeat(:all) do
        move_cursor_to 20
        stroke_horizontal_rule
        move_down 5
        text "Document généré le #{I18n.l(Time.current, format: :long)}", size: 8, align: :center
      end
    end
  end
end
