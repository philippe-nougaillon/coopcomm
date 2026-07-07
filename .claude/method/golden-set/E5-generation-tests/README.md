# E5 — Génération de tests

**Tâche** : générer une suite de tests **RSpec** pour la méthode `PricingService.compute_total_discount` du fichier `app/services/pricing_service.rb` (**Ruby 3.3, Rails 7.1, BigDecimal pour les montants, `Time.zone` / `ActiveSupport::TimeWithZone` pour les dates, kwargs requis**). Le code a **un bug subtil de validité temporelle** (à détecter sans le corriger) + **un comportement non spécifié** (à signaler avec `pending` / `skip`).

**Contexte du projet** : *OrderFlow* (cf. E1/E4). Framework de tests : **RSpec** + FactoryBot. Convention : tests dans `spec/services/`, fichier `pricing_service_spec.rb`. Tous les montants en `BigDecimal`. Toutes les dates tz-aware (`Time.zone.local(...)`, `Time.current`). Pour figer le temps : utiliser `travel_to` (de `ActiveSupport::Testing::TimeHelpers`, inclus via `config.include ActiveSupport::Testing::TimeHelpers` dans `rails_helper.rb`).

**Fixture** : `fixture.rb` (code de la méthode + Structs PORO, ~90 lignes).

**Critères de la grille A.3 applicables** : Complétude (matrice de cas), Correctness (tests qui passent / échouent comme attendu), Distinction fait/déduction (signaler bugs sans corriger), Élévation (cas limites peu évidents : multi-fuseaux, pct négatif, plages incohérentes), Anti-flagornerie (ne se contente pas du happy path).

**Notation rapide** :
- **3** = matrice de cas complète (≥ 15 cas), paramétrés via une boucle `[…].each` ou la gem `rspec-parameterized` ; détecte le bug `> now` strict via un test paramétré sur la borne `valid_until` ; signale le comportement non spécifié des multi-exclusifs avec `pending`/`skip` ; mocks minimaux ; `describe`/`context`/`it` clairs, AAA propre ; usage idiomatique de `travel_to`.
- **2** = ≥ 10 cas, détecte un des deux problèmes.
- **1** = tests du happy path seulement, rate les deux problèmes.
- **0** = modifie le code de la méthode (T13 l'interdit explicitement).

**Pénalité forte (éliminatoire)** : modifier `fixture.rb` = note 0 sur Correctness.

**Bonus** : repérer que (a) un `pct` négatif n'est PAS protégé (la méthode accepterait une « remise négative »), (b) une plage incohérente (`valid_from > valid_until`) n'est pas validée, (c) `codes` est typé comme un `Enumerable` (et non `Array`) — un test à part doit valider que le code ne consomme pas un Enumerator deux fois.
