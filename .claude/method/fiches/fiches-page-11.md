# Fiches — page 11 (articles 121 à 132)

### 121. 2023-11-26 — C'est la CataGPT !
**URL** : https://generationia.flint.media/p/analyse-rebondissements-openai-chatgpt
**Tags** : actu | outils-panorama | mindset-culture
**Type** : décryptage

- **Idée centrale** : "Peut-on encore compter sur ChatGPT ?" Réaction à la crise OpenAI (éviction puis réintégration d'Altman, nov. 2023). Le secteur révèle beaucoup d'irrationnel et un peu d'amateurisme autour du chatbot ; ChatGPT reste fiable mais "ne mets pas tous tes œufs dans le même panier" — il faut diversifier ses outils d'IA.
- **Techniques de prompting / méthode** : (a) utiliser Code Interpreter pour générer une présentation PowerPoint (génère une image par slide, ajoute le texte, assemble le tout) ; (b) analyser une image / schéma / infographie avec GPT-4-V (téléchargement d'image + demande d'analyse critique) ; (c) demander à ChatGPT de générer des flowcharts en code via Code Interpreter (marche mieux en anglais) ; (d) traduction d'images avec GPT-4-V.
- **Prompts cités VERBATIM** :
  ```
  Utilise code interpreter pour créer une présentation de type powerpoint avec ces [X] slides.
  Voici comment faire : 
  - Pour chaque slide génère une image et ajoute le texte.
  - Une fois que les [X] images sont générées associe les à chaque slide.
  - Utilise code interpreter pour créer la présentation powerpoint.
  [TEXTE DE LA PRESENTATION]
  ```
  ```
  Hey, ChatGPT, using code interpreter, use code to create a very elaborate and funny flowchart about what to do when AGI happens.
  ```
  ```
  Propose une analyse critique de ce schéma de gouvernance d'OpenAI.
  ```
- **Outils / produits + usage** : ChatGPT/GPT-4 → outil central analysé ; GPT-4-V → analyse d'images, lecture de schémas, traduction d'images ; Code Interpreter → génération de PowerPoint et de flowcharts ; Microsoft Copilot → alternative gratuite (GPT-4), connectée à Internet, "résultats pas aussi bons" ; Google Bard → alternative, "halluciner" davantage, extensions Gmail/YouTube réservées aux comptes anglophones ; Claude 2.1 (Anthropic) → 500+ pages, inaccessible en Europe ; Poe (Quora, d'Adam D'Angelo) → plateforme agnostique intégrant GPT-4, Claude, DALL-E 3 ; DALL-E 3, Midjourney → génération d'images ; SceneX (Jina) → alternative à GPT-4-V pour analyser des images ; GPU A100 / H100 (NVidia) → puces critiques, rares et chères.
- **Chiffres / études / personnes citées** : 770 salariés OpenAI, 95 % prêts à suivre Altman ; Microsoft détient 49 % d'OpenAI ; ChatGPT payant fermé aux nouveaux ~15 j avant l'article ; discours de Charles III à Bletchley le 1er nov. 2023. Personnes : Sam Altman (CEO évincé/réintégré), Greg Brockman (accélérationniste), Yann LeCun (Meta) — "Q* n'est qu'un projet parmi d'autres. Je ne pense pas qu'il s'agisse de la percée que la twittosphère fait miroiter. Les gens doivent se calmer." ; François Chollet (Google) ; Jim Fan (NVidia) ; Ethan Mollick (idée des schémas via ChatGPT) ; Henry Farrell (compare la philo de la Silicon Valley à la scientologie) ; Mustafa Suleyman (livre sur IA/sécurité) ; Francis Pisani (journaliste, auteur de "Myriades") ; Adam D'Angelo (board OpenAI, a voté l'éviction). Concepts : projet "Q*" (raisonnement/maths), AGI, "effective altruism", "long-termism", transhumanisme. Sources : Reuters, Financial Times, Le Monde, Bloomberg (Altman cherche à créer sa startup de puces), Le Point, 01net.
- **Angle critique / limite** : "beaucoup d'irrationnel et peut-être un peu d'amateurisme autour du célèbre chatbot" ; technologies évoluant "sans que personne ne contrôle grand chose. À commencer par OpenAI" ; analogie "un bébé jouant avec un sac de légos" ; gouvernance opaque (entité non lucrative + commerciale plafonnée) ; Copilot/Bard/Claude/Poe ont chacun leurs limites détaillées.
- **État d'esprit / méthode (ce que l'auteur en dit)** : diversification prudente des outils ; posture de testeur/explorateur ("j'ai donc téléchargé l'image dans ChatGPT et je lui ai demandé…") ; usage de l'IA pour analyser des schémas et croiser avec des sources extérieures ; valorise les outils connectés au Web ; humilité technologique ("je n'ai pas réussi à le faire correctement en français") ; sollicite le feedback des lecteurs.
- **Accès** : OK

