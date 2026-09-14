# Checklist opérationnelle — conduite de session

> Sortie de `CLAUDE.md` le 2026-09-11 (règles génériques, non spécifiques à CoopComm). L'essentiel est repris en 5 lignes dans `CLAUDE.md` ; ce fichier garde le détail, à relire lors d'un bilan de méthode.


### (a) Toute conversation / tâche
- **Cadrage 30 s** avant d'exécuter : objectif clair ? contexte donné ? périmètre + livrable définis ? Sinon → poser des questions / laisser l'agent poser des questions + valider le plan.
- **Un seul sujet par conversation.** Quand ça s'allonge (~20 échanges, ou les réponses se dégradent — *context rot*) → demander une synthèse écrite dans un fichier (`.claude/method/journal-session.md`) et relancer une conversation propre.
- **Fournir le contexte / les fichiers** pertinents ; ne pas s'appuyer sur la « connaissance » du modèle pour des faits sur ce projet — lui faire lire le code/les docs.
- **Faire poser des questions avant d'agir** + valider le plan ; pour une tâche complexe : « D'abord lis les fichiers. Ensuite pose-moi des questions. Puis propose plusieurs approches. »
- **Vérifier à chaque étape**, pas seulement à la fin. Si c'est trop long pour être vérifié, c'est trop long → 10 petites itérations vérifiées plutôt qu'une grosse génération.
- **Moins d'étapes IA** : les erreurs se propagent en cascade ; biais du milieu sur les longs contextes.
- **Distinguer fait / déduction / opinion** dans ce que l'agent affirme (et le lui demander, de façon fluide).
- **Anti-flagornerie + devil's advocate** : « critique ta réponse » ; « défends la position inverse ». Instruction système : pas de flagornerie, esprit critique.
- **Pas de données sensibles** dans les prompts ; pas de secret dans les fichiers ; vérifier la conformité du fournisseur de modèle (RGPD, rétention).
- **Relire la sortie** — ne jamais accepter sans relecture (« s'endormir au volant » : plus l'IA paraît sûre, plus le risque d'erreur grimpe).
- **Clôture** : angles morts / ce qui reste incertain ; prochaines étapes ; questions ouvertes.

### (b) Spécifique au code / Claude Code
- **Explorer l'existant AVANT d'écrire** : « explore les fichiers et dis-moi ce que tu trouves » (structure, conventions, points sensibles, tests existants).
- **Mini-plan validé** par moi avant la moindre ligne de code. (Voir aussi le PROTOCOLE §3.)
- **`CLAUDE.md` à jour** : ce fichier (section 1). En fin de session : maj « état d'avancement » + « décisions ». `.claude/method/journal-session.md` pour le suivi détaillé d'une session.
- **Tout en Markdown** pour la doc/les notes ; éviter PDF/Word ; l'agent scanne les `.md` plus vite.
- **Conversations courtes + jardinage** : refactorer/nettoyer régulièrement les dossiers de travail (« fais une revue de ce dossier et propose des améliorations pour le nettoyer »).
- **Périmètre d'accès minimal** : l'agent travaille dans le(s) dossier(s) autorisé(s) ; pas d'accès au home ni à d'autres projets. Attention au **lethal trifecta** (accès à des données privées + exposition à du contenu non fiable + capacité de communiquer vers l'extérieur = risque d'exfiltration) → en casser au moins un. Détail : `methode-evaluation-et-securite-agents.md` §B.
- **Skills/fichiers importés de tiers** : faire analyser leurs failles (instructions cachées, exfiltration) avant usage ; épingler les versions.
- **Actions irréversibles** (`git push`, `reset --hard`, suppression hors périmètre, envoi de mail/message, migration, déploiement, paiement) : confirmation explicite de l'humain — jamais auto-accordée. `git commit` fréquent ou snapshot avant de lâcher un agent sur le repo.
- **Coût** : Claude Code consomme beaucoup de tokens ; budget/plafond ; limites de boucles/timeout ; modèle suffisant (Sonnet/Haiku quand ça suffit, pas Opus partout).
- **Devil's advocate sur les décisions d'archi** que l'agent propose.
- **Construire progressivement** : un modèle, un-deux outils, trois étapes max ; vérifier chaque sortie avant d'augmenter la complexité ; humain dans la boucle au point de risque max.

### (c) Slash-commands & méta-méthodes
- **Si `.claude/commands/` est présent dans le projet** (avec `kit-prompting.md` dans `.claude/method/`), 11 commandes sont disponibles :
  - **Action** (déclenchables d'un trait) : `/extract` (T1, analyse de doc), `/deep-research` (T4), `/image-prompt` (T6), `/refactor` (T7, code), `/session-start` (T8, démarrage/reprise/clôture), `/review` (T9, PR), `/post-mortem` (T10), `/api-doc` (T11), `/triage` (T12, tickets en JSON), `/tests` (T13).
  - **Méta** : `/eval` (lance une éval du `.claude/method/golden-set/` — voir `methode-evaluation-et-securite-agents.md` §A).
  - Chaque commande renvoie au template correspondant de `.claude/method/kit-prompting.md` — **source de vérité unique**, ne pas dupliquer.
- **Postures à invoquer VERBALEMENT** (pas de slash-command — ce sont des manières de conduire la conversation, pas des actions ponctuelles) :
  - **T2 — Dialogue Engineering** : « construis la conversation par strates avant la vraie question » ; convoque des penseurs (« Comment X aborderait‑il cette question ? », « cite 5 auteurs qui ont pensé ce problème »), exige des références scientifiques/philo, **anti‑flagornerie** systématique, clôture par la **phase 4 de Polya**.
  - **T3 — Écriture sans clichés** : avant la rédaction, énonce la hiérarchie **Fond → Structure → Style (non négociable)** + les contraintes anti‑lissage (bannir « crucial / captivant / dans un monde / il est important de noter que », pas de « ce n'est pas X – c'est Y », pas de tirets quadratins, « Open Loop » au § 1 fermée au § 10).
  - **T5 — Critique steelman** : pour toute décision d'archi/produit, exige le **steelman des deux côtés** + le devil's advocate + les conditions sous lesquelles la recommandation s'inverserait.
  - **Pourquoi pas de commande dédiée** : ces postures s'orchestrent dans la conversation et perdent leur tranchant si on les déclenche d'un seul mot. Tu peux toujours les rappeler à l'agent : *« Pour la suite : T2 / T3 / T5. »*

---

