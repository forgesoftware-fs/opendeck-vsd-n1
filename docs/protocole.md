# Investigation du protocole N1

## Point de départ et inconnues

L'[issue consacrée au VSD N1](https://github.com/bitfocus/companion-surface-mirabox-stream-dock/issues/30)
rapporte un périphérique `5548:1002` présentant deux interfaces HID :

| Interface | Descripteur publié | Endpoints et tailles maximales annoncées |
| --- | --- | --- |
| `0` | HID sans protocole standard déclaré ; candidate pour le contrôleur | `0x82` IN : 512 octets ; `0x03` OUT : 1024 octets |
| `1` | HID de type clavier de démarrage | `0x81` IN : 64 octets |

Ce relevé provient d'un autre exemplaire. Il mentionne des descripteurs de
rapports de 36 et 90 octets, mais leur lecture a échoué. Il ne fournit donc pas
les usages HID ni le contenu de ces rapports. Ces longueurs et les tailles
maximales des endpoints ne définissent pas le format des commandes.

Avant le relevé local ci-dessous, le VID/PID, les interfaces, les usages, les
identifiants de rapport, les tailles réelles des transferts et le rôle de chaque
interface restaient à confirmer. La sélection `0xFFA0:1` du code N3 était une
hypothèse pour le N1.

## Relevé sysfs local du 27 septembre 2026

Le noyau expose un périphérique `5548:1002`, USB 2.0, une configuration et deux
interfaces HID. `bcdDevice` vaut `0002`, le débit négocié est 480 Mbit/s et la
puissance déclarée est 450 mA. Les chaînes USB rapportent le fabricant
`HOTSPOTEKUSB` et le produit `HOTSPOTEKUSB HID DEMO`. Elles ne confirment pas à
elles seules l'étiquette commerciale, la révision ni le firmware de l'exemplaire.
Le numéro de série n'est pas conservé dans le dépôt.

Session : Linux x86_64, noyau `7.2.4-ogc3.1.fc44.x86_64`, `udevadm` 259. Le
descripteur de configuration USB relevé depuis sysfs est :

```text
12 01 00 02 00 00 00 40 48 55 02 10 02 00 01 02 03 01
09 02 42 00 02 01 00 a0 e1
09 04 00 00 02 03 00 00 00
09 21 00 02 00 01 22 24 00
07 05 82 03 00 02 01
07 05 03 03 00 04 01
09 04 01 00 01 03 01 01 00
09 21 00 02 00 01 22 5a 00
07 05 81 03 40 00 0a
```

| Interface | Descripteur d'interface | Rapport HID et usage | Endpoints USB |
| --- | --- | --- | --- |
| `0` (`1-2:1.0` dans cette session) | Classe `03`, sous-classe `00`, protocole `00`, deux endpoints | 36 octets ; collection d'application page `0xFFA0`, usage `1` ; rapport entrant 512 octets et sortant 1024 octets, sans identifiant de rapport déclaré | `0x82` IN, interruption, 512 octets, intervalle 1 ; `0x03` OUT, interruption, 1024 octets, intervalle 1 |
| `1` (`1-2:1.1` dans cette session) | Classe `03`, sous-classe `01`, protocole `01`, un endpoint | 90 octets ; interface clavier de démarrage avec collections clavier et commandes grand public | `0x81` IN, interruption, 64 octets, intervalle 10 |

Les rapports HID ont été lus depuis sysfs. La configuration USB expose les
adresses et tailles maximales des endpoints ci-dessus. L'interface `0` correspond
au candidat de découverte `0xFFA0:1` utilisé par le code N3 ; cette correspondance
identifie l'interface candidate, pas le protocole applicatif. L'interface `1`
est le clavier et ne doit pas être ouverte comme contrôleur de touches.

Descripteurs de rapports relevés, en hexadécimal :

```text
Interface 0 (36 octets):
06 a0 ff 09 01 a1 01 09 02 15 00 26 ff 00 75 08
96 00 02 81 02 09 03 15 00 26 ff 00 75 08 96 00
04 91 02 c0

Interface 1 (90 octets):
05 01 09 06 a1 01 85 01 05 07 19 e0 29 e7 15 00
25 01 75 01 95 08 81 02 95 01 75 08 81 01 95 05
75 01 05 08 19 01 29 05 91 02 95 01 75 03 91 01
95 06 75 08 15 00 25 65 05 07 19 00 29 65 81 00
c0 05 0c 09 01 a1 01 85 02 19 00 2a 3c 02 15 00
26 3c 02 95 01 75 10 81 00 c0
```

