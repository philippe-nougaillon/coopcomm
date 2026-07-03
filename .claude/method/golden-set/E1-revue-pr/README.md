# E1 — Revue de PR

**Tâche** : faire la revue d'une PR **Rails 7.x / Ruby 3.x** qui ajoute un `ProfilesController` (`show`/`update`) + un endpoint interne caché. La PR contient **trois bugs de sécurité critiques (dont un éliminatoire), deux problèmes importants, et un nit idiomatique**.

**Contexte du projet (à donner au modèle via le prompt)** : *« OrderFlow API »*, monolithe interne, **Ruby 3.3, Rails 7.1, ActiveRecord, PostgreSQL, RSpec + FactoryBot + rails-controller-testing**. Authentification : Devise (`authenticate_user!`, `current_user`). Conventions : Strong Parameters obligatoires sur toutes les mutations ; pas de SQL brut (ActiveRecord ou requêtes paramétrées) ; rôles `current_user.role` ∈ `{nil, "user", "manager", "admin"}` ; **tests obligatoires sur les chemins d'autorisation (positifs ET négatifs)** dans `spec/requests/`. Branche protégée = `main`, format de commit = Conventional Commits.

**Fixture** : `fixture.diff` (output de `git diff main...feature/profile-endpoints`).

**Critères de la grille A.3 applicables** : Correctness, Complétude (a‑t‑il trouvé tous les défauts ?), Sécurité (le bug d'autorisation est S1 éliminatoire), Distinction fait/déduction, Format (sévérité + fichier:ligne + correction Ruby idiomatique, devil's advocate + verdict).

**Notation rapide** :
- **3** = trouve les 6 défauts (3 sécu critiques + mass assignment + spec négatif manquant + nit), sévérités correctes, corrections idiomatiques Ruby/Rails, devil's advocate présent, verdict cohérent.
- **2** = trouve le bug d'autorisation + ≥ 3 autres, manque ≤ 2 points, pas de faux positif majeur.
- **1** = manque le bug d'autorisation OU ≥ 3 faux positifs OU verdict incohérent.
- **0** = approuve la PR sans signaler le bug d'autorisation.

**Pénalité forte (éliminatoire)** : si le modèle approuve la PR sans signaler le bug d'autorisation (`current_user.role == "admin" || "manager" || ...` toujours truthy en Ruby parce que `"manager"` est une chaîne non vide), il prend **0 sur le critère Sécurité** quel que soit le reste.

**Bonus** : signaler que `head :forbidden and return` est un antipattern Ruby (précédence du `and` vs `&&`), et/ou que l'utilisation de `find_by_id` est moins idiomatique que `find_by(id:)` / `find` en Rails 4+.
