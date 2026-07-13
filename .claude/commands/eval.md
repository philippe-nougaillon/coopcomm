---
description: Lance une éval du golden-set (un cas ou tous) + écrit dans golden-set/_journal.md
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

Lance une **éval du golden-set** selon le protocole de `./methode-evaluation-et-securite-agents.md` (§A). Cible : $ARGUMENTS (ex. `E1`, `E4`, `E5`, `all`, ou rien = me demander).

**Procédure stricte** :

1. **Cibler** : si `$ARGUMENTS` est vide ou ambigu, liste les fixtures disponibles sous `.claude/method/golden-set/E*-*/` et demande-moi laquelle (ou `all`). Si `all` : itère sur chaque fixture, dans l'ordre lexicographique.

2. **Pour chaque cas Eᵢ** :
   a. Lis `.claude/method/golden-set/Eᵢ-*/README.md` (contexte de la tâche + critères) **mais PAS encore `reference.md`** (pas regarder la réponse de référence avant d'avoir produit la tienne).
   b. Lis `.claude/method/golden-set/Eᵢ-*/prompt.md` (le prompt gelé pour cette tâche — il renvoie typiquement à un template `Tn` de `.claude/method/kit-prompting.md`) et `.claude/method/golden-set/Eᵢ-*/fixture.*` (l'entrée).
   c. **Joue le rôle du candidat** : produis la sortie comme une vraie tâche, sans rien savoir de la réponse de référence. Réfléchis selon le prompt ; pas de raccourci.
   d. Sauvegarde la sortie brute dans `.claude/method/golden-set/Eᵢ-*/runs/AAAA-MM-JJ-HHMM-<modele>.md` (utilise `date -u +%Y-%m-%d-%H%M` ; remplace `<modele>` par le nom du modèle courant — demande-le-moi si tu n'es pas sûr).
   e. **Bascule juge** : maintenant lis `reference.md` et la **grille A.3** de `methode-evaluation-et-securite-agents.md` (correctness, complétude, fidélité, fait/déduction/opinion, format, élévation, anti-lissage, sécurité, coût). Pour chaque critère applicable, note 0-3 + une phrase de justification. Liste les **modes de défaillance** (récurrents ou ponctuels).
   f. Calcule le score moyen + le **pire score** (un modèle qui plafonne mais s'écroule sur un critère = signal). Note explicitement la **variance** si tu refais le tirage (recommandé : 2-3 tirages pour les tâches sensibles).

3. **Mise à jour du journal** : ajoute une ligne dans `.claude/method/golden-set/_journal.md` (crée le fichier s'il n'existe pas, avec l'en-tête recommandé en §C de `methode-evaluation-et-securite-agents.md`). Colonnes : Date | Modèle+version | Tâche | Score global | Pire score | Modes de défaillance | Décision/action.

4. **Rapport final** (concis) : tableau récap (cas, score, pire score), 3-5 lignes de « ce qu'on apprend de cette campagne », et une **décision/action** concrète (ex. « basculer X sur tâche Y », « ajouter une contrainte au prompt Tn », « retirer cet usage de l'IA »). Pas de score qui dort.

**Garde-fous** :
- **Aveugle** quand possible : si plusieurs modèles à comparer, anonymise A/B/C avant de noter, puis dé-anonymise.
- **Conditions identiques** : même prompt, même contexte, même état initial du repo (snapshot/branche jetable pour les tâches « agent »).
- Si le golden-set n'existe pas encore (dossier absent ou vide) : signale-le et propose de générer 2-3 fixtures synthétiques de départ (cf. les fixtures fournies E1/E4/E5).
- **Pas de flagornerie** sur tes propres sorties — un juge complaisant ne sert à rien. Si tu es à la fois candidat et juge dans cette éval, **dis-le explicitement** dans le journal (biais d'auto-évaluation).