Ce relevé établit l'interface HID candidate et les descripteurs de cet exemplaire.
Il n'établit aucune commande d'initialisation, aucun événement de bouton et aucun
format d'image. Lors de ce premier relevé, `lsusb` n'a pas pu initialiser libusb
dans l'environnement d'analyse (`-99`) et aucun nœud `/dev/hidraw*` n'y était
exposé ; la lecture sysfs a fourni les descripteurs USB et HID. Les captures
usbmon C01–C03c et C02b décrites ci-dessous ont ensuite été réalisées sur l'hôte
Bazzite.
Le jalon J1 reste ouvert.

## Première capture usbmon locale du 27 septembre 2026

Une capture réalisée sur l'hôte Bazzite avec `dumpcap` sur `usbmon1` a recueilli
31 946 paquets, sans perte signalée. Le N1 était sur le bus 001 ; son adresse est
passée de `024` à `025` après reconnexion. Le fichier brut
`C01-init-stream.pcapng` a été conservé hors du dépôt, dans
`/tmp/opendeck-vsd-n1-captures/`.

L'analyse filtrée sur le bus 1 et l'adresse 25 montre les échanges d'énumération
et de contrôle, mais aucun transfert sur les endpoints candidats de l'interface
0 (`0x82` IN et `0x03` OUT). Elle ne révèle donc aucune commande applicative.
L'état de VSD Craft pendant cette capture n'ayant pas été consigné, ce silence
ne permet pas de conclure si le logiciel était connecté au N1. Vérifier son état
et provoquer explicitement une action avant d'interpréter une capture silencieuse.

`usbmon1` capture le bus entier. Le fichier brut peut donc contenir du trafic
d'autres appareils USB ; conserver les originaux localement et filtrer par bus
et adresse avant de partager un extrait. L'adresse USB peut changer à chaque
reconnexion. Cette capture ne valide ni l'initialisation applicative, ni les
événements de bouton, ni le transfert d'image ; le jalon J1 reste ouvert.

## Capture de boutons locale C02 du 27 septembre 2026

VSD Craft a été lancé avec Proton et l'opérateur confirme qu'il fonctionne avec
le N1. La version de Proton, le préfixe Wine et l'ordre des actions physiques
n'ont pas été notés. Une seconde capture sur `usbmon1` a recueilli 61 373 paquets,
sans perte signalée. Le fichier `C02-buttons-stream.pcapng` reste dans
`/tmp/opendeck-vsd-n1-captures/`, hors du dépôt.

Filtrée sur le bus 1 et l'adresse 25, cette trace montre le trafic applicatif sur
l'interface 0 : environ 12 042 transferts sortants de 1 024 octets sur `0x03`,
ainsi que des réponses entrantes de 512 octets sur `0x82`. Les rapports sortants
contiennent les marqueurs `DIS`, `LIG`, `QUCMD`, `BAT`, `STP`, `CLE`, `MOD` et
`CONNECT`. La capture contient aussi des blocs JPEG/JFIF `ff d8 ff e0` ; C03c
permettra d'associer deux d'entre eux aux images de test.

Les premières commandes applicatives apparaissent à 34,389 s : `DIS`, `LIG`
avec les données `00 00 41`, `QUCMD 1f 11`, puis un second `LIG` avec la même
valeur. Dans `mirajazz 0.16.2`, `LIG 00 00 <valeur>` est la commande de luminosité
de l'écran ; le trafic a donc la forme de `set_brightness(65)`. Cette
correspondance de données ne constitue pas une mesure de luminosité physique.
La première commande `BAT` apparaît à 34,568 s : elle annonce `0x1343` octets
pour la cible `0x12`, puis un `STP` suit à 34,569 s.
Deux commandes `CLE 00 00 00 ff` suivent à 34,647 s ; le code de la bibliothèque
utilise la cible `0xff` pour l'effacement global. À 35,408 s, `MOD 00 00 33`
correspond à son encodage du mode 3. Un `CONNECT` à 44,427 s a la même commande
que `keep_alive`, mais cette capture ne valide pas une cadence périodique.
`QUCMD 1f 11` n'a pas été retrouvée dans la source étudiée et reste inexpliquée.

Les réponses observées commencent par `ACK\0\0OK\0\0`. Une réponse contient les
octets `aa ff`. Dans les quatre réponses suivantes, l'octet d'indice 9 vaut
`0x0f` ou `0x0d`, et celui d'indice 10 vaut successivement `01` puis `00` :
`0x0f` à environ 40,823 s et 41,043 s, puis `0x0d` à environ 42,221 s et
42,401 s depuis le début de la capture. Cette disposition correspond à la
lecture d'entrée de `mirajazz 0.16.2`, qui utilise `data[9]` comme identifiant et
`data[10]` comme état lorsque la variante prend en charge appui et relâchement.
Les paires sont compatibles avec ces transitions, mais les positions physiques
n'ont pas été consignées et les autres champs de la réponse restent à vérifier.
Le trafic confirme que VSD Craft sous Proton échange avec l'interface candidate
du N1 ; il ne suffit pas à lui seul à déterminer la disposition ou toutes les
capacités du N1. Le jalon J1 reste ouvert.

