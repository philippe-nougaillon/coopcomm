# frozen_string_literal: true

require 'test_helper'

# `MailLog#to` n'a pas de forme garantie : selon le job qui l'écrit, la colonne
# contient une adresse, une liste CSV, un tableau ou du JSON.
class MailLogsHelperTest < ActionView::TestCase
  test 'un destinataire absent est rendu par un tiret' do
    assert_equal '—', format_mail_recipients(nil)
    assert_equal '—', format_mail_recipients('')
  end

  test 'une adresse unique est rendue telle quelle' do
    assert_equal 'ariel.weil@paris.fr', format_mail_recipients('ariel.weil@paris.fr')
  end

  test 'une liste séparée par des virgules est rendue une adresse par ligne' do
    rendu = format_mail_recipients('a@paris.fr, b@paris.fr')

    assert_equal 'a@paris.fr,<br/>b@paris.fr', rendu
  end

  test 'une liste au format JSON est rendue une adresse par ligne' do
    rendu = format_mail_recipients('["a@paris.fr", "b@paris.fr"]')

    assert_equal 'a@paris.fr,<br/>b@paris.fr', rendu
  end

  test "un JSON tronqué rend la valeur brute plutôt qu'une erreur" do
    assert_equal '[a@paris.fr', format_mail_recipients('[a@paris.fr')
  end

  test 'un tableau déjà décodé est rendu une adresse par ligne' do
    assert_equal 'a@paris.fr,<br/>b@paris.fr', format_mail_recipients(['a@paris.fr', ' b@paris.fr'])
  end

  test 'les entrées vides et les espaces superflus sont retirés' do
    assert_equal 'a@paris.fr', format_mail_recipients('  a@paris.fr , , ')
  end

  test 'une liste de nombres ne doit pas faire tomber la page des logs' do
    assert_nothing_raised { format_mail_recipients('[1, 2]') }
  end

  test 'le HTML contenu dans la valeur est rendu sans échappement (ÉPINGLAGE H4)' do
    # Comportement actuel (html_safe sur une valeur non échappée) : à inverser
    # le jour où chaque adresse sera échappée avant le join.
    assert_equal '<b>x</b>@paris.fr', format_mail_recipients('<b>x</b>@paris.fr')
    assert_predicate format_mail_recipients('<b>x</b>@paris.fr'), :html_safe?
  end
end
