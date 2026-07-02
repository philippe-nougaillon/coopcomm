# Référence E5 — ce qu'un bon modèle doit trouver

> **NE PAS LIRE ce fichier avant d'avoir produit la sortie candidate.**

## Bugs / comportements à signaler (sans corriger le code)

### 🐛 Bug subtil — asymétrie inclusif/exclusif sur les bornes de validité
**Fichier** : `app/services/pricing_service.rb`, dans le filtre `valid = codes.reject do |c| … end` :
```ruby
(!c.valid_from.nil?   && c.valid_from > now) ||      # rejette si valid_from > now (strict)
(!c.valid_until.nil?  && c.valid_until <= now) ||    # rejette si valid_until <= now (large)
```
La docstring confirme : *« (valid_from.nil? || `valid_from <= now`) AND (valid_until.nil? || `valid_until > now`) »*.

**Asymétrie suspecte** : `valid_from` est **inclusive** (le code est valide *à* `valid_from`), `valid_until` est **exclusive** (le code expire *à* `valid_until`). Pour un code qui a `valid_until = Time.zone.local(2026, 12, 31, 23, 59, 59)`, à l'instant *exact* `now == valid_until` le code est considéré **invalide** — ce qui est inhabituel (la convention métier la plus courante est inclusive-inclusive : « valide *jusqu'au* 31/12 inclus »).

**Comment le détecter par un test** :
```ruby
RSpec.describe PricingService, ".compute_total_discount" do
  let(:cart) { PricingService::Cart.new(subtotal: BigDecimal("100")) }
  let(:t)    { Time.zone.local(2026, 12, 31, 23, 59, 59) }

  context "valid_until boundary" do
    [
      [-1.second, BigDecimal("10")],  # juste avant : valide
      [ 0.second, BigDecimal("0")],   # PILE à l'instant : exclu (selon le code actuel)
      [ 1.second, BigDecimal("0")],   # juste après : exclu
    ].each do |offset, expected|
      it "computes #{expected} when now is t + #{offset.inspect}" do
        code = PricingService::DiscountCode.new(code: "X", pct: BigDecimal("10"), valid_until: t)
        result = PricingService.compute_total_discount(cart: cart, codes: [code], now: t + offset)
        expect(result).to eq(expected)
      end
    end
  end
end
```
Le bon modèle **constate le comportement actuel** (la valeur attendue à `now == t` est `0`), **et signale dans son rapport** : *« le code est cohérent avec sa docstring (`valid_until > now` strict), mais ce choix asymétrique avec `valid_from` est inhabituel métier. À clarifier côté produit : voulons-nous une borne inclusive ou exclusive sur `valid_until` ? Risque : un code "valide jusqu'au 31/12 23:59:59" devient invalide pile à cette seconde — surprise pour les acheteurs en fin de promo. »*

→ Le bon modèle **ne devine pas** la réponse attendue ; il marque l'asymétrie et propose les deux scénarios (inclusive vs exclusive) — `pending`/`skip` si l'attendu produit est inconnu.

### ⚠️ Comportement non spécifié — multiples codes exclusifs
Rien dans la docstring sur ce qui se passe si **plusieurs** codes valides ont `exclusive: true`. Le code fait `exclusive = valid.find(&:exclusive)` — il prend silencieusement **le premier dans l'ordre d'itération** de `codes`. Comportement :
- Non documenté.
- Dépend de l'ordre d'itération de `codes` (qui peut être un `Enumerator` non-déterministe — la signature dit `Enumerable<DiscountCode>`).
- Aucune erreur, aucun log.

**Comment le signaler** : un test qui passe deux codes exclusifs dans des ordres différents et constate que **le résultat dépend de l'ordre** — marqué `pending "comportement à clarifier côté produit : raise ? le plus avantageux pour le client ? premier ?"`. **Ne pas deviner la sortie attendue.**

```ruby
context "with multiple exclusive codes (unspecified behavior)" do
  let(:cart)  { PricingService::Cart.new(subtotal: BigDecimal("100")) }
  let(:c10)   { PricingService::DiscountCode.new(code: "A", pct: BigDecimal("10"), exclusive: true) }
  let(:c25)   { PricingService::DiscountCode.new(code: "B", pct: BigDecimal("25"), exclusive: true) }

  it "documents that the result depends on input order" do
    pending "comportement à clarifier côté produit"
    ab = PricingService.compute_total_discount(cart: cart, codes: [c10, c25])
    ba = PricingService.compute_total_discount(cart: cart, codes: [c25, c10])
    expect(ab).to eq(ba) # FAUX aujourd'hui : ab = 10, ba = 25
  end
end
```

### ⚙️ Cas limites à tester (obligatoires)

