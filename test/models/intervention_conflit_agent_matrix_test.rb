# frozen_string_literal: true

require 'test_helper'

# Matrice EXHAUSTIVE du conflit de disponibilité AGENT sur les dates d'intervention.
class InterventionConflitAgentMatrixTest < ActiveSupport::TestCase
  setup do
    @agent = users(:bond)
    @adherent = users(:weil)
    @service = @adherent.services.first
    @org = organisations(:mairie_paris)
  end

  JOUR = '2025-04-08' # passé : autorise aussi les dates réelles
  EXISTANTE = %w[10:00 12:00].freeze

  # [libellé (relation d'Allen), début_nouvelle, fin_nouvelle, conflit_attendu]
  TOPOLOGIES = [
    ['avant (disjointe, finit avant le début)',          '08:00', '09:00', false],
    ['après (disjointe, commence après la fin)',         '13:00', '14:00', false],
    ['se touchent : la nouvelle finit au début',         '09:00', '10:00', true],
    ['se touchent : la nouvelle commence à la fin',      '12:00', '13:00', true],
    ['chevauche : commence avant, finit pendant',        '09:00', '11:00', true],
    ['chevauche : commence pendant, finit après',        '11:00', '13:00', true],
    ['même début, la nouvelle est plus courte',          '10:00', '11:00', true],
    ['même début, la nouvelle englobe (plus longue)',    '10:00', '13:00', true],
    ['la nouvelle est englobée par l’existante',         '10:30', '11:30', true],
    ['la nouvelle englobe l’existante',                  '09:00', '13:00', true],
    ['même fin, la nouvelle commence plus tard',         '11:00', '12:00', true],
    ['même fin, la nouvelle englobe (commence avant)',   '09:00', '12:00', true],
    ['identiques (début ET fin égaux)',                  '10:00', '12:00', true]
  ].freeze

  # [libellé, type de date de l'EXISTANTE, type de date de la NOUVELLE]
  COMBOS = [
    ['réel vs réel',   :real, :real],
    ['réel vs prévu',  :real, :prev],
    ['prévu vs prévu', :prev, :prev],
    ['prévu vs réel',  :prev, :real]
  ].freeze

  COMBOS.each do |combo_label, type_existante, type_nouvelle|
    TOPOLOGIES.each do |topo_label, debut_new, fin_new, conflit_attendu|
      test "#{combo_label} — #{topo_label}" do
        creer_existante(type_existante)
        nouvelle = construire_nouvelle(type_nouvelle, debut_new, fin_new)

        contexte = "#{combo_label} / #{topo_label}"
        if conflit_attendu
          assert_not nouvelle.valid?, "Conflit attendu mais NON détecté — #{contexte}"
          assert_includes nouvelle.errors.full_messages.join(' '),
                          'Conflit(s) détecté(s) sur un agent',
                          "Mauvais message d'erreur — #{contexte}"
        else
          assert nouvelle.valid?,
                 "Aucun conflit attendu mais détecté (#{nouvelle.errors.full_messages.to_sentence}) — #{contexte}"
        end
      end
    end
  end

  private

  def creer_existante(type)
    Intervention.create!(
      attrs_dates(type, EXISTANTE[0], EXISTANTE[1]).merge(
        description: 'Intervention existante',
        organisation: @org, agents: [@agent], adherent: @adherent, service: @service
      )
    )
  end

  def construire_nouvelle(type, debut, fin)
    Intervention.new(
      attrs_dates(type, debut, fin).merge(
        description: 'Nouvelle intervention',
        organisation: @org, agents: [@agent], adherent: @adherent, service: @service
      )
    )
  end

  # Place la fenêtre [debut, fin] dans les champs réels OU prévus, l'autre paire
  # restant nil — c'est ce qui exerce le repli réel→prévu de la plage effective.
  def attrs_dates(type, debut, fin)
    d = "#{JOUR} #{debut}"
    f = "#{JOUR} #{fin}"
    case type
    when :real then { début: d, fin: f }
    when :prev then { début_prévue: d, fin_prévue: f }
    end
  end
end
