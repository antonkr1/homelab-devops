# Notes — Ansible (configuration automatisée)

## VM control node : gummi-ship
Création d'une VM dédiée (192.168.1.207, 2 Go RAM / 2 cœurs / 20 Go) pour piloter Ansible et Terraform vers le reste du homelab, pattern classique en DevOps (une machine centrale plutôt que son PC perso). Ansible ne tourne pas nativement sur Windows, d'où cette VM plutôt que WSL.

## Structure (`proxmox/ansible/` dans le dépôt)
```
ansible.cfg           # host_key_checking off, timeouts augmentés
inventory.ini         # VMs du homelab, groupées par rôle
install-docker.yml    # installation de Docker (idempotent)
nopassword-sudo.yml   # sudo sans mot de passe sur les VMs gérées
nopassword-policy.yml # SSH par clé uniquement (mots de passe désactivés)
add-pc-key.yml        # autorise la clé SSH du PC fixe sur les VMs
regen-hostkeys.yml    # régénère les clés d'hôte SSH des VMs clonées
qemu-agent.yml        # installe qemu-guest-agent
onboot-vms.yml        # ordre de démarrage des VMs dans Proxmox
shutdown-all.yml      # arrêt propre de toute l'infra
```

Groupes définis dans l'inventaire : `docker_hosts` (gummi-workshop, hundred-acre-wood) et `k8s_cluster` (destiny-islands, radiant-garden, twilight-town).

## Playbook install-docker.yml
Reproduit en automatisé les étapes faites manuellement en début de projet sur `gummi-workshop` et `hundred-acre-wood` : mise à jour système, installation Docker via le script officiel, ajout de l'utilisateur au groupe `docker`, test `hello-world`. Vérifie la présence de Docker avant d'agir, ne réinstalle rien si déjà présent.

## Playbooks d'exploitation
- **Arrêt propre** (`shutdown-all.yml`) : workers K8s → pause → master → VMs Docker → Proxmox (optionnel). Chaque étape exige une confirmation explicite en paramètre, sinon tout est `skipped`.
- **Démarrage automatique** (`onboot-vms.yml`) : pose l'ordre et les délais de démarrage de chaque VM dans Proxmox ; `gummi-workshop` (Pi-hole) démarre en premier. Idempotent : ne modifie que ce qui diffère.
- **Durcissement SSH** (`nopassword-policy.yml`) : SSH par clé uniquement, vérification que `PasswordAuthentication no` est bien actif.
- **VMs clonées** (`regen-hostkeys.yml`, `qemu-agent.yml`) : un clone garde les clés d'hôte SSH de l'original, elles sont régénérées pour obtenir une empreinte distincte par nœud.

## Problèmes rencontrés et résolus

**SSH entre gummi-ship et les VMs cibles** : nécessite la clé SSH de `gummi-ship` copiée sur chaque VM cible. Pour les nœuds où l'authentification par mot de passe est désactivée (cluster K8s), ajout manuel de la clé publique dans `authorized_keys`.

**Timeout sudo** (`Timeout waiting for privilege escalation prompt`) : causé par un bug de `sudo-rs` (la réimplémentation Rust de sudo désormais utilisée par défaut sur les versions récentes d'Ubuntu), pas un souci de configuration Ansible. Résolu en configurant un accès sudo sans mot de passe pour l'utilisateur, via un fichier dédié dans `/etc/sudoers.d/`.

## Résultat validé
```
PLAY RECAP
gummi-workshop     : ok=6  changed=2  unreachable=0  failed=0
hundred-acre-wood  : ok=6  changed=2  unreachable=0  failed=0
```
`changed=2` sur les deux VMs confirme l'idempotence : Docker étant déjà installé, seules les tâches réellement nécessaires ont produit un changement.

## Complémentarité Terraform + Ansible
Terraform crée l'infrastructure (VM clonée depuis template cloud-init en quelques secondes). Ansible configure ce qu'il y a dedans (Docker, etc.) de façon reproductible et idempotente, sur des VMs neuves ou déjà existantes.

## Prochaine étape
Écrire un playbook pour les nœuds `k8s_cluster` (containerd, kubeadm, kubelet, kubectl), reproduisant en automatisé le travail manuel initial de la Phase 3.