Les codes `0x0f` et `0x0d` observés dans ces rapports entrants réapparaissent
comme cibles d'image dans les trames `BAT` de C03c. La capture C02c décrite
ci-dessous les associe aux 15e et 13e touches de la grille ; les cibles d'image
et les événements de bouton partagent donc cet espace d'identifiants.

## Capture de boutons standard locale C02b du 27 septembre 2026

La capture `C02b-button-map-stream.pcapng`, conservée hors du dépôt dans
`/tmp/opendeck-vsd-n1-captures/`, contient 18 390 paquets sur 25,855723 secondes,
sans perte signalée. Le N1 `5548:1002` était sur le bus 1 à l'adresse 26 ; cette
adresse a changé depuis C02. Les rapports HID produits par la séquence d'actions
sont reçus sur l'interface clavier standard 1, endpoint `0x81` IN.

Cette interface a fourni 17 rapports non nuls de 9 octets, chacun suivi d'un
rapport de relâchement nul. Les usages de touche capturés, dans leur ordre
chronologique, sont `53 57 56 5f 60 61 5c 5d 5e 59 5a 5b 62 63 58 55 54`.
L'opérateur indique avoir parcouru les boutons principaux, puis les boutons du
haut et enfin la molette ; les positions individuelles n'ont pas été consignées
avec la trace, et la correspondance de cette séquence avec les gestes reste à
confirmer.

C02b ne contient ni commande sortante sur l'endpoint interruptif `0x03`, ni
rapport de données entrant sur `0x82`. Elle ne montre donc pas le trafic
applicatif `CRT`/`ACK` observé en C02 et ne permet pas de relier ces usages
clavier aux identifiants `0x0d` et `0x0f` des réponses propriétaires. La capture
montre un chemin d'entrée distinct ; l'état de connexion de VSD Craft pendant
ce scénario est maintenant connu : l'opérateur confirme que VSD Craft était
fermé. L'absence de commandes `CRT` et de réponses `ACK` est donc attendue.

## Capture de boutons avec VSD Craft C02c du 27 septembre 2026