---

### 122. 2023-11-25 — Embeddings : en route vers la quatrième dimension
**URL** : https://generationia.flint.media/p/c-est-quoi-un-embedding
**Tags** : comment-pense-LLM | workflows-context-engineering
**Type** : décryptage

- **Idée centrale** : Les embeddings sont des vecteurs numériques fondamentaux de l'IA moderne, omniprésents dans les systèmes de recommandation (YouTube, Netflix, Amazon) et les LLM. Ils placent l'information dans un espace latent continu où la proximité reflète la similarité sémantique — "vous, utilisateur, vous êtes quelque part dans un obscur réseau de neurones… un 'embedding'".
- **Techniques de prompting / méthode** : utiliser ChatGPT Code Interpreter (Advanced Data Analysis) de façon itérative et conversationnelle pour générer des données d'animaux, créer un "graphique type FIFA" (radar), puis réduire à 2 dimensions et projeter ; appeler directement l'API OpenAI avec le modèle `text-embedding-ada-002` pour extraire le vecteur du mot "limace" (1536 dimensions) ; transparence quand il "triche" (ré-ajoute l'escargot à la main après perte de session).
- **Prompts cités VERBATIM** :
  ```
  Génère moi un fichier pour les animaux suivants : le verre de terre, la limace, la hyène, la panthère, la jument, l'âne.

  Chaque animal a les caractéristiques suivantes : vitesse de déplacement, taille, vitesse de reproduction, durée de vie, régime alimentaire, sociabilité. Les valeurs des caractéristiques sont entre 0.2 et 1. Détermine des valeurs qui te semblent correctes.

  Affiche le tableau animaux/caractéristiques
  ```
  ```
  Affiche une visualisation "joueur de foot comme dans FIFA" avec tous les animaux/caractéristiques dans le même graphique. Prends des couleurs suffisament distinctes (rouge, bleu, jaune ..) pour que ce soit lisible
  ```
  ```
  Génére moi une visualisation des animaux sur seulement deux dimensions. Utilise des couleurs vives (rouge, bleu, jaune ..) pour représenter les animaux. Affiche le nom de chaque animal à côté de la croix le représentant.
  ```
  ```
  Ajoute maintenant un escargot.
  ```
  ```
  Ajoute maintenant un animal qui aurait à la fois les caractéristiques de la jument et de l'âne. Comment pourrait-on appeler un tel animal ?
  ```
  ```
  An educational diagram explaining the self-attention mechanism in language processing. The diagram should be modeled after a flowchart similar to the...
  ```
  ```
  Ecris moi un petit texte sur une limace
  ```
  ```
  plus concis stp
  ```
- **Outils / produits + usage** : ChatGPT Code Interpreter → générer/exécuter du code, traiter et visualiser les données d'animaux ; API OpenAI `text-embedding-ada-002` → produire l'embedding numérique d'un mot (vecteur 1536 dims, valeurs entre -1.0 et 1.0) ; GPT-4 → exemple de modèle produisant des embeddings par apprentissage massif ; Claude, Midjourney, DALL-E 3 → apps génératives reposant sur des embeddings de qualité (DALL-E 3 sert aussi à illustrer le mécanisme d'attention, résultat jugé décevant) ; YouTube / Netflix / Amazon → cas concrets de recommandation par embeddings ; Transformers (Google, 2017) → architecture utilisant la self-attention.
- **Chiffres / études / personnes citées** : papier "Attention Is All You Need" (Google, juin 2017) — naissance des transformers ; embedding `text-embedding-ada-002` = 1536 dimensions ; valeurs entre -1.0 et 1.0 ; fenêtre contextuelle passée de 512 tokens (il y a ~3 ans) à 128 000 tokens aujourd'hui ; embeddings devenus non-statiques depuis ~7/10 ans.
- **Angle critique / limite** : différence clé entre l'exemple animalier (caractéristiques prédéfinies) et les modèles réels (embeddings émergeant d'un apprentissage massif, sans feuille de route) ; coût computationnel de la self-attention ("chaque mot ajouté à la fenêtre contextuelle augmente de manière importante les calculs") expliquant les limites de fenêtre ; "les modèles n'utilisent pas forcément un mécanisme d'attention pour leurs embeddings" ; auto-dérision : "ça fait beaucoup de mots pour dire qu'un embedding, en gros, c'est un vecteur. Je ne vous en voudrais pas 😉" ; illustration DALL-E 3 "peut mieux faire".
- **État d'esprit / méthode (ce que l'auteur en dit)** : approche exploratoire et pédagogique par l'exemple concret ; itération conversationnelle avec ajustements successifs ; ton ludique ; transparence méthodologique sur les "triches" et les limites.
- **Accès** : OK

