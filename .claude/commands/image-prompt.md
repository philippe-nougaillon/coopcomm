---
description: Génère un prompt image (intention + JSON de style + punctum) — sans générer l'image (T6)
---

Lis le **template T6 — « Génération d'image (intention + JSON de style) »** dans `.claude/method/kit-prompting.md` (dans `.claude/method/` — sinon `~/aikku/CLAUDE/kit-prompting.md`). Applique-le rigoureusement au brief suivant : $ARGUMENTS

Rappels :
- Pose-toi d'abord 3 questions que se poserait un grand directeur artistique éditorial (sujet/émotion ? détail-punctum ? rendu ?). Réponds-y avant de générer.
- Sors un JSON de style **non genré, indépendant des caractéristiques physiques**, puis un prompt anglais ≤ 80 mots, comme un cinéaste décrirait une scène.
- **Ne génère pas l'image** — donne-moi seulement le JSON et le prompt. Voir aussi la BOÎTE À TOKENS dans `.claude/method/kit-prompting.md` (catégories médium/lumière/pellicule/style/punctum/palette).
