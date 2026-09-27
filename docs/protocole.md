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

Sur l'exemplaire Basicolor, confirmer le VID/PID, les interfaces, les usages, les
identifiants de rapport, les tailles réelles des transferts et le rôle de chaque
interface. La sélection `0xFFA0:1` du code N3 reste une hypothèse pour le N1.

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

Pour C03, utiliser une image asymétrique avec repères de coins et conserver son
fichier d'origine. Refaire ensuite le changement sur une autre position pour
identifier le champ d'adresse. Une commande absente du logiciel ou du matériel
est consignée comme non observée.

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
| Initialisation | À renseigner | Inconnue | À comparer | Non effectuée |
| Boutons | À renseigner | Inconnue | À comparer | Non effectuée |
| Image d'une touche | À renseigner | Inconnue | À comparer | Non effectuée |
| Luminosité, si disponible | À renseigner | Inconnue | À comparer | Non effectuée |

Une compatibilité démontrée permet de réutiliser la variante concernée. Des écarts
exigent une adaptation dédiée et des essais ciblés. Si les données restent
insuffisantes, poursuivre les captures et garder la prise en charge expérimentale.