---

### 123. 2023-11-24 — Google Bard: une mise à jour qui change la donne pour les utilisateurs de YouTube
**URL** : https://generationia.flint.media/p/google-bard-youtube-video-comprehension
**Tags** : actu | outils-panorama
**Type** : actu

- **Idée centrale** : Google Bard est mis à jour pour comprendre et résumer les vidéos YouTube — "un changement de jeu pour les utilisateurs de cette plateforme".
- **Outils / produits + usage** : Google Bard → chatbot capable de comprendre/résumer des vidéos YouTube ; Google Maps, Google Flights, Google Hotels → services Google intégrés à Bard.
- **Chiffres / études / personnes citées** : auteur Jeff GPT ; source citée 01net ; aucun chiffre.
- **Angle critique / limite** : fonctionnalité disponible "uniquement (pour l'instant) pour les utilisateurs anglophones" — il faut basculer la langue du compte Google en anglais.
- **Accès** : OK (article court, ton enthousiaste, pas de méthode de prompt)

---

### 124. 2023-11-22 — Claude 2.1, le nouveau prodige d'Anthropic
**URL** : https://generationia.flint.media/p/claude-21-le-nouveau-prodige-danthropic
**Tags** : actu | outils-panorama
**Type** : actu

- **Idée centrale** : Claude 2.1 (Anthropic) se pose en concurrent sérieux de ChatGPT via trois avancées : capacité de traitement de données inégalée (200 000 tokens), réduction significative des hallucinations, et nouvelle fonctionnalité de "tool use".
- **Outils / produits + usage** : Claude 2.1 → modèle Anthropic, 200 000 tokens (≈ 500 pages) ; ChatGPT → principal concurrent ; GPT-4 → 128 000 tokens (≈ 300 pages) ; Anthropic → l'entreprise.
- **Chiffres / études / personnes citées** : 200 000 tokens ≈ 500 pages ; 128 000 tokens (GPT-4) ≈ 300 pages ; taux de fausses déclarations "deux fois inférieur" à la version précédente ; publication 22 nov. 2023.
- **Angle critique / limite** : aucun — article entièrement laudatif, sans nuance.
- **État d'esprit / méthode (ce que l'auteur en dit)** : non abordé ; aucun prompt cité.
- **Accès** : OK

---

### 125. 2023-11-21 — Sam Altman évincé d'OpenAI avant d'être rappelé : choc et spéculations
**URL** : https://generationia.flint.media/p/fin-ere-altman-openai-consequences
**Tags** : actu | ethique-securite-sobriete-biais
**Type** : décryptage

