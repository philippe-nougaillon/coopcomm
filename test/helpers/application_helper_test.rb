# frozen_string_literal: true

require 'test_helper'

class ApplicationHelperTest < ActionView::TestCase
  # `sort_link` échappe son titre avec `h` : ActionView::TestCase ne charge que
  # le helper testé.
  include ERB::Util

  # `sort_link` interroge le contrôleur, qui expose ces méthodes aux vues.
  attr_accessor :sort_column, :sort_direction

  def colonne_triable?(colonne)
    %w[users.nom users.email].include?(colonne)
  end

  setup do
    @app_instance = ENV.fetch('APP_INSTANCE', nil)
    # `sort_link` régénère l'URL courante : hors requête réelle, il faut lui dire
    # sur quelle page on se trouve.
    @request.path_parameters = { controller: 'users', action: 'index' }
  end

  teardown do
    ENV['APP_INSTANCE'] = @app_instance
  end

  # ==================== Bandeau de démonstration ====================

  test 'une instance de démonstration est reconnue quelles que soient la casse et les espaces' do
    ENV['APP_INSTANCE'] = ' DEMO '

    assert_predicate self, :demo_instance?
  end

  test "une instance de production n'affiche pas le bandeau de démonstration" do
    ENV['APP_INSTANCE'] = 'production'

    assert_not demo_instance?
  end

  test "une instance sans variable d'environnement n'affiche pas le bandeau de démonstration" do
    ENV.delete('APP_INSTANCE')

    assert_not demo_instance?
  end

  # ==================== Horodatage de la messagerie ====================

  test "un message du jour n'est horodaté que par son heure" do
    travel_to Time.zone.local(2026, 7, 15, 18, 0) do
      assert_equal '09:30', message_time_format(Time.zone.local(2026, 7, 15, 9, 30))
    end
  end

  test 'un message de la semaine écoulée est horodaté par son jour de la semaine' do
    travel_to Time.zone.local(2026, 7, 15, 18, 0) do
      assert_equal 'vendredi', message_time_format(Time.zone.local(2026, 7, 10, 9, 30))
    end
  end

  test 'un message plus ancien est horodaté par sa date complète' do
    travel_to Time.zone.local(2026, 7, 15, 18, 0) do
      assert_equal '01/06/2026', message_time_format(Time.zone.local(2026, 6, 1, 9, 30))
    end
  end

  test 'un horodatage absent est rendu par une chaîne vide' do
    assert_equal '', message_time_format(nil)
  end

  # ==================== Injection des pictogrammes ====================

  test 'un pictogramme connu est injecté dans la page' do
    svg = embedded_svg('icons/add.svg')

    assert_match(/<svg/, svg)
    assert_predicate svg, :html_safe?
  end

  test 'un pictogramme inconnu ne casse pas la page' do
    assert_equal '', embedded_svg('icons/pictogramme_inexistant.svg')
  end

  test 'les classes passées au helper sont ajoutées au pictogramme' do
    svg = Nokogiri::HTML::DocumentFragment.parse(embedded_svg('icons/add.svg', class: 'w-4 h-4')).at_css('svg')

    assert_includes svg['class'], 'w-4 h-4'
  end

  test 'un pictogramme sans titre est décoratif' do
    svg = Nokogiri::HTML::DocumentFragment.parse(embedded_svg('icons/add.svg')).at_css('svg')

    assert_equal 'true', svg['aria-hidden']
  end

  test 'un pictogramme titré porte un nom accessible et une infobulle' do
    svg = Nokogiri::HTML::DocumentFragment.parse(embedded_svg('icons/add.svg', title: 'Ajouter')).at_css('svg')

    assert_equal 'img', svg['role']
    assert_equal 'Ajouter', svg['aria-label']
    assert_equal 'Ajouter', svg.at_css('title').text
    assert_nil svg['aria-hidden']
  end

  # ==================== En-têtes de tri des index ====================

  test 'cliquer la colonne déjà triée inverse le sens du tri' do
    self.sort_column = 'users.nom'
    self.sort_direction = 'asc'

    assert_match 'direction=desc', sort_link('users.nom', 'Nom')
  end

  test 'cliquer une autre colonne demande un tri croissant' do
    self.sort_column = 'users.nom'
    self.sort_direction = 'asc'

    assert_match 'direction=asc', sort_link('users.email', 'Email')
  end

  test 'le pictogramme de la colonne triée est visible, celui des autres n\'apparaît qu\'au survol' do
    self.sort_column = 'users.nom'
    self.sort_direction = 'asc'

    assert_no_match(/opacity-0/, sort_link('users.nom', 'Nom'))
    assert_match(/opacity-0 group-hover:opacity-100/, sort_link('users.email', 'Email'))
  end

  test 'une colonne non déclarée triable est rendue sans lien' do
    lien = sort_link('users.memo', 'Mémo')

    assert_no_match(/<a /, lien)
    assert_match 'Mémo', lien
  end

  test 'trier repart de la première page' do
    self.sort_column = 'users.nom'
    self.sort_direction = 'asc'
    @request.path_parameters = { controller: 'users', action: 'index' }
    params[:page] = '3'

    assert_no_match(/page=/, sort_link('users.nom', 'Nom'))
  end

  test 'l\'en-tête annonce le sens du tri aux lecteurs d\'écran' do
    self.sort_column = 'users.nom'
    self.sort_direction = 'desc'

    assert_match 'aria-sort="descending"', th_tri('Nom', colonne: 'users.nom')
    assert_match 'aria-sort="none"', th_tri('Email', colonne: 'users.email')
  end

  test 'un en-tête sans colonne triable garde ses classes et son titre' do
    entete = th_tri('Mots clés', class: 'px-4 py-3')

    assert_match 'class="px-4 py-3"', entete
    assert_match 'Mots clés', entete
    assert_no_match(/<a /, entete)
  end

  test 'le titre de la colonne est échappé' do
    self.sort_column = 'users.nom'
    self.sort_direction = 'asc'

    assert_no_match(/<script>/, sort_link('users.nom', '<script>alert(1)</script>'))
  end
end
