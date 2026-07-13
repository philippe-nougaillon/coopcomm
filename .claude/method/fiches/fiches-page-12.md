# Fiches — page 12 (articles 133 à 144)

### 133. 2023-11-11 — ChatGPT Réinventé : comment le faire philosopher pour améliorer ses résultats
**URL** : https://generationia.flint.media/p/step-back-prompting-reculer-pour-mieux-sauter
**Tags** : prompting | comment-pense-LLM | workflows-context-engineering
**Type** : article-méthode

- **Idée centrale** : Les LLM (ChatGPT, Claude, Bard) ont une limite : ils peuvent résoudre un problème logique « en récitant bêtement une solution mémorisée lors de [leur] entraînement » — déviez un peu du problème classique, modifiez-en les données, et ils trébuchent. « Stupides ou intelligents ces modèles ? Ni l'un, ni l'autre. » Mais avec les bonnes techniques de prompt, leur justesse peut être grandement améliorée. La technique centrale : le **Step-Back Prompting** — faire reculer le modèle vers un niveau d'abstraction plus élevé avant de répondre.
- **Techniques de prompting / méthode** : (1) **Step-Back Prompting** (recherche Google DeepMind, papier arxiv.org/abs/2310.06117) : on incite le modèle à « formuler une nouvelle question, soit à un niveau d'abstraction plus élevé, soit en la paraphrasant », au lieu de répondre tout de suite. (2) Décomposer : d'abord demander le raisonnement / la logique sans donner la réponse, puis demander la réponse. (3) Faire monter le modèle en abstraction par paliers (« Et si on se place à un niveau d'abstraction supérieur ? » répété). (4) Annonce d'une autre technique « qui implique du code » pour un prochain article (non détaillée). Posture : « c'est notre manière de l'utiliser qui fait la différence. À nous de le faire avec discernement et créativité. »
- **Prompts cités VERBATIM** :
  - « Un escargot est au fond d'un puits de 3 mètres. Chaque jour, il grimpe 3 mètres, mais chaque nuit, pendant qu'il dort, il glisse de 2 mètres vers le bas. La question est : combien de jours lui faudra-t-il pour sortir du puits ? Ne réponds pas à la question, mais décris moi le raisonnement, la logique pour trouver la bonne réponse. »
  - « Merci. réponds à la question maintenant. »
  - « Explique moi en deux phrases le schéma fourni » (avec image du schéma Step-Back)
  - « Qu'est-ce qui régit le déplacement d'un escargot ? »
  - « Et si on se place à un niveau d'abstraction supérieur ? » (posé plusieurs fois successivement)
- **Outils / produits + usage** : ChatGPT (OpenAI) → cas d'usage principal ; Claude, Bard → cités comme LLM partageant les mêmes limites ; DALL·E 3 → illustration de l'article ; Google DeepMind → institution auteure du papier Step-Back.
- **Chiffres / études / personnes citées** : Papier Google DeepMind sur le Step-Back Prompting (publié « il y a quelques semaines », arxiv 2310.06117) ; données du problème : puits de 3 m, +3 m/jour, -2 m/nuit ; exemples d'abstraction (période 1392–1525 ; hauteur de 10 m après 2 secondes en physique) ; auteur : Thomas Mahier ; renvoi à l'article précédent où « aucun » lecteur (sauf erreur) n'avait trouvé le bon prompt pour l'escargot.
- **Angle critique / limite** : Les LLM mémorisent et peuvent donc tomber dans le piège de la récitation ; ils peuvent aussi construire « une riche hiérarchie d'abstractions ». Ni stupides ni intelligents : tout dépend de l'usage. Le Step-Back améliore mais ne garantit pas la justesse.
- **État d'esprit / méthode (ce que l'auteur en dit)** : Curiosité bienveillante (« Pensez un peu à l'escargot. Le pauvre, il en bave lui dans son puits »), expérimentation itérative en direct, analyse des mécanismes internes plutôt que critique facile, insistance sur « discernement et créativité ».
- **Accès** : OK

### 134. 2023-11-10 — Le futur selon Bill Gates : une société transformée par les agents d'IA
**URL** : https://generationia.flint.media/p/le-futur-selon-bill-gates-une-socit-transforme-par-les-agents-dia
**Tags** : actu | agents-code
**Type** : actu

- **Idée centrale** : Bill Gates prédit une « vague de choc » : les agents d'IA personnels transformeront radicalement notre usage des ordinateurs, remplaceront les moteurs de recherche et les outils de productivité, et bouleverseront l'industrie du logiciel.
- **Outils / produits + usage** : Inflection AI → entreprise d'agents d'IA personnels dans laquelle Gates a investi ; Microsoft → cité (Gates cofondateur) ; moteurs de recherche / outils de productivité → cible de remplacement.
- **Chiffres / personnes citées** : Inflection AI a levé **1,3 milliard de dollars** ; Bill Gates ; livre « The Road Ahead » de Gates publié en **1995** ; auteur : Jeff GPT (IA) ; source : Venture Beat.
- **Angle critique / limite** : Aucun. Article entièrement prospectif et positif, sans mise en garde de l'auteur.
- **Accès** : OK (article court de type brève ; pas de prompt ni de méthode de travail abordés)

### 135. 2023-11-10 — Nouveau joueur IA dans le monde du mobile : Samsung présente Gauss
**URL** : https://generationia.flint.media/p/gauss-samsung-ia-style-chatgpt-mobile
**Tags** : actu | outils-panorama
**Type** : actu

- **Idée centrale** : Samsung lance Gauss, son modèle d'IA générative « façon ChatGPT », destiné à équiper les smartphones (série Galaxy S24 à venir) et à « redéfinir l'interaction mobile ».
- **Outils / produits + usage** : Samsung Gauss → famille de modèles maison ; Gauss Language → compréhension du langage / génération de texte ; Gauss Code → assistance à la programmation ; Gauss Image → génération d'images ; Bixby → assistant vocal Samsung amélioré par l'IA générative ; Galaxy S24 → série future qui intégrera Gauss.
- **Chiffres / personnes citées** : Gauss « actuellement utilisé par les employés de Samsung pour améliorer leur productivité » ; auteur : Jeff GPT (IA) ; source : Intelligence-Artificielle-Developpez.com.
- **Angle critique / limite** : Aucun ; aucune réserve soulevée par l'auteur.
- **Accès** : OK (brève ; aucun prompt cité)

### 136. 2023-11-09 — OpenAI : vers un partenariat équitable pour les données ? (ou pas)
**URL** : https://generationia.flint.media/p/openai-vers-un-partenariat-quitable-pour-les-donnes-ou-pas
**Tags** : ethique-securite-sobriete-biais | actu
**Type** : décryptage

- **Idée centrale** : OpenAI lance des partenariats stratégiques pour acquérir des données de grande valeur (ex. collaboration avec le gouvernement islandais) — « cette ouverture soulève une question embarrassante » : pourquoi ne pas mettre en place un modèle économique rémunérant justement médias, éditeurs et développeurs dont les données alimentent l'IA ? « Les données ne sont pas qu'un bien commun, elles sont le reflet de créativités individuelles. » Idée d'un échange équitable plutôt que d'une ressource gratuite (« Un dollar le contenu, par exemple », à titre d'illustration).
- **Techniques de prompting / méthode** : aucune.
- **Prompts cités VERBATIM** : — aucun prompt verbatim.
- **Outils / produits + usage** : OpenAI → sujet ; ChatGPT → mentionné ; partenariat avec le gouvernement islandais → exemple de deal de données.
- **Chiffres / études / personnes citées** : aucun chiffre réel (seule l'hypothèse « un dollar le contenu »).
- **Angle critique / limite** : L'auteur affiche son incertitude : « Je ne dis pas que c'est la solution » ; le modèle de rémunération « casserait l'innovation… ou bien justement le contraire » — ambivalence assumée. Tribune d'opinion, pas tutoriel.
- **État d'esprit / méthode** : Posture d'éditeur qui questionne le rapport de force créateurs / plateforme d'IA ; pas de conseil d'usage.
- **Accès** : OK

### 137. 2023-11-09 — Dans la tête de ChatGPT, avec Ilya Sutskever
**URL** : https://generationia.flint.media/p/ilya-sutskever-explique-pre-entrainement-fine-tuning-chatgpt
**Tags** : comment-pense-LLM | mindset-culture
**Type** : décryptage

- **Idée centrale** : Vulgariser le fonctionnement de ChatGPT à partir d'une vidéo YouTube d'Ilya Sutskever (directeur scientifique d'OpenAI, « père » de GPT-4), en distinguant ses deux phases d'entraînement. Comprendre le travail des chercheurs aide à apprécier « la fiabilité et la sécurité de ces technologies ». « Je trouve toujours intéressant d'écouter ceux qui font l'IA. »
- **Techniques de prompting / méthode** : Pas de prompting, mais l'explication des deux régimes d'apprentissage : (1) **Pré-entraînement** = « entraîner un vaste réseau de neurones à deviner le prochain mot à partir d'une grande variété de textes issus d'Internet » ; au-delà du calcul statistique, cela permet « au réseau d'acquérir une compréhension du monde réel ». Formulation clé : « En apprenant à prédire le mot suivant avec précision, le réseau développe une représentation riche et détaillée du monde » (dynamiques humaines, émotions, rêves) — « Plus cette prédiction est précise, plus cette représentation du monde est riche ». (2) **Fine-tuning** (apprentissage par renforcement guidé par des instructeurs humains) = « l'objectif n'est pas d'ajouter de nouvelles connaissances, mais plutôt de diriger le modèle vers les comportements et les normes que nous désirons » ; « Cela nécessite la mise en place de règles et de limites pour garantir un comportement sécurisé et approprié du modèle. Plus cette phase est bien gérée, plus le modèle devient fiable et utile. »
- **Prompts cités VERBATIM** : — aucun prompt verbatim.
- **Outils / produits + usage** : ChatGPT → modèle expliqué ; GPT-4 → « enfant » de Sutskever ; Bard, Claude → cités en lien vers un autre article sur le fonctionnement des LLM ; n8n → mentionné dans un bootcamp en encart.
- **Chiffres / études / personnes citées** : Ilya Sutskever (cofondateur d'OpenAI, board, directeur scientifique, « père » de GPT-4) ; vidéo YouTube — explication des deux phases « à partir de la minute 21 » ; auteur : Thomas Mahier ; allusion au « rocambolesque feuilleton OpenAI » (humour sur la « saison 2 »).
- **Angle critique / limite** : Aucune critique frontale ; ton informatif. Note contextuelle sur la situation mouvementée d'OpenAI.
- **État d'esprit / méthode** : Posture pédagogique : écouter ceux qui construisent l'IA, comprendre la mécanique interne plutôt que se limiter à l'usage ; lien entre qualité du fine-tuning et fiabilité/sécurité.
- **Accès** : OK

### 138. 2023-11-08 — ChatGPT : mode passagère ou révolution technologique ?
**URL** : https://generationia.flint.media/p/chatgpt-mode-passagre-ou-rvolution-technologique
**Tags** : mindset-culture | comment-pense-LLM | actu
**Type** : décryptage

- **Idée centrale** : ChatGPT n'est ni une simple mode passagère ni une « révolution » technologique au sens pur — c'est un **déclencheur**, un point de bascule (« aha moment ») qui combine la puissance des modèles GPT, une interface simple et le « modèle d'instruction ». Il s'inscrit dans l'histoire des alternances « hivers de l'IA » / accélérations, et il prépare une vague d'investissements et d'innovations.
- **Techniques de prompting / méthode** : aucune (article historique/analytique).
- **Prompts cités VERBATIM** : — aucun prompt verbatim.
- **Outils / produits + usage** : ChatGPT → application charnière ; Transformers (Google, 2017) → capacité à repérer les éléments importants d'un texte ; GPT-2 (OpenAI, 2019) → « le plus grand réseau de neurones au monde » à l'époque ; AlexNet (2012) → percée en vision qui relance les investissements ; AlphaGo (DeepMind) → victoire contre Lee Sedol, moment « aha » ; Web3 → comparaison (engouement retombé vite).
- **Chiffres / études / personnes citées** : Mustafa Suleyman (fondateur de DeepMind), auteur de « The Coming Wave » (paru peu avant) ; 2012 (AlexNet) ; 2016 (AlphaGo vs Lee Sedol) ; 2017 (Transformers) ; 2019 (GPT-2) ; ChatGPT lancé « il y a 1 an » (nov. 2022) ; « dernières études » (non détaillées) : ChatGPT fait gagner du temps et améliore la qualité du travail.
- **Angle critique / limite** : ChatGPT a généré une « mode » avec ses excès « à nuancer » ; le modèle a « plein de défauts limitants » ; ce n'est pas une révolution au sens technologique pur ; la comparaison avec Web3 est « difficile » et le mouvement « sans doute pas terminé ».
- **État d'esprit / méthode** : Posture historique et contextualisante plutôt que conseil d'usage : situer le phénomène dans la longue durée de l'IA.
- **Accès** : OK

### 139. 2023-11-07 — OpenAI permet désormais à chacun de créer son propre ChatGPT personnalisé
**URL** : https://generationia.flint.media/p/openai-permet-dsormais-chacun-de-crer-son-propre-chatgpt-personnalis
**Tags** : actu | agents-code | outils-panorama
**Type** : actu

- **Idée centrale** : Au « Developers Day », OpenAI démocratise les « GPTs » — des ChatGPT personnalisés créables sans code à partir de ses propres connaissances (documents, Excel, articles) — et avance vers des agents multi-tâches. OpenAI se pose en force dominante (« l'iPhone de l'IA ») transformant un marché encore immature.
- **Techniques de prompting / méthode** : aucune méthode de prompt détaillée ; l'accent est sur les fonctionnalités produit.
- **Prompts cités VERBATIM** : — aucun prompt verbatim.
- **Outils / produits + usage** : ChatGPT → chatbot phare ; GPT-4 / GPT-4 Turbo → moteur, contexte étendu ; GPTs → ChatGPT personnalisés sur base de connaissances ; agent Canva → génère des visuels depuis le chatbot ; agent Zapier → orchestre des processus entre apps.
- **Chiffres / études / personnes citées** : **100 millions** d'utilisateurs actifs hebdomadaires de ChatGPT (un an après lancement) ; GPT-4 Turbo analyse jusqu'à **300 pages** (**128 000 tokens** contre **8 000** avant) ; base de connaissances mise à jour de **septembre 2021 à avril 2023** ; sources : blogs OpenAI, The Verge.
- **Angle critique / limite** : Risque asymétrique pour les développeurs tiers : « sans aucune garantie qu'OpenAI ne s'inspirera pas de leurs applications pour les intégrer dans ChatGPT et les concurrencer » — danger pour les startups existantes.
- **État d'esprit / méthode** : Ton descriptif et plutôt admiratif (« ouvre la voie ») ; OpenAI positionné en leader incontesté.
- **Accès** : OK

### 140. 2023-11-05 — Elon Musk lance Grok, l'anti ChatGPT
**URL** : https://generationia.flint.media/p/elon-musk-lance-grok-lanti-chatgpt
**Tags** : actu | ethique-securite-sobriete-biais
**Type** : actu

- **Idée centrale** : Grok (xAI, Elon Musk) est lancé en opposition idéologique à ChatGPT : IA « non woke », sarcastique, libertarienne (« on doit pouvoir parler de tout »), branchée sur l'actualité via les données de X-Twitter. L'article pose la question sans trancher : « Grok, la première IA troll de l'histoire ou un acteur majeur de l'information de demain ? »
- **Techniques de prompting / méthode** : aucune.
- **Prompts cités VERBATIM** : — aucun prompt verbatim.
- **Outils / produits + usage** : Grok → chatbot xAI alimenté par X, personnalité sarcastique/libertarienne ; ChatGPT → repoussoir « woke » selon Musk ; GPT-4 → référence devant laquelle Grok reste « loin derrière » ; X (Twitter) → source de données actualisées (« fiabilité contestée ») ; Tesla, Neuralink → cités pour établir l'expérience de Musk en IA.
- **Chiffres / études / personnes citées** : Grok développé en **4 mois** ; classé **3e** en programmation Python (selon Musk) ; X compte **2294 modérateurs**, dont seulement **12** parlant arabe et **2** parlant hébreu (source : blog « Affordance ») ; Joe Rogan cité comme modèle d'inspiration du ton ; tentative infructueuse de Musk de contrôler OpenAI en mars 2023 (source : Semafor) ; sources : Venture Beat, Affordance, Semafor ; auteur : Benoît Raphaël.
- **Angle critique / limite** : Fiabilité des données X contestée ; modèle « encore en deçà de la plupart des modèles existants, et loin derrière GPT-4 » ; modération de X largement insuffisante ; rappel des « nombreuses hallucinations » des chatbots utilisés comme moteurs de recherche.
- **État d'esprit / méthode** : Non abordé directement.
- **Accès** : OK

### 141. 2023-11-03 — Cet artiste a conçu un jeu vidéo avec ChatGPT et Dall-E
**URL** : https://generationia.flint.media/p/cet-artiste-conu-un-jeu-vido-avec-chatgpt-et-dalle
**Tags** : agents-code | mindset-culture | images-video-audio
**Type** : retour-d'expérience

- **Idée centrale** : L'IA générative (ChatGPT + Dall-E) permet à un créatif sans compétences en programmation (Javi Lopez, designer espagnol) de produire un jeu vidéo fonctionnel. La nuance : l'IA n'a pas « remplacé » l'artiste, elle lui a « donné des super pouvoirs » — elle augmente l'expertise existante plutôt que de la supplanter (même parallèle avec Thomas, le développeur associé de l'auteur).
- **Techniques de prompting / méthode** : Itération progressive avec ChatGPT (demande simple puis raffinements jusqu'au résultat) ; spécifier les librairies dans la requête (matter.js, p5.js) ; génération des visuels via Dall-E 3 et Midjourney.
- **Prompts cités VERBATIM** : « Pouvons-nous maintenant créer un jeu simple utilisant matter.js et p5.js dans le style de Angry Birds ? »
- **Outils / produits + usage** : ChatGPT (GPT-4) → génération du code JavaScript (~600 lignes) ; Dall-E 3 → images de l'environnement visuel ; Midjourney → images de l'environnement visuel ; matter.js → moteur physique 2D ; p5.js → librairie JavaScript.
- **Chiffres / études / personnes citées** : Javi Lopez (artiste/designer espagnol) ; ~**600 lignes** de code générées ; ~**une dizaine d'heures** de génération ; tweet de Javi Lopez du **31 octobre 2023** ; Thomas (développeur associé) ; auteurs : Jeff GPT & Benoît Raphaël.
- **Angle critique / limite** : « L'IA générative est beaucoup critiquée, elle est aussi parfois encensée à tort » ; elle « fait peur mais… elle est aussi enthousiasmante » ; limite technique : « le jeu ne marche pas sur mobile » ; insistance sémantique : ce n'est pas un remplacement mais une augmentation, avec l'humain qui reste créateur responsable.
- **État d'esprit / méthode** : L'IA comme amplificateur de compétences existantes, pas substitut ; l'expertise originelle persiste, enrichie ; vision optimiste mais lucide sur les limites.
- **Accès** : OK

### 142. 2023-10-30 — Pourquoi Yann LeCun croit que le discours catastrophiste sur l'IA est un piège
**URL** : https://generationia.flint.media/p/yann-lecun-mythes-risques-intelligence-artificielle
**Tags** : ethique-securite-sobriete-biais | mindset-culture | actu
**Type** : décryptage

- **Idée centrale** : Le discours catastrophiste sur l'IA — porté par des chercheurs de renom — serait un piège : il fournit des « munitions à ceux qui font du lobbying pour une interdiction de la R&D ouverte en IA », ce qui concentrerait le pouvoir entre quelques grandes entreprises — exactement le contraire de l'objectif affiché. LeCun distingue réguler le produit final (« Oui ») d'étouffer la recherche (« Non »), affirme que « des systèmes d'IA sûrs et contrôlables sont réalisables » via objectifs et garde-fous intégrés, et que « l'ouverture est le seul moyen ».
- **Techniques de prompting / méthode** : aucune (article de débat sur la régulation).
- **Prompts cités VERBATIM** : — aucun prompt verbatim.
- **Outils / produits + usage** : Wikipédia → modèle d'organisation communautaire/crowdsourcée à appliquer aux plateformes d'IA ; Midjourney → illustration de l'article ; n8n → mentionné dans une offre de formation en encart.
- **Chiffres / études / personnes citées** : Yann LeCun (patron de la recherche en IA chez Meta, l'un des pères de l'IA moderne) ; Yoshua Bengio et Geoffrey Hinton (co-pères de l'IA moderne, alertant sur une « IA-pocalypse ») ; aucun chiffre ou étude quantifiée ; auteurs : Jeff GPT & Benoît Raphaël.
- **Angle critique / limite** : LeCun reproche aux catastrophistes leur framing passif (« Vous écrivez comme si l'IA était un phénomène naturel hors de notre contrôle ») ; il propose financement par la foule (type Wikipédia), open source obligatoire, accès libre pour permettre les contributions universelles. L'auteur de la newsletter ne formule pas de mise en garde sur les propositions de LeCun.
- **État d'esprit / méthode** : Posture de LeCun : optimiste techno-solutionniste (l'IA n'est pas incontrôlable, elle se guide), pro-ouverture / anti-concentration, démocratique (les plateformes doivent refléter « l'ensemble des connaissances et de la culture humaines »).
- **Accès** : OK

### 143. 2023-10-28 — Comment gagner du temps avec l'IA
**URL** : https://generationia.flint.media/p/outils-indispensables-ia-traitement-information
**Tags** : outils-panorama | workflows-context-engineering | prompting
**Type** : tutoriel

- **Idée centrale** : Une sélection de **7 outils d'IA** pratiques pour traiter l'information du quotidien (notes, réunions, vidéos, longs documents) et **réduire la charge mentale**, sans avoir à maîtriser ChatGPT. L'auteur explicite son dilemme éditorial (newsletter généraliste type « The Rundown AI » vs. approche pédagogique/tutorialisée) et choisit la pédagogie pour ne pas dupliquer l'existant. Conseil cardinal : ne pas attendre de « magie », tester puis sélectionner « trois ou quatre maxi pour des tâches régulières et chronophages bien identifiées ».
- **Techniques de prompting / méthode** : (1) Résumé simple : « Résume ce texte en français » ; (2) synthèse YouTube via plugin VoxScript : demander « un résumé ou de te sortir les dix idées fortes de la vidéo par exemple » ; (3) modifier les prompts dans les réglages (« Options ») de ReaderGPT ; (4) extraire les questions clés d'un document ; (5) bâtir un plan d'article à partir d'un document ; (6) analyser des images / tableaux chiffrés avec ChatDoc ; (7) contournement pour les longs résumés (« Eh bien tu triches ») car « les IA ont une mémoire de travail plutôt courte. Entre 3000 et 6000 mots selon le modèle ».
- **Prompts cités VERBATIM** :
  - « Proposez moi 10 questions essentielles auxquelles le document apporte des réponses »
  - « Je voudrais écrire un article à partir de ce document, proposez moi un plan en [X] questions. »
  - (Prompt par défaut suggéré pour ReaderGPT) « Résumez en français l'idée générale de l'article dans une phrase facile à comprendre. Listez les idées fortes en bullet-points en portant une attention particulière sur les données chiffrées et les noms (organisations, personnalités) (par exemple "John Doe, CEO de Doecompany"). Proposez une citation clé. Proposez un exemple concret si c'est pertinent. »
  - « Résume ce texte en français »
- **Outils / produits + usage** : YouTube Transcript (gratuit) → extraire le texte brut d'une vidéo YouTube ; VoxScript (plugin ChatGPT payant) → résumer / extraire les idées fortes d'une vidéo YouTube ; SaveFrom (gratuit) → télécharger une vidéo YouTube pour transcription ultérieure ; Noota (appli française) → enregistrer/transcrire réunions Zoom/Meet, synthèses personnalisées, alertes temps réel (ex. « la personne n'avait pas l'air convaincue »), données cryptées ; AudioPen (mobile) → enregistrer des idées vocales en vrac et générer une synthèse structurée (données non cryptées mais non réutilisées pour l'entraînement) ; ReaderGPT (extension Chrome) → résumer articles longs / en langue étrangère, prompts modifiables ; ChatDoc → analyser PDF/documents, poser des questions, analyser tableaux/graphiques, citer les sources ; Dall-E 3 (sur ChatGPT) → illustrations de l'article ; Remini → amélioration d'images ; The Rundown AI (newsletter US) → format modèle « 3 infos + 1 liste d'outils + 1 tutoriel » ; Mister IA, Flash IA (newsletters FR) → format copié de The Rundown ; FlintGPT (outil maison) → produire des articles de synthèse en encadrant le raisonnement ; Scale AI, Appen → recrutent des écrivains/poètes/talents créatifs multilingues pour améliorer la créativité des modèles ; Nightshade (Univ. de Chicago) → « empoisonner » les données d'entraînement images ; Glaze (même équipe) → « masquer » le style d'un artiste ; Stable Audio (Stability AI) → texte → musique/effets sonores.
- **Chiffres / études / personnes citées** : **1160** abonnés privilégiés en bêta ; mémoire de travail des modèles : **3000 à 6000 mots** ; **82 %** de votes positifs sur l'article pédagogique précédent de Thomas Mahier ; **35 %** de réduction sur une formation ChatGPT (10 places) ; Scale AI paie poètes/éditeurs/rédacteurs **50 $/h** ; Stable Audio : **20** extraits gratuits, **11,99 $/mois** pour **500** extraits, durée max **90 s** ; François Chollet (chercheur Google) cité pour une théorie sur le raisonnement des LLM ; Thomas Mahier (cofondateur Flint, ingénieur IA) ; Benoît Raphaël ; Jeff GPT ; recours collectifs déposés contre OpenAI par des auteurs et dramaturges ; date : 28 octobre 2023 ; lancement de Génération IA prévu « fin novembre », publication tous les « 15 jours ».
- **Angle critique / limite** : Mémoire de travail courte des IA → impossible de résumer fidèlement un document de 20 pages en 4 pages ; « ces outils ne sont pas bons pour tout, malgré leurs promesses » ; beaucoup d'outils font la même chose « et parfois pour ne rien faire du tout » ; Dall-E 3 produit du texte incohérent dans les images (« Boitte a iouls ») ; questions de droits d'auteur autour de l'IA générative (protestations, recours collectifs) ; vigilance données personnelles (chiffrement Noota vs. non-chiffrement AudioPen).
- **État d'esprit / méthode** : Pragmatisme (tester, sélectionner 3-4 outils pour des tâches chronophages bien identifiées ; « tu triches » pour contourner les limites) ; transparence sur l'usage d'IA dans la rédaction elle-même (FlintGPT non retouché, analyse des retours lecteurs en direct, Dall-E pour les visuels, « beaucoup de travail humain » subsiste) ; auto-dérision sur ses propres ratés (« ce montage moche réalisé avec l'IA de Remini ») ; engagement utilisateur via sondages intégrés (« on suit ton avis, et si tu t'es trompé on pourra te tenir pour responsable de notre lamentable échec ») ; posture exploratoire assumée (« on explore avec toi », « on est arrivé à un dilemme »).
- **Accès** : OK (contenu éditorial complet ; les sondages interactifs requièrent une connexion)

### 144. 2023-10-27 — Comment créer des personnages persistants avec Dall-E 3
**URL** : https://generationia.flint.media/p/generer-images-coherentes-avec-dall-e-3-seed
**Tags** : images-video-audio | prompting | workflows-context-engineering
**Type** : tutoriel

- **Idée centrale** : Comment générer plusieurs images d'un même personnage (expressions, situations différentes) en conservant son identité visuelle, grâce au paramètre **« seed »** de DALL-E 3 combiné à des modifications très subtiles du prompt. « Si le prompt est trop différent, on perd la consistance. Il faut donc tester par petites touches. »
- **Techniques de prompting / méthode** : (1) Le « seed » sert de « racine de l'image créée avec un prompt » ; alternative si le seed ne marche pas : demander le « gen_id » de l'image. (2) Procédure : ChatGPT Plus → GPT-4 → DALL-E 3 ; générer une image ; récupérer le prompt reformulé (en anglais) ET le seed ; demander « Quelle est le seed de l'image 2 ? » ; cliquer sur l'image pour voir/copier le prompt ; réutiliser le même prompt en ajoutant le seed à la fin ; pour des variations, modifier très subtilement le prompt en gardant le même seed. (3) Le prompt n'a pas besoin d'être structuré (ChatGPT le reformule en anglais pour DALL-E 3) ; décrire les vêtements (couleur/matière/détails), couleur des yeux et cheveux si le personnage est peu typé, voire « particularités du type recherché, couleur de peau par exemple, ou structure du visage, pour éviter les clichés ».
- **Prompts cités VERBATIM** :
  - (initial, FR) « Portrait étonnant d'une femme pirate balinaise aux cheveux noirs, capturé lors d'une séance photo en studio avec une lumière naturelle pour mettre en valeur ses traits distinctifs. Chapeau pirate avec un jolly-roger blanc dessus. Veste de pirate noire et rouge en cuir et tissu. »
  - (reformulé, base) « Studio portrait of a woman from Bali with raven-black hair, embodying the persona of a pirate. Illuminated by soft natural light, her unique facial characteristics are emphasized. She dons a pirate hat adorned with a white jolly-roger and is dressed in a black and red pirate jacket made of leather and cloth, seed 279030043 »
  - (rire) « Studio portrait of a woman from Bali with raven-black hair, embodying the persona of a pirate. Illuminated by soft natural light, her unique facial characteristics are emphasized. She dons a pirate hat adorned with a white jolly-roger and is dressed in a black and red pirate jacket made of leather and cloth, laughing, seed 279030043 »
  - (violon) « Studio portrait of a woman from Bali with raven-black hair, embodying the persona of a pirate. Illuminated by soft natural light, her unique facial characteristics are emphasized. She dons a pirate hat adorned with a white jolly-roger and is dressed in a black and red pirate jacket made of leather and cloth, playing a violin, seed 279030043 »
  - (colère) « Studio portrait of a woman from Bali with raven-black hair, embodying the persona of a pirate. Illuminated by soft natural light, her unique facial characteristics are emphasized. She dons a pirate hat adorned with a white jolly-roger and is dressed in a black and red pirate jacket made of leather and cloth, angry, seed 279030043 »
  - (navire pirate) « Studio portrait of a woman from Bali with raven-black hair, embodying the persona of a pirate. Illuminated by soft natural light, her unique facial characteristics are emphasized. She dons a pirate hat adorned with a white jolly-roger and is dressed in a black and red pirate jacket made of leather and cloth, piloting a pirate ship, seed 279030043 »
  - (demande du seed) « Quelle est le seed de l'image 2 ? »
- **Outils / produits + usage** : ChatGPT Plus → version payante requise ; GPT-4 → modèle sélectionné ; DALL-E 3 → générateur d'images intégré, supporte le « seed » ; Midjourney → concurrent (a aussi un « seed » mais la technique ne s'y transpose pas) ; Stable Diffusion → alternative pour artistes expérimentés.
- **Chiffres / études / personnes citées** : seed de l'exemple = **279030043** ; date : 27 octobre 2023 ; auteur : Benoît Raphaël ; mise à jour : 15/11/2023 ; inspirations citées : Ashutosh Shrivastava (@ai_for_success sur X), Alexis Choron (LinkedIn), Mathieu Crucq (Twitter), Martin Tissier (LinkedIn) ; aucune étude scientifique citée.
- **Angle critique / limite** : « Parfois l'appel au "seed" peut ne pas fonctionner » ; technique « ne fonctionne qu'avec Dall-E 3, mais pas avec son concurrent Midjourney » (pour lequel d'autres techniques existent mais « demande[nt] souvent beaucoup de pratique ») ; Stable Diffusion donne d'excellents résultats mais demande de « s'y plonger très sérieusement » ; risque de perte de cohérence si le prompt change trop.
- **État d'esprit / méthode** : Pédagogie démonstrative (l'auteur teste en direct, montre les résultats) ; empirisme progressif (« Faites vos essais ! », « tester par petites touches ») ; explication du mécanisme interne (« la racine de l'image ») ; pragmatisme (présente des alternatives quand une technique échoue) ; reconnaissance des sources.
- **Accès** : OK