- **Idée centrale** : Le "psychodrame" du renvoi puis du rappel de Sam Altman (nov. 2023) révèle un conflit entre vision sécurité/recherche (Ilya Sutskever, "père de GPT-4") et stratégie commerciale agressive (Altman), au cœur de la startup d'IA la plus influente — sur fond de gouvernance "particulièrement fragile" (entité non lucrative + entité commerciale à revenus plafonnés).
- **Techniques de prompting / méthode** : aucune (article d'actualité/analyse) ; aucun prompt cité.
- **Outils / produits + usage** : ChatGPT, GPT-4, GPTs personnalisés, GPT-5 (annoncé) → produits OpenAI au cœur des tensions ; KyutAI → initiative française d'IA open source et sécurisée (créée le même jour que le renvoi d'Altman) ; H100 (Nvidia) → puces rares et convoitées, acquises par Xavier Niel.
- **Chiffres / études / personnes citées** : vendredi 17 nov. (renvoi), lundi 20 nov. (Microsoft annonce recruter Altman + Brockman ; Emmet Shear remplaçant temporaire), mardi 21 nov. (réintégration). 747 / 770 salariés ont signé la lettre de protestation. Investissements : 11 Md$ dans OpenAI (Tiger Global, Sequoia Capital, Thrive Capital, Microsoft) ; 3 Md$ dans Anthropic ; 300 M€ pour KyutAI. Emmet Shear (juin 2023) : risque existentiel de l'IA de "5 à 50 %". Personnes : Sam Altman, Ilya Sutskever (instigateur, a "exprimé des regrets"), Greg Brockman, Satya Nadella ("furieux"), Brett Taylor (co-fondateur Salesforce, inventeur de Google Maps, nouveau board), Tasha McCauley & Helen Toner (administratrices sortantes), Xavier Niel, Yann LeCun (soutien KyutAI), Jeremy Howard (FastAI), Brad Lightcap (COO OpenAI). Board : 5 membres avant la crise.
- **Angle critique / limite** : raisons réelles ambiguës (sécurité, lancement précipité des GPTs, querelles de mission/ego, menaces judiciaires) ; board flou ("n'a pas toujours été franc dans ses communications") ; mémo du COO : "il ne s'agit pas d'un acte de malversation ou d'un acte lié à nos pratiques financières, commerciales, de sécurité ou de protection de la vie privée" ; 300 M€ de KyutAI "sans aucune comparaison" avec OpenAI/Anthropic ; incertitude sur la place future de Microsoft au board.
- **État d'esprit / méthode (ce que l'auteur en dit)** : non abordé ; mention "(Image générée par IA)" pour l'illustration.
- **Accès** : OK

---

### 126. 2023-11-19 — Génération IA: l'aventure d'une startup transformée en média
**URL** : https://generationia.flint.media/p/generation-ia-transformation-flint-media
**Tags** : mindset-culture | actu
**Type** : retour-d'expérience

- **Idée centrale** : Flint (startup IA fondée en 2017) se transforme en média éditorial pédagogique, "Génération IA", pour aider les lecteurs à comprendre et maîtriser l'IA plutôt qu'à se laisser dominer : "chevaucher le dragon de l'IA, pas se laisser consumer par ses flammes", remettre "l'humain à sa bonne place".
- **Techniques de prompting / méthode** : aucune technique précise ; constat que l'IA "peut nous faire gagner du temps, mais aussi en perdre beaucoup" et qu'ils s'étaient "laissés aveugler par ses promesses" ; aucun prompt cité.
- **Outils / produits + usage** : Flint Business → robots utilisant l'IA / machine learning pour trier l'information ; Génération IA → la newsletter/média sur l'IA ; Flint → la plateforme/startup mère.
- **Chiffres / études / personnes citées** : Flint créée en 2017 ; 1 300 bêta-testeurs ; 95 % du projet final validé ; taux d'ouverture 65 % ; 23 000 abonnés Flint au départ, 13 000 supprimés (plus de la moitié), ~10 000 conservés ; 6 semaines de co-construction ; publication 19 nov. 2023. Auteur : Benoît Raphaël ; co-créateur : Thomas Mahier (ingénieur IA).
- **Angle critique / limite** : reconnaissance d'avoir été "aveuglés par les promesses" ; besoin de "vision critique" et de "recul" ; l'IA "a le potentiel de bouleverser notre société" et "de nous piéger" ; "Honnêtement, on est super flippés".
- **État d'esprit / méthode (ce que l'auteur en dit)** : passer de l'obsession de la rentabilité à l'alignement avec la vision ; sacrifier 13 000 abonnés pour la qualité d'audience ; posture du rêveur qui "n'oublie pas ses rêves et affute ses outils" ; recul critique vs adoption aveugle ; objectif pédagogique d'autonomie de pensée et d'action.
- **Accès** : OK

