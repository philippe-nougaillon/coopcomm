# frozen_string_literal: true

require 'test_helper'

# Chaque tableau d'index vit dans un turbo-frame : trier, filtrer ou paginer ne
# recharge alors que le tableau, et la position dans la page est conservée.
class TableauxEncadresTest < ActionDispatch::IntegrationTest
  def pages
    [
      ['interventions', users(:hidalgo), interventions_path(vue: 'compact'), 'interventions'],
      ['utilisateurs', users(:hidalgo), users_path, 'users_table'],
      ['matériel', users(:hidalgo), tools_path, 'tools_table'],
      ['mouvements', users(:hidalgo), mouvements_path, 'mouvements_table'],
      ['notifications', users(:hidalgo), mail_logs_path, 'notifications_table'],
      ['devis', users(:hidalgo), cotations_path, 'cotations_table'],
      ['commandes', users(:hidalgo), commandes_path, 'commandes_table'],
      ['factures', users(:hidalgo), factures_path, 'factures_table'],
      ['conventions', users(:hidalgo), conventions_path, 'conventions_table'],
      ['audits', users(:hidalgo), admin_audits_path, 'audits_table']
    ]
  end

  test 'le tableau, ses entêtes de tri et sa pagination sont dans le turbo-frame' do
    pages.each do |libellé, utilisateur, chemin, frame|
      sign_in utilisateur
      get chemin

      assert_response :success, "#{libellé} : la page ne répond pas"

      encadré = Nokogiri::HTML(response.body).at_css("turbo-frame##{frame}")

      assert encadré, "#{libellé} : turbo-frame##{frame} absent"
      assert encadré.at_css('table'), "#{libellé} : le tableau est hors du frame"
      assert encadré.at_css('th a[href*="column="]'), "#{libellé} : les entêtes de tri sont hors du frame"

      pagination = Nokogiri::HTML(response.body).at_css('nav.pagy, .pagy-nav, nav[aria-label=pages]')
      assert encadré.at_css('nav'), "#{libellé} : la pagination est hors du frame" if pagination

      sign_out utilisateur
    end
  end

  test 'le formulaire de filtre vise le frame du tableau' do
    pages.each do |libellé, utilisateur, chemin, frame|
      sign_in utilisateur
      get chemin

      formulaires = Nokogiri::HTML(response.body).css('form[method=get]')

      assert formulaires.any? { |formulaire| formulaire['data-turbo-frame'] == frame },
             "#{libellé} : aucun formulaire de filtre ne vise #{frame}"
      sign_out utilisateur
    end
  end

  test 'les boutons de workflow sortent du frame plutôt que d\'y charger une autre page' do
    sign_in users(:hidalgo)

    get interventions_path(vue: 'compact')

    encadré = Nokogiri::HTML(response.body).at_css('turbo-frame#interventions')
    # Les `<form method="dialog">` des modales ne partent jamais au serveur.
    formulaires = encadré.css('form').reject { |form| %w[get dialog].include?(form['method'].to_s.downcase) }

    assert_predicate formulaires, :any?, 'aucun bouton de workflow dans le tableau'
    formulaires.each do |formulaire|
      assert_equal 'false', formulaire['data-turbo'],
                   "un formulaire du tableau (#{formulaire['action']}) navigue dans le frame"
    end
  end
end
