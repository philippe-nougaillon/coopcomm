# frozen_string_literal: true

require 'test_helper'

class ExportToXlsNewslettersTest < ActiveSupport::TestCase
  setup do
    @newsletters = Newsletter.all
  end

  test 'aucune newsletter donne un classeur réduit à sa ligne d’en-tête' do
    assert_equal 1, feuille_des_newsletters(Newsletter.none).rows.count
  end

  test 'chaque newsletter occupe une ligne, sous l’en-tête' do
    assert_equal @newsletters.count + 1, feuille_des_newsletters(@newsletters).rows.count
  end

  test 'le classeur des newsletters porte trois colonnes' do
    assert_equal 3, feuille_des_newsletters(@newsletters).row(0).size
  end

  test 'l’email et la date de création sont écrits dans leurs colonnes' do
    newsletter = newsletters(:bond)
    feuille = feuille_des_newsletters(Newsletter.where(id: newsletter.id))

    assert_equal newsletter.email, cellule_sous_entete(feuille, 'Email')
    assert_equal I18n.l(newsletter.created_at), cellule_sous_entete(feuille, 'Créé_le')
  end

  private

  def feuille_des_newsletters(newsletters)
    Spreadsheet.open(StringIO.new(ExportToXls::Newsletters.call(newsletters))).worksheet(0)
  end

  def cellule_sous_entete(feuille, entete)
    feuille.row(1)[feuille.row(0).index(entete)]
  end
end