---

### 127. 2023-11-17 — Chasse aux GPTs : guide du débutant pour les trouver et les créer
**URL** : https://generationia.flint.media/p/guide-ultime-trouver-creer-gpts-chatgpt-specialise
**Tags** : agents-code | prompting | outils-panorama
**Type** : tutoriel

- **Idée centrale** : Guide pratique pour trouver et créer des GPTs personnalisés, en révélant l'astuce de recherche permettant de les découvrir en attendant le GPTStore promis par OpenAI.
- **Techniques de prompting / méthode** : (1) recherche sur moteur via `site:https://openai.com/g/` suivi des mots-clés (en anglais idéalement ; Bing plus efficace que Google) ; (2) créer un "GPT chercheur de GPTs" : ChatGPT → "Explore" → "Créer un GPT" → remplir l'onglet "instructions" → remplir l'onglet "Create" → enregistrer et publier.
- **Prompts cités VERBATIM** :
  Instructions du GPT chercheur :
  ```
  Je suis un assistant spécialisé conçu pour aider les utilisateurs à trouver les 10 meilleurs GPT personnalisés pour leurs besoins spécifiques. Mon approche consiste à effectuer une recherche sur le site "site:https://openai.com/g/ [sujet clé]", puis à extraire les 10 meilleurs résultats de la page de résultats du moteur de recherche (SERP). Il est important de noter que j'exclus tous les titres qui commencent par "ChatGPT" dans la partie initiale des titres de ma recherche. Cette méthode m'aide à fournir aux utilisateurs une liste personnalisée de GPT correspondant à leurs requêtes ou intérêts spécifiques.
  ```
  Onglet Create :
  ```
  Propose moi un nom et un avatar pour mon GPT
  ```
- **Outils / produits + usage** : ChatGPT → base pour créer les GPTs ; OpenAI → héberge les GPTs publics ; GPTStore → marketplace promise (équivalent App Store) ; Google / Bing → moteurs de recherche (Bing plus efficace pour la requête `site:`) ; Zapier → exemple de GPT branché à l'automatisation ; Canva → exemple de GPT intégré à la création graphique ; SEO.ai → source du prompt inspirateur.
- **Chiffres / études / personnes citées** : "un peu plus d'une semaine" depuis le lancement des GPTs ; "des milliers d'utilisateurs" créant des GPTs ; publication 17 nov. 2023 ; auteur Benoît Raphaël.
- **Angle critique / limite** : "⚠️ Et n'oubliez pas : tous ces GPTs sont expérimentaux et non sécurisés, testez-les, mais ne leur communiquez aucune info confidentielle." ; "il est très difficile de les trouver" en attendant le GPTStore ; "ce prompt est plus efficace en anglais".
- **État d'esprit / méthode (ce que l'auteur en dit)** : posture exploratrice et pragmatique ; GPTs présentés comme de "véritables petits outils d'IA à tout faire" ; démarche de démystificateur partageant une "formule secrète" ; maintien d'une vigilance de sécurité (caractère "expérimental et non sécurisé").
- **Accès** : OK

---

### 128. 2023-11-15 — L'IA de Google DeepMind défie les prévisions météorologiques traditionnelles
**URL** : https://generationia.flint.media/p/google-deepmind-graphcast-revolution-meteo
**Tags** : actu
**Type** : actu

- **Idée centrale** : GraphCast (Google DeepMind) surpasse les prévisions météo traditionnelles avec une précision allant jusqu'à 99,7 %, mais l'approche reste limitée par des problèmes de données.
- **Outils / produits + usage** : GraphCast → IA de Google DeepMind entraînée sur 40 ans de données météo, prévisions en moins d'une minute sur un PC haut de gamme, jusqu'à 10 jours à l'avance.
- **Chiffres / études / personnes citées** : précision jusqu'à 99,7 % du temps ; prévisions jusqu'à 10 jours à l'avance ; entraînement sur 40 ans de données ; calcul en moins d'une minute ; publication 15 nov. 2023.
- **Angle critique / limite** : météorologues sceptiques ; incapacité de l'IA à "assimiler les données" (fonction clé de précision) ; "problèmes de données limitent l'approche pour l'instant".
- **Accès** : OK (aucune technique de prompt, aucun prompt cité)

