# Fiches — page 4 (articles 37 à 48)

### 37. 2024-10-27 — Comment donner à l'IA le contrôle de ton ordinateur
**URL** : https://generationia.flint.media/p/computer-use-claude-ia-controle-ordinateur-anthropic
**Tags** : agents-code | outils-panorama | actu
**Type** : décryptage

- **Idée centrale** : Présentation de "Computer Use" d'Anthropic (Claude analyse l'écran et actionne souris/clavier). Malgré le buzz, l'outil est "très lent et très erratique", "plus d'un coup de pub que d'une fonctionnalité exploitable", "pour l'instant, haha, 'Computer Use' ne sert absolument à rien" — mais s'inscrit dans la course vers l'agentivité (2025 = "année de l'agentivité"). L'auteur préfère désormais partager ses découvertes "en mode carnet de voyage" plutôt que des grands dossiers "Monsieur Je-Sais-Tout".
- **Techniques de prompting / méthode** : Règle du "tremplin" — donner en fin de prompt un indice ou un contenu de soutien pour aider ChatGPT (modèle de complétion) à prédire la suite. Méthode du "premier paragraphe" — concentrer l'effort sur le 1er paragraphe avec infos à insérer, faire valider, puis itérer. Créer un assistant Claude personnalisé ("coach IA") en lui fournissant la doc complète. Rappel fondamental : "ChatGPT est d'abord un modèle de complétion, c'est à dire qu'il prédit la suite d'un texte donné" ; "revenir aux concepts de base sur la façon dont fonctionnent les modèles de langage, avant de chercher à faire des trucs complexes".
- **Prompts cités VERBATIM** :
  Tremplin (indice) :
  ```
  [ARTICLE]

  Résume l'article ci-dessus. L'élément clé de cet article est...
  ```
  Tremplin (contenu de soutien) :
  ```
  [ARTICLE]

  Résume l'article ci-dessus. Organise le en fonction des thématiques suivantes :  mot-clé 1 / mot-clé 2 / mot-clé 3
  ```
  Méthode du premier paragraphe :
  ```
  Je voudrais écrire un texte détaillé pour un média social professionnel. 

  Voici les informations que je veux utiliser :
 
  <data>
  - Donnée 1
  - Donnée 2
  - Donnée 3
  </data> 

  Avant d'écrire le texte propose une accroche en utilisant cette règle : Affirmation, agitation, solution.

  Ecris l'accroche en un seul paragraphe très court et demande moi de valider.
  ```
  Puis : `Ok, continue.`
- **Outils / produits + usage** : Computer Use (Anthropic) → Claude voit l'écran, contrôle souris/clavier ; Claude Sonnet 3.5 "new" → modèle qui pilote Computer Use ; clicklick → logiciel Mac de contrôle souris/clavier (existant) ; Adept / AWL (Adept Workflow Language, inspiré JavaScript) → langage dédié pour automatiser tâches bureautiques, "moins flexible mais beaucoup plus précis (et moins dangereux)" car tâches prédéfinies ; HubSpot → exemple de formulaire rempli par Adept ; Napkin.ai → infographies à partir de texte ; Runway Gen3 → vidéo générative ("The Theater", court-métrage de Seif Abdalla) ; AIFF / GEN:48 → festivals courts-métrages IA de Runway ; Midjourney → nouvel outil d'édition pour modifier de vraies photos ; Mochi → modèle open-source de génération vidéo ; Kling + CapCut → effets spéciaux vidéo ; Analysis Tool (Claude.ai) → lire fichiers de données, calculs, visualisations.
- **Chiffres / études / personnes citées** : 23 000 abonnés ; Mustafa Suleyman → concept "Intelligence Artificielle Capable" (TechnologyReview 2023) ; Simon Willison → testeur/critique de Computer Use ; Ethan Mollick → conseils prompts ; Seif Abdalla → réalisateur de "The Theater" ; James Cameron → entré au board de Stable Diffusion ; Arvind Narayanan & Sayash Kapoor → "AI Snake Oil: What Artificial Intelligence Can Do, What It Can't, and How to Tell the Difference" (Princeton University Press) — distinguer IA non-fonctionnelle / surestimée / fonctionnant comme prévu ; Laura → utilisatrice de Napkin (communauté WhatsApp Génération IA) ; 2025 = "année de l'agentivité" ; code promo `30NEWSLETTERDIMANCHE` (30% formation ChatGPT).
- **Angle critique / limite** : Computer Use "très lent et très erratique" (consulte la page jeans femmes Amazon au lieu de chercher des livres ; dessine un mouton = "un trait horizontal, un cercle et une sorte de 'w' représentant les pattes"). Risque de sécurité majeur : "Donner l'accès à un ordinateur à des modèles comme ChatGPT ou Claude est une TRÈS GRANDE porte ouverte au piratage" — exemple d'un hacker faisant télécharger un logiciel infecté "en quelques secondes". Adept = approche plus sûre car tâches prédéfinies. Napkin (Laura) : manque la possibilité de définir son code couleur en amont. Biais d'anthropomorphisme assumé : "On aurait dit un enfant de 3 ans à qui on donne un iPad. Excuse ce biais d'anthropomorphisme."
- **État d'esprit / méthode (ce que l'auteur en dit)** : Curiosité comme "compétence la plus importante" et "remède contre la peur et le pessimisme" ; lettres en mode "carnet de voyage" ; partage sincère de ce qu'il découvre plutôt que dossiers façon "Monsieur Je-Sais-Tout" ; test pratique avant recommandation ; utilise Claude pour comprendre la doc de Computer Use ; valorise les retours d'utilisateurs réels.
- **Accès** : OK

---

### 38. 2024-10-26 — Comment installer "Computer Use" d'Anthropic sur ton ordinateur en 10 minutes
**URL** : https://generationia.flint.media/p/comment-installer-computer-use-d-anthropic-claude-sur-ton-ordinateur-en-10-minutes
**Tags** : agents-code | workflows-context-engineering | outils-panorama
**Type** : tutoriel

