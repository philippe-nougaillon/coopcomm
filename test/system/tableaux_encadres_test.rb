# frozen_string_literal: true

require 'application_system_test_case'

# Chaque tableau d'index vit dans un turbo-frame : trier, filtrer ou paginer ne
# recharge alors que le tableau, et la position dans la page est conservée.
class TableauxEncadresTest < ApplicationSystemTestCase
  PAGES = [
    ['interventions', :interventions_compact, 'interventions'],
    ['utilisateurs', :users_path, 'users_table'],
    ['matériel', :tools_path, 'tools_table'],
    ['mouvements', :mouvements_path, 'mouvements_table'],
    ['notifications', :mail_logs_path, 'notifications_table'],
    ['devis', :cotations_path, 'cotations_table'],
    ['commandes', :commandes_path, 'commandes_table'],
    ['factures', :factures_path, 'factures_table'],
    ['conventions', :conventions_path, 'conventions_table'],
    ['audits', :admin_audits_path, 'audits_table']
  ].freeze

  setup { login(users(:hidalgo)) }

  test 'le tableau, ses entêtes de tri et sa pagination sont dans le turbo-frame' do
    PAGES.each do |libellé, chemin, frame|
      visit chemin_de(chemin)

      encadré = document.at_css("turbo-frame##{frame}")

      assert encadré, "#{libellé} : turbo-frame##{frame} absent"
      assert encadré.at_css('table'), "#{libellé} : le tableau est hors du frame"
      assert encadré.at_css('th a[href*="column="]'), "#{libellé} : les entêtes de tri sont hors du frame"

      pagination = document.at_css('nav.pagy, .pagy-nav, nav[aria-label=pages]')
      assert encadré.at_css('nav'), "#{libellé} : la pagination est hors du frame" if pagination
    end
  end

  test 'le formulaire de filtre vise le frame du tableau' do
    PAGES.each do |libellé, chemin, frame|
      visit chemin_de(chemin)

      formulaires = document.css('form[method=get]')

      assert formulaires.any? { |formulaire| formulaire['data-turbo-frame'] == frame },
             "#{libellé} : aucun formulaire de filtre ne vise #{frame}"
    end
  end

  test 'les boutons de workflow sortent du frame plutôt que d’y charger une autre page' do
    visit interventions_path(vue: 'compact')

    encadré = document.at_css('turbo-frame#interventions')
    # Les `<form method="dialog">` des modales ne partent jamais au serveur.
    formulaires = encadré.css('form').reject { |form| %w[get dialog].include?(form['method'].to_s.downcase) }

    assert_predicate formulaires, :any?, 'aucun bouton de workflow dans le tableau'
    formulaires.each do |formulaire|
      assert_equal 'false', formulaire['data-turbo'],
                   "un formulaire du tableau (#{formulaire['action']}) navigue dans le frame"
    end
  end

  private

  def chemin_de(chemin)
    chemin == :interventions_compact ? interventions_path(vue: 'compact') : send(chemin)
  end

  def document = Nokogiri::HTML(page.html)
end
