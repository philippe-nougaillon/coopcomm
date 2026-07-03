# Prompt E5 (gelé)

> Source de vérité : applique le **template T13 — « Génération de tests »** de `../../kit-prompting.md`. Le bloc ci-dessous est ce qu'on injecte au modèle évalué.

---

**NE MODIFIE PAS LE CODE DE PRODUCTION.** Écris uniquement des tests.

**Contexte du projet** : *OrderFlow API*, Ruby 3.3, Rails 7.1, `BigDecimal` pour les montants, `Time.zone` / `ActiveSupport::TimeWithZone` pour les dates, framework de tests **RSpec** + FactoryBot. Tests dans `spec/services/`, fichier cible `pricing_service_spec.rb`. Conventions : nommage descriptif (`describe`/`context`/`it`), un comportement par test, AAA (`# Arrange / # Act / # Assert`), mocks minimaux, pas de dépendance à l'ordre, `travel_to` (de `ActiveSupport::Testing::TimeHelpers`) pour figer le temps. Pour paramétrer : `[…].each do |a, b| it "…" do … end end` ou la gem `rspec-parameterized` si tu la connais.

**Code à tester** :
```ruby
[colle ici le contenu de fixture.rb]
```

Procède selon le template T13 :
1. D'abord (Chain of Thought, « Raisonnement: » en gras) : liste le contrat de la méthode publique (préconditions, postconditions, invariants), les chemins (happy path, erreurs, cas limites : vide, nil, zéro, négatif, très grand, dates aux bornes, fuseaux, codes exclusifs multiples, plafond global), et les effets de bord à isoler.
2. Propose la matrice de tests (table : cas → entrée → sortie/effet attendu → priorité). Si la liste est longue, attends ma validation.
3. Écris les tests RSpec. Nommage descriptif, AAA clair, paramétrage là où ça aide, mocks minimaux.
4. Signale les cas que tu n'as PAS pu couvrir et pourquoi.
5. Signale tout **bug du code de production** découvert en écrivant les tests (fichier:ligne + scénario qui le déclenche) — **sans le corriger**.
6. Porte de sortie : si le comportement attendu d'un cas n'est pas spécifié et pas déductible, écris un test `pending` ou `skip` avec un commentaire « comportement à clarifier » — ne devine pas le résultat attendu.
