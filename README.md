# Homelab DevOps — Proxmox + Kubernetes (kubeadm) + GitOps

> Serveur maison monté à partir de pièces récupérées, utilisé comme terrain d'apprentissage DevOps/Kubernetes en conditions quasi réelles (cluster multi-nœuds, CI/CD, observabilité, sécurité). Kubernetes installé "à la main" via kubeadm plutôt qu'une distribution allégée, pour comprendre chaque composant en profondeur.

## Objectif du projet

Monter un homelab complet, du matériel jusqu'à un cluster Kubernetes en production personnelle, en documentant chaque étape et chaque décision technique. Le but : développer des compétences DevOps concrètes et transférables au monde professionnel.

## Statut actuel

Infrastructure opérationnelle : Proxmox, cluster Kubernetes (kubeadm) à 3 nœuds,
GitOps avec ArgoCD, observabilité, PKI interne, accès distant par Tailscale.

Application déployée : **PoMAssistant** (Vue 3 / Supabase), servie en HTTPS sur le réseau
local et via Tailscale. Chaîne : GitHub Actions → GHCR → ArgoCD.

Voir [ROADMAP.md](ROADMAP.md) pour le détail des phases.

## Architecture actuelle

```
Serveur physique (traverse-town) — 192.168.1.201
└── Proxmox VE (hyperviseur)
      │
      ├── Cluster Kubernetes (kubeadm)
      │     ├── destiny-islands  : control plane — 192.168.1.202
      │     ├── radiant-garden   : worker         — 192.168.1.203
      │     └── twilight-town    : worker         — 192.168.1.204
      │           └── ArgoCD, Prometheus, Grafana, Loki (répartis sur le cluster)
      │
      ├── gummi-workshop     : VM Docker — Gitea, Pi-hole — 192.168.1.205
      ├── hundred-acre-wood  : VM jeux — Pelican, Wings, Minecraft — 192.168.1.206
      └── gummi-ship         : VM control node — Terraform, Ansible — 192.168.1.207
```

Voir [docs/architecture.md](docs/architecture.md) pour le détail.

## Matériel

Voir [docs/hardware-specs.md](docs/hardware-specs.md) pour la liste complète des composants et leur coût.

## Réseau

Voir [docs/network.md](docs/network.md) pour la topologie réseau (CPL, plages IP) et l'accès distant via Tailscale.

## Roadmap

Voir [ROADMAP.md](ROADMAP.md) pour le détail des phases et l'avancement.

## Décisions techniques

Chaque choix technique important (Proxmox vs bare-metal, kubeadm vs k3s, etc.) est documenté dans [docs/decisions/](docs/decisions/) au format ADR (Architecture Decision Record).

## Structure du dépôt

homelab-devops/
├── apps/                    # Manifests déployés par ArgoCD (un dossier = une Application)
│   ├── pomassistant/        #   Deployment, Service, Ingress, NetworkPolicy
│   ├── metallb-config/      #   Pool d'IP
│   ├── monitoring-ingress/  #   Ingress Grafana
│   └── argocd-ingress/      #   Ingress ArgoCD
├── cicd/
│   └── argocd/              # Applications ArgoCD (appliquées une fois avec kubectl apply)
├── terraform/               # Provisionnement des VMs Proxmox
├── proxmox/ansible/         # Playbooks : Docker, arrêt/démarrage, clés SSH
├── docs/
│   ├── architecture.md
│   ├── network.md
│   ├── hardware-specs.md
│   └── notes/
├── monitoring/
├── ROADMAP.md
└── README.md

## Journal de bord

Ce README et la documentation associée sont mis à jour au fil du projet, pas rédigés a posteriori — l'idée est de garder une trace fidèle des décisions et des galères rencontrées.