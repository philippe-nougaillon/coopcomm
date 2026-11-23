# frozen_string_literal: true

# Une page wiki telle qu'une instance la reçoit d'une autre, JSON relu : une
# image collée dans le contenu, une photo et un document.
module PageWikiExportee
  def page_wiki_exportée
    { 'titre' => 'Réserver une benne', 'sous_titre' => 'Depuis la fiche outil', 'catégorie' => 'guide',
      'poids' => 4, 'épinglée' => true, 'private' => false,
      'contenu' => '<div>Le plan</div><action-text-attachment sgid="fichier-0" caption="Le plan"></action-text-attachment>',
      'fichiers' => { 'fichier-0' => fichier_wiki_exporté('exemple.png', 'image/png') },
      'photo' => fichier_wiki_exporté('exemple.png', 'image/png'),
      'document' => fichier_wiki_exporté('exemple.pdf', 'application/pdf') }
  end

  def fichier_wiki_exporté(nom, type)
    { 'filename' => nom, 'content_type' => type,
      'data' => Base64.strict_encode64(File.binread("test/fixtures/files/#{nom}")) }
  end
end