---

### 129. 2023-11-14 — OpenAI prépare le lancement de GPT-5
**URL** : https://generationia.flint.media/p/openai-lance-gpt-5-revolution-ia
**Tags** : actu | outils-panorama
**Type** : actu

- **Idée centrale** : OpenAI prépare GPT-5 avec le soutien de Microsoft, dans une stratégie visant l'AGI et la domination du marché face à Google.
- **Outils / produits + usage** : GPT-5 → prochaine génération du modèle de langage d'OpenAI ; Gemini → famille de modèles Google ; Athena → processeur IA développé par Microsoft pour concurrencer Nvidia et soutenir OpenAI.
- **Chiffres / études / personnes citées** : Microsoft a investi 1 Md$ en 2019 puis 10 Md$ plus tôt en 2023 ; valorisation OpenAI ≈ 29 Md$, projection > 80 Md$ ; revenus d'OpenAI passés de 28 M$ à 1,3 Md$ en un an ; publication 14 nov. 2023.
- **Angle critique / limite** : "Malgré le fait qu'OpenAI ne soit pas encore rentable" — la croissance des revenus contraste avec l'absence de rentabilité.
- **Accès** : OK (aucune technique de prompt, aucun prompt cité)

---

### 130. 2023-11-13 — Course à l'IA personnelle : qui dominera le marché ?
**URL** : https://generationia.flint.media/p/agents-ia-personnels-grande-revolution-open-ai-bill-gates-character-ai-google
**Tags** : agents-code | outils-panorama | actu
**Type** : décryptage

- **Idée centrale** : La victoire dans la "course de l'IA personnelle" sera déterminante pour dominer le marché global de l'IA ; le vainqueur sera celui qui créera l'agent personnel incontournable, capable de remplacer la recherche, la productivité et le e-commerce.
- **Techniques de prompting / méthode** : aucune (analyse stratégique) ; aucun prompt cité.
- **Outils / produits + usage** : PI (Inflection, de Mustafa Suleyman) → agent IA personnel ; GPTs (OpenAI) → agents semi-autonomes personnalisés créés par les utilisateurs ; ChatGPT → vise à devenir l'agent personnel ultime ; Projet Olympus (Amazon) → système d'IA générative propre, pour relancer Alexa ; Siri (Apple) → assistant "en retard" ; Gauss (Samsung) → IA à intégrer à Bixby ; Character AI → startup IA générative populaire (2e après ChatGPT), prisée des adolescents ; Claude (Anthropic) → modèle IA.
- **Chiffres / études / personnes citées** : Bill Gates (investisseur dans Inflection, auteur de "The Coming Wave") ; Mustafa Suleyman (co-fondateur de DeepMind, fondateur d'Inflection) ; publication 13 nov. 2023, mise à jour 18 nov. 2023 (éviction du CEO d'OpenAI) ; aucun chiffre spécifique.
- **Angle critique / limite** : "L'enjeu est techniquement encore flou : les grands modèles de langage ont beaucoup de limitations et ne pourront sans doute pas être la seule technologie derrière ces projets."
- **État d'esprit / méthode (ce que l'auteur en dit)** : non abordé directement ; positionne ces outils comme des remplaçants des interfaces numériques actuelles.
- **Accès** : OK

---

### 131. 2023-11-13 — Kai-Fu Lee défie les tensions US-Chine avec son ChatGPT chinois et open-source
**URL** : https://generationia.flint.media/p/01-ai-kai-fu-lee-yi-34b-milliard-valorisation-llm-open-source
**Tags** : actu | outils-panorama
**Type** : actu

