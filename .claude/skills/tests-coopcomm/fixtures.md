# Fixtures

Quand **aucune fixture ne porte l'attribut nécessaire** au test (état de workflow, booléen à `true`, appartenance à une autre organisation…), **en créer une** plutôt que d'écrire l'enregistrement dans le test ou de muter une fixture existante avec `update!`.

**Nom explicite qui dit l'attribut** : `cotation_validée`, `mouvement_marseille`, `wiki_page_publique`.

⚠ **Ne jamais modifier une fixture déjà utilisée ailleurs** — on en ajoute une à côté.

⚠ **Toujours relancer la suite complète après un ajout.** Une fixture de plus casse tout test qui compte des enregistrements en dur (pagination, `assert_difference` global, tâches qui balaient une table entière). C'est alors **le test fragile qu'on rend robuste** (compter à partir de la base au lieu d'un littéral), **pas la fixture qu'on retire**.
