# Fixtures

## En ajouter une, plutôt que de bricoler

Quand **aucune fixture ne porte l'attribut nécessaire** au test (état de workflow, booléen à `true`, appartenance à une autre organisation…), **en créer une** plutôt que d'écrire l'enregistrement dans le test ou de muter une fixture existante avec `update!`.

**Nom explicite qui dit l'attribut** : `cotation_validée`, `mouvement_marseille`, `wiki_page_publique`. C'est le nom qui porte la précision, jamais un commentaire.

⚠ **Ne jamais modifier une fixture déjà utilisée ailleurs** — on en ajoute une à côté.

⚠ **Toujours relancer la suite complète après un ajout.** Une fixture de plus casse tout test qui compte des enregistrements en dur (pagination, `assert_difference` global, tâches qui balaient une table entière). C'est alors **le test fragile qu'on rend robuste** (compter à partir de la base au lieu d'un littéral), **pas la fixture qu'on retire**.

## Où elles vivent dans le fichier de test

**Une fixture principale, posée dans le `setup`**, et des fixtures dérivées quand la situation l'exige (un acteur d'une autre organisation, un record dans un autre état). Une fixture utilisée **une seule fois** reste dans le test qui s'en sert ; dès qu'elle sert deux fois, elle remonte au `setup`.

## Jamais de date relative

⚠ **Ne jamais ancrer une fixture ni un test sur `Time.now` / `Date.today`** (`CLAUDE.md` §3) : ça produit des « bombes du jeudi » (une date relative retombe sur une fixture existante), des échecs entre 14 h et 15 h, ou entre minuit et 4 h. **Ancrer sur une date passée fixe**, choisie sans conflit de disponibilité.

## Fichiers

Les pièces jointes, classeurs et **réponses d'API** vivent dans `test/fixtures/files/` — une par service et par cas. Elles sont **écrites à la main**, réduites aux champs que le code lit réellement ; une réponse réelle capturée est **relue et expurgée** avant d'être commitée (clé d'API, jeton, identifiant de compte, adresse et numéro de téléphone réels n'ont rien à y faire, le dépôt est candidat à l'open-source).

⚠ Un pré-requis de fichier ne se `skip` pas, il s'asserte — voir `SKILL.md`.
