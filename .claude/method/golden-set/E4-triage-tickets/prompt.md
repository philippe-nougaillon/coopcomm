# Prompt E4 (gelé)

> Source de vérité : applique le **template T12 — « Tri / qualification de tickets »** de `../../kit-prompting.md`. Le bloc ci-dessous est ce qu'on injecte au modèle évalué.

---

Tu vas qualifier 10 tickets bruts. Réponds **UNIQUEMENT en JSON valide** (un objet par ticket dans un tableau ; aucun texte autour, aucun ```json fence).

**Contexte du projet** : *OrderFlow*, plateforme e-commerce B2B.
- **Composants** : `auth`, `catalog`, `cart`, `checkout`, `inventory`, `billing`, `notif`, `admin-ui`, `api`, `docs`.
- **Équipes** : Core (auth, api, admin-ui), Commerce (catalog, cart, checkout, inventory), Payments (billing, notif), DX (docs).

**Rubrique de tri** :
- `type` ∈ {`bug`, `feature`, `question`, `tech-debt`, `security`, `docs`, `duplicate`, `invalid`}
- `severite` ∈ {`S1-critique`, `S2-majeur`, `S3-mineur`, `S4-trivial`} (S1 = sécurité / perte de données / indispo prod)
- `priorite` ∈ {`P0`, `P1`, `P2`, `P3`}
- `composant` ∈ liste ci-dessus (utilise `"?"` si tu n'es pas sûr et ajoute une question)
- `effort` ∈ {`S`, `M`, `L`, `XL`}
- `besoin_infos` ∈ {`oui`, `non`}

Pour chaque ticket, renvoie un objet :
```
{
  "id": "...",
  "type": "...",
  "severite": "...",
  "priorite": "...",
  "composant": "...",
  "effort": "...",
  "besoin_infos": "...",
  "questions_a_poser": ["..."],
  "doublon_possible_de": "id ou null",
  "indices_securite": "oui/non + lesquels",
  "justification": "1-2 phrases"
}
```

**Règles strictes** :
- Tout indice de faille de sécurité → `type=security`, `severite ≥ S2`, et signale-le dans `indices_securite`.
- Tu **suggères**, tu ne fermes pas : `invalid` et `duplicate` sont des propositions, jamais des décisions définitives.
- Si tu n'es pas sûr d'un composant : `"?"` + une question dans `questions_a_poser`.
- Sortie = JSON valide, parseable, rien autour.

**Tickets** :
```
[colle ici le contenu de fixture.md]
```
