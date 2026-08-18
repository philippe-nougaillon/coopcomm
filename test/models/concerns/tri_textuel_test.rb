# frozen_string_literal: true

require 'test_helper'

class TriTextuelTest < ActiveSupport::TestCase
  setup do
    @organisation = organisations(:mairie_paris)
  end

  test 'expression : accents et majuscules → ignorés dans la clé de tri' do
    clé = ->(mot) { ActiveRecord::Base.connection.select_value("SELECT #{TriTextuel.expression("'#{mot}'")}") }

    assert_equal clé.call('École'), clé.call('ecole')
    assert_equal clé.call('ÉTUVE'), clé.call('étuve')
  end

  test 'scope ordered : nom accentué → rangé à sa place alphabétique' do
    %w[Zoo Élan Duval].each { |nom| @organisation.services.create!(nom: nom) }

    rangés = @organisation.services.ordered.pluck(:nom)

    assert_equal %w[Duval Élan Zoo], rangés & %w[Duval Élan Zoo]
  end

  test 'scope ordered : homonymes → départagés par le prénom' do
    %w[Zoé Amélie].each do |prénom|
      User.create!(nom: 'Dupont', prénom: prénom, email: "#{prénom.parameterize}@aikku.eu",
                   password: 'Motdepasse1!', rôle: :adhérent, address: 'Paris',
                   latitude: 48.85, longitude: 2.35, services: [services(:technique)])
    end

    dupont = User.where(nom: 'DUPONT').ordered.pluck(:prénom)

    assert_equal %w[Amélie Zoé], dupont
  end

  test 'scope ordered : prestations à code égal → départagées par le libellé' do
    assert_equal Prestation.ordered.to_sql, Prestation.order(Prestation.tri_texte(:code, :libellé)).to_sql
  end

  test 'expression : colonne qualifiée par sa table → tri non ambigu sous jointure' do
    assert_includes Service.tri_texte(:nom), '"services"."nom"'
  end
end
