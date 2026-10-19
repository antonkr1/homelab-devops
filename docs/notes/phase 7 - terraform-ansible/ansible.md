# Notes — Ansible (configuration automatisée)

## Structure créée sur gummi-ship
```
~/ansible/
├── ansible.cfg        # config (host_key_checking off, timeouts augmentés)
├── inventory.ini      # liste des VMs du homelab, groupées par rôle
└── install-docker.yml # playbook d'installation Docker idempotent
```

Groupes définis dans l'inventaire : `docker_hosts` (gummi-workshop, hundred-acre-wood) et `k8s_cluster` (destiny-islands, radiant-garden, twilight-town).

## Playbook install-docker.yml
Reproduit en automatisé les étapes faites manuellement en début de projet sur `gummi-workshop` et `hundred-acre-wood` : mise à jour système, installation Docker via le script officiel, ajout de l'utilisateur au groupe `docker`, test `hello-world`. Idempotent — vérifie la présence de Docker avant d'agir, ne réinstalle rien si déjà présent.

## Problèmes rencontrés et résolus

**SSH entre gummi-ship et les VMs cibles** : nécessite la clé SSH de `gummi-ship` copiée sur chaque VM cible. Pour les nœuds où l'authentification par mot de passe est désactivée (cluster K8s), ajout manuel de la clé publique dans `authorized_keys`.

**Timeout sudo** (`Timeout waiting for privilege escalation prompt`) : causé par un bug de `sudo-rs` (la réimplémentation Rust de sudo désormais utilisée par défaut sur les versions récentes d'Ubuntu), pas un souci de configuration Ansible. Résolu en configurant un accès sudo sans mot de passe pour l'utilisateur, via un fichier dédié dans `/etc/sudoers.d/` — contournement du bug en plus d'être une pratique standard recommandée pour des hosts gérés par automatisation.

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