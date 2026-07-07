---
description: Doc d'API fidèle à la source (porte de sortie sur les ambiguïtés) — T11
allowed-tools: Read, Glob, Grep, Bash
---

Lis le **template T11 — « Documentation d'API »** dans `.claude/method/kit-prompting.md` (dans `.claude/method/` — sinon `~/aikku/CLAUDE/kit-prompting.md`). Applique-le rigoureusement à la source suivante (spec OpenAPI / code des handlers / exemples) : $ARGUMENTS

Rappels :
- Public cible = « profane éduqué » du domaine : clair, précis, aucune zone d'ombre.
- **N'invente rien hors de la source.** Toute info absente → « [à documenter — non spécifié dans la source] ».
- Pas de phrases préfabriquées (« n'hésitez pas à », « tout simplement », « il est important de noter que »).
- Inclus : Quickstart 5 lignes, pièges connus, changelog vide à remplir.
- À la fin : liste les incohérences/ambiguïtés repérées dans la source.
