# frozen_string_literal: true

# Texte d'une numérisation, transcrit page par page par le modèle de langage : lu d'un bloc sur plusieurs images, il invente ce qui manque.
class TranscrirePages < ApplicationService
  CONSIGNE = <<~TEXTE
    Tu transcris une page numérisée d'un document administratif français. Recopie tout le texte de la page, ligne par ligne, dans l'ordre de lecture, sans rien corriger, résumer ni ajouter.
    Un emplacement laissé vide (pointillés, soulignés, case non remplie) s'écrit [vide] : n'invente jamais ce qui n'est pas écrit.
    Une mention écrite à la main se transcrit entre crochets, ainsi : [manuscrit : 350]. Si elle est illisible : [manuscrit illisible].
    Une ligne de tableau se recopie sur une seule ligne, ses cellules séparées par « | ».
    Ne réponds que par la transcription.
  TEXTE

  def initialize(images)
    @images = images
  end

  def call
    @images.map { |image| InterrogerIa.call(consigne: CONSIGNE, contenu: 'Transcris cette page.', images: [image]) }.join("\n\n")
  end
end
