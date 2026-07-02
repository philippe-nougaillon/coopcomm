#!/usr/bin/env python3
"""Garde-fou PreToolUse pour les commandes Bash de Claude Code.

Bloque de façon déterministe les actions interdites sans accord explicite
(cf. CLAUDE.md, section "Périmètre de l'agent") : git push / reset --hard /
clean, migrations & opérations de schéma DB, déploiement, envois réels
mail/SMS/WhatsApp (Mailgun/Twilio).

Reçoit le JSON du hook sur stdin, écrit une décision "deny" sur stdout si la
commande matche un motif dangereux ; sinon ne dit rien (la chaîne de
permissions normale décide). Aucune dépendance externe (pas de jq) — Python 3
de /usr/bin, toujours disponible.

  echo '{"tool_input":{"command":"git push origin main"}}' | python3 guard-bash.py

Conçu pour "fail-closed" sur les motifs ; mais si le JSON est illisible, on
laisse passer (fail-open) plutôt que de bloquer tout le travail légitime —
le hook est un filet, pas l'unique barrière.
"""
import json
import re
import sys


def deny(reason: str) -> None:
    json.dump(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": reason,
            }
        },
        sys.stdout,
    )
    sys.exit(0)


def main() -> None:
    try:
        data = json.load(sys.stdin)
        cmd = (data.get("tool_input") or {}).get("command") or ""
    except Exception:
        # JSON illisible : on n'a pas de quoi décider, on laisse passer.
        sys.exit(0)

    if not isinstance(cmd, str) or not cmd.strip():
        sys.exit(0)

    # --- git : push (toutes formes : --force, -C, options globales) ---
    if re.search(r"(?:^|[;&|]|\s)git(?:\s+-\S+|\s+-C\s+\S+)*\s+push\b", cmd):
        deny("BLOQUE : 'git push' interdit sans accord explicite (CLAUDE.md). "
             "Demande-moi de pousser a la main.")

    if re.search(r"\bgit(?:\s+-\S+)*\s+reset\s+(?:--hard|--keep|--merge)\b", cmd):
        deny("BLOQUE : 'git reset --hard' (perte de travail) interdit sans accord explicite.")

    if re.search(r"\bgit(?:\s+-\S+)*\s+clean\s+(?:-\w*f|--force)", cmd):
        deny("BLOQUE : 'git clean -f' (suppression de fichiers non suivis) interdit sans accord explicite.")

    # --- migrations / operations de schema destructrices (toute invocation rails) ---
    if re.search(r"\bdb:(?:migrate|rollback|drop|reset|setup|prepare|schema:load|truncate_all)\b", cmd):
        deny("BLOQUE : tache de migration/schema DB (db:migrate, db:rollback, db:drop...) "
             "interdite sans accord explicite. App en prod.")

    # --- deploiement ---
    if (re.search(r"(?:^|[;&|]|\s)(?:kamal|mina|dokku)\b", cmd)
            or re.search(r"\bcap\s+[^|;&]*\bdeploy\b", cmd)
            or re.search(r"(?:^|[;&|]|\s)(?:bin/deploy|\./deploy)\b", cmd)):
        deny("BLOQUE : commande de deploiement interdite sans accord explicite.")

    # --- envois reels mail / SMS / WhatsApp (best-effort sur invocations bash) ---
    if (re.search(r"\bdeliver_now\b", cmd)
            or re.search(r"(?i)\b(?:twilio|mailgun)\b", cmd)
            or re.search(r"(?i)rails\s+runner[^|;&]*(?:deliver|whatsapp|\bsms\b|messages\.create)", cmd)):
        deny("BLOQUE : envoi reel d'email/SMS/WhatsApp (Mailgun/Twilio) interdit sans accord explicite. "
             "Vraies communes en prod.")

    sys.exit(0)


if __name__ == "__main__":
    main()