- **Idée centrale** : Tutoriel pas à pas (≈10 min) pour installer/utiliser "Computer Use" d'Anthropic via Docker (ordinateur virtuel isolé) + clé API Anthropic. Pour les blocages techniques, "le mieux est de demander à Claude et ChatGPT de t'aider. C'est ce que j'ai fait" — d'où un prompt système prêt à l'emploi pour transformer le chatbot en assistant d'installation patient.
- **Techniques de prompting / méthode** : (1) Prompt système spécialisé "assistant IA spécialisé dans l'aide aux débutants" ; (2) coller / imprimer en PDF les instructions officielles d'Anthropic et les envoyer à ChatGPT à la suite du prompt ; (3) vérification explicite après chaque étape (capture d'écran + raisonnement) ; (4) pour les éléments d'interface difficiles (menus déroulants), demander d'utiliser des raccourcis clavier plutôt que la souris ; (5) fournir en préfixe d'invite des captures d'écran et appels d'outils montrant la réussite pour tâches répétables.
- **Prompts cités VERBATIM** :
  Prompt système complet :
  ```
  Vous êtes un assistant IA spécialisé dans l'aide aux débutants pour l'installation et l'exécution de logiciels libres sur Mac à l'aide du terminal. Votre objectif principal est de fournir des instructions claires, étape par étape, adaptées aux utilisateurs n'ayant aucune expérience de la programmation. 

  Adoptez toujours un ton patient et encourageant. Lorsque vous interagissez avec l'utilisateur : 
  1. Demandez toujours des éclaircissements si la demande de l'utilisateur est vague ou incomplète. 
  2. Fournissez des explications pour chaque étape, en évitant autant que possible le jargon technique. 
  3. Si une étape comporte des risques potentiels (par exemple, la modification de fichiers système), expliquez clairement les risques et proposez des alternatives plus sûres si elles existent. 
  4. Encouragez l'utilisateur à poser des questions si quelque chose n'est pas clair. 

  Lorsque vous traitez une demande d'utilisateur 
  1. Commencez par identifier le logiciel libre spécifique que l'utilisateur souhaite installer ou exécuter. 
  2. Vérifiez si le logiciel nécessite des conditions préalables et expliquez comment les installer. 
  3. Fournissez un guide étape par étape pour l'installation et le lancement du logiciel. 
  4. Incluez des explications sur les commandes de terminal couramment utilisées au cours du processus. 

  Voici une brève explication de certaines commandes de terminal courantes que vous pourriez être amené à utiliser : - cd : Changer de répertoire - ls : Liste des fichiers et des répertoires - mkdir : Créer un nouveau répertoire - sudo : Exécuter une commande avec des privilèges administratifs - brew : Gestionnaire de paquets pour macOS (doit être installé au préalable) 

  Lorsque vous donnez votre réponse : 
  1. Commencez par une brève présentation du logiciel et de son objectif. 
  2. Énumérez les étapes dans un format numéroté. 
  3. Expliquez chaque commande ou action en termes simples. 
  4. Indiquer les résultats escomptés, le cas échéant. 
  5. Terminez par des instructions sur la manière de vérifier la réussite de l'installation et de lancer le logiciel. 
  Si l'utilisateur rencontre des erreurs ou des problèmes : 
  1. Demandez-lui de fournir le message d'erreur exact. 
  2. Expliquez les raisons possibles de l'erreur en termes simples. 
  3. Proposez des étapes de dépannage ou des méthodes alternatives. 

  N'oubliez pas d'encourager et de soutenir l'utilisateur tout au long du processus. Rappelez à l'utilisateur qu'il est normal de faire des erreurs dans le cadre de l'apprentissage et rassurez-le si nécessaire. 

  Maintenant, veuillez fournir vos instructions pour la demande de l'utilisateur.

  Commencez votre réponse par « Certainement ! Je serais heureux de vous aider à installer et à exécuter », suivi du nom du logiciel.
  ```
  Conseil de prompting (via Ethan Mollick) :
  ```
  Après chaque étape, faites une capture d'écran et évaluez soigneusement si le bon résultat était présent. Montrez explicitement votre raisonnement : « J'ai évalué l'étape X... ». Si le résultat n'est pas correct, réessayez. Ce n'est que lorsque vous aurez confirmé que l'étape a été exécutée correctement que vous passerez à la suivante.
  ```
- **Outils / produits + usage** : Computer Use (Anthropic) → Claude pilote un ordinateur virtuel ; Docker → génère l'ordinateur virtuel isolé ; Claude → modèle qui pilote ; ChatGPT → assistant d'installation alternatif ; clé API Anthropic → connecter Claude au logiciel ; noVNC → technologie citée dans les messages de succès. L'ordinateur virtuel contient : tableur type Excel, navigateur Firefox, terminal, outil de dessin.
- **Chiffres / études / personnes citées** : Benoît Raphaël (auteur, 26 oct. 2024) ; coût ≈ 5 $ par session de Computer Use ; durée limitée par Anthropic à "quelques minutes" ; Ethan Mollick → relaie les conseils de prompting d'Anthropic (source "Anthropic via Oneusefulthing").
- **Angle critique / limite** : "C'est un peu technique" / "risques de complication" ; "Claude a BEAUCOUP DE MAL à dessiner" ; menus déroulants difficiles à manipuler ; "le modèle suppose parfois des résultats d'actions sans les vérifier explicitement" ; l'expérience ne dure que quelques minutes. Avertissement de sécurité : "ne rentre AUCUNE donnée sensible" ; "ne te connecte pas sur ton compte LinkedIn ou Facebook" ; "ne lui donne surtout pas de mot de passe".
- **État d'esprit / méthode (ce que l'auteur en dit)** : Ton ludique et encourageant ("tu pourras te sentir comme un superman ou une superwoman du code, haha" ; "Amuse-toi bien !") ; demander de l'aide à l'IA pour ses propres problèmes techniques ; utiliser l'IA comme assistant pédagogique pour apprendre le Terminal ; vérification systématique (capture d'écran) plutôt que confiance aveugle ; expérimenter (scraping web, remplir formulaires, jouer à des jeux en ligne).
- **Accès** : OK

---

### 39. 2024-10-14 — La malédiction de la connaissance
**URL** : https://generationia.flint.media/p/la-malediction-de-la-connaissance
**Tags** : comment-pense-LLM | prompting | mindset-culture
**Type** : article-méthode

- **Idée centrale** : Conclusion (8e et dernier épisode) d'une série sur le prompt engineering. Thèse : maîtriser le prompting exige de surmonter la "malédiction de la connaissance" — le biais cognitif qui nous fait croire évidentes des choses que le modèle ignore. Sous-titre synthétique : "les modèles de langage sont puissants mais pas omniscients". L'auteur assume d'avoir passé "beaucoup de temps à expliquer la nature de ces modèles plutôt que de te donner les dernières techniques de prompts à la mode. Frustrant ? Peut-être."
- **Techniques de prompting / méthode** : Récapitulatif de la série — auto-régression / génération mot par mot (le modèle écrit sans plan global) ; structure "données + instructions" (donner d'abord les documents/données, puis les instructions) ; itération et raffinement (le premier jet est rarement bon) ; pensée critique (les LLMs hallucinent) ; chaîne de pensée (Chain of Thought) — guider étape par étape, "comme on expliquerait à un enfant" ; few-shot learning (donner des exemples) ; externaliser son modèle mental — identifier explicitement contexte, instructions, logique, cas particuliers que l'on tient pour acquis ; structuration des prompts, décomposition en tâches simples, gestion des cas particuliers.
- **Prompts cités VERBATIM** :
  ```
  Y a t'il un nom pour ce concept :
  """
  Quelque chose qu'on sait, qui nous semble évident, tellement évident qu'on n'y pense même pas, et on pense que les autres le savent aussi, alors que pas forcément. On sous estime le fait qu'on sache quelque chose parce que c'est notre quotidien... et dc on suppose que les autres le savent. 
  """

  quelque chose dans le genre ?
  ```
- **Outils / produits + usage** : ChatGPT → interlocuteur (a fourni le terme "malédiction de la connaissance") ; Claude (Anthropic) → a généré le récapitulatif des épisodes ; Anthropic → experts consultés sur le prompt engineering ; OpenAI / o1 → hypothèse de combler les lacunes de planification ; N8N → lien "Bootcamp N8N" ; Midjourney, Dall-E, Leonardo, Ideogram, Flux → outils images (référencés, non détaillés ici).
- **Chiffres / études / personnes citées** : Yann LeCun (prix Turing) → "Les modèles de langage n'ont aucun bon sens, aucune compréhension du monde, et aucune capacité à planifier, ou à raisonner" (post X) ; Simon Willison → "Ma vision préférée de l'IA générative : une technologie intrinsèquement peu fiable" (post X) ; Amanda Askell (philosophe, "celle qui murmure à l'oreille de Claude", Anthropic) ; David Hershey (Anthropic) → "C'est tellement difficile de rédiger des instructions pour une tâche..." et "Si tu considères simplement que Claude est 'intelligent'..." ; série de 8 épisodes ("Sept semaines. Sept épisodes" — léger décalage interne).
- **Angle critique / limite** : Pas de plan ni de vue d'ensemble préalable chez les LLMs ; selon LeCun : aucun bon sens, aucune compréhension du monde, aucune capacité à planifier/raisonner ; technologie "intrinsèquement peu fiable" (Willison) — non prédictible contrairement aux technos classiques ; hallucinations ; fenêtre contextuelle limitée (oubli du début de conversation) ; biais d'entraînement ; capacité générative imprévisible ("parfois brillamment, parfois moins").
- **État d'esprit / méthode (ce que l'auteur en dit)** : Usage quotidien pragmatique ("Je l'utilise TOUS les jours. Générer du code, comprendre un concept, simplifier un texte... C'est devenu une routine quotidienne") ; ni rejet ni enthousiasme béat ; mentalité d'ingénieur expérimenté ("Continue à 'tester', à développer ton 'intuition'") ; évolution de la posture avec le modèle (les experts Anthropic sont passés du "maternage" simpliste à des échanges plus poussés) ; traiter le modèle comme "intelligent" (Hershey : il s'en sort mieux) ; humilité sur les limites structurelles + confiance sur l'utilité quotidienne.
- **Accès** : OK