La capture `C02b-button-map-stream-vsd.pcapng` (nom fourni par l'opérateur),
conservée dans `/tmp/opendeck-vsd-n1-captures/`, contient 79 471 paquets sur
30,237566 secondes, sans perte signalée. Le N1 est sur le bus 1 à l'adresse 26.
Les échanges propriétaires sur `0x03` OUT et `0x82` IN confirment que VSD Craft
était actif et échangeait avec le contrôleur.

Les 44 rapports `ACK\0\0OK\0\0` non nuls relevés sur `0x82` encodent 15 paires
appui/relâchement, avec les IDs `0x01` à `0x0f` et les états `01` puis `00`,
puis trois paires de même forme pour les IDs `0x1e`, `0x1f` et `0x23`. L'opérateur
confirme avoir pressé les 15 touches de la grille ligne par ligne, de gauche à
droite puis de haut en bas. Les IDs `0x01` à `0x0f` correspondent donc à cet
ordre de lecture. L'opérateur confirme aussi avoir essayé, de gauche à droite,
les deux boutons séparés du haut puis le clic de la molette ; ils ont produit
`0x1e`, `0x1f` et `0x23` respectivement.

Les huit rapports restants portent tous l'ID `0x33` et l'état `00`, de 26,495 s
à 27,300 s. C02d montre que `0x33` est émis pendant une rotation horaire ; aucun
état `01` pour cet ID n'apparaît. Aucun rapport de clavier standard sur `0x81`
n'est relevé pendant cette capture avec VSD Craft ; cela contraste avec les
17 paires de touches de C02b, logiciel fermé.

## Capture de molette isolée C02d du 27 septembre 2026

La capture `C02d-wheel-isolated.pcapng`, conservée hors du dépôt dans
`/tmp/opendeck-vsd-n1-captures/`, contient 33 070 paquets sur 19,690990 secondes,
sans perte signalée. Le trafic propriétaire est sur le bus 1, adresse 26 ; il
contient 66 rapports `ACK` entrants sur `0x82`.

Un appui-relâchement `0x23/01` puis `0x23/00` apparaît entre 5,047 s et 6,414 s.
L'opérateur confirme qu'il s'agit du clic de molette. Les rotations produisent
20 rapports `0x32/00` (9,561–12,025 s) et 44 rapports `0x33/00` (8,869–9,246 s
puis 12,390–16,501 s). L'opérateur confirme avoir commencé par le sens horaire ;
la première série `0x33` suit cette action. `0x32` apparaît dans la phase de
rotation opposée, ce qui l'associe probablement au sens antihoraire ; la trace
contient ensuite de nouveaux rapports `0x33`. Les deux IDs de rotation restent
sans état `01` et sont donc des événements, non des transitions d'appui.

### Synthèse de la cartographie des commandes

| Commande physique | ID `ACK` | État observé | Niveau de preuve |
| --- | --- | --- | --- |
| Touches principales 1 à 15, de gauche à droite puis de haut en bas | `0x01` à `0x0f`, dans l'ordre | `01` appui, `00` relâchement | Confirmé par C02c et l'ordre donné par l'opérateur |
| Bouton séparé supérieur gauche | `0x1e` | `01` / `00` | Confirmé par la séquence C02c |
| Bouton séparé supérieur, deuxième dans l'ordre | `0x1f` | `01` / `00` | Confirmé par la séquence C02c |
| Clic de molette | `0x23` | `01` / `00` | Confirmé en C02d |
| Rotation horaire | `0x33` | Rapports événementiels `00` | Confirmé comme premier sens en C02d |
| Rotation antihoraire | `0x32` | Rapports événementiels `00` | Probable : apparaît dans la phase opposée en C02d |

Les IDs `0x32` et `0x33` décrivent des événements de rotation, pas des états
maintenus. C02d contient aussi des rapports `0x33` après les rapports `0x32` ;
la capture confirme le premier sens horaire, mais ne documente pas assez
finement les gestes pour lever toute ambiguïté sur chaque inversion.

## Capture d'images locale C03 du 27 septembre 2026

La capture déclarée pour les changements d'image a été faite avec VSD Craft sous
Proton, sur `usbmon1`, bus 001 et adresse 25. Le fichier
`C03-images-stream.pcapng`, conservé hors du dépôt dans
`/tmp/opendeck-vsd-n1-captures/`, fait 454 Mo. `capinfos` y relève environ
620 000 paquets sur 173,165 secondes.

Le trafic filtré comprend 246 002 rapports sortants de 1 024 octets sur
l'endpoint `0x03`. Aucun rapport de données entrant sur `0x82` n'a été relevé
dans ce scénario. Parmi les rapports sortants, 49 206 commencent par la signature
JPEG/JFIF `ff d8 ff e0`. Leur réassemblage jusqu'au marqueur JPEG de fin a produit
49 205 images complètes et une image incomplète ; les octets donnent 903 empreintes
SHA-256 distinctes. Un échantillon reconstitué à partir de trois rapports HID
consécutifs est une image JPEG/JFIF de 96 × 96 pixels, longue de 2 929 octets,
suivie de remplissage nul dans les 3 072 octets transférés.

Cette capture confirme des données JPEG de 96 × 96 pixels réparties entre
plusieurs rapports HID. L'opérateur précise que la touche modifiée était la
première case de la grille VSD Craft, en haut à gauche. Les noms des deux fichiers
source et les heures des changements ne sont pas connus ; leur accès est compliqué
par le chemin Windows présenté dans Proton. Le repère de grille ne suffit pas à
associer les JPEG reconstitués à cette touche ni à un code USB. La fréquence des
images dans la capture ne doit pas être assimilée au nombre d'images source, car
des contenus se répètent.
À ce stade, le format applicatif complet, le rôle des marqueurs `CRT` et la
correspondance des touches restent à déterminer ; la capture C03c plus récente
ci-dessous lève une partie de ces inconnues.

## Reprise C03b et correction de l'analyse du 27 septembre 2026

La capture `C03b-known-images.pcapng` a recueilli 148 865 paquets en 43,664
secondes sur `usbmon1`; elle est conservée hors du dépôt dans
`/tmp/opendeck-vsd-n1-captures/` et cible le bus 1, adresse 25. La première
analyse ne lisait que `usb.capdata` et avait donc ignoré la plupart des rapports :
Wireshark expose ici les données HID principalement dans `usbhid.data`.

Sur `0x03` OUT, la trace contient 58 919 soumissions et autant de complétions.
Chaque soumission porte un rapport de 1 024 octets, soit 60 333 056 octets au
total ; 58 868 rapports sont lus dans `usbhid.data` et les 51 autres dans
`usb.capdata`. Le réassemblage repère 11 785 JPEG/JFIF complets, dont 9 784
images de 96 × 96 pixels et 2 001 de 80 × 80 pixels. Les octets donnent 870
empreintes distinctes ; l'un de ces JPEG distincts n'a pas pu être décodé par
l'outil d'image.
Les dix premiers JPEG apparaissent pendant les 9 premières millisecondes, mais
des transmissions continuent jusqu'à la fin de la capture. L'ancienne conclusion
« dix images seulement, puis aucun trafic » était donc erronée.

L'opérateur précise avoir uniquement modifié les champs de l'éditeur. La capture
d'écran montre l'action « Boîte à Outils : Ouvrir », pas le parcours de changement
d'icône. La relecture des JPEG ne retrouve pas de correspondance convaincante
avec les rendus A/B identifiés ensuite en C03c. C03b ne permet donc pas d'établir
si la modification de ces champs déclenche un transfert d'image ; elle ne testait
pas le parcours « Change Icon ».

## Changement d'icône local C03c du 27 septembre 2026

La capture `C03c-icon-change.pcapng`, conservée hors du dépôt dans
`/tmp/opendeck-vsd-n1-captures/`, contient 115 988 paquets du bus USB 1. Elle
dure 34,133362 secondes. Sur le N1 à l'adresse 25, endpoint `0x03` OUT, elle
contient 46 055 soumissions et 46 070 complétions ; chaque soumission transporte
1 024 octets, soit 47 160 320 octets. L'extraction relève 9 212 marqueurs JPEG
de début et 9 211 marqueurs de fin ; 9 211 JPEG complets ont été réassemblés,
dont 9 210 décodés. Les flux complets donnent 870 empreintes SHA-256 distinctes.

Deux JPEG réassemblés correspondent aux images de référence après prise en compte
du cadrage agrandi et du bandeau de titre visible dans le rendu VSD : l'image A
est présente dans la trame 30 395 à 10,758222 secondes ; l'image B apparaît dans
la trame 55 069 à 17,583638 secondes. L'opérateur confirme avoir choisi A puis B
par « Change Icon » et les avoir vues successivement dans VSD Craft et sur le
N1. La touche ciblée est la première case, en haut à gauche, selon la capture
d'écran. C03c confirme donc que ce parcours transmet les images au N1 et modifie
son affichage.

Chaque image est précédée d'une trame `BAT`. Dans ces rapports, le marqueur
`CRT\0\0BAT\0` est suivi d'un octet nul supplémentaire `00`, d'une longueur JPEG sur deux
octets en ordre réseau (big-endian), d'une cible d'image sur un octet, puis de
remplissage. Pour A, les cinq octets qui suivent le marqueur sont `00 19 9a 01
00` : longueur `0x199a` (6 554 octets), cible `0x01`, puis remplissage nul. Les
6 554 octets JPEG suivants correspondent exactement à la longueur annoncée. Pour
B, la trame 55 067 porte `00 1b a7 01 00` : longueur `0x1ba7` (7 079 octets),
même cible `0x01`, et le JPEG suivant fait 7 079 octets. Une trame `STP` suit
chaque transfert A/B.

Cette structure correspond à l'en-tête construit par la fonction `send_image`
de `mirajazz 0.16.2` : longueur sur 16 bits big-endian, identifiant de touche
transmis comme `key + 1`, rapports d'image complétés, puis commande `STP` lors
de `flush`. Le code de la bibliothèque explique donc la forme des trames
observées, sans démontrer à lui seul la compatibilité du N1 avec l'initialisation,
la disposition ou le rendu d'image de cette variante.

Le couple cible `0x01` / première case en haut à gauche est donc établi sur cet
exemplaire. D'autres valeurs de cible, de `0x02` à `0x11`, apparaissent dans la
capture, mais leurs positions ne sont pas relevées. Les valeurs `0x0d` et `0x0f`
coïncident avec deux codes d'événement C02 ; leur correspondance physique reste
à vérifier. Cette capture ne valide ni l'initialisation, ni les boutons, ni
l'intégration OpenDeck ; J1 reste en cours.

## Images de référence utilisées sous Proton

Les fichiers choisis pendant la capture C03 initiale n'étant pas connus, ses
JPEG ne peuvent pas être associés à une source précise. Deux PNG de référence
utilisés ensuite en C03c sont disponibles dans [`test-assets/`](test-assets/) :

| Fichier | Dimensions | Repère visuel | SHA-256 |
| --- | --- | --- | --- |
| [`N1-test-A.png`](test-assets/N1-test-A.png) | 96 × 96 | Lettre A, quatre quadrants rouge, jaune, vert et bleu | `c628cd74d74d76343f4f67b58d1789e6038b88cd6be372066e1a3fb681f2d713` |
| [`N1-test-B.png`](test-assets/N1-test-B.png) | 96 × 96 | Lettre B, quatre quadrants violet, cyan, orange et gris clair | `be515d3cf626d84425fa5e840e79b39d4f65ce0274f509fb7312448accaec4c8` |

Dans le sélecteur Windows de VSD Craft lancé sous Proton, le dépôt est accessible
via la lettre `Z:` ; le chemin observé commence par `Z:/home/<utilisateur>`. Pour
ce clone, ouvrir ensuite
`Z:/home/<utilisateur>/forgesoftware/Projects/opendeck-vsd-n1/docs/test-assets/`
et choisir les fichiers par leur nom exact. Si le dépôt a été déplacé, adapter
le chemin jusqu'à `docs/test-assets` ; les deux noms restent fixes.

Lors de C03c, le clic droit sur la case supérieure gauche puis « Change Icon » a
permis de sélectionner A puis B. L'opérateur a confirmé l'affichage successif des
deux images dans VSD Craft et sur le N1. Le guide VSD décrit ce parcours générique,
mais ne documente ni l'encapsulation USB ni le comportement propre au N1.

## Dossier de preuves

Créer un dossier de session hors du dépôt pour les captures brutes. Conserver
avec chaque session les informations suivantes :

```text
Session / date / opérateur :
Modèle / révision / firmware / identifiant local de l'exemplaire :
OS / noyau / architecture :
VSD Craft / Wine ou Proton / méthode de lancement :
OpenDeck / mode natif ou Flatpak / version du plugin, si utilisé :
Outil de capture et version :
Bus / adresse USB / interfaces / chemins hidraw / usages :
État initial du contrôleur et applications ouvertes :
Scénario / fichier / empreinte SHA-256 :
Actions et horodatages :
Trames pertinentes / sens / endpoint / longueur / octets :
Observation / hypothèse / inconnues / essai de confirmation :
```

Accompagner les captures d'un schéma des commandes physiques et des images
sources utilisées. Numéroter les boutons selon leur position, indépendamment des
codes reçus. Garder une copie originale des traces ; documenter les filtres
utilisés pour les extraits partagés. Une capture de bus peut inclure d'autres
périphériques : limiter les extraits diffusés au matériel étudié.

## Scénarios à capturer séparément

Fermer OpenDeck et les autres clients du contrôleur pendant les captures de VSD
Craft. Pour chaque scénario, noter l'état initial, effectuer une seule opération
à la fois et répéter pour distinguer les champs constants des données variables.

| ID / fichier conseillé | Opération | Observation recherchée |
| --- | --- | --- |
| C00 / `00-repos.pcapng` | Contrôleur branché, logiciel fermé, puis repos de 30 secondes | Trafic spontané et état de référence |
| C01 / `01-init.pcapng` | Capturer avant le branchement et le lancement de VSD Craft, puis attendre 45 secondes | Énumération, commandes initiales, réponses et éventuel maintien de connexion |
| C02 / `02-boutons.pcapng` | Appuyer puis relâcher chaque bouton, cinq fois, avec pauses et positions notées | Codes, états, répétitions, interface utilisée et indexation |
| C02c / `C02b-button-map-stream-vsd.pcapng` | VSD Craft ouvert et N1 visible ; appuyer sur les touches principales ligne par ligne, puis sur les deux boutons du haut et cliquer la molette | Relier les IDs `ACK` aux commandes physiques |
| C02d / `C02d-wheel-isolated.pcapng` | Cliquer la molette, faire une rotation horaire puis antihoraire en séparant les gestes par des pauses | ID du clic, IDs et sens des rotations |
| C03 / `03-image.pcapng` | Changer uniquement l'image d'une touche ; alterner deux images distinctes | En-têtes, position, format, découpage, ordre, validation finale et orientation |
| C04 / `04-luminosite.pcapng` | Si disponible dans VSD Craft, sélectionner trois valeurs distinctes | Commande, échelle et réponse ; noter les valeurs exactes de l'interface |
| C05 / `05-options.pcapng` | Si présents, isoler appui maintenu, rotation/appui d'encodeur, veille et réveil | Capacités supplémentaires ; subdiviser en un fichier par fonction |

Pour C03, utiliser les images de référence ci-dessus et conserver leurs noms et
empreintes avec les heures de sélection. Refaire ensuite le changement sur une
autre position pour identifier le champ d'adresse. Une commande absente du
logiciel ou du matériel est consignée comme non observée.

## Capture sous Windows avec USBPcap

1. Disposer de Wireshark et USBPcap sur la machine où VSD Craft pilote le N1.
2. Identifier le contrôleur USB auquel le N1 est connecté et sélectionner
   l'interface USBPcap correspondante.
3. Démarrer la capture avant l'opération, notamment avant l'initialisation.
4. Exécuter un scénario, arrêter la capture et l'enregistrer avec ses notes.
5. Vérifier que les données des transferts sont présentes, puis isoler le
   périphérique par bus/adresse pour l'analyse. Relever à nouveau son adresse
   après chaque reconnexion.

Conserver les transferts de contrôle et les deux interfaces lors de l'acquisition
initiale. Un filtre fondé uniquement sur le VID/PID ne suffit pas à retrouver
tous les échanges, car ces champs ne figurent pas dans chaque transfert.
Voir la [procédure USB de Wireshark](https://wiki.wireshark.org/CaptureSetup/USB).

## Capture sur Bazzite avec usbmon

Cette voie suppose que VSD Craft sous Wine/Proton reconnaît réellement le N1 et
exécute les opérations choisies. Consigner la version et le préfixe utilisés.
Si cette condition échoue, utiliser Windows pour obtenir une référence ; une
capture silencieuse sous Proton ne permet pas de conclure sur le protocole.

Utiliser les outils de capture sur l'hôte Bazzite. Prévoir `lsusb`, `udevadm` et
`dumpcap` ; leur disponibilité et leurs droits sont à vérifier sur l'installation.
Les valeurs de session et de bus ci-dessous sont des exemples à remplacer.

```bash
N1_CAPTURE_DIR="$HOME/n1-captures/AAAA-MM-JJ-session01"
mkdir -p "$N1_CAPTURE_DIR"
lsusb -d 5548:1002
sudo lsusb -v -d 5548:1002 > "$N1_CAPTURE_DIR/usb-descriptors.txt"
sudo modprobe usbmon
sudo dumpcap -D
```

Identifier les nœuds HID associés au N1, puis relever chacun d'eux. Remplacer
`hidrawN` par le nœud réellement identifié ; ne pas choisir le premier nœud de la
machine. Répéter pour les différentes interfaces.

```bash
ls -l /dev/hidraw*
N1_HIDRAW='/dev/hidrawN'
udevadm info --attribute-walk --name="$N1_HIDRAW"
udevadm info --query=property --name="$N1_HIDRAW" > "$N1_CAPTURE_DIR/${N1_HIDRAW##*/}-udev.txt"
sudo cat "/sys/class/hidraw/${N1_HIDRAW##*/}/device/report_descriptor" > "$N1_CAPTURE_DIR/${N1_HIDRAW##*/}-report-descriptor.bin"
```

Décoder ces descripteurs pour relever usages, identifiants, tailles et types de
rapports. Conserver également l'association entre nœud HID et numéro d'interface.

Choisir `usbmonB` avec le numéro de bus relevé dans `lsusb` : par exemple
`Bus 003` correspond à `usbmon3`. Capturer un scénario, puis arrêter avec Ctrl+C.

```bash
N1_USBMON='usbmon3'
sudo dumpcap -i "$N1_USBMON" -s 0 -w - > "$N1_CAPTURE_DIR/01-init.pcapng"
```

La redirection crée le fichier avec l'utilisateur courant ; seul l'outil de
capture est élevé. Le paramètre `-s 0` demande la longueur maximale de capture
par défaut de `dumpcap`. Vérifier ensuite l'absence de troncature et de pertes,
en particulier pour les images. Renommer la sortie pour chaque scénario.
Références : [options de dumpcap](https://www.wireshark.org/docs/man-pages/dumpcap.html)
et [documentation usbmon](https://docs.kernel.org/usb/usbmon.html).

Ouvrir le fichier dans Wireshark. Un filtre d'affichage tel que
`usb.bus_id == 3 && usb.device_address == 5` doit être adapté au relevé réel ;
l'adresse peut changer après un branchement. Garder les échanges d'énumération
dans l'original. `usbmon` observe les transferts soumis à la pile USB ; associer
soumission et complétion d'une même URB pour éviter de les compter deux fois.

## Comparer à mirajazz

Le dépôt verrouille `mirajazz 0.16.2`. Les liens vers son code épinglé
[d'envoi et de commandes](https://github.com/4ndv/mirajazz/blob/v0.16.2/src/device.rs),
son [lecteur d'événements](https://github.com/4ndv/mirajazz/blob/v0.16.2/src/state.rs)
et son [tableau des variantes](https://github.com/4ndv/mirajazz/blob/v0.16.2/README.md)
permettent de comparer les octets à la version réellement utilisée. La
[documentation de mirajazz](https://github.com/4ndv/mirajazz#protocol-versions)
présente des variantes internes, issues de rétro-ingénierie :

| Variante | Repères documentés à comparer |
| --- | --- |
| `0` | Repli ancien choisi par la bibliothèque ; paquets de 512 octets, particularités de série et d'acquittement |
| `1` | Paquets de 512 octets ; absence des deux états physiques d'appui |
| `2` | Paquets de 1024 octets ; effacement particulier ; absence des deux états physiques d'appui |
| `3` | Paquets de 1024 octets ; états d'appui et de relâchement ; autres capacités selon le matériel |

Le code local attribue la variante `3` au **TreasLin N3**. Cette correspondance ne
décide pas celle du N1. Les observations C02/C03c présentent plusieurs
correspondances de trame avec cette bibliothèque, mais cela ne suffit pas à
attribuer une variante complète au N1.

| Élément comparé | Observation N1 | Code `mirajazz 0.16.2` | État |
| --- | --- | --- | --- |
| `DIS` et `LIG` C02 | `DIS`, puis deux `LIG 00 00 41` | `initialize` envoie `DIS` puis `LIG` à zéro ; `set_brightness(65)` envoie `LIG 00 00 41` | `DIS` et format de luminosité reconnus ; séquence différente de l'initialisation générique, effet non mesuré |
| `CLE`, `MOD` et `CONNECT` C02 | `CLE 00 00 00 ff`, `MOD 00 00 33`, `CONNECT` | Effacement global, `set_mode(3)`, `keep_alive` | Formes correspondantes ; effets physiques et cadence non mesurés |
| Sortie C02 `QUCMD` | `QUCMD 1f 11` | Non repérée dans le code étudié | Inconnue, à ne pas émettre sans validation |
| En-tête image | Octet nul supplémentaire `00`, longueur u16 big-endian, cible `01` pour la première case | `send_image` écrit une longueur u16 big-endian et la cible `key + 1` | Correspondance C03c pour la première case |
| Fin d'image | `STP` après chacune des deux images testées | `flush` envoie `STP` | Correspondance C03c A/B |
| Événement entrant | Réponse `ACK`; indices 9 et 10 portent `0f/0d` et `01/00` | Le lecteur de variante à deux états prend ID à l'indice 9 et état à l'indice 10 | Structure compatible ; positions N1 non établies |
| Format et dimensions | JPEG/JFIF observé ; C03 et C03b décodent du 96 × 96 et du 80 × 80 | Le N3 utilise par défaut JPEG 64 × 64 tourné de 90° | Différence à résoudre avant réemploi du rendu |

`QUCMD 1f 11` reste non documentée. Dans C02 et C03c, `usb.data_len` et la
charge utile HID exposée par Wireshark valent 1 024 octets. Le descripteur de
rapport de l'interface 0, relevé depuis sysfs plus haut, déclare un rapport de
sortie de 1 024 octets sans identifiant de rapport numéroté. `mirajazz` construit
un tampon hôte de 1 025 octets : l'API HIDRAW demande un octet initial `00` pour
le numéro de rapport, suivi des données. Comme le rapport de cette interface
n'est pas numéroté, ce préfixe hôte ne fait pas partie des 1 024 octets transmis
sur USB. Les longueurs observées sont donc cohérentes entre l'API hôte et le
bus. Les codes entrants `0x0d` et `0x0f`
ne sont pas acceptés par le décodeur de `src/inputs.rs` actuel. Les identifiants
de cible d'image observés vont de `0x01` à `0x11`, tandis que seule la cible
`0x01` a été reliée à une position physique. Ces écarts interdisent encore de
réutiliser sans adaptation le décodeur et la configuration du N3.

Pour chaque opération, rapprocher : interface et usage, sens, type de rapport,
en-tête, opcode, adresse de touche, longueur, charge utile, fragmentation,
acquittement, délai et effet physique. Pour les images, établir aussi format,
dimensions, rotation, miroir et commande de validation éventuelle. Distinguer
les limites USB, les rapports HID et les messages applicatifs.

Produire une table d'analyse avant de choisir la variante :

| Opération | Capture et trames | Interprétation | Correspondance mirajazz | Confirmation matérielle |
| --- | --- | --- | --- | --- |
| Initialisation | C01 : énumération et contrôle seulement ; C02 : `DIS`, `LIG 00 00 41`, `QUCMD`, `CLE`, `MOD`, `CONNECT` | `DIS` et les commandes connues ont des formes correspondantes ; `LIG` est un réglage à 65 ; `QUCMD` inconnue | Partielle | Échanges VSD Craft observés, mais initialisation OpenDeck non testée |
| Boutons et molette | C02b : 17 paires clavier sur `0x81`, logiciel fermé ; C02c : IDs `0x01`–`0x0f`, `0x1e`, `0x1f`, `0x23` dans l'ordre des gestes ; C02d : `0x23/01` puis `0x23/00`, 20 `0x32/00` et 44 `0x33/00` | IDs de grille ligne par ligne ; `0x1e`/`0x1f` pour les deux boutons du haut, `0x23` pour le clic de molette ; `0x33` horaire et `0x32` probablement antihoraire | Forte pour les 17 boutons et le clic, partielle pour le sens de rotation | C02c/C02d confirment les ACK avec VSD Craft actif ; confirmer le sens de `0x32` et les séquences complètes |
| Image d'une touche | C03c : `BAT`, longueur u16 BE, cible `0x01`, JPEG A/B, puis `STP` | Correspond à `send_image`/`flush`; cible `0x01` reliée à la première case | Forte pour ce parcours | Oui, confirmation de l'opérateur pour A puis B |
| Luminosité, si disponible | C02 : `LIG 00 00 41`, forme `set_brightness(65)` | Forme de commande reconnue ; les valeurs 0–100 sont prises en charge par la bibliothèque | Partielle | Effet physique non mesuré ; aucun changement de niveau comparé |

Une compatibilité démontrée permet de réutiliser la variante concernée. Des écarts
exigent une adaptation dédiée et des essais ciblés. Si les données restent
insuffisantes, poursuivre les captures et garder la prise en charge expérimentale.
