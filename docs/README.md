# Documentation du plugin Basicolor N1 / VSD N1

Ce dossier cadre l'adaptation du fork `opendeck-vsd-n1` pour le contrôleur
Basicolor N1, identifié dans le besoin par le couple USB `5548:1002`.

**État au 27 septembre 2026 : J0 est implémenté ; J1 est en cours.** Les captures
exploratoires C01–C03 ont été recueillies sur l'exemplaire local avec Bazzite et
Proton ; elles ne valident pas encore le protocole complet ni le plugin OpenDeck.
Le code examiné est celui du commit
`10d183451807cc172fdf394bdd34f41a33fb52d3`, version `0.11.0` du plugin d'origine.
Il reconnaît le TreasLin N3 `5548:1001`, mais pas le N1 `5548:1002`.
Aucun échange d'initialisation, d'appui ou d'image ni aucune recette du N1
n'accompagne cet état initial. Un premier relevé sysfs local confirme maintenant
deux interfaces HID pour `5548:1002` ; il est détaillé dans
[l'investigation du protocole](protocole.md). L'identité du fork, son assemblage
Linux et une règle udev dédiée ont aussi été mis en place. La découverte reste
désactivée jusqu'à la qualification du protocole.

Les captures C02 et C03 montrent que VSD Craft échange avec l'interface candidate
et transmet des données JPEG de 96 × 96 pixels. Les codes de bouton, les commandes,
la correspondance image/touche et le transfert complet restent à décoder ; aucun
essai d'acceptation du plugin n'a encore été exécuté.

La première version doit permettre à OpenDeck de détecter le N1, de recevoir les
appuis sur ses boutons et d'afficher une image sur une touche. La proximité des
identifiants USB constitue une piste d'étude ; la compatibilité du protocole
reste à démontrer.

## Documents

| Document | Contenu |
| --- | --- |
| [Cadrage du besoin](cadrage.md) | Objectif, périmètre de la première version, exigences et chantier distinct du lancement d'applications |
| [Plan de développement](developpement.md) | État du code, identité J0, architecture, jalons et assemblage Linux |
| [Investigation du protocole](protocole.md) | Inventaire HID, captures Windows et Linux, comparaison à `mirajazz` et preuves attendues |
| [Installation et diagnostic Bazzite](bazzite.md) | Règle udev proposée, procédure native et vérification séparée de Flatpak |
| [Plan de recette](recette.md) | Critères d'acceptation, matrice native/Flatpak et modèle de compte rendu |
| [Sources](sources.md) | Références consultées et limites de ce qu'elles établissent |

## Ordre de travail

1. ~~Préparer l'identité du fork et conserver son historique et sa licence.~~ **J0 fait** ; vérifier l'unicité de l'identité avant diffusion.
2. ~~Relever les interfaces et recueillir les captures initiales.~~ **C01–C03 faits** ; associer les codes et les images aux actions et positions
   physiques, puis compléter les fonctions disponibles.
3. Établir le protocole, puis réaliser une implémentation expérimentale isolée.
4. Valider détection, boutons et image sur le N1 avant de l'annoncer compatible.
5. Préparer l'archive et exécuter la recette Bazzite pour chaque mode d'installation.
6. Étendre les capacités selon les observations : luminosité, appui long,
   encodeurs ou autres fonctions présentes sur l'exemplaire testé.

Les procédures décrivent les travaux qui restent à réaliser. L'identité du fork,
la recette d'assemblage et le nom de la règle udev existent, mais ne constituent
pas une annonce de prise en charge. Toute validation doit indiquer le matériel,
le firmware, les versions logicielles et les preuves utilisées.