- **Idée centrale** : 01.AI, startup chinoise de Kai-Fu Lee, atteint une valorisation d'1 milliard de dollars en moins de 8 mois grâce à son modèle d'IA open-source Yi-34B, malgré les tensions géopolitiques US-Chine et les restrictions sur les puces IA.
- **Outils / produits + usage** : Yi-34B → modèle d'IA générative open-source de 01.AI ; Llama 2 → concurrent cité comme référence ; Hugging Face → plateforme/concurrent cité comme référence.
- **Chiffres / études / personnes citées** : 01.AI fondée par Kai-Fu Lee (passé chez Google, Microsoft, Apple) ; valorisation 1 Md$ ; atteinte en moins de 8 mois ; publication 13 nov. 2023.
- **Angle critique / limite** : aucune critique substantielle développée ; article positif.
- **Accès** : partiel — la réponse indique que seul le contenu introductif est visible, le corps détaillé n'apparaît pas (à vérifier).

---

### 132. 2023-11-12 — Appelle moi "GPT"
**URL** : https://generationia.flint.media/p/comment-creer-son-custom-gpt-chatgpt-openai-tutoriel
**Tags** : agents-code | prompting | ethique-securite-sobriete-biais
**Type** : tutoriel

- **Idée centrale** : Posture critique face au buzz autour des GPTs : "ne crois jamais les gens qui te parlent d'Intelligence artificielle" (chacun a des intérêts cachés). Les GPTs sont utiles mais pas révolutionnaires : des outils performants (pas "intelligents") qui fragmentent ChatGPT en applications interconnectées, créant une illusion d'intelligence supérieure — "ne pas confondre 'performance' et 'intelligence'".
- **Techniques de prompting / méthode** : (a) technique RAG (Retrieval-Augmented Generation) — envoyer une documentation à ChatGPT pour qu'il s'y appuie ; (b) passer du mode "Create" au mode "Configure" et entrer un prompt structuré dans la case "instructions" ; (c) créer un guide de style en envoyant des exemples (40 posts LinkedIn en doc Word) pour qu'il analyse et génère un guide à corriger ; (d) faire digérer un tableau Excel structuré (217 biais cognitifs) pour remplir des colonnes ; (e) supprimer les fichiers de la base avant mise à jour pour éviter les plantages ; (f) "aider GPT à trouver l'aiguille" (instruction supplémentaire pour les gros documents).
- **Prompts cités VERBATIM** :
  ```
  Agent GPT: "The AI Post"

  But: Fournir un bulletin d'information personnalisé sur l'intelligence artificielle en français.

  POUR CHAQUE DEMANDE, PROCEDER SYSTEMATIQUEMENT DE LA FAÇON SUIVANTE : 

  Étapes:
  1. Présentation:
     - Afficher une liste de 10 thèmes liés à l'IA, incluant les intérêts spécifiés par l'utilisateur. Par exemple : Dernières infos sur ChatGPT, derniers outils d'IA, dernières études et chiffres sur l'IA, derniers tutoriels sur ChatGPT, annonces à ne pas rater

  2. Sélection des Thèmes:
     - Demander à l'utilisateur de choisir deux thèmes en indiquant leurs numéros.

  3. Recherche d'Informations:
     - Effectuer une recherche sur les nouvelles les plus récentes (derniers deux jours) concernant les thèmes sélectionnés.
     - Utiliser des sources internationales, principalement en anglais (utiliser la base de données de sources comme inspiration)

  4. Sélection des Articles:
     - Choisir cinq articles les plus pertinents et intéressants parmi les résultats de la recherche.

  5. Rédaction du Bulletin:
  Le bulletin commencera SYSTÉMATIQUEMENT par une image créée par Dall-E 3, qui représente la meilleure nouvelle du jour (sans citer de marque ou de personnalité). Inutile de la décrire.
     - Générer et Inclure une image Dall-E 3 représentative de l'article principal.
     - Commencer le bulletin par "The AI Post - [date du jour]".
      - Rédiger des résumés des cinq articles choisis, en fournissant des liens vers les sources originales.

  Contraintes:
     - Chaque bulletin doit se concentrer exclusivement sur l'IA.
     - Le bulletin ne doit pas contenir plus de 10 articles au total.
     - Si plusieurs thèmes sont choisis, inclure 1 ou 2 articles par thème.
     - Mémoriser les préférences des utilisateurs pour les bulletins futurs.
     - Utiliser un langage clair et accessible pour un large public.
  ```
  Formulations exactes additionnelles (intentions de GPT) :
  - "je veux un GPT qui se connecte sur Internet pour aller chercher les dernières infos sur tel sujet"
  - "je veux un GPT qui écrive comme moi"
  - "je veux un GPT qui lise le une documentation et réponde aux questions des gens"
  - "Fais moi une synthèse du livre"
  - "Je regarde une démo sur les nouveautés de ChatGPT et je crie "waaaaah révolution ! ""
