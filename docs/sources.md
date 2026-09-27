# Sources et portée des observations

Documentation préparée le 27 septembre 2026. Les pages en ligne peuvent évoluer ;
relever leur révision lors d'une future décision d'implémentation.

## Référence locale

Le dépôt a été examiné au commit
`10d183451807cc172fdf394bdd34f41a33fb52d3` (`0.11.0`). Le
[plan de développement](developpement.md) relie les constats à leurs fichiers.
Les versions réellement résolues sont dans [Cargo.lock](../Cargo.lock), et la
licence conservée est [LICENSE](../LICENSE).

## Références externes

| Source | Utilité | Limite |
| --- | --- | --- |
| [Plugin opendeck-akp03](https://github.com/4ndv/opendeck-akp03) | Provenance, appareils annoncés, installation et construction | Le support du TreasLin N3 ne démontre pas celui du N1 |
| [Règle udev d'origine](https://github.com/4ndv/opendeck-akp03/blob/main/40-opendeck-akp03.rules) | Exemple d'accès aux périphériques depuis Linux | Les identifiants et le périmètre doivent être adaptés |
| [Issue VSD N1, Companion, nº 30](https://github.com/bitfocus/companion-surface-mirabox-stream-dock/issues/30) | Relevé USB public pour `5548:1002` et ses deux interfaces HID | Observation d'un autre exemplaire, sans format de commandes établi |
| [VSDinside : Stream Dock Series Function Guide](https://www.vsdinside.com/es/blogs/tutorial/stream-dock-series-function-guide) | Parcours générique de changement d'icône : clic droit sur une touche, « Change Icon », puis image locale | Ne documente pas la confirmation ni le transfert USB propres au N1 |
| [Bibliothèque mirajazz](https://github.com/4ndv/mirajazz) | Familles de protocoles et principes de la bibliothèque | Les variantes sont internes ; comparer aussi au code de la version utilisée |
| Source épinglée [mirajazz v0.16.2 : commandes et images](https://github.com/4ndv/mirajazz/blob/v0.16.2/src/device.rs), [événements](https://github.com/4ndv/mirajazz/blob/v0.16.2/src/state.rs), [variantes](https://github.com/4ndv/mirajazz/blob/v0.16.2/README.md) | Comparaison des marqueurs `BAT`/`STP`, des commandes, des champs d'événement et des capacités annoncées | Décrit le code générique verrouillé dans ce dépôt, pas une qualification du Basicolor N1 |
| [Wireshark : capture USB](https://wiki.wireshark.org/CaptureSetup/USB) | Méthodes USBPcap et usbmon | Le bon bus et les données capturées doivent être vérifiés localement |
| [Noyau Linux : usbmon](https://docs.kernel.org/usb/usbmon.html) | Nature des traces et interfaces de capture Linux | Une trace incomplète ne décrit pas toute la charge utile |
| [Noyau Linux : API HIDRAW](https://docs.kernel.org/hid/hidraw.html) | Préfixe du numéro de rapport fourni par l'hôte et contenu des rapports HID non numérotés | Le descripteur de chaque interface et la longueur USB restent à vérifier localement |
| [Manuel dumpcap](https://www.wireshark.org/docs/man-pages/dumpcap.html) | Sélection d'interface, longueur capturée et fichier de sortie | Disponibilité et droits à vérifier sur Bazzite |
| [Permissions Flatpak](https://docs.flatpak.org/en/latest/sandbox-permissions.html) | Différence entre accès de l'hôte et exposition des périphériques | Les permissions USB ne prouvent pas l'accès à hidraw |
| [Commandes Flatpak](https://docs.flatpak.org/en/latest/flatpak-command-reference.html) | Inspection des installations, permissions et lancement de diagnostic | Consigner la version et la configuration effectivement testées |

## Règle de traçabilité

Associer chaque conclusion technique à l'un des éléments suivants : code et
version examinés, observation publiée, capture de l'exemplaire ou résultat de
recette. Conserver les hypothèses comme telles jusqu'à reproduction. Mettre à
jour le statut de prise en charge dans [l'index](README.md) uniquement avec les
preuves correspondantes.
