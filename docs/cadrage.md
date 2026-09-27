# Cadrage du besoin

## Objectif

Utiliser un Basicolor N1 / VSD N1 (`5548:1002`) dans OpenDeck sur Bazzite à partir
du fork de `opendeck-akp03`. Le plugin doit assurer les échanges matériels et
transmettre les événements à OpenDeck.

La première version fonctionnelle couvre trois résultats : détection du
contrôleur, réception de ses appuis et affichage d'une image sur une touche.
Sa livraison comprend une archive installable, une règle udev et une procédure
Bazzite accompagnée des résultats de recette.

## Exigences

| ID | Exigence | Preuve attendue |
| --- | --- | --- |
| N1-01 | Conserver l'historique, la licence GPL-3.0 et l'attribution du projet d'origine | Historique Git préservé, fichier `LICENSE` et provenance documentée |
| N1-02 | Donner au fork une identité OpenDeck propre et des noms de fichiers cohérents | Manifeste, exécutables, namespace, archive et règle udev concordants |
| N1-03 | Identifier `5548:1002` et ouvrir la bonne interface HID | Inventaire de l'exemplaire, descripteurs et journal d'ouverture |
| N1-04 | Initialiser le contrôleur et transmettre les appuis de ses boutons | Captures analysées, correspondance des touches et événements OpenDeck |
| N1-05 | Afficher une image sur au moins une touche avec écran | Correspondance position/image, orientation et rendu physique vérifiés |
| N1-06 | Retrouver un fonctionnement stable après redémarrage et reconnexion | Recette sans doublon d'appareil ni bouton bloqué |
| N1-07 | Permettre l'utilisation native sans lancer OpenDeck en administrateur | Accès HID de l'utilisateur après application de la règle udev |
| N1-08 | Évaluer séparément OpenDeck en Flatpak | Résultat explicite, permissions effectives et éventuel blocage documentés |
| N1-09 | Ajouter les capacités complémentaires confirmées par les captures | Preuves et recette propres à chaque capacité annoncée |

Les exigences N1-03 à N1-05 déterminent le succès du prototype. La première
livraison Bazzite exige aussi N1-01, N1-02, N1-06 et N1-07, ainsi qu'un résultat
documenté pour N1-08. Un blocage Flatpak doit être publié comme tel ; une livraison
native peut être qualifiée indépendamment. N1-09 intervient après cette base.

## Périmètre initial

- Cible principale : Bazzite, avec une première chaîne de compilation Linux
  x86_64, conformément au `justfile` hérité. Toute autre architecture demande
  sa propre compilation et sa recette.
- OpenDeck : le README d'origine annonce un minimum de `2.5.0`. La version
  effectivement validée pour le N1 devra figurer dans chaque livraison.
- Boutons : établir leur nombre, leur disposition et leur indexation sur
  l'exemplaire. Les constantes du N3 ne décrivent pas automatiquement le N1.
- Images : commencer par une touche avec écran, puis étendre la correspondance
  aux autres positions confirmées.
- Relâchement : déterminer s'il est transmis par le matériel ou reconstitué à
  partir d'un événement de clic. Documenter cette différence avant d'annoncer
  l'appui long ou le maintien d'une action.
- Fonctions suivantes : luminosité, encodeurs, veille et autres commandes,
  selon l'équipement observé et les captures disponibles.

La compatibilité Windows/macOS du N1, les animations et la prise en charge
d'autres modèles demandent des validations supplémentaires. Windows peut servir
à capturer le logiciel constructeur sans faire partie de la première livraison.

## Informations à établir sur l'exemplaire

| Information | Moyen de la déterminer |
| --- | --- |
| Révision matérielle et firmware | Étiquette, logiciel constructeur et réponse USB si disponible |
| Interfaces HID, usages et rapports | Inventaire local et descripteurs de rapports complets |
| Nombre et disposition des commandes | Relevé physique et captures bouton par bouton |
| Format, dimensions et orientation des images | Captures de changements d'images et rendu sur une touche |
| Initialisation et éventuel maintien de connexion | Capture du démarrage et du repos prolongé |
| Disponibilité de VSD Craft sous Proton | Essai avec versions et configuration consignées ; Windows si nécessaire |
| Accès depuis le Flatpak installé | Permissions, visibilité du nœud HID et ouverture réelle par le plugin |

Une information issue d'un autre exemplaire reste une indication tant qu'elle
n'est pas reproduite. Le VID/PID, une taille de paquet ou une ressemblance
visuelle ne suffisent pas à choisir un protocole.

## Chantier distinct : lancement d'applications

Le plugin matériel s'arrête à la transmission d'un événement exploitable par
OpenDeck. La boîte de dialogue de sélection d'application et l'exécution d'une
application relèvent d'OpenDeck ou d'un plugin d'actions.

Le besoin associé peut être suivi sous **APP-01** : permettre de sélectionner
une application Linux installée via son entrée `.desktop`, puis de la lancer
avec une action OpenDeck. Son étude devra couvrir la découverte des entrées,
l'exécution selon les mécanismes du bureau, les erreurs affichées et le contexte
natif ou Flatpak. Le choix du composant à modifier reste à établir.

La recette matérielle observera les événements OpenDeck avec une action simple
déjà fonctionnelle ou les journaux. Un événement reçu correctement peut valider
N1-04 même si la sélection d'application demeure défaillante.
