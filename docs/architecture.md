# Architecture

## Vue d'ensemble

```
┌─────────────────────────────────────────────┐
│ Serveur physique                            │
│ i5-9600KF · 32 Go RAM · SSD 1To             │
│ hostname: traverse-town                     │
└──────────────────────┬──────────────────────┘
                       │
         ┌─────────────▼────────────┐
         │ Proxmox VE (hyperviseur) │
         │ 192.168.1.201            │
         └─────────────┬────────────┘
         ┌─────────────┼─────────────┐
         │             │             │
   ┌─────▼─────┐ ┌─────▼─────┐ ┌─────▼─────┐
   │ VM master │ │ VM worker1│ │ VM worker2│
   │ Ubuntu +  │ │ Ubuntu +  │ │ Ubuntu +  │
   │ Kubernetes│ │ Kubernetes│ │ Kubernetes│
   │ (kubeadm) │ │ (kubeadm) │ │ (kubeadm) │
   │ .202      │ │ .203      │ │ .204      │
   └───────────┘ └───────────┘ └───────────┘
```


   ## Installation Kubernetes

Cluster monté "à la main" via **kubeadm** plutôt qu'une distribution allégée type k3s — choix assumé pour comprendre chaque composant en profondeur (voir [ADR 0002](decisions/0002-kubeadm-vs-k3s.md)).

- **Container runtime** : containerd
- **CNI (réseau des pods)** : Calico
- **Ingress** : nginx-ingress (à installer manuellement, k3s l'inclut par défaut mais pas kubeadm)

## Couches applicatives sur le cluster Kubernetes

- **CI/CD** : Gitea (dépôt Git self-hosted) + runner CI + ArgoCD (GitOps)
- **Observabilité** : Prometheus (métriques) + Grafana (dashboards) + Loki (logs)
- **Sécurité** : Vault (secrets), cert-manager (TLS auto)
- **Apps hébergées** : à définir (Nextcloud, Pi-hole, Jellyfin, blog perso...)

## Réseau

- Connexion Ethernet obligatoire (Proxmox ne gère pas le WiFi) — serveur à l'étage relié à la box via kit CPL + switch TP-Link TL-SG105
- Plage DHCP de la box : 192.168.1.1 à 192.168.1.200
- Plage réservée aux IP fixes du homelab : 192.168.1.201-253 (voir [network.md](network.md))
- Accès SSH par clé uniquement, pas de mot de passe (à mettre en place)

## Couches applicatives sur le cluster Kubernetes

- **CI/CD** : Gitea (self-hosted sur `gummi-workshop`, hors cluster) + Gitea Actions (runner dédié) + ArgoCD (GitOps, sur le cluster)
- **DNS local** : Pi-hole (sur `gummi-workshop`), résolution des `.home`
- **Observabilité** : Prometheus (métriques) + Grafana (dashboards) + Loki (logs) — à venir Phase 5
- **Sécurité** : Vault (secrets), cert-manager (TLS auto), 2FA Proxmox — à venir Phase 5
- **Apps hébergées** : `auto-gw-report` (Flask, image privée Docker Hub)

## Flux GitOps

```
Push sur Gitea (main)
   → Gitea Actions (runner dédié) : build image Docker + push Docker Hub
   → ArgoCD détecte le changement dans le dossier k8s/ du repo (polling ~3 min, ou refresh manuel)
   → Synchronisation automatique sur le cluster (namespace default)
```

## Décisions

Voir [decisions/](decisions/) pour le détail argumenté de chaque choix technique.