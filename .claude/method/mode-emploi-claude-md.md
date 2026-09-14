# Mode d'emploi — adapter CLAUDE.md à un nouveau projet

> Sorti de `CLAUDE.md` le 2026-09-11 : sans usage dans un projet en cours.


1. **Copie ce fichier** à la racine du projet sous le nom `CLAUDE.md` (et `CLAUDE.minimal.md` si tu préfères la version courte ; supprime celui que tu n'utilises pas).
2. **Remplis uniquement la section 1** (« CE PROJET »). Laisse les sections 2 et 3 intactes — ce sont les règles, identiques partout.
3. **Crée `.env.example`** (noms des variables, pas les valeurs) et un `.gitignore` qui exclut au minimum : `.env`, `*.key`, `*.pem`, `.claude/settings.local.json`, `.claude/CLAUDE.local.md`, et tout fichier de secrets.
4. **Crée un sous-dossier `.claude/`** si besoin (cf. arborescence type dans `generation-ia-synthese-approfondie.md` §17.5) :
   - `.claude/settings.json` (réglages partagés : permissions allowlist, hooks — à committer ; **aucun secret**) ; `.claude/settings.local.json` (réglages perso — à NE PAS committer) ;
   - `.claude/commands/` : les 11 slash-commands (`/extract`, `/deep-research`, `/image-prompt`, `/refactor`, `/session-start`, `/review`, `/post-mortem`, `/api-doc`, `/triage`, `/tests`, `/eval`) — chacune renvoie au template `Tn` de `.claude/method/kit-prompting.md` (à copier dans `.claude/method/`, ou laisser pointer vers `~/aikku/CLAUDE/kit-prompting.md`) ; voir `~/aikku/CLAUDE/.claude/commands/README.md`.
   - `.claude/skills/` (skills — ⚠ auditer toute skill tierce) ; `.claude/agents/` (sous-agents).
5. **À chaque fin de session** : maj de « état d'avancement » et « décisions (et pourquoi) » dans la section 1 ; `.claude/method/journal-session.md` pour le détail.
6. **Renvois utiles** (si tu as ces fichiers sous la main) :
   - `generation-ia-synthese-approfondie.md` — la synthèse complète : §0 protocole, §5 prompting (toutes les techniques), §6 context engineering, §8 agents & code, §10 éthique/sécurité, §13 THÉSAURUS du prompting, §16 TEMPLATES (T1–T13 : analyse de doc, dialogue engineering, écriture sans clichés, recherche approfondie, steelman, image, refacto code, démarrage de session, revue de PR, post-mortem, doc d'API, tri de tickets, génération de tests).
   - `.claude/method/kit-prompting.md` — version légère : thésaurus + boîte à tokens images + 13 templates + checklist. À charger en conversation de travail.
   - `methode-evaluation-et-securite-agents.md` — protocole d'évaluation maison (golden set + grille + cadence) + checklist sécurité « builder / agent en prod » (au-delà du lethal trifecta) + checklist « pré-mise-en-prod ».
7. **Régime** : ce modèle suppose le régime « Claude Max + agents » (Claude Code/Cowork, MCP, Skills). Si tu travailles sur un projet plus modeste, `CLAUDE.minimal.md` suffit ; les règles des sections 2-3 restent valables.