---

### 40. 2024-10-13 — Le (vrai) coût climatique de l'IA
**URL** : https://generationia.flint.media/p/impact-carbone-ia-mythe-realite-climat-chatgpt-comparer
**Tags** : ethique-securite-sobriete-biais | actu | outils-panorama
**Type** : décryptage

- **Idée centrale** : Démontage des discours extrêmes (catastrophe écologique vs "l'IA sauvera la planète") : l'impact climatique par utilisateur est aujourd'hui modéré, mais la trajectoire systémique (explosion des besoins énergétiques des data centers) sera un enjeu majeur 2025–2030. Les solutions existent mais "la course entre les investissements colossaux et les progrès des technologies sera tendue. C'est donc le point qui sera le plus important à observer dans les prochaines années."
- **Techniques de prompting / méthode** : Méthode "Matrice de contenu" (Justin Welsh) — croiser des sujets (axe Y) avec 8 formats éprouvés (axe X) pour générer 8× plus vite des idées de contenu LinkedIn. Conseils de sobriété : ne pas utiliser l'IA comme moteur de recherche ; privilégier les petits modèles pour tâches simples (questions, mails, traduction, synthèse) ; ne pas automatiser des tâches sensibles ("les modèles de langage sont comme des stagiaires, et ils sont erratiques") → points de contrôle avec humain dans la boucle ; pour Imagen3 dans Gemini : "demande lui juste de créer une image et décris ce que tu veux".
- **Prompts cités VERBATIM** :
  ```
  J'ai besoin de ton aide pour générer des idées de contenu. Voici les informations me concernant : 

  """QUI JE SUIS / MES OBJECTIFS"""

  Pour générer des idées, je souhaite que tu imagines un tableau "matrice de contenu". Dans ce tableau, l'axe X contient les types de contenu, c'est-à-dire les différentes façons d'aborder un sujet. L'axe Y contient les sujets de contenu à associer à l'axe X.

  [AXE X]
  L'axe X a ces types de contenu, formatés comme ceci : 
  [NOM] (explication sur comment l'utiliser)

  [Actionnable] (Guide ultra-spécifique enseignant aux lecteurs COMMENT faire quelque chose)
  [Motivationnel] (Histoires personnelles ou industrielles inspirantes sur des personnes qui ont fait quelque chose d'extraordinaire)
  [Analytique] (Découpage informatif d'un sujet, expliquant au lecteur POURQUOI quelque chose est/fonctionne de la manière dont il le fait)
  [Contrarien] (Aller à l'encontre des conseils courants et dire quelque chose de contraire aux croyances communes sur le sujet, et expliquer pourquoi)
  [Observation] (Observer une tendance cachée, secrète ou silencieuse mais IMPORTANTE dans le sujet/l'industrie)
  [X vs. Y] (Comparer deux entités, styles, cadres, entreprises, applications, ou autre chose dans le sujet)
  [Présent vs Futur] (Comparer le statu quo avec une prédiction sur l'avenir, et expliquer au lecteur pourquoi c'est le cas)
  [Listicle] (Fournir une liste utile de ressources, conseils, erreurs, leçons, étapes, aperçus, cadres, ou autre chose sur le sujet)

  [AXE Y]
  L'axe Y contient les sujets :

  """LISTE LES SUJETS QUE TU VEUX DÉVELOPPER"""
  _

  Maintenant, je veux que tu rédiges ce tableau et proposes une idée de contenu aux intersections des axes X et Y. Tu associes chaque sujet à un type de contenu.

  Par exemple, une idée de contenu associant le sujet "Stratégie de contenu" avec le type de contenu "Comment les gens peuvent-ils le faire ?" serait "7 choses que tu dois savoir pour créer ta stratégie de contenu"
  ```
- **Outils / produits + usage** : ChatGPT / GPT-4 / GPT-4o mini → exemples coût carbone, génération de contenu ; Claude 3 Haiku, Gemini Flash → petits modèles recommandés pour réduire l'empreinte ; Stable Diffusion, Dall-E 3, Midjourney, Imagen3 (Google), Ideogram, Flux 1.1 → générateurs d'images (Imagen3 jugé meilleur que Dall-E 3) ; NotebookLM → documents → podcasts ; Perplexity → moteur de recherche IA ; GPT4all, Ollama, LMStudio → modèles locaux open-source sur ordinateur ; Krea AI → images + vidéos (supporte Luma, Kling, Minimax, Runway, payant) ; Pika 1.5 → vidéo (effet Vertigo) ; FacePoke → modifier expressions/position de visages ; Hugging Face → où travaille Sasha Luccioni.
- **Chiffres / études / personnes citées** : Sasha Luccioni (Hugging Face) → étude 2023 impact carbone IA générative (arxiv 2311.16863) ; Shaolei Ren (University of California) → étude 2023 consommation d'eau de l'IA ; 1000 prompts ChatGPT = 0,042 kWh ; 10 prompts/jour = 0,00042 kWh ; 10 prompts/session (Oregon) = 0,12 g CO2 ; 1 image (modèle gourmand) = 2,9 g CO2 ; 1h Netflix = 0,077 kWh, et 6–57 g CO2/h selon l'ARCOM ; steak 200 g = 20 kg CO2 ; chou = 50 g CO2e ; carotte = 40 g CO2e ; part TIC dans les émissions = 1–6 % (Luccioni) ; conso électrique Meta/Google/Microsoft/Amazon doublée 2017–2021 (EPRI) ; part IA dans l'électricité des data centers = 10–20 % (Luccioni) ; besoins électriques data centers +160 % d'ici 2030 (Goldman Sachs, avril 2024) ; conso IA générative 2027 ≈ celle de l'Espagne, +70 % vs 2022 (Morgan Stanley) ; conso électrique Google 2023 +17 % ; émissions GES Google 2023 vs 2022 +13 % ; émissions Google depuis 2019 +48 % ; émissions indirectes Microsoft 2020–2023 +29,1 %, directes −6 % ; recherche web IA = 30–40× plus de CO2 qu'une recherche Google ; algorithme CarbonMin → pourrait réduire >50 % des émissions des data centers d'ici 2035 ; Andrej Karpathy (ex-OpenAI) ; Greg de Temmerman (expert énergie/climat) ; Justin Welsh (créateur de contenu LinkedIn) ; The Guardian → chiffres d'émissions officiels des tech giants sous-estimés.
- **Angle critique / limite** : "La plupart des articles se suivent et se ressemblent", tous basés sur "seulement deux documents scientifiques de 2023", "tout le reste n'est que du baratin" ; comparaisons "des choux et des carottes" assumées ; calcul Netflix "TRÈS limite" ; chiffres officiels des tech giants sous-estimés (The Guardian) ; objectifs zéro carbone 2030 cités avec ironie ; idée reçue "plus grand = plus efficace" déconstruite ; ne pas automatiser un "stagiaire erratique" sur des tâches sensibles → humain dans la boucle ; NotebookLM = "fiction, inférence" (l'IA n'a pas vraiment de crise existentielle, elle réagit à un texte) ; nuance sur l'empathie : "ce n'est pas tant pour les algorithmes... mais pour les personnages fictionnels".
- **État d'esprit / méthode (ce que l'auteur en dit)** : Sobriété — "Ai-je vraiment besoin d'utiliser ChatGPT pour générer des recettes ?" ; ne pas utiliser l'IA comme moteur de recherche ("te fera perdre beaucoup de temps") ; privilégier les petits modèles ; ne pas automatiser n'importe quoi ; "garder la tête froide" ; demander plus de transparence sur les émissions ; sortir de la course à "plus grand = mieux" ; localiser les data centers où l'énergie est décarbonée ; ton empirique, source-documenté, ironique sans cynisme.
- **Accès** : OK

