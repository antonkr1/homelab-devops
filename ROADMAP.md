# Roadmap

## Phase 0 — Préparation matérielle
- [x] Récupération/achat des pièces (CPU, RAM, PSU, SSD, boîtier)
- [ ] Test individuel des pièces d'occasion (RAM, PSU)
- [ ] Assemblage physique
- [ ] Mise à jour BIOS carte mère
- [ ] Activation de la virtualisation (VT-x) dans le BIOS

## Phase 1 — Matériel & OS
- [ ] Installation de Proxmox VE
- [ ] Configuration réseau (IP fixe / réservation DHCP)
- [ ] Accès SSH sécurisé (clé, pas de mot de passe)
- [ ] Premier snapshot de configuration de base

## Phase 2 — Conteneurisation Docker
- [ ] Dockeriser une première application perso
- [ ] Écrire un docker-compose pour un stack multi-conteneurs
- [ ] Push des images sur un registry (Docker Hub ou registry perso)

## Phase 3 — Cluster Kubernetes (k3s)
- [ ] Créer les VMs (1 master + 1-2 workers) sous Proxmox
- [ ] Installer k3s sur chaque nœud
- [ ] Déployer une première app sur le cluster
- [ ] Mettre en place l'ingress (Traefik/nginx)
- [ ] (Optionnel) MetalLB si plusieurs machines physiques

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

## Bonus / idées futures
- [ ] Héberger un vrai service utile (Nextcloud, Pi-hole, Jellyfin)
- [ ] Ansible pour automatiser le provisioning complet
- [ ] Terraform pour la gestion des VMs Proxmox
- [ ] Explorer Talos Linux en remplacement d'Ubuntu Server
