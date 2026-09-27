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
usbmon C01–C03 et C03b décrites ci-dessous ont ensuite été réalisées sur l'hôte Bazzite.
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
ainsi que des réponses entrantes de 512 octets sur `0x82`. Plusieurs rapports
sortants commencent par `CRT\0\0` et portent notamment les marqueurs ASCII
`BAT`, `STP`, `CLE`, `LIG`, `QUC`, `MOD`, `DIS` et `CON`. Leur sens reste
inconnu. Les données comprennent aussi des blocs commençant par la signature
JPEG/JFIF `ff d8 ff e0` ; leur réassemblage et leur association à une image source
ne sont pas établis.

Les réponses observées commencent par `ACK\0\0OK\0\0`. Une réponse contient les
octets `aa ff`. Deux autres codes apparaissent chacun avec les valeurs `01` puis
`00` : `0f` à environ 40,823 s et 41,043 s, puis `0d` à environ 42,221 s et
42,401 s depuis le début de la capture. Ces paires sont compatibles avec des
transitions d'appui et de relâchement, mais les positions physiques n'ont pas
été consignées et la sémantique des champs n'est pas confirmée. Le trafic
confirme que VSD Craft sous Proton échange avec l'interface candidate du N1 ; il
ne suffit pas encore à déterminer les commandes, les identifiants de touches ou
le format complet des images. Le jalon J1 reste ouvert.

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
Le format applicatif complet, le rôle des marqueurs `CRT` observés avec C02 et la
correspondance des touches restent à déterminer ; J1 reste ouvert.

## Reprise d'image locale C03b du 27 septembre 2026

Une nouvelle capture sur `usbmon1` a recueilli 148 865 paquets en 43,664 secondes,
sans perte signalée. Le fichier `C03b-known-images.pcapng` est conservé hors du
dépôt dans `/tmp/opendeck-vsd-n1-captures/`. Elle cible le bus 1, adresse 25.
Sur `0x03` OUT, la trace contient 58 919 soumissions et autant de complétions ;
seules 51 soumissions portent une charge utile, toutes dans les 9,119 premières
millisecondes. Elles totalisent 52 224 octets.

Ces charges utiles contiennent dix JPEG complets de 96 × 96 pixels, entre 2 891
et 2 997 octets. Leur aperçu correspond aux icônes déjà présentes dans la grille
(illustrations, touches colorées et chiffre `1`). Aucun ne correspond aux images
de référence `N1-test-A.png` et `N1-test-B.png`. Aucun transfert de données sur
`0x82` IN n'a été observé. Après les dix premières millisecondes, la capture ne
contient plus de charge utile applicative de l'interface candidate.

C03b ne confirme donc pas l'envoi des deux nouvelles images : elle documente
seulement le chargement initial de la grille déjà configurée. La trace seule ne
permet pas de savoir si les sélections A/B ont été appliquées dans VSD Craft ni
si une commande distincte est nécessaire pour envoyer la configuration. J1 reste
ouvert.

## Images de référence pour reprendre C03 sous Proton

Les fichiers choisis pendant C03 n'étant pas connus, les JPEG de cette capture
ne peuvent pas encore être associés à une source précise. Pour une nouvelle
capture, deux PNG de référence sont disponibles dans [`test-assets/`](test-assets/) :

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

Pour cette reprise, démarrer une nouvelle capture avant tout changement. Sur la
case supérieure gauche déjà ciblée, sélectionner A, attendre deux secondes et
noter l'heure, puis sélectionner B, attendre deux secondes et noter à nouveau
l'heure. Garder le chemin et le nom de chaque source avec la capture, et vérifier
l'image affichée dans VSD Craft avant de passer à la suivante. Ces fichiers
facilitent l'identification et l'orientation des JPEG ; ils ne permettent pas,
à eux seuls, de déduire l'encapsulation ou le code USB de la touche.

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

La [documentation de mirajazz](https://github.com/4ndv/mirajazz#protocol-versions)
présente des variantes internes, issues de rétro-ingénierie :

| Variante | Repères documentés à comparer |
| --- | --- |
| `0` | Repli ancien choisi par la bibliothèque ; paquets de 512 octets, particularités de série et d'acquittement |
| `1` | Paquets de 512 octets ; absence des deux états physiques d'appui |
| `2` | Paquets de 1024 octets ; effacement particulier ; absence des deux états physiques d'appui |
| `3` | Paquets de 1024 octets ; états d'appui et de relâchement ; autres capacités selon le matériel |

Le code local attribue la variante `3` au **TreasLin N3**. Cette correspondance ne
décide pas celle du N1. Comparer au code de la version `0.16.2` verrouillée dans le
dépôt, et consigner toute autre version étudiée.

Pour chaque opération, rapprocher : interface et usage, sens, type de rapport,
en-tête, opcode, adresse de touche, longueur, charge utile, fragmentation,
acquittement, délai et effet physique. Pour les images, établir aussi format,
dimensions, rotation, miroir et commande de validation éventuelle. Distinguer
les limites USB, les rapports HID et les messages applicatifs.

Produire une table d'analyse avant de choisir la variante :

| Opération | Capture et trames | Interprétation | Correspondance mirajazz | Confirmation matérielle |
| --- | --- | --- | --- | --- |
| Initialisation | C01, bus 1/adresse 25 : énumération et contrôle seulement ; aucun transfert sur `0x82`/`0x03` | Aucun échange applicatif observé ; état de VSD Craft non consigné | À comparer | Non effectuée |
| Boutons | C02 : réponses `ACK\0\0OK\0\0` avec codes `0x0f` et `0x0d`, valeurs `01` puis `00` | Paires compatibles avec appui/relâchement ; positions et champs non confirmés | À comparer | Non effectuée |
| Image d'une touche | C03 : JPEG/JFIF 96 × 96 réassemblé depuis trois rapports de 1 024 octets ; case supérieure gauche ciblée. C03b : dix JPEG initiaux, aucun des deux fichiers tests | Trames JPEG observées ; C03b ne confirme pas l'envoi de A/B ; code USB de la touche et sémantique de l'encapsulation non établis | À comparer | Non effectuée |
| Luminosité, si disponible | À renseigner | Inconnue | À comparer | Non effectuée |

Une compatibilité démontrée permet de réutiliser la variante concernée. Des écarts
exigent une adaptation dédiée et des essais ciblés. Si les données restent
insuffisantes, poursuivre les captures et garder la prise en charge expérimentale.
