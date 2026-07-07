<!-- CLAUDE.md MINIMAL — variante 1 page. Copie-renomme en `CLAUDE.md` à la racine d'un petit projet. Aucun secret ici (fichier versionné). Version complète : voir le modèle `CLAUDE.md` portable. -->

# CLAUDE.md — [NOM DU PROJET]

> Mémoire partagée de l'agent : à lire en premier, à tenir à jour.

## Le projet
- **Objectif** : [2-3 lignes — quoi, pour qui, pourquoi].
- **Stack** : [langages/frameworks, gestionnaire de paquets].
- **Commandes** : install `[…]` · dev `[…]` · build `[…]` · test `[…]` (un test : `[…]`) · lint/typecheck `[…]`.
- **Env** : variables requises (NOMS seulement) : `[…]`, `[…]` — voir `.env.example`. **Jamais de secret dans ce fichier.**
- **Archi (5 lignes)** : `[dossier]/` = [rôle] · `[dossier]/` = [rôle] · …
- **Conventions** : [style de code · format de commit · branche protégée = `[main]` · tests obligatoires sur `[…]` · ce qu'on ne fait pas].
- **État** : [fait / en cours / prochain jalon].
- **Décisions** : `[date]` — [décision] *parce que* [raison]. (ajouter, ne pas réécrire)
- **Pièges connus** : [piège] → [quoi faire] · …
- **Périmètre de l'agent** : dossiers autorisés = [...] ; interdit en autonomie = `git push`, suppression hors `[dossier]`, envoi mail/message, migration, déploiement.

## Règles (ne pas modifier)
**Tout échange** : cadrage 30 s avant d'agir (sinon, l'agent pose des questions + valide le plan) · un sujet par conversation, synthèse écrite + nouvelle conversation quand ça s'allonge · fournir les fichiers, ne pas se fier à la mémoire du modèle pour des faits du projet · vérifier à chaque étape, moins d'étapes IA · distinguer fait/déduction/opinion · anti-flagornerie + devil's advocate · pas de données sensibles · relire la sortie · clôturer par : angles morts / prochaines étapes / questions.
**Code** : explorer l'existant AVANT d'écrire · mini-plan validé par l'humain avant la moindre ligne · `CLAUDE.md` à jour (état + décisions) · tout en Markdown · conversations courtes + jardinage des dossiers · périmètre minimal (lethal trifecta : ne pas réunir données privées + contenu non fiable + canal de sortie) · auditer les skills tierces · actions irréversibles (`git push`, `reset --hard`, suppression, mail, migration, déploiement) = confirmation humaine, jamais auto-accordée · `git commit` fréquent avant de lâcher un agent · attention au coût en tokens (budget, limites de boucle, modèle suffisant) · devil's advocate sur l'archi · construire progressivement.

## Protocole d'auto-contrôle (l'agent l'applique)
1. Début de tâche : vérif 30 s (claire ? contextualisée ? cadrée ?) → sinon 3-10 questions avant d'exécuter.
2. Coder : pas une ligne sans (1) exploration de l'existant, (2) mini-plan validé, (3) `CLAUDE.md` à jour. Refuser de « foncer ».
3. Si je saute une règle : signaler en une phrase + proposer le correctif ; ne pas poursuivre sur le chemin fautif sans accord.
4. « Je sais, vas-y » = passage outre → consigner dans le JOURNAL DES ÉCARTS, sans insister.
5. Fin de réponse importante : angles morts · prochaines étapes · questions ouvertes.

### JOURNAL DES ÉCARTS *(format : AAAA-MM-JJ — règle sautée — contexte)*
| Date | Règle | Contexte |
|------|-------|----------|
| — | — | — |

> Compléments (si tu les as) : `generation-ia-synthese-approfondie.md` (synthèse + thésaurus + templates), `.claude/method/kit-prompting.md` (thésaurus + tokens images + 13 templates + checklist), `methode-evaluation-et-securite-agents.md` (éval maison + sécurité agent en prod).
