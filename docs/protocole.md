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
usbmon C01–C03c décrites ci-dessous ont ensuite été réalisées sur l'hôte Bazzite.
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
`CONNECT`. Les noms `DIS`, `CLE`, `MOD`, `CONNECT`, `BAT` et `STP` correspondent
à des commandes implémentées dans `mirajazz 0.16.2` ; la comparaison détaillée
est plus bas. `LIG` apparaît avec un octet `0x41` dans son champ de données,
dont la signification reste inconnue. La commande `QUCMD` suivie de `1f 11` n'a
pas été retrouvée dans cette version de la bibliothèque. La capture contient
aussi des blocs JPEG/JFIF `ff d8 ff e0` ; C03c permettra d'associer deux d'entre
eux aux images de test.

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
comme cibles d'image dans les trames `BAT` de C03c. Cette coïncidence suggère
un espace d'identifiants commun, mais ne permet pas d'associer ces deux codes à
des positions physiques : l'ordre des actions C02 n'a pas été noté.

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

Le dépôt verrouille `mirajazz 0.16.2`. Les liens vers son
[code d'envoi et de commandes](https://docs.rs/crate/mirajazz/0.16.2/source/src/device.rs),
son [lecteur d'événements](https://docs.rs/crate/mirajazz/0.16.2/source/src/state.rs)
et son [tableau des variantes](https://docs.rs/crate/mirajazz/0.16.2/source/README.md)
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
| Sorties C02 | `DIS`, `CLE`, `MOD`, `CONNECT`, `BAT`, `STP` | Commandes portant ces marqueurs dans `device.rs` | Correspondance des noms ; ordre complet et effets N1 encore à qualifier |
| Sortie C02 `LIG` | Champ contenant `0x41` | Initialisation générique présente dans la bibliothèque | Valeur et sémantique N1 à comparer en détail |
| Sortie C02 `QUCMD` | `QUCMD 1f 11` | Non repérée dans le code étudié | Inconnue, à ne pas émettre sans validation |
| En-tête image | Octet nul supplémentaire `00`, longueur u16 big-endian, cible `01` pour la première case | `send_image` écrit une longueur u16 big-endian et la cible `key + 1` | Correspondance C03c pour la première case |
| Fin d'image | `STP` après chacune des deux images testées | `flush` envoie `STP` | Correspondance C03c A/B |
| Événement entrant | Réponse `ACK`; indices 9 et 10 portent `0f/0d` et `01/00` | Le lecteur de variante à deux états prend ID à l'indice 9 et état à l'indice 10 | Structure compatible ; positions N1 non établies |
| Format et dimensions | JPEG/JFIF observé ; C03 et C03b décodent du 96 × 96 et du 80 × 80 | Le N3 utilise par défaut JPEG 64 × 64 tourné de 90° | Différence à résoudre avant réemploi du rendu |

La capture C02 relève aussi `LIG` deux fois au démarrage et un échange
`QUCMD 1f 11` qui reste non documenté. Les codes entrants `0x0d` et `0x0f`
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
| Initialisation | C01 : énumération et contrôle seulement ; C02 : marqueurs `DIS`, `LIG`, `QUCMD`, `CLE`, `MOD`, `CONNECT` | Plusieurs marqueurs existent dans `mirajazz`; valeur `LIG` et sens de `QUCMD` inconnus | Partielle | Échanges VSD Craft observés, mais initialisation N1 non reproduite |
| Boutons | C02 : réponses `ACK\0\0OK\0\0`, ID `0x0f`/`0x0d` à l'indice 9 et état `01`/`00` à l'indice 10 | Structure compatible avec le lecteur d'entrée à deux états | Partielle | L'opérateur a vu ces états dans la capture ; positions physiques non consignées |
| Image d'une touche | C03c : `BAT`, longueur u16 BE, cible `0x01`, JPEG A/B, puis `STP` | Correspond à `send_image`/`flush`; cible `0x01` reliée à la première case | Forte pour ce parcours | Oui, confirmation de l'opérateur pour A puis B |
| Luminosité, si disponible | À renseigner | Inconnue | À comparer | Non effectuée |

Une compatibilité démontrée permet de réutiliser la variante concernée. Des écarts
exigent une adaptation dédiée et des essais ciblés. Si les données restent
insuffisantes, poursuivre les captures et garder la prise en charge expérimentale.
