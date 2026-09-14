#!/usr/bin/env python3
"""Auto-approbation PreToolUse des fichiers de suivi de l'agent.

PE a accordé (2026-07-13, élargi 2026-07-27) l'écriture SANS demander dans
`suivi/` (registre `bugs-signales.md`, `points-a-trancher.md`), dans
`.claude/method/` (journal, fiches…) et dans le répertoire de mémoire de
l'agent. Cet accord
tenait dans les instructions, donc l'agent le « savait » — mais c'est le
harnais, pas l'agent, qui affiche « make this edit to bugs-signales.md? ».
Une consigne en langage naturel ne peut pas éteindre ce prompt ; seul un hook
qui renvoie `permissionDecision: "allow"` le fait de façon déterministe.

Reçoit le JSON du hook sur stdin. Si le chemin visé est dans un des dossiers
autorisés, écrit une décision "allow" sur stdout ; sinon ne dit rien (la
chaîne de permissions normale décide). Aucune dépendance externe (pas de jq).

  echo '{"tool_input":{"file_path":"suivi/bugs-signales.md"}}' \
      | python3 allow-notes.py

Fail-open : si le JSON est illisible ou le chemin absent, on se tait et on
laisse le flux de permissions habituel trancher.
"""
import json
import os
import sys

PROJET = os.environ.get("CLAUDE_PROJECT_DIR", "/home/pedacquet/aikku/coopcomm")

# Dossiers dont TOUT le contenu est éditable sans confirmation.
DOSSIERS_AUTORISES = (
    os.path.join(PROJET, "suivi"),
    os.path.join(PROJET, ".claude"),
    "/home/pedacquet/.claude/projects/-home-pedacquet-aikku-coopcomm/memory",
)

# Fichiers isolés éditables sans confirmation (PE : section 1 de CLAUDE.md ;
# le hook ne sait pas distinguer les sections, donc le fichier entier passe).
FICHIERS_AUTORISES = (os.path.join(PROJET, "CLAUDE.md"),)

# Aucune exception : PE a tranché le 2026-07-28 (« tous les fichiers dans le
# dossier .claude »). Les hooks eux-mêmes (guard-bash.py, ce fichier) et
# settings.local.json sont donc éditables sans confirmation — l'agent peut
# techniquement désarmer ses propres garde-fous, risque accepté et signalé.
# Ce qui reste : les interdits du « Périmètre de l'agent » (push, migrate,
# déploiement, envois réels) restent des règles de conduite, et guard-bash.py
# continue de les bloquer tant qu'il n'est pas modifié.
DOSSIERS_EXCLUS = ()
FICHIERS_EXCLUS = ()


def main() -> None:
    try:
        payload = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        return

    chemin = (payload.get("tool_input") or {}).get("file_path")
    if not chemin:
        return

    # realpath : neutralise `..`, les liens symboliques et les chemins relatifs.
    cible = os.path.realpath(chemin)

    def sous(dossier: str) -> bool:
        racine = os.path.realpath(dossier)
        return cible == racine or cible.startswith(racine + os.sep)

    # Les exclusions priment : on se tait, la confirmation habituelle s'applique.
    if any(sous(d) for d in DOSSIERS_EXCLUS):
        return
    if any(cible == os.path.realpath(f) for f in FICHIERS_EXCLUS):
        return

    autorise = any(sous(d) for d in DOSSIERS_AUTORISES) or any(
        cible == os.path.realpath(f) for f in FICHIERS_AUTORISES
    )
    if autorise:
        json.dump(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "allow",
                    "permissionDecisionReason": (
                        "Fichier de suivi de l'agent : écriture accordée "
                        "d'avance par PE (suivi/ / CLAUDE.md / .claude/ / mémoire)."
                    ),
                }
            },
            sys.stdout,
        )


if __name__ == "__main__":
    main()
