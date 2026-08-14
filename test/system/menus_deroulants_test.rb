# frozen_string_literal: true

require 'application_system_test_case'

# Les options d'un menu déroulant se lisent dans l'ordre alphabétique, accents et
# majuscules ignorés — comme les tableaux. Les listes dont l'ordre porte un sens
# métier (états d'un workflow, motifs, rôles) sont volontairement absentes.
class MenusDeroulantsTest < ApplicationSystemTestCase
  setup do
    interventions(:tonte_locaux).update!(tag_list: 'Zonage, entretien, Élagage')
    users(:bond).update!(tag_list: 'Zonage, entretien, Élagage')
  end

  MENUS_ADMINISTRATEUR = [
    ['paramètres : utilisateurs', :admin_parametres_path, 'select#user_id']
  ].freeze

  MENUS_MANAGER = [
    ['interventions : services', :interventions_path, 'select#service'],
    ['interventions : adhérents', :interventions_path, 'select#adherent_id'],
    ['interventions : matériel', :interventions_path, 'select#tool_ids'],
    ['interventions : mots clés', :interventions_path, 'select#tags_'],
    ['utilisateurs : services', :users_path, 'select#services'],
    ['utilisateurs : mots clés', :users_path, 'select#user_tag'],
    ['planning : services', :agent_calendrier_users_path, 'select#services'],
    ['devis : adhérents', :cotations_path, 'select[name="adhérent_ids[]"]'],
    ['devis : services', :cotations_path, 'select#service_ids'],
    ['commandes : adhérents', :commandes_path, 'select[name="adhérent_ids[]"]'],
    ['factures : adhérents', :factures_path, 'select[name="adhérent_ids[]"]'],
    ['conventions : adhérents', :conventions_path, 'select#adherent_id'],
    ['notifications : destinataires', :mail_logs_path, 'select#search'],
    ['audits : utilisateurs', :admin_audits_path, 'select#user_id'],
    ['audits : types', :admin_audits_path, 'select#type'],
    ['mouvements : matériel', :mouvements_path, 'select#tool_ids'],
    ['formulaire d’intervention : adhérents', :new_intervention_path, 'select#intervention_adherent_id'],
    ['formulaire d’intervention : matériel', :new_intervention_path, 'select#intervention_tool_ids'],
    ['formulaire de devis : adhérents', :new_cotation_path, 'select#cotation_adherent_id'],
    ['formulaire de devis : prestations', :new_cotation_path, 'select[name*="prestation_id"]']
  ].freeze

  test 'les options des menus déroulants d’un administrateur sont rangées par ordre alphabétique' do
    login(users(:administrateur_paris))

    verifier(MENUS_ADMINISTRATEUR)
  end

  test 'les options des menus déroulants d’un manager sont rangées par ordre alphabétique' do
    login(users(:hidalgo))

    verifier(MENUS_MANAGER)
  end

  test 'un menu groupé range ses groupes et les options de chaque groupe' do
    login(users(:hidalgo))

    visit interventions_path

    groupes = document.css('select#agent_ids optgroup')

    assert_predicate groupes, :any?
    étiquettes = groupes.map { |groupe| groupe['label'] }

    assert_equal TriTextuel.ranger(étiquettes), étiquettes

    groupes.each do |groupe|
      options = groupe.css('option').map { |option| option.text.strip }.compact_blank

      assert_equal TriTextuel.ranger(options), options, "groupe #{groupe['label']} dans le désordre"
    end
  end

  private

  def verifier(menus)
    menus.each do |libellé, chemin, sélecteur|
      visit send(chemin)

      champs = document.css(sélecteur)

      assert_predicate champs, :any?, "#{libellé} : menu introuvable (#{sélecteur})"
      # Un formulaire imbriqué rend le même menu plusieurs fois : chacun se range
      # pour lui-même.
      champs.each do |menu|
        libellés = options_du_menu(menu)

        assert_predicate libellés, :any?, "#{libellé} : menu vide"
        assert_equal TriTextuel.ranger(libellés), libellés, "#{libellé} : options dans le désordre"
      end
    end
  end

  def document = Nokogiri::HTML(page.html)

  # L'option d'invite (« Tous », « Choisir… ») porte une valeur vide et reste en tête.
  def options_du_menu(menu)
    menu.css('option').reject { |option| option['value'].blank? }
        .map { |option| option.text.strip }
  end
end
