# Aikku CoopCom

## Application Web de coopération et de mutualisation de services entre communes

Un Workflow simple pour suivre le statut de chaque Intervention (Nouveau, Accepté, En cours, Terminé, Validé, Archivé).

Une information claire et partagée entre les parties prenantes et les services (Client/Adhérent, Agent technique, Manager, Comptabilité, Archives)

Une référence unique et sur tous les supports (PC/Smartphone)

## Composition d'une Intervention

+ Description
+ Tags (Urgent, etc.)
+ Client
+ Assignée à
+ Statut (Nouveau, Accepté, En cours, Terminé, Validé, Archivé)
+ Temps passé et temps de pause 
+ Photos
+ Commentaires
+ Evaluation 

## Fonctionnalités 

+ Recherche et filtres 
+ Export Excel des interventions
+ Notification par email des parties prenantes sur changement de Statut
+ Audit trail des modifications (Activité de la base de données)


# Installer Aikku CoopCom avec Docker

## Créer un nouveau serveur Arch Linux (chez Gandi) et s’y connecter
$ ssh arch@92.243.26.96

## Pour mettre à jour le système
$ sudo pacman -Syu

## Pour installer les packages git, docker, docker-compose
$ sudo pacman -S git docker docker-compose

## Pour voir les packages installés
$ sudo pacman -Qe

## Activer et Démarrer le Docker daemon
$ sudo systemctl enable docker

Nécessite parfois un reboot ou 
$ sudo systemctl start docker

## Pour checker l’état de Docker

$ systemctl status docker

# Installer Aikku CoopCom depuis les sources

## Cloner le repo
$ git clone https://github.com/philippe-nougaillon/coopcom.git

Dans le répertoire de Aikku CoopCom, copier le fichier dot.env.example en .env
$ cp dot.env.example .env

ou créer le fichier .env comme suit :
```
PGHOST=db
PGUSER=postgres
PGPASSWORD=changeme
```

## Créer le container 
$ sudo docker-compose build

## Créer la base de données Aikku CoopCom
$ sudo docker-compose run --rm web bin/rails db:setup

## Créer le premier utilisateur (Administrateur)

$ sudo docker-compose run --rm web bin/rails c

> User.create(email: 'philippe.nougaillon@gmail.com', admin: true, password: '1234567890', confirmed_at: DateTime.now)

> exit

## Démarrer le serveur dans le conteneur
$ sudo docker-compose up

## Lancer Aikku CoopCom
Ouvrir un navigateur et aller sur http://ip_du_serveur:3000 

Se connecter avec l'utilisateur/adminstrateur nouvellement créé 