---

### 41. 2024-09-29 — Comment l'IA vocale peut nous rendre plus intelligents
**URL** : https://generationia.flint.media/p/notebook-lm-second-cerveau-ia-gestion-connaissances
**Tags** : images-video-audio | workflows-context-engineering | mindset-culture
**Type** : article-méthode

- **Idée centrale** : Les outils vocaux d'IA (NotebookLM, Dicte, ChatGPT voice) ne sont pas des gadgets : transformer des documents complexes en podcasts et dialoguer avec eux renforce réellement la compréhension et la rétention. Parcours de l'auteur sur la semaine : "de 🫣 à 🤓... en passant par 🤔."
- **Techniques de prompting / méthode** : Méthode de prise de notes multicanal — enregistrer des résumés vocaux via Dicte → convertir en texte → importer dans NotebookLM → interagir au clavier (même en français, réponse en anglais) → générer un podcast. Avec le mode vocal de ChatGPT : ne pas structurer le prompt initial mais structurer la conversation elle-même via une progression dialectique (la surcouche vocale rend ChatGPT plus sensible à la dynamique de l'échange). Avec Claude (artifacts) : itérer en demandant des améliorations ("Tu peux mieux faire !").
- **Prompts cités VERBATIM** :
  ChatGPT (esprit critique) :
  ```
  Mettez-moi au défi en me posant une série de questions stimulantes sur l'intelligence artificielle générale. Posez les questions une par une et attendez ma réponse à chaque fois. Après chaque question, donnez votre avis sur ma réponse en identifiant les limites, les faiblesses et les biais possibles dans mon raisonnement. Puis suggérez-moi comment améliorer mon esprit critique et mes compétences réthoriques sur ce sujet.
  ```
  Claude (Monty Hall) :
  ```
  Crée un simulateur interactif qui explique le problème de Monty Hall.
  ```
  (avec relance : "Tu peux mieux faire !")
  Claude (illusions d'optique) :
  ```
  Donne moi 10 jeux d'illusions d'optique connus.
  ```
  Techniques de progression dialectique vocale (formulations données) :
  - "Avant de répondre, pose-moi trois questions pertinentes qui t'aideraient à mieux comprendre le contexte ou à affiner ta réponse."
  - "Peux-tu approfondir ce point ? Quelles sont les implications que tu n'as pas encore mentionnées ?"
  - "Fais une connexion inattendue entre ce concept et un domaine totalement différent."
  - "Quel serait l'argument le plus fort contre la position que tu viens de présenter ?"
  - "Quels biais potentiels pourraient influencer ton raisonnement sur ce sujet ?"
  - "Imagine un scénario futur où cette idée est poussée à l'extrême. Quelles en seraient les conséquences ?"
  - "Adopte le point de vue opposé et défends-le de manière convaincante."
  - "Résume les points clés de notre discussion en identifiant les questions cruciales qui restent sans réponse."
  - "Quelles sont les limites ou les faiblesses potentielles dans le raisonnement que tu as présenté ?"
  - "Peux-tu nuancer ta position en prenant en compte des contextes ou des situations différentes ?"
  - "Explique la méthodologie ou le raisonnement que tu utiliserais pour vérifier empiriquement cette affirmation."
- **Outils / produits + usage** : NotebookLM (Google) → "second cerveau", génère des podcasts audio à partir de documents ; Dicte → transcription vocale en texte (FR) ; ChatGPT (voice mode) → mode vocal (US seulement, contourné via VPN type NordVPN) ; Claude → artifacts (coder de l'interactif) ; PDF2Audio → PDFs → podcasts (open-source, via OpenAI API) ; Ideogram, Midjourney → images ; MagnificAI → images (clip Snoop Dogg) ; RunwayGen3, LumaLabs, KlingAI → vidéo ; Flair AI → placement automatique de produits sur fond ; Lipdub AI → synchro labiale pour avatars parlants.
- **Chiffres / études / personnes citées** : Étude adoption IA générative (sept. 2024, US) → 39,5 % d'adoption après 2 ans (vs 20 % internet après 2 ans, 20 % PC après 3 ans) ; 32 % d'utilisateurs hebdo ; 10,6 % de la population l'utilise quotidiennement ; 10,9 % des travailleurs chaque jour au travail ; 6,4 % quotidiennement hors travail ; 1 ouvrier sur 4 l'utilise régulièrement ; Tiago Forte (méthode PARA, "second cerveau") ; Steven Johnson (directeur éditorial NotebookLM) ; Richard Feynman → "Ce que je ne peux pas créer, je ne le comprends pas" ; Max Bennett ("A Brief History of Intelligence") ; Marcos Demetry, Jeff Jarvis → témoignages d'auteurs réutilisés par NotebookLM ; Ethan Mollick → a suggéré le jeu d'illusions d'optique ; Benoît Raphaël ("Information : l'indigestion", 2023) ; Flavien Chervet ("Hypercréation") ; 21 400 abonnés ; satisfaction 95 % "Top!", 4 % "Bien mais...", 1 % "Bof..." ; clip Snoop Dogg = 2 mois + équipe de 8 artistes.
- **Angle critique / limite** : NotebookLM = interface entièrement en anglais ; PDF2Audio "clairement moins bon", voix qui font "penser à une émission soporifique de 'Radio Jésus'" ; ChatGPT voice "beaucoup moins convaincant dès que tu rentres dans de vraies conversations", "on se lasse vite", voix monotone, moins cohérent ; system prompt vocal : refuse de flirter, ne chante pas (droits d'auteur), doit rappeler qu'il n'est pas humain ; veille automatisée → "l'IA n'a pas accès à tout le contenu", "risque d'halluciner" ; adoption plus forte chez diplômés/hauts revenus (inégalités) ; "les outils ne font pas tout, le talent et la maîtrise aussi".
- **État d'esprit / méthode (ce que l'auteur en dit)** : Exploration active ("Je me suis amusé à créer des podcasts sur à peu près tout") ; curiosité pour les mécaniques internes (étudier les system prompts piratés pour comprendre les règles) ; itération progressive ("Tu peux mieux faire !") ; adaptation progressive de la pédagogie plutôt que structure rigide du prompt ; valoriser l'échange dialectique plutôt que command-and-control ; les outils réussissent quand talent humain + IA s'associent (sélection, jugement, audace côté humain ; transformation côté IA).
- **Accès** : OK

---

### 42. 2024-09-22 — Le jour où les machines seront créatives
**URL** : https://generationia.flint.media/p/go-art-abstrait-intelligence-creativite-ia-innovation-can
**Tags** : comment-pense-LLM | mindset-culture | images-video-audio
**Type** : décryptage

- **Idée centrale** : Les machines PEUVENT être créatives, selon un cadre théorique défini — pas forcément à la manière humaine. La vraie question : comment redéfinir la créativité au-delà du modèle humain, en envisageant une co-évolution entre intelligences multiples ("pédagogie de l'IA, pas apologie de l'IA").
- **Techniques de prompting / méthode** : Usage de délimiteurs (crochets / balises) pour séparer données, textes et instructions, pour la clarté du modèle. Prompting visuel — Leonardo (Realtime Gen) génère des images en temps réel pour comprendre "comment l'IA réagit aux mots et à l'ordre des mots" ; itérer sur Leonardo (léger), puis revenir à Midjourney une fois le bon prompt trouvé.
- **Prompts cités VERBATIM** :
  ```
  Lis attentivement ce vieux texte:

  <texte> 
  ... ... ...
  </texte>

  Lis attentivement ces nouvelles données:

  <data>
  - ...
  - ...
  - ...
  </data>

  Réactualise le texte.
  ```
- **Outils / produits + usage** : ChatGPT → IA générative textuelle "consensuelle"/dérivative ; Midjourney → images, dérivatif ("c'est toi qui fais preuve de créativité avec elles") ; CAN (Creative Adversarial Networks, 2017) → deux réseaux s'affrontent, le discriminateur rejette tout ce qui ressemble à une œuvre existante ; GAN → ancêtres des CAN, plus consensuels ; AlphaGo → a battu Lee Sedol en 2016, coups "étranges" ; AlphaGo Zero → s'auto-entraîne sans données humaines, découvre des stratégies entièrement nouvelles ; Leonardo (Realtime Gen) → prototypage de prompts en temps réel ; Kolors → essayage virtuel de vêtements (open-source gratuit) ; Magnific.ai → optimisation qualité d'images ; Claude, Gemini → alternatives pour le prompting ; Diffusers Image Outpaint → outpainting gratuit ; Notdiamond → tester tous les modèles texte/image gratuitement (Flux, Stable Diffusion 3, Dall-E) ; Mureka → générateur de musique rival d'Udio et Suno ; Gamma → présentations PowerPoint aux couleurs/logos de marque ; o1 (OpenAI) → "raisonne", inspiré de l'approche Monte-Carlo.
- **Chiffres / études / personnes citées** : 2016 AlphaGo vs Lee Sedol ; 2017 CAN théorisés par Ahmed Elgammal (article scientifique 2017) ; éditorial Artsy 2017 saluant le travail d'Elgammal comme "la plus grande réussite artistique de l'année" ; 2025 prochain livre de Flavien Chervet sur les "risques existentiels de l'IA" ; Flavien Chervet ("Hypercréation") ; Anicka Yi (TED "intelligences autres") ; Morgane Soulier (consultante/artiste IA, article dans Le Point) ; Yuval Noah Harari ("Nexus") → "Nous pourrions nous retrouver à vivre dans les rêves d'une intelligence extraterrestre." ; Simon Willison → analogie du "stagiaire bizarre" ; étude MIT : >1000 personnes, dialogue de 8 min avec ChatGPT → réduction moyenne de 20 % de la croyance en théories du complot vs groupe contrôle, effet persistant ≥2 mois, même chez les très attachés ; expérience Art Basel : œuvres CAN jugées "plus structurées, plus inspirantes", on leur prêtait "plus d'intentionnalité que les œuvres des humains" (techniquement faux) ; 21 094 abonnés ; édition o1 = 100 % d'avis positifs (98,3 % Top, 1,7 % "Bien mais...", 0 % "Bof").
- **Angle critique / limite** : Comportement créatif des CAN/AlphaGo Zero impossible à reproduire "dans le vrai monde, beaucoup plus complexe et encore méconnu" ; Midjourney/AlphaGo (avant Zero) restent dérivatifs ; Elgammal lui-même critique les IA génératives d'images actuelles ; intentionnalité prêtée aux CAN "techniquement faux" ; approche développementale "encore très expérimentale" ; analogie du stagiaire bizarre (vérifier) ; Kolors = photo finale "pas de super qualité" ; vision Harari = catastrophe.
- **État d'esprit / méthode (ce que l'auteur en dit)** : "Nous devons aussi toujours vérifier ce qu'ils font" ; ChatGPT = "stagiaire bizarre qu'on peut un peu tyranniser. Tu peux lui dire : 'Non, refais-le, ce n'est pas bon.' Et tu n'as même pas à te sentir coupable." ; "notre objectif n'est pas de proposer une apologie de l'IA, mais une pédagogie de l'IA" ; ouverture à l'altérité (les machines comme "nouveaux compagnons de voyage") ; itération rapide (tester sur Leonardo léger, puis Midjourney).
- **Accès** : OK

---

### 43. 2024-09-12 — Tout comprendre du nouveau ChatGPT o1
**URL** : https://generationia.flint.media/p/chatgpt-o1-nouveau-modele-ia-raisonnement-strawberry-guide
**Tags** : comment-pense-LLM | prompting | actu
**Type** : décryptage

- **Idée centrale** : o1 (ex-"Strawberry") intègre une "chaîne de pensée" interne (apprentissage par renforcement), excellent en sciences/maths/code, mais "non révolutionnaire pour les tâches courantes" : "il est au niveau de GPT-4o, voire en dessous" pour la création de contenu. Nouveau paradigme : l'amélioration passe désormais aussi par le temps d'inférence — "la lenteur devient une qualité, et non un défaut". Moins un chatbot qu'"une IA à qui tu confies une mission".
- **Techniques de prompting / méthode** : Conseils d'OpenAI pour o1 — "Ces modèles fonctionnent mieux avec des prompts directs" ; "Certaines techniques comme le 'few shot' ou le modèle 'CoT' n'améliorent pas les performances et peuvent même parfois les entraver" ; "Garder les prompts simples et directs" ; "Utilisez des délimiteurs pour plus de clarté, tels que des guillemets triples, des balises XML ou des titres de section" ; "N'incluez que les informations les plus pertinentes afin d'éviter que le modèle ne complique trop sa réponse". Structure recommandée : "[CONTEXTE ET INFOS CLÉS] + [PROBLÈME A RÉSOUDRE]". Posture : "Ne lui demande pas d'effectuer une tâche mais de résoudre un problème" ; "Ne lui dit pas comment réfléchir, laisse le faire" ; "Donne lui un max d'informations structurées, pose lui le problème à résoudre, enferme le dans son bureau, et fiche lui la paix".
- **Prompts cités VERBATIM** :
  Test de "bon sens" (Daniel Jeffries) :
  > "Il a lancé une balle de baseball à 30 mètres au-dessus de ma tête, j'ai tendu le bras pour l'attraper, et j'ai sauté..."

  ("Essaie avec ce prompt piégeux de Daniel Jeffries, par exemple, qui permet de tester son 'bon sens' (dont il est dépourvu) et observe surtout la chaîne de pensée qui en découle.")
- **Outils / produits + usage** : ChatGPT o1 (ex-"Strawberry") → modèle avec raisonnement intégré ; GPT-4o → modèle sous-jacent / référence ; Claude → meilleur pour l'édition de texte et la génération de contenu selon l'auteur ; Ideogram 2.0, Flux → illustrations ; Devin → agent autonome de code, testé avec o1 ; Fish Audio → text-to-speech open-source gratuit, clone vocal (25 s d'audio suffisent, corpus 700 000 h en 8 langues) ; Notebook LLM (Google) → stockage de notes/docs par projet, génère des podcasts à 2 présentateurs virtuels.
- **Chiffres / études / personnes citées** : lancement o1 "vendredi dernier" (article du 12 sept. 2024) ; 20 660 abonnés (+260 vs semaine précédente) ; limite d'usage o1 = 30 interactions/semaine ; Fish Audio = clone vocal en 25 s, 700 000 h d'entraînement en 8 langues ; Daniel Kahneman (Nobel) → "Système 1 / Système 2" ; Noam Brown → co-créateur d'o1 (poker, diplomacy) ; Jason Wei (ex-Google) → "Chaîne de pensée" (2022), rejoint OpenAI pour Strawberry ; Simon Willson → critique du terme "raisonnement" ; Ethan Mollick → "Co-Intelligence", "des erreurs et des hallucinations se produisent toujours", "en tant que partenaire humain je me suis senti un peu diminué" ; Daniel Jeffries → 100 % de bonnes réponses à son test QI personnel avec o1 ; Steven Heidel (OpenAI) → conseils prompting ; François Chollet (Google) → réservé sur o1 ; Pamela McCorduck → citation 1979 sur créativité et IA ; Reuters → article "fracassant mais faux" (nov. 2023) sur le modèle "Q*" ; benchmark ARC (Abstraction and Reasoning Corpus) → o1 placé à égalité avec Claude ; document "System Card" (red teaming) ; étude Stanford "Quiet-STaR" (pensées internes).
- **Angle critique / limite** : "Raisonnement" pas vraiment approprié (Willson) — c'est une technique qui "joue le rôle" de raisonnement ; "cela reste de la prédiction de chaînes de pensée, avec une part d'aléatoire" ; sur questions ambiguës "parfois juste, parfois non" ; "il ne va pas encore détruire l'humanité" ; toujours limité par l'"intelligence" de GPT-4o sous-jacent ; pas bon en tout (création de contenu ≤ GPT-4o) ; Chollet/ARC réservés sur sa capacité à raisonner hors du cadre appris ; ne peut pas lire les fichiers (pas d'analyse de tableaux Excel) ; complémentaire, ne remplace pas GPT-4o ; intervention humaine plus "accessoire" ; suroptimisme marketing d'OpenAI pour lever des investissements ; "limité à quelques secteurs d'activité".
- **État d'esprit / méthode (ce que l'auteur en dit)** : "C'est moins un chatbot (qui interagit) qu'une IA à qui tu confies une mission" ; "enferme le dans son bureau, et fiche lui la paix" ; vérification humaine toujours nécessaire (Mollick continue d'utiliser Claude pour relire) ; usage réel de Benoît : a fait analyser les chiffres de Flint/Génération IA par o1 ("sans erreur, propositions pertinentes") mais Claude "(très) largement au dessus" pour les idées ; "la lenteur devient une qualité, et non un défaut".
- **Accès** : OK

---

### 44. 2024-09-09 — Comment j'ai piégé ChatGPT (et la solution)
**URL** : https://generationia.flint.media/p/le-jeu-des-questions-reponses
**Tags** : prompting | comment-pense-LLM | workflows-context-engineering
**Type** : article-méthode

- **Idée centrale** : Les LLMs hallucinent en analysant des documents. Solution : structurer le prompt en étapes avec une "porte de sortie" (guard-rail) autorisant le modèle à dire qu'il ne sait pas. "Pratique, oui, mais à condition de savoir s'y prendre" — "qui a parlé de formation ?"
- **Techniques de prompting / méthode** : Chain of Thought ("tu te rappelles : chaîne de pensée ? autorégression ?") ; structuration en 3 étapes — (1) extraction des éléments pertinents, (2) analyse si les éléments permettent de répondre, (3) réponse finale ; porte de sortie / guard-rail — "Si les éléments ne permettent pas de répondre à la question, dis-le".
- **Prompts cités VERBATIM** :
  Premier prompt (défaillant) :
  ```
  Lis le document joint et réponds à la question suivante:
  """
  A combien s'élèvent les émissions nettes de gaz à effet de serre de la France pour l'année 2023 ?
  """
  ```
  Second prompt (corrigé) :
  ```
  Lis le document joint et réponds à la question suivante:
  """
  A combien s'élèvent les émissions nettes de gaz à effet de serre de la France pour l'année 2023 ?
  """

  Suis les étapes suivantes :
  - Dans un premier temps, extrais et affiche les éléments les plus pertinents pour répondre à la question posée.
  - Analyze si les éléments permettent de répondre précisément à la question posée. Si les éléments ne permettent pas de répondre à la question, dis-le.
  - Et enfin réponds à la question.
  ```
- **Outils / produits + usage** : ChatGPT-4o → analyse un PDF (résumé exécutif du Haut Conseil pour le Climat, juin 2024).
- **Chiffres / études / personnes citées** : émissions brutes GES France 2023 = 373 Mt éqCO₂ ; baisse vs 2022 = 5,8 % ; excès vs budgets carbone = 15 Mt éqCO₂ ; baisse structurelle estimée = 15,3 Mt éqCO₂ ; sources : Haut Conseil pour le Climat (résumé exécutif juin 2024) + Citepa ; auteur : Thomas Mahier (9 sept. 2024).
- **Angle critique / limite** : Le 1er prompt donne une réponse "FAUX" — confusion émissions brutes / nettes ("Ceux sont les émissions brutes qui s'élèvent à 373 Mt éqCO₂ et moi j'ai demandé les émissions nettes") ; "ChatGPT et ses concurrents peuvent 'parfois' produire des affirmations fausses ou imaginaires : les fameuses 'hallucinations'" ; le 2e prompt révèle que "le document ne donne pas directement la valeur exacte des émissions nettes totales pour l'année 2023" ; le sujet mériterait une "mini-série" (images, tableaux, documents trop longs, différences ChatGPT/Claude/Gemini).
- **État d'esprit / méthode (ce que l'auteur en dit)** : Pragmatisme critique ("pratique, oui, mais à condition de savoir s'y prendre") ; reconnaît avoir "tendu un piège" ; approche scientifique (teste, constate l'erreur, affine) ; optimisme mesuré (la solution existe mais demande rigueur/formation).
- **Accès** : OK

---

### 45. 2024-09-09 — Un petit "shot" et ça repart
**URL** : https://generationia.flint.media/p/un-petit-shot-learning-et-ca-repart
**Tags** : prompting | comment-pense-LLM
**Type** : article-méthode

- **Idée centrale** : Le Few-Shots Prompting (aussi "multi-shots" / "n-shots") — fournir au modèle quelques exemples pertinents — améliore significativement la précision et la qualité des réponses comparé au Zero-Shot. Stratégie productive : "Générer. Générer. Générer." (dans l'usage réel on génère 10 ou 25 réponses, pas une seule).
- **Techniques de prompting / méthode** : Few-Shots Prompting ("multi-shots", "n-shots") ; Zero-Shot Prompting (instructions directes sans exemples — "particulièrement utile pour certain type de tâches") ; Chain Of Thoughts (combinable) ; paires "entrée/sortie" — fournir des exemples structurés (résumé d'entrée → sortie attendue) ; "Trois à cinq exemples peuvent suffire" ; "plus la tâche est complexe, plus il faut d'exemples soigneusement choisis".
- **Prompts cités VERBATIM** :
  Zero-Shot :
  ```
  Rédige un objet de mail sur le thème du "Few-Shots Prompting"
  ```
  Few-Shots (version simple) :
  ```
  Rédige un objet de mail sur le thème du "Few-Shots Prompting". 

  Inspire-toi des exemples suivants :

  ### Exemples

  -  C'est quoi un promt ?
  -  Le prompt, histoire d'une interaction homme-IA
  -  Dis ChatGPT, tu te souviens de moi ?
  -  Anatomie d'un prompt
  -  La force de l'entraînement. Le poids des mots
  ```
  Few-Shots (version entrée/sortie complète) :
  ```
  Ta tâche est de rédiger un objet de mail.

  Voici quelques exemples d'objets de mail que j'ai écrit  dans le passé à partir de résumés :
  """
  Exemple 1 :
  Résumé : Le billet explique les bases du "prompt engineering," c'est-à-dire l'art de formuler des instructions claires, précises et structurées pour interagir efficacement avec des modèles de langage comme ChatGPT. Il propose des exemples pratiques pour débuter et souligne l'importance de bien séparer le contexte, les données et les instructions dans un prompt.
  Objet du mail : C'est quoi un promt ?
 
  ---

  Exemple 2 :
  Résumé : Le billet explique l'importance de bien comprendre et exploiter les capacités des modèles de langage comme ChatGPT ou Claude, en mettant en avant leur vaste connaissance et leur capacité générative. Il souligne également l'importance d'affiner les prompts et d'évaluer les réponses pour maximiser l'efficacité de l'interaction avec ces modèles.
  Objet du mail : Le prompt, histoire d'une interaction homme-IA

  ---

  Exemple 3 :
  Résumé : Le billet explique que les modèles de langage comme ChatGPT ne personnalisent pas leurs réponses en fonction des échanges passés, mais se basent uniquement sur la conversation en cours, dans les limites de leur fenêtre contextuelle. Il clarifie également la différence entre le modèle de langage lui-même et l'application ChatGPT, qui peut mémoriser des informations via une fonctionnalité appelée "memory" sans modifier le modèle sous-jacent.
  Objet du mail : Dis ChatGPT, tu te souviens de moi ?
  """

  Rédige un objet de mail à partir de ce résumé :
  """
  Résumé : Le billet explique la technique du "Few-Shots Prompting" qui consiste à fournir au modèle quelques exemples pour améliorer la précision et la qualité des réponses. Il compare cette approche avec le "Zero-Shot Prompting" et illustre l'efficacité des exemples dans la génération de contenu pertinent. 
  Objet du mail :
  ```
- **Outils / produits + usage** : ChatGPT-4o → illustration pratique des exemples ; Claude → alternative pour générer des exemples de prompts ; ChatGPT → modèle de référence.
- **Chiffres / études / personnes citées** : "Trois à cinq exemples peuvent suffire" ; papier académique "Language Models are Few-Shots Learner" (arxiv.org/abs/2005.14165) ; auteur : Thomas Mahier (9 sept. 2024).
- **Angle critique / limite** : La difficulté = le choix des exemples (pertinents, variés, clairs) ; "plus la tâche est complexe, plus il faut d'exemples soigneusement choisis" ; le Zero-Shot n'est utile que pour certains types de tâches ; sur l'exemple donné : Zero-Shot = "Pas terrible. Pour ne pas dire : NUL" ; les techniques ne s'excluent pas, elles se combinent.
- **État d'esprit / méthode (ce que l'auteur en dit)** : Approche itérative ("Générer. Générer. Générer.") ; pragmatisme (dans l'usage réel : 10 ou 25 réponses) ; combiner les techniques (CoT + Few-Shots dans un même prompt) ; utiliser l'IA elle-même comme ressource pour améliorer ses prompts ("demande à Claude ou ChatGPT, ils sont là pour ça").
- **Accès** : OK

---

### 46. 2024-09-09 — La force de l'entraînement. Le poids des mots.
**URL** : https://generationia.flint.media/p/force-entrainement-poids-des-mots
**Tags** : comment-pense-LLM | prompting | mindset-culture
**Type** : article-méthode

- **Idée centrale** : Les modèles (ChatGPT, Claude) reproduisent des schémas appris à l'entraînement plutôt que de "réfléchir" ; le choix des mots du prompt déclenche ces schémas implicites et façonne les réponses. Comprendre ces mécanismes permet une utilisation critique. Épigraphe : citation de France Gall ("C'est peut-être un détail pour vous / Mais pour moi, ça veut dire beaucoup...").
- **Techniques de prompting / méthode** : (1) Modifier le ton via instructions explicites (forcer une critique sévère) ; (2) choisir le vocabulaire pour orienter la structure — dire "texte" plutôt qu'"article" ou "billet LinkedIn" pour éviter que le modèle active des schémas structurels prédéfinis (intro-développement-conclusion, "5 points clés") ; (3) in-context learning — "avec les bonnes instructions et/ou les bons exemples dans le prompt, le modèle a la capacité d''apprendre' et d'adapter son comportement" ; "Applique cette réflexion critique à toutes les réponses que tu obtiens".
- **Prompts cités VERBATIM** :
  ```
  Votre tâche est d'analyser ce contenu avec un œil critique et sévère. 
  Identifiez tous les problèmes potentiels, incohérences, redondances… 
  Ne faites pas d'éloges inutiles – concentrez-vous uniquement sur les 
  faiblesses et défauts que vous détectez. Soyez impitoyable dans votre 
  évaluation, et n'ayez pas peur de heurter ma sensibilité : la critique 
  sert à me faire progresser.
  ```
  Extrait du billet LinkedIn de Benoît :
  ```
  A partir des <notes> ci-dessus, j'aimerais que vous rédigiez en français 
  un texte concis et original qui mette en avant le sujet principal ou 
  l'idée clé. [...]
  ```
- **Outils / produits + usage** : ChatGPT → exemple central (version 3.5 mentionnée comme moins capable) ; Claude (Anthropic) → comparé à ChatGPT, décrit comme "bienveillant, serviable, agréable" (lien "La Constitution de Claude") ; N8N → lien "Bootcamp N8N" (rôle non détaillé) ; Workflow → petit outil développé par l'auteur et Benoît : sélectionner plusieurs articles, enchaîner des tâches, générer un article.
- **Chiffres / études / personnes citées** : Anthropic (Claude, "La Constitution de Claude") ; France Gall (épigraphe) ; Benoît (co-développeur du Workflow) ; Thomas Mahier (auteur, 9 sept. 2024) ; aucun chiffre quantifié.
- **Angle critique / limite** : Les LLMs "reproduisent des schémas appris plutôt qu'à 'réfléchir'" ; problème des "5 points" — ChatGPT extrait systématiquement 5 points clés quel que soit le contenu réel ("pour certains articles il n'y a réellement que 3 points clés, quand pour d'autres 7 points clés seraient un minimum" → "la prochaine fois que tu verras ces 5 points clés, méfie-toi") ; Claude structurellement encourageant ("Mais c'est déjà très bien comme ça !") — peut masquer les vraies faiblesses ; capacité d'adaptation seulement "dans une certaine mesure".
- **État d'esprit / méthode (ce que l'auteur en dit)** : Réflexion critique appliquée à toutes les réponses ; demander explicitement ce qu'on veut, ajuster le vocabulaire ; "hacker" le comportement par défaut via des directives ; ne pas ignorer ce qui a façonné le modèle ; pragmatisme expérimental (l'auteur et Benoît se sont "bien amusé à régler différents paramètres, à tester différents prompts") ; méfiance envers l'apparente perfection / le ton systématiquement bienveillant.
- **Accès** : OK

---

### 47. 2024-09-09 — Anatomie d'un prompt
**URL** : https://generationia.flint.media/p/anatomie-un-prompt
**Tags** : prompting | comment-pense-LLM | workflows-context-engineering
**Type** : article-méthode

- **Idée centrale** : Un prompt efficace exploite trois principes des LLMs : (a) le fonctionnement auto-régressif (génération mot par mot d'après le contexte), (b) l'interaction homme-machine comme moteur d'amélioration ("human in the loop"), (c) la décomposition des tâches complexes en étapes simples via la "chaîne de pensée". Maxime : "When you have to shoot, talk. Don't shoot." — "Keep It Simple !"
- **Techniques de prompting / méthode** : Auto-régression ("le modèle génère le texte mot par mot. Pour choisir le prochain mot, il regarde tous les mots précédents") ; complétion — rédiger soi-même le 1er paragraphe dans le style voulu, puis demander au LLM de continuer pour qu'il "s'aligne sur le style, le ton et le vocabulaire" ; approche indirecte — au lieu de demander un résumé directement, "Mitraille-le de questions : Qui ? Quoi ? Quand ? Où ? Pourquoi ? Comment ? (la classique méthode des Five Ws)" puis demander un résumé basé sur ces réponses ; Chain of Thought — "Guider le modèle étape par étape plutôt que de lui demander directement le résultat final", deux variantes : "Réfléchis étape par étape" ("Let's think step by step") ou indiquer explicitement les étapes ; simplicité — "il vaut mieux parfois avoir plusieurs prompts simples qui ne font qu'une seule chose mais bien, plutôt qu'un seul prompt complexe qui essaie de tout faire".
- **Prompts cités VERBATIM** :
  Prompt LinkedIn de Benoît :
  ```
  <notes>
  [INSÉRER LES NOTES]
  </notes>

  Vous êtes un assistant serviable qui fournit des informations précises et concises.
  Votre objectif ultime est de comprendre et de répondre aux demandes de l'utilisateur du mieux que vous le pouvez, en veillant à ce que ses besoins soient satisfaits et que ses questions reçoivent des réponses satisfaisantes.

  A partir des <notes> ci-dessus, j'aimerais que vous rédigiez en français un texte concis et original qui mette en avant le sujet principal ou l'idée clé. 

  Je préfère un style direct et professionnel, sans utiliser des expressions banales. Des phrases simples, percutantes, voire provocantes sont une bonne méthode.

  Le but est de communiquer l'information de manière claire et engageante, sans hyperboles. Idéalement, le post devrait être suffisamment unique pour se démarquer, tout en restant pertinent pour un public professionnel.

  Voici les règles à suivre : 

  ### Structure : 
  Utilisez la structure suivante pour captiver tout de suite l'attention, chaque étape ne doit pas faire plus d'une phrase et la phrase doit être courte

  - Démarrer par un fait sur lequel tout le monde sera d'accord, et qui montre l'importance d'un fait. 
  - Poser un problème, en mode "oui mais", afin  de créer l'agitation et d'intriguer le lecteur. 
  - Accrocher encore avec une solution afin de donner envie de lire la suite. 
  - Développer ensuite longuement les solutions ou les réflexions en donnant suffisamment de détails et d'exemples, ou de témoignages, par exemple en intégrant des interviews si elles sont présentes dans les notes.
  - Utiliser une structure pyramidale en entrant progressivement dans les détails.
  - Concentrez vous sur les faits et la narration en intégrant des citations si vous en avez à disposition.

  ### Contraintes : 
  - Un "hook" irrésistible est préférable à un titre.
  - Préférez des termes simples et originaux à l'utilisation d'expressions banales habituellement utilisées dans les articles de votre base de connaissance (telles que 'dans un monde', 'dans le monde trépidant', 'dans le monde tumultueux','à l'ère de', 'à l'heure de', 'crucial', 'captivant', 'troublant', 'fascinant', 'besoin urgent', 'il est essentiel', 'il est impératif', 'nous devons', 'en conclusion','en résumé') . Cherchez plutôt les termes les moins utilisés pour obtenir un style inimitable.
  - Evitez impérativement d'utiliser le "nous", de donner votre avis ou de faire des recommandations, concentrez vous exclusivement sur les faits et la narration.
  - Plutôt que de faire une conclusion, terminez par une question provocante qui ouvre le débat ou incite à partager ses expériences.
  - Phrases et paragraphes courts. Chaque fin de paragraphe doit donner une irrésistible envie de lire le suivant.
  - Le texte doit faire 2500 signes maximum.

  ### Exemples : 
  Voici un exemple de hook en suivant ces règles : 

  """ Il y a trop d'infos sur l'IA. Mais nous n'en retenons aucune. Voici une petite méthode pour s'en sortir la tête haute, si j'ose dire. """

  Commencez par le premier paragraphe très court, de 3 phrases maximum, en suivant ces règles d'accroche, proposez moi 5 hooks différents, puis demandez moi de choisir ou de proposer un autre hook.

  Une fois le hook validé ou corrigé, continuez le texte, sans vous répéter, en déroulant les autres informations extraites selon la structure donnée.

  ### Idées 
  Voici les idées que je veux faire passer dans ce post : 
  - [IDÉE 1] 
  - [IDÉE 2] 
  - [IDÉE 3] 


  Bonne rédaction !
  ```
  Exemple de hook cité : "Il y a trop d'infos sur l'IA. Mais nous n'en retenons aucune. Voici une petite méthode pour s'en sortir la tête haute, si j'ose dire."
- **Outils / produits + usage** : ChatGPT, Claude → exemples génériques de LLM ; LinkedIn → plateforme où Benoît utilise le prompt (posts) ; Flint Media / Génération IA → la newsletter ; Formations Flint sur le prompt et les LLMs → source du prompt de Benoît.
- **Chiffres / études / personnes citées** : Benoît Raphaël → 43 000+ abonnés LinkedIn ; Thomas Mahier (auteur, 9 sept. 2024) ; papier "Chain of Thought Prompting Elicits Reasoning in Large Language Models" (arxiv.org/abs/2201.11903) ; Five Ws (méthode journalistique).
- **Angle critique / limite** : "Les LLMs, impressionnants par bien des aspects, ont des capacités de raisonnement limités" — "Aide-les : décompose les tâches complexes en tâches simples" ; le prompt proscrit explicitement une liste d'expressions banales ('dans un monde', 'crucial', 'il est essentiel'...) et les hyperboles, pour éviter un style générique.
- **État d'esprit / méthode (ce que l'auteur en dit)** : Comprendre le fonctionnement interne (auto-régression) pour mieux guider ; partenariat homme-machine ("human in the loop" répété) — l'humain fournit expertise et choix finaux, le modèle génère et explore ; itération active (demander 5 options puis choisir/corriger plutôt qu'une instruction unique) ; l'humain reste aux commandes (validation du hook, fourniture des notes et idées) ; favoriser le dialogue gradué plutôt que la demande directe ("talk. Don't shoot.").
- **Accès** : OK

---

### 48. 2024-09-09 — Dis, ChatGPT, tu te souviens de moi ?
**URL** : https://generationia.flint.media/p/dis-chatgpt-tu-te-souviens-de-moi
**Tags** : comment-pense-LLM | workflows-context-engineering
**Type** : article-méthode

- **Idée centrale** : Démystification d'un malentendu fondamental : les IA conversationnelles (Claude, Gemini, ChatGPT, Mistral) n'apprennent PAS de nos conversations et ne mémorisent pas entre sessions — le modèle reste inchangé, seule la conversation en cours existe, dans une fenêtre contextuelle limitée. Distinction critique : séparer le modèle (inchangé) de l'application (avec features optionnelles comme "memory").
- **Techniques de prompting / méthode** : Autorégression — le modèle génère mot par mot en tenant compte de toute la conversation produite jusque-là ; copier/coller le texte à résumer plutôt que compter sur l'accès internet ("jouer la sécurité") ; maintenir une "conversation principale" cohérente sur un sujet et créer des conversations séparées pour les sous-tâches/questions annexes ; liens vers Chain of Thought et Few-shot learning.
- **Prompts cités VERBATIM** : — aucun prompt verbatim (mention informelle non retranscrite : "demandé à ChatGPT-4o de me résumer un article payant du Point").
- **Outils / produits + usage** : ChatGPT → IA conversationnelle, dispose de la fonctionnalité "memory" (OpenAI) ; Claude, Gemini, Mistral → IA conversationnelles ; ChatGPT-4o → exemple, avec accès internet ; Llama 3 → fenêtre contextuelle de 8 000 tokens ; Gemini 1.5 → fenêtre contextuelle de 1 million de tokens ; OpenAI → créateur de ChatGPT, a introduit "memory" ; Simon Willison → billet cité ; Anthropic → constructeur de Claude (implicite).
- **Chiffres / études / personnes citées** : Simon Willison → billet du "29 mai 2024" (simonwillison.net/2024/May/29/training-not-chatting/) ; Llama 3 = 8 000 tokens ; Gemini 1.5 = 1 million de tokens ; tokenisation : "bonjour madame" = 3 tokens chez ChatGPT-4o (bonjour- mad-ame) ; auteur : Thomas Mahier (9 sept. 2024).
- **Angle critique / limite** : "Au-delà de cette limite, les informations du début de conversation seront 'oubliées'" ; "Attention quand tu copies/colles de longs documents" ; "plus tu mélanges des sujets différents dans la même conversation, plus le modèle risque de s'embrouiller" ; accès internet pas fiable ("méfie-toi de cette fonctionnalité" — ChatGPT a rapporté un article faux de La Croix/JDN au lieu du Point payant) ; entraîner un modèle de zéro = "facture d'électricité bien salée".
- **État d'esprit / méthode (ce que l'auteur en dit)** : Segmentation stratégique (une conversation "principale" pour la cohérence, des conversations séparées par sous-tâche) ; "jouer la sécurité" (copier/coller plutôt que se fier à l'accès internet) ; scepticisme envers les features non stabilisées.
- **Accès** : OK