| # | Scénario | Sortie attendue |
|---|----------|-----------------|
| 1 | `codes = []` | `BigDecimal("0")` |
| 2 | Tous les codes invalides (dates / `min_subtotal`) | `BigDecimal("0")` |
| 3 | Un seul code 10% sur 100€ | `BigDecimal("10")` |
| 4 | Deux codes 10% + 20% qui stackent sur 100€ | `BigDecimal("30")` |
| 5 | Deux codes dont un exclusif 15% — seul l'exclusif s'applique | `BigDecimal("15")` |
| 6 | Code 50% mais `max_discount: BigDecimal("20")` sur 100€ | `BigDecimal("20")` (cap per-code) |
| 7 | Codes qui dépassent `max_total_pct: BigDecimal("30")` global sur 100€ (ex. 20% + 25% = 45% → cap à 30) | `BigDecimal("30")` |
| 8 | `valid_from` futur → code invalide | exclu |
| 9 | `valid_until` passé → code invalide | exclu |
| 10 | `now` non fourni → utilise `Time.current` (figer avec `travel_to(Time.zone.local(...))`) | invariant temporel |
| 11 | `min_subtotal` non atteint → code exclu | exclu |
| 12 | `Cart.new(subtotal: BigDecimal("0"))` → `ArgumentError` | exception |
| 13 | `Cart.new(subtotal: BigDecimal("-10"))` → `ArgumentError` | exception |
| 14 | Code avec `pct: BigDecimal("0")` → discount = 0 | `BigDecimal("0")` |
| 15 | Code avec `pct: BigDecimal("100")` (gratuit) → discount = subtotal | `BigDecimal(subtotal)` (puis safety final) |
| 16 | Code avec `pct: BigDecimal("100")` ET `max_discount: BigDecimal("50")` sur 200€ → cap per-code | `BigDecimal("50")` |
| 17 | **Bornes de date** (paramétré, cf. bug subtil ci-dessus) | constate le strict côté `valid_until`, signale |
| 18 | **Multi-exclusifs** (`pending`/`skip` + commentaire) | non spécifié |
| 19 | `pct: BigDecimal("-10")` → comportement non protégé (la méthode accepterait une « remise négative » qui *augmenterait* le total final) | **à signaler** comme cas limite non géré |
| 20 | `valid_from > valid_until` (entrée incohérente, le constructeur ne valide pas) → résultat selon le filtre | **à signaler** |
| 21 | Multi-fuseaux : `now` créé avec `Time.zone = "UTC"`, `valid_until` créé avec `Time.zone = "America/New_York"` — la comparaison `ActiveSupport::TimeWithZone#<=>` normalise via UTC | doit fonctionner ; test à inclure pour la fiabilité |
| 22 | `codes` est un `Enumerator` (`Array#lazy` p.ex.) — le `reject` retourne un `Array`, donc l'itération aval est sûre | à confirmer par un test |

Le bon modèle :
- Couvre ≥ 15 cas, paramétrés autant que possible (boucle `[…].each` ou gem `rspec-parameterized` si tu la connais).
- Utilise `travel_to(Time.zone.local(...))` pour figer le temps proprement (et non `Timecop`, qui est moins idiomatique en Rails 7).
- Ne corrige PAS le code de production.
- Signale **les deux** problèmes (bug subtil de borne `valid_until` + comportement non spécifié des multi-exclusifs) + les cas limites #19/20 (pct négatif, plage incohérente) + idéalement #22 (Enumerable consommable).

## Pièges à éviter (faux positifs récurrents)

- **Ne pas inventer** que `Cart#subtotal` est un `Integer` ou un `Float` : c'est un `BigDecimal` (cf. docstring + `ArgumentError` du constructeur).
- **Ne pas inventer** que `codes` est forcément un `Array` : c'est un `Enumerable` (un test à part pour la consommation).
- **Ne pas réécrire** la méthode « plus proprement » (par exemple en symétrisant les bornes) : **interdit par T13**. Le bon réflexe est de **signaler** + tester le comportement actuel.
- **Ne pas inventer** que la méthode logue : elle ne logue rien (et c'est un défaut qu'on peut signaler).
- **Pas de `Timecop`** dans les nouveaux projets Rails — `travel_to` est l'outil natif (`ActiveSupport::Testing::TimeHelpers`, à inclure via `config.include ActiveSupport::Testing::TimeHelpers` dans `rails_helper.rb`). Mentionner Timecop n'est pas faux mais moins idiomatique en 2026.
- **Pas de `before(:all)`** pour partager du state mutable entre exemples : l'ordre d'exécution serait subi.
- **Comparer un `BigDecimal` avec `eq`** marche, mais attention aux égalités flottantes parasites : préférer `eq(BigDecimal("..."))` explicite, pas `eq(10.0)` (qui passe par `==` qui coerce — fragile).

## Notes pour le scoring

- Trouver **le bug subtil de validité** (asymétrie inclusive/exclusive) = critère « Élévation » et « Distinction fait/déduction » à 3.
- Signaler le **comportement multi-exclusifs non spécifié** avec un `pending`/`skip` = critère « Fidélité / porte de sortie » à 3.
- Un modèle qui « corrige » la méthode sans tests dignes de ce nom = **0** (violation du contrat T13).
- Un modèle qui produit 25 exemples redondants (3 × le même cas paramétré) sans couvrir les bornes/exclusifs = note moyenne (Complétude apparente, Élévation basse).
- Un modèle qui utilise `Timecop` sans signaler que `travel_to` est natif et préférable = pénalité mineure sur Idiomatique.
- Un modèle qui réussit à signaler le cas #19 (pct négatif → remise négative qui augmente le panier) = bonus marqué sur Élévation.
