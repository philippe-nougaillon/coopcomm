# Perfectionnements — CoopComm

> **Améliorations repérées en session, ni urgentes ni décidées** : ce qui serait mieux et n'est ni un bug, ni une décision à prendre, ni une action humaine, ni une dette. Ergonomie, lisibilité, outillage, petits plus. Faits ou abandonnés : `perfectionnements-faits.md`. Décisions en attente : `points-a-trancher.md`. Actions humaines : `actions-a-faire.md`.
>
> **Perfectionnement, dette ou risque ?** Le code livré à réécrire ou nettoyer, parce qu'il devient plus dur à maintenir ou plus lent, est une **dette** : `dettes-ouvertes.md`. Un angle mort où une régression passerait sans être vue est un **risque** : `risques-surveilles.md`. Ici, ce serait mieux, mais attendre ne coûte pas davantage.
>
> **Gravité** — la fiche va dans la section de ce qui **reste perdu tant que la fiche attend** :
> - 🔴 **Bloque la prod ou l'argent** : attendu par de vrais utilisateurs avant la mise en prod, obligation contractuelle, argent.
> - 🟠 **Attendu avant la montée en charge ou le prochain jalon** : gêne visible en usage courant, ou un chantier prévu en dépend.
> - ⚪ **Confort** : cas rare, long terme, ou acté et non planifié.
>
> **Règle de tenue** : prochain numéro libre ci-dessous (préfixe `P`), rangement **par numéro** dans la section. Une fiche commence par une ligne **Effort : faible (moins d'une demi-journée), moyen (une demi-journée à deux jours), élevé (au-delà)**, puis constat, impact, piste. **Toute limite, angle mort ou « non vérifié » cité dans une réponse devient une fiche ici, dans `dettes-ouvertes.md` ou dans `risques-surveilles.md`, ou complète la sienne, dans le même tour.** Une fiche faite ou abandonnée quitte ce fichier pour `perfectionnements-faits.md`, titre préfixé `✅ FAIT (AAAA-MM-JJ)` ou `✅ ABANDONNÉ (AAAA-MM-JJ)`, avec le commit ou la raison.
>
> **Prochain numéro libre : P4**

---

## 🔴 Bloque la prod ou l'argent

_Aucune._

## 🟠 Attendu avant la montée en charge ou le prochain jalon

### P1 — slim-select : soumission, troncature des puces, labels et filtres Service inégaux d'une vue à l'autre (constat 2026-10-05, sonde HTML sur 25 pages, 54 selects)
- **Effort : moyen.** Chantier ouvert par PE le 2026-10-05 ; le code mort et le doublon de câblage relevés le même jour ont été réglés le jour même (**DT13**, `dettes-reglees.md`).
- **Deux soumissions** sur un même formulaire : `this.form.submit()` (rechargement complet hors Turbo, `data-turbo-action: "advance"` ignoré) sur le statut de `commandes`, `cotations`, `factures` et `adherent_crm` et sur tout `conventions/index` ; `requestSubmit()` sur les autres filtres. Impact : d'un filtre à l'autre, la page recharge ou non, le scroll saute ou non.
- **Troncature des puces** : `max_values_shown_*` absent sur 7 filtres multiples (`interventions/index` adhérents, mots clés, service, agents, matériels ; `mouvements/index` matériels ; `adherent_crm` services), valeurs de 1/1 à 6/3 ailleurs sans règle apparente. Mesuré au navigateur sur `/users` : le badge `+ 1` et la puce cachée fonctionnent. Piste : une règle par largeur de colonne, posée une fois.
- **Labels sans champ** : `interventions/index` — `select_tag "tags[]"` produit l'id `tags_` quand `label_tag :tags` vise `tags` ; `mouvements/index` — id `etats-select` posé sur le select que `label_tag :etats` désigne. Au sens strict c'est faux aujourd'hui (le label ne cible rien) : fiche B si on préfère.
- **Filtres Service** (tous bornés au périmètre) : quatre noms de paramètre (`services[]`, `service[]`, `service_ids[]`, `service_id[]`) et deux comportements par défaut pour l'administrateur — pré-filtré sur ses services (`users`, calendrier des agents, via `scoped_services`), tout le périmètre (`interventions` — voulu —, devis/commandes/factures par intersection avec `get_services_by_role`, conventions et CRM par `policy_scope`).

### P2 — Selects d'identité sans invite (constat 2026-08-31, lot B99 ; ex-DT8, requalifié perfectionnement le 2026-10-05)
- **Effort : faible.**
- sur un formulaire d'intervention neuf, les widgets **Adhérent** et **Service** s'affichent complètement vides, sans aucune invite — le placeholder d'un select requis est vide par construction. Comportement antérieur au lot B99, mais plus visible depuis que la ligne vide a disparu du menu. Le remède est déjà pratiqué dans le dépôt : `prompt: "Choisir un adhérent"` (`commandes/_form`), là où les trois `_prestation_form` ont au contraire `prompt: ""`. Décision d'ergonomie à prendre en une fois pour les ~8 selects concernés.

## ⚪ Confort

### P3 — Template de PR GitHub (mis de côté le 2026-07-10 ; ex-DT11, requalifié perfectionnement le 2026-10-05)
- **Effort : faible.**
- créer `.github/pull_request_template.md` avec 5-6 cases à cocher (une par famille d'erreur de `CONTRIBUTING.md` §2) — GitHub pré-remplit alors la description de chaque PR, cases cliquables. Décision client : **pour l'instant on utilise `CONTRIBUTING.md` seul** ; à réévaluer si la checklist n'est pas suivie en revue. Doc : <https://docs.github.com/fr/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository>.
