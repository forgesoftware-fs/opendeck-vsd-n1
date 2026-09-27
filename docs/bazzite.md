# Installation et diagnostic sur Bazzite

**Procédure préparatoire, non exécutée sur un N1.** Le dépôt fournit maintenant
un assemblage Linux et `40-opendeck-vsd-n1.rules`, mais aucune recette matérielle
n'a été exécutée. La règle sert aux investigations et ne valide pas le protocole.

## Prérequis à relever

- Version et architecture de Bazzite, noyau, session graphique active.
- Version d'OpenDeck et mode d'installation : natif ou Flatpak.
- Version, commit et empreinte de l'archive du plugin N1.
- Révision et firmware du contrôleur, identifiant USB confirmé par
  `lsusb -d 5548:1002`.
- Disponibilité de `udevadm` et `getfacl` pour examiner les droits.

Effectuer les opérations udev sur l'hôte Bazzite. Fermer VSD Craft et les autres
clients du contrôleur. Tester les installations native et Flatpak l'une après
l'autre, avec une seule instance d'OpenDeck active.

## Règle udev de développement

Le fichier [40-opendeck-vsd-n1.rules](../40-opendeck-vsd-n1.rules) contient la
règle suivante, à valider sur l'exemplaire :

```udev
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="5548", ATTRS{idProduct}=="1002", MODE="0660", TAG+="uaccess"
```

Cette règle reprend le mécanisme d'accès HID de la règle du projet d'origine,
limitée au couple USB `5548:1002`. Elle autorise les nœuds HID correspondants via les droits de session.
La sélection de l'interface du contrôleur appartient au plugin : cette règle
ne distingue pas à elle seule l'interface clavier.

Vérifier les ACL de la session locale active après reconnexion. Ajouter une
règle pour les nœuds USB bruts seulement si le backend retenu en démontre le
besoin, toujours limitée au N1.

## Installer une livraison validée

1. Récupérer `opendeck-vsd-n1.plugin.zip` et `40-opendeck-vsd-n1.rules` depuis la
   même livraison du fork. Vérifier leur version et les empreintes publiées.
2. Dans OpenDeck, ouvrir **Plugins → Install from file** et importer l'archive.
   Vérifier le nom Basicolor N1 / VSD N1 et l'absence d'erreur de chargement.
3. Depuis le dossier contenant la règle livrée, l'installer sur l'hôte :

   ```bash
   sudo install -m 0644 40-opendeck-vsd-n1.rules /etc/udev/rules.d/40-opendeck-vsd-n1.rules
   sudo udevadm control --reload-rules
   ```

4. Quitter complètement OpenDeck, débrancher puis rebrancher le N1.
5. Identifier à nouveau le nœud HID du contrôleur ; son numéro peut avoir changé.
   Relever ses attributs et ses droits en remplaçant `hidrawN` :

   ```bash
   N1_HIDRAW='/dev/hidrawN'
   udevadm info --attribute-walk --name="$N1_HIDRAW"
   getfacl "$N1_HIDRAW"
   test -r "$N1_HIDRAW" && test -w "$N1_HIDRAW"
   ```

   Confirmer `5548:1002` et l'interface choisie. Le dernier contrôle doit réussir
   depuis le terminal de l'utilisateur normal ; l'ouverture réelle sera
   confirmée par le journal du plugin.
6. Relancer OpenDeck sans élévation et exécuter la [recette](recette.md) :
   détection, boutons, image et reconnexion.

Cette séquence adapte l'[installation du plugin d'origine](https://github.com/4ndv/opendeck-akp03#installation).
Une installation réussie de l'archive ne prouve pas encore l'accès au matériel.

## Vérification supplémentaire pour Flatpak

Commencer par confirmer l'accès sur l'hôte. Identifier ensuite l'installation
OpenDeck réellement utilisée, sans supposer son identifiant :

```bash
flatpak --version
flatpak list --app --columns=application,name,version,installation
```

Remplacer la valeur suivante par l'identifiant relevé. Si deux installations du
même identifiant existent, préciser `--user` ou `--system` dans les commandes.

```bash
N1_FLATPAK_ID='IDENTIFIANT_OPENDECK_RELEVE'
flatpak info "$N1_FLATPAK_ID"
flatpak info --show-permissions "$N1_FLATPAK_ID"
flatpak override --user --show
flatpak override --user --show "$N1_FLATPAK_ID"
flatpak override --system --show
flatpak override --system --show "$N1_FLATPAK_ID"
```

Consigner les permissions déclarées et les éventuelles dérogations. Depuis le
même terminal où `N1_HIDRAW` désigne le nœud confirmé, examiner sa visibilité et
ses droits dans le bac à sable :

```bash
flatpak run --command=sh "$N1_FLATPAK_ID" -c 'ls -l "$1"; test -r "$1" && test -w "$1"' sh "$N1_HIDRAW"
```

L'accès udev sur l'hôte ne garantit pas l'exposition de `/dev/hidraw` dans
Flatpak. Les permissions USB et le portail USB décrits par Flatpak concernent
l'accès USB brut ; leur présence ne démontre pas l'accès HID attendu par ce
plugin. Voir les [permissions de périphériques Flatpak](https://docs.flatpak.org/en/latest/sandbox-permissions.html#device-access).

Si le nœud fonctionne sur l'hôte mais reste absent du bac à sable, un essai
ponctuel peut aider à isoler la cause. Quitter OpenDeck, puis lancer :

```bash
flatpak run --device=all "$N1_FLATPAK_ID"
```

Cet essai expose tous les périphériques pour ce lancement et doit être consigné
comme tel. Quitter l'application puis la relancer normalement termine cet
essai sans dérogation persistante. Une réussite dans cette configuration
n'établit pas le fonctionnement avec les permissions ordinaires. Les options
utilisées sont décrites dans la [référence des commandes Flatpak](https://docs.flatpak.org/en/latest/flatpak-command-reference.html).

Importer l'archive dans l'instance Flatpak si nécessaire, puis vérifier son
chargement et l'ouverture réelle du HID dans ses journaux. Exécuter toute la
recette avec les permissions retenues pour la livraison. Documenter la
configuration reproductible ou le blocage restant avant d'annoncer le support
Flatpak.

## Diagnostic

| Symptôme | Vérification suivante |
| --- | --- |
| Aucun `5548:1002` dans `lsusb` | Câble, port et identification physique de l'appareil |
| Périphérique USB présent, accès HID refusé sur l'hôte | Correspondance de la règle, reconnexion, ACL et session active |
| HID accessible, aucun candidat dans le plugin | VID/PID, usage page, usage, interface et numéro de série |
| Ouverture réussie, initialisation en erreur | Commandes héritées, protocole choisi, réponses et capture C01 |
| Appuis reçus sur de mauvaises positions | Table de correspondance N1 et distinction contrôleur/clavier |
| Image absente ou déformée | Format, dimensions, rotation, fragmentation et validation finale |
| Natif fonctionnel, Flatpak en échec | Visibilité HID, permissions, chargement du binaire et journaux Flatpak |
| Événement OpenDeck reçu, application non lancée | Chantier APP-01 du [cadrage](cadrage.md) |

## Retirer l'installation

Désinstaller le plugin N1 depuis OpenDeck. Retirer uniquement sa règle
`/etc/udev/rules.d/40-opendeck-vsd-n1.rules`, recharger les règles udev puis
rebrancher l'appareil. Si des dérogations Flatpak persistantes ont été ajoutées
pendant une investigation, rétablir leur état consigné avant l'essai.
