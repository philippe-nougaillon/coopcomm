# frozen_string_literal: true

require 'test_helper'

# Les options d'un menu déroulant se lisent dans l'ordre alphabétique, accents et
# majuscules ignorés — comme les tableaux. Les listes dont l'ordre porte un sens
# métier (états d'un workflow, motifs, rôles) sont volontairement absentes.
class MenusDeroulantsTest < ActionDispatch::IntegrationTest
  # Trois mots clés dont l'ordre brut (Zonage, entretien, Élagage) diffère de
  # l'ordre attendu : sans normalisation, la sentinelle tomberait.
  setup do
    interventions(:tonte_locaux).update!(tag_list: 'Zonage, entretien, Élagage')
    users(:bond).update!(tag_list: 'Zonage, entretien, Élagage')
  end

  # [libellé, utilisateur, chemin, sélecteur du menu]
  def menus
    [
      ['paramètres : utilisateurs', users(:administrateur_paris), admin_parametres_path, 'select#user_id'],
      ['interventions : services', users(:hidalgo), interventions_path, 'select#service'],
      ['interventions : adhérents', users(:hidalgo), interventions_path, 'select#adherent_id'],
      ['interventions : matériel', users(:hidalgo), interventions_path, 'select#tool_ids'],
      ['interventions : mots clés', users(:hidalgo), interventions_path, 'select#tags_'],
      ['utilisateurs : services', users(:hidalgo), users_path, 'select#services'],
      ['utilisateurs : mots clés', users(:hidalgo), users_path, 'select#user_tag'],
      ['planning : services', users(:hidalgo), agent_calendrier_users_path, 'select#services'],
      ['devis : adhérents', users(:hidalgo), cotations_path, 'select[name="adhérent_ids[]"]'],
      ['devis : services', users(:hidalgo), cotations_path, 'select#service_ids'],
      ['commandes : adhérents', users(:hidalgo), commandes_path, 'select[name="adhérent_ids[]"]'],
      ['factures : adhérents', users(:hidalgo), factures_path, 'select[name="adhérent_ids[]"]'],
      ['conventions : adhérents', users(:hidalgo), conventions_path, 'select#adherent_id'],
      ['notifications : destinataires', users(:hidalgo), mail_logs_path, 'select#search'],
      ['audits : utilisateurs', users(:hidalgo), admin_audits_path, 'select#user_id'],
      ['audits : types', users(:hidalgo), admin_audits_path, 'select#type'],
      ['mouvements : matériel', users(:hidalgo), mouvements_path, 'select#tool_ids'],
      ['formulaire d\'intervention : adhérents', users(:hidalgo), new_intervention_path, 'select#intervention_adherent_id'],
      ['formulaire d\'intervention : matériel', users(:hidalgo), new_intervention_path, 'select#intervention_tool_ids'],
      ['formulaire de devis : adhérents', users(:hidalgo), new_cotation_path, 'select#cotation_adherent_id'],
      ['formulaire de devis : prestations', users(:hidalgo), new_cotation_path, 'select[name*="prestation_id"]']
    ]
  end

  test 'les options des menus déroulants sont rangées par ordre alphabétique' do
    menus.each do |libellé, utilisateur, chemin, sélecteur|
      sign_in utilisateur
      get chemin

      assert_response :success, "#{libellé} : la page ne répond pas"

      champs = css_select(sélecteur)

      assert_predicate champs, :any?, "#{libellé} : menu introuvable (#{sélecteur})"
      # Un formulaire imbriqué rend le même menu plusieurs fois : chacun se range
      # pour lui-même.
      champs.each do |menu|
        libellés = options_du_menu(menu)

        assert_predicate libellés, :any?, "#{libellé} : menu vide"
        assert_equal TriTextuel.ranger(libellés), libellés, "#{libellé} : options dans le désordre"
      end
      sign_out utilisateur
    end
  end

  test 'un menu groupé range ses groupes et les options de chaque groupe' do
    sign_in users(:hidalgo)

    get interventions_path

    groupes = css_select('select#agent_ids optgroup')

    assert_predicate groupes, :any?
    étiquettes = groupes.map { |groupe| groupe['label'] }

    assert_equal TriTextuel.ranger(étiquettes), étiquettes

    groupes.each do |groupe|
      options = groupe.css('option').map { |option| option.text.strip }.compact_blank

      assert_equal TriTextuel.ranger(options), options, "groupe #{groupe['label']} dans le désordre"
    end
  end

  # L'option d'invite (« Tous », « Choisir… ») porte une valeur vide et reste en tête.
  def options_du_menu(menu)
    menu.css('option').reject { |option| option['value'].blank? }
        .map { |option| option.text.strip }
  end
end
