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
- [ ] HTTPS sur l'ingress (port NodePort 31850 déployé mais pas encore configuré)
- [ ] DNS local (Pi-hole) pour remplacer l'accès IP+port brut par un nom de domaine interne

## Phase 4 — CI/CD & GitOps
- [ ] Héberger Gitea
- [ ] Mettre en place un pipeline CI (build + test + push image)
- [ ] Installer ArgoCD
- [ ] Premier déploiement en GitOps (push → sync auto)

## Phase 5 — Observabilité & sécurité
- [ ] Déployer Prometheus + Grafana
- [ ] Centraliser les logs avec Loki
- [ ] Mettre en place Vault pour la gestion des secrets
- [ ] TLS automatique avec cert-manager
- [ ] Network policies de base
- [ ] WireGuard natif Proxmox — approfondissement VPN une fois Tailscale déjà en place

## Bonus / idées futures
- [ ] Héberger un vrai service utile (Nextcloud, Pi-hole, Jellyfin)
- [ ] Ansible pour automatiser le provisioning complet
- [ ] Terraform pour la gestion des VMs Proxmox
- [ ] Explorer Talos Linux en remplacement d'Ubuntu Server
- [ ] Explorer k3s en comparaison, une fois kubeadm maîtrisé (comprendre ce que k3s automatise concrètement)