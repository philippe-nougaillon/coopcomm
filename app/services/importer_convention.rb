# frozen_string_literal: true

# Range ce que l'IA a lu dans la convention déposée, une convention par ligne de service : la première ligne reste sur la
# convention déposée, chaque ligne suivante en devient une sœur, même document et même déposant ; toutes attendent d'être
# validées.
class ImporterConvention < ApplicationService
  def initialize(convention, lu, lecture)
    @convention = convention
    @lu = lu
    @lecture = lecture
  end

  def call
    premiere, *suivantes = @lu[:services].presence || [nil]
    suivantes.each do |ligne|
      Convention.create!(attributs(ligne).merge(workflow_state: Convention::ANALYSE, deposant: @convention.deposant,
                                                document: @convention.document.blob))
    end
    @convention.assign_attributes(attributs(premiere))
    @convention.terminer!
  end

  private

  def attributs(ligne)
    { user: @lu[:user].valeur, service: ligne&.service, heures_conventionnees: ligne&.heures,
      date_début: @lu[:date_début].valeur || @lu[:date_signature].valeur || Date.current.beginning_of_year,
      date_signature: @lu[:date_signature].valeur, date_fin_prévue: @lu[:date_fin_prévue].valeur,
      résumé: @lu[:résumé].valeur, analyse: analyse(ligne) }
  end

  def analyse(ligne)
    { pages: @lecture.pages, pages_ocr: @lecture.pages_ocr, pages_transcrites: @lecture.images.size,
      nom_adherent: @lu[:nom_adhérent].valeur, adherent: extrait(@lu[:user]),
      date_debut: extrait(@lu[:date_début]), date_signature: extrait(@lu[:date_signature]), date_fin: extrait(@lu[:date_fin_prévue]),
      service: ligne && { extrait: ligne.extrait, retrouve: ligne.extrait_retrouve },
      services: @lu[:services].filter_map { |lu| lu.service&.id } }
  end

  def extrait(proposition)
    { extrait: proposition.extrait, retrouve: proposition.extrait_retrouve }
  end
end
