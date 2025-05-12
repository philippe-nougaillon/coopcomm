require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  setup do
    @tool = Tool.create(name: "Débroussailleuse", organisation: organisations(:mairie_paris))
  end

  test "création du premier document sur un outil avec la bonne version" do
    # Version du document à 1.0
    nouveau_document = Document.create(category: "carte_grise", tool: @tool)

    assert_equal 1, nouveau_document.version
  end

  test "changement de version si ajout d'un document de la même catégorie sur un outil" do
    # Version du document à 1.0
    Document.create(category: "carte_grise", tool: @tool)

    # Version du document à 2.0
    nouveau_document = Document.create(category: "carte_grise", tool: @tool)

    assert_equal 2, nouveau_document.version
  end

  test "aucun changement de version si ajout d'un document d'une catégorie différente sur un outil" do
    # Version du document à 1.0
    Document.create(category: "carte_grise", tool: @tool)

    # Version du document à 1.0
    nouveau_document = Document.create(category: "certificat_assurance", tool: @tool)

    assert_equal 1, nouveau_document.version
  end

  test "aucun changement de version si ajout d'un document de la même catégorie sur un autre outil" do
    other_tool = tools(:tondeuse)

    # Version du document à 1.0
    Document.create(category: "carte_grise", tool: other_tool)

    # Version du document à 1.0
    nouveau_document = Document.create(category: "carte_grise", tool: @tool)

    assert_equal 1, nouveau_document.version
  end
end
