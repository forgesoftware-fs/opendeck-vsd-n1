# Plan de recette du Basicolor N1

**État : aucune recette du plugin OpenDeck exécutée.** Les captures matérielles
exploratoires C01–C04 et C02b–C02d sont consignées dans l'investigation du protocole ;
C03c confirme le changement d'icône A puis B par VSD Craft et leur affichage sur
le N1. C04 documente la molette et une variation visible de luminosité rapportée
par l'opérateur, sans constituer une recette du plugin.
Cette observation du logiciel constructeur ne remplace pas les contrôles
d'acceptation ci-dessous et ne constitue pas un rapport de compatibilité du plugin.

## Conditions et preuves

Utiliser un N1 identifié, une version précise du plugin et une seule instance
d'OpenDeck à la fois. Fermer VSD Craft. Conserver les journaux horodatés, le relevé
des positions physiques, les images sources et des photos du résultat matériel.
Relier les observations de protocole aux captures décrites dans
[Investigation du protocole](protocole.md).

Exécuter la grille une fois en natif, puis une fois dans Flatpak. Employer les
statuts **Réussi**, **Échoué**, **Bloqué**, **Non exécuté** ou **Sans objet**, avec
une justification pour les deux derniers cas. Un résultat sans preuve reste
non validé.

## Contrôles de la première version

Les répétitions ci-dessous sont les critères proposés pour la première recette.
Elles devront être effectuées sur l'archive destinée à la livraison.

| ID | Exigences | Manipulation | Résultat attendu |
| --- | --- | --- | --- |
| R01 | N1-01, N1-02 | Examiner l'archive, sa provenance et le manifeste ; l'importer dans OpenDeck | Identité N1 cohérente, licence présente, binaire chargé, plugin d'origine non écrasé |
| R02 | N1-03, N1-07, N1-08 | Installer la règle, reconnecter et ouvrir le HID depuis le plugin sans élévation | Accès effectif à l'interface du contrôleur avec les permissions documentées |
| R03 | N1-03, N1-04 | Démarrer OpenDeck avec le N1 connecté, puis faire trois redémarrages d'OpenDeck | Un appareil enregistré, identité stable, bonne interface et initialisation réussie |
| R04 | N1-04 | Faire dix appuis courts sur chaque bouton physique inventorié, en comptant les événements/actions | Un déclenchement par appui, position correcte, aucune perte ni duplication, aucun bouton restant actif |
| R05 | N1-05 | Sur une touche avec écran, alterner deux images asymétriques pendant trois cycles | Bonne position, image complète et lisible, orientation correcte, absence de corruption |
| R06 | N1-06 | Débrancher puis rebrancher trois fois pendant qu'OpenDeck fonctionne ; refaire un appui et un changement d'image | Retrait puis retour de l'appareil, reprise fonctionnelle et absence de doublon |
| R07 | N1-04, N1-05, N1-06 | Laisser connecté dix minutes, puis refaire dix appuis et un changement d'image | Connexion utilisable, commandes et événements toujours corrects |
| R08 | N1-02, N1-03 | Vérifier les filtres actifs ; si un autre appareil pris en charge est disponible, essayer la coexistence | Aucun appareil revendiqué sans validation ; aucune régression sur les modèles conservés et testés |

Pour R04, consigner les événements physiques disponibles et les éventuels
relâchements reconstitués par le pilote. Le fonctionnement des clics ne suffit
pas à valider l'appui long. Pour R08, indiquer explicitement les modèles non
disponibles et les limites de la couverture.

## Extensions, après réussite de la base

| ID | Fonction | Critère si la fonction est annoncée |
| --- | --- | --- |
| E01 | Luminosité | Au moins trois valeurs permises produisent l'effet attendu, sans interrompre les boutons ni les images |
| E02 | Appui long | Maintien puis relâchement correctement transmis, sans relâchement prématuré ni action bloquée |
| E03 | Encodeurs | Index, sens, pas de rotation et éventuel appui conformes au relevé physique |
| E04 | Autres touches avec écran | Correspondance et rendu vérifiés sur toutes les positions annoncées |
| E05 | Veille et réveil du système | Reprise des boutons et du rendu sans doublon ni blocage |

Marquer **Sans objet** les fonctions absentes du matériel. Une fonction présente
mais non étudiée reste **Non exécuté** et n'est pas annoncée compatible.

## Matrice de résultats initiale

| Contrôle | OpenDeck natif | OpenDeck Flatpak | Preuves |
| --- | --- | --- | --- |
| R01 — Archive et installation | Non exécuté | Non exécuté | À joindre |
| R02 — Droits et interface HID | Non exécuté | Non exécuté | À joindre |
| R03 — Détection et initialisation | Non exécuté | Non exécuté | À joindre |
| R04 — Boutons | Non exécuté | Non exécuté | À joindre |
| R05 — Image sur une touche | Non exécuté | Non exécuté | À joindre |
| R06 — Reconnexion | Non exécuté | Non exécuté | À joindre |
| R07 — Fonctionnement après repos | Non exécuté | Non exécuté | À joindre |
| R08 — Cohabitation et autres modèles | Non exécuté | Non exécuté | À joindre |
| E01 à E05 — Extensions | Non exécuté | Non exécuté | Selon capacités confirmées |

## Modèle de compte rendu

Créer un compte rendu distinct par combinaison de versions et de permissions :

```text
Date / opérateur :
Modèle / révision / firmware :
Bazzite / noyau / architecture :
OpenDeck / mode d'installation :
Flatpak / runtime / permissions / dérogations, si concerné :
Plugin / commit / archive / SHA-256 :
Règle udev / interface et usages HID / nœud ouvert :
Contrôle Rxx ou Exx :
Préconditions et manipulations :
Résultat attendu :
Résultat observé et nombre de répétitions :
Statut :
Preuves : journaux, captures/trames, photos :
Anomalies / limites / prochaine vérification :
```

## Décision de livraison

Le prototype matériel est validé lorsque la détection, tous les boutons inclus
dans son périmètre et l'image d'une touche sont démontrés sur l'exemplaire.
La livraison native exige aussi une archive installable, les droits utilisateur,
la stabilité et la reconnexion. Toute limite de R08 doit être explicite.

Déclarer séparément le résultat Flatpak et les permissions nécessaires. Un essai
avec `--device=all` ne valide que cette configuration. Une fonctionnalité encore
non testée conserve ce statut dans les notes de livraison.

Le défaut de sélection d'application est suivi dans APP-01. Sa résolution ne
conditionne pas la réception des événements matériels vérifiée par R04.