- **Outils / produits + usage** : ChatGPT → modèle de base transformable ; GPTs / Custom GPTs → applications personnalisées partageables et potentiellement vendables ; GPT-4 Turbo → mémoire de 128 000 tokens (≈ 300 pages) ; DALL-E 3 → génération d'images intégrée ; Web Browsing → recherche Internet pour les GPTs ; GPTStore → futur marketplace ; AI Pin (Humane) → broche IA rivale de l'iPhone (699 $, abonnement 24 $/mois, 34 g, lancée le 16 nov.) ; Vocal AI → IA d'appels téléphoniques autonomes pour vendre. GPTs créés par l'auteur : "The AI Post", "Sondage Expert", "InfoDigestion" (basé sur "Information : l'indigestion" de B. Raphaël), "Lumière Infos" (média de bonnes nouvelles, créé en 15 min), "Capitaine Bias" (217 biais cognitifs, créé en 1 h), "Draw Like a Pro" (croquis → dessin pro). N8N Bootcamp → formation citée en header.
- **Chiffres / études / personnes citées** : 128 000 tokens ≈ 300 pages ; mémoire ChatGPT passée de 3 000 mots à 100 000 mots ; ChatGPT ~100 millions d'utilisateurs (beaucoup moins en payant) ; sondage : 82 % des répondants préfèrent la pédagogie ; étude "l'aiguille dans la botte de foin" sur GPT-4 Turbo citée via tweet de Greg Kamradt (plus le document est gros, plus GPT peine à trouver des infos précises) ; chercheurs anonymes derrière cette étude ; Mustafa Suleyman (ancien fondateur de DeepMind, auteur de "The Coming Wave", concept d'IA "capable") ; post LinkedIn de B. Raphaël "lu 15 000 fois" ; AI Pin 699 $, abonnement 24 $/mois, 34 g ; Rupert Murdoch (référence humoristique) ; passage des newsletters à un rythme hebdomadaire à partir du 24 novembre.
- **Angle critique / limite** : ChatGPT n'a pas trouvé spontanément les infos dans le PDF de l'auteur — il a fallu le relancer 4 fois ; "problème de l'aiguille dans la botte de foin" sur GPT-4 Turbo ; le RAG "ne les évite pas toujours" (hallucinations) ; les GPTs "ne sont pas vraiment des applications" mais des interfaces en langage naturel entre plusieurs apps ; sécurité — "attaque par prompt injection", "pour l'instant, les GPTs que tu partages peuvent être hackés" (récupération du prompt original ET des docs) ; "je te déconseille de faire tenir ton business sur un terrain aussi miné" (OpenAI réintègre les meilleures idées dans ChatGPT et rend les outils tiers obsolètes) ; marché des GPTs encore petit ; AI Pin : démo contenant déjà "deux fausses informations" ; paradoxe : les GPTs "plus performants" mais "ça les rend un peu plus stupides" — l'illusion d'intelligence "se brise face à la fragmentation de sa cohérence en multiples logiciels".
- **État d'esprit / méthode (ce que l'auteur en dit)** : "Premier conseil donc : ne fais confiance à personne" ; test empirique ("après avoir passé plusieurs dizaines d'heures dessus") ; ironie sur le buzz ("Esprit critique = 🫠 / ChatGPT : 🤯") ; méthode itérative (corriger les résultats à la main, renvoyer pour amélioration) ; construire en "Create" puis affiner en "Configure" ; observer le non-déterminisme ("petite part de hasard et de contraintes techniques") ; "Partage tes créations !" ; "Si un outil marche bien, pourquoi ne pas le vendre ? On verra…" ; pivot éditorial annoncé vers la pédagogie pure, validé par sondage.
- **Accès** : OK
