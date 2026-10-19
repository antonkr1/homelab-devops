# Roadmap

## Phase 0 — Préparation matérielle
- [x] Récupération/achat des pièces (CPU, RAM, PSU, SSD, boîtier)
- [x] Test individuel des pièces d'occasion (RAM, PSU)
- [x] Assemblage physique
- [x] Mise à jour BIOS carte mère
- [x] Activation de la virtualisation (VT-x) dans le BIOS

## Phase 1 — Matériel & OS
- [x] Installation de Proxmox VE
- [x] Configuration réseau (IP fixe : 192.168.1.201, via kit CPL)
- [x] VPN (Tailscale) pour accès à distance — avancé plus tôt que prévu, besoin d'accès externe pendant le montage du reste
- [x] Accès SSH sécurisé (clé, pas de mot de passe)
- [x] Premier snapshot de configuration de base

## Phase 2 — Conteneurisation Docker
- [x] Créer une VM Ubuntu Server dédiée
- [x] Installer Docker dessus
- [x] Dockeriser une première application perso
- [ ] Écrire un docker-compose pour un stack multi-conteneurs reporté, prévu avec une vraie app multi-services plus tard
- [x] Push des images sur un registry (Docker Hub ou registry perso)

## Phase 3 — Cluster Kubernetes (kubeadm, approche "hard way")
- [x] Créer les VMs (1 master + 2 workers) sous Proxmox
- [x] Installer containerd sur chaque nœud
- [x] Installer kubeadm, kubelet, kubectl sur chaque nœud
- [x] Initialiser le control plane (kubeadm init) sur le master
- [x] Installer un CNI (Calico)
- [x] Joindre les workers au cluster (kubeadm join)
- [x] Déployer une première app pour valider le cluster (`auto-gw-report`, image privée Docker Hub)
- [x] Configurer l'ingress manuellement (nginx-ingress, testé via NodePort HTTP)
- [x] HTTPS sur l'ingress (port NodePort 31850 déployé mais pas encore configuré)
- [x] DNS local (Pi-hole) pour remplacer l'accès IP+port brut par un nom de domaine interne

## Phase 4 — CI/CD & GitOps
- [x] Héberger Gitea
- [x] Mettre en place un pipeline CI (build + test + push image)
- [x] Installer ArgoCD
- [x] Premier déploiement en GitOps (push → sync auto)

## Phase 5 — Observabilité & sécurité
- [x] Déployer Prometheus + Grafana (Helm, kube-prometheus-stack)
- [x] Centraliser les logs avec Loki (Helm, loki-stack + Promtail)
- [x] Mettre en place Vault pour la gestion des secrets (Helm, mode persistant, KV v2)
- [x] TLS automatique avec cert-manager (CA interne auto-signée, usage `.home`)
- [x] Network policies de base (Calico, restriction trafic sur `auto-gw-report`)
- [ ] WireGuard natif Proxmox — approfondissement VPN une fois Tailscale déjà en place
- [x] 2FA sur l'interface web Proxmox (TOTP activé sur `root@pam`)

## Pelican / Minecraft
- [x] VM dédiée hundred-acre-wood créée (192.168.1.206) — isolée du reste pour un service exposé publiquement
- [x] Panel Pelican + Wings installés en docker-compose (K8s abandonné — bug connu/documenté de Pelican avec l'installateur web)
- [x] Serveur Minecraft (Paper) fonctionnel via Pelican
- [x] Domaine traverse-town.com acheté, redirection de port Freebox, SRV configuré
- [x] Connexion sans port (SRV) validée — fonctionnel depuis l'extérieur
- [ ] HTTPS sur Pelican Panel et Wings (actuellement HTTP simple, IP brute)

## Terraform / Ansible (provisioning automatisé)
- [x] VM control node gummi-ship créée (192.168.1.207)
- [x] Ansible + Terraform installés
- [x] Authentification Proxmox (API Token) configurée pour Terraform
- [x] Template cloud-init Ubuntu 24.04 créé (VM ID 9000)
- [x] Premier clonage automatisé validé (IP + clé SSH injectées automatiquement)
- [x] Premier playbook Ansible (install-docker.yml) — testé et idempotent sur gummi-workshop et hundred-acre-wood
- [x] Playbook Ansible pour le cluster k8s_cluster (containerd, kubeadm, kubelet, kubectl)

## Exploitation & résilience
- [x] Diagnostic d'un arrêt inexpliqué (coupure brutale volontaire, aucune panne matérielle)
- [x] Arrêt propre de toute l'infra (`shutdown-all.yml`, validé)
- [x] Démarrage automatique ordonné des VMs (`onboot-vms.yml`, validé après arrêt/rallumage complet)
- [x] Clé SSH du PC fixe autorisée sur les 5 VMs (`add-pc-key.yml`)
- [x] Clés d'hôte SSH régénérées sur les 3 nœuds K8s
- [x] DNS Pi-hole sur master, workers et hundred-acre-wood (gummi-workshop exclue volontairement)
- [x] `/etc/hosts` hérité des clones corrigé sur les 6 machines
- [x] `terraform-minimal` ne démarre plus seule (`on_boot = false`)
- [ ] Arrêt/démarrage complet des VMs pour activer l'agent QEMU (installé, activé côté Proxmox)
- [ ] BIOS : « Restore on AC Power Loss » = Power On
- [ ] Template Terraform / cloud-init : supprimer les clés d'hôte SSH, corriger `/etc/hosts` et le DNS au premier démarrage
- [ ] Playbook de contrôle de `/etc/hosts` (`lineinfile`)
- [ ] Clés Vault dans un gestionnaire de mots de passe, puis étudier l'auto-unseal
- [ ] Commiter les playbooks dans le dépôt
- [ ] Optionnel : onduleur (UPS)
- [ ] Reprise de l'hébergement de PoMAssistant (CI/CD Jenkins ou GitHub Actions ; RAM : 28 Go alloués sur 32 Go)

## Bonus / idées futures
- [ ] Héberger un vrai service utile (Nextcloud, Pi-hole, Jellyfin)
- [ ] Ansible pour automatiser le provisioning complet
- [x] Terraform pour la gestion des VMs Proxmox
- [ ] Explorer Talos Linux en remplacement d'Ubuntu Server
- [ ] Explorer k3s en comparaison, une fois kubeadm maîtrisé (comprendre ce que k3s automatise concrètement)