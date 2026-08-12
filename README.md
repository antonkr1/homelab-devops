# Homelab DevOps — Proxmox + k3s + GitOps

> Serveur maison monté à partir de pièces récupérées, utilisé comme terrain d'apprentissage DevOps/Kubernetes en conditions quasi réelles (cluster multi-nœuds, CI/CD, observabilité, sécurité).

## Objectif du projet

Monter un homelab complet, du matériel jusqu'à un cluster Kubernetes en production personnelle, en documentant chaque étape et chaque décision technique. Le but : développer des compétences DevOps concrètes et transférables au monde professionnel.

## Statut actuel

🚧 En cours — Phase 1 (matériel & OS)

## Architecture visée

```
Serveur physique
   └── Proxmox VE (hyperviseur)
         ├── VM 1 : Ubuntu Server → k3s (master)
         └── VM 2 : Ubuntu Server → k3s (worker)
              └── CI/CD (Gitea + ArgoCD)
              └── Observabilité (Prometheus + Grafana + Loki)
```

Voir [docs/architecture.md](docs/architecture.md) pour le détail.

## Matériel

Voir [docs/hardware-specs.md](docs/hardware-specs.md) pour la liste complète des composants et leur coût.

## Roadmap

Voir [ROADMAP.md](ROADMAP.md) pour le détail des phases et l'avancement.

## Décisions techniques

Chaque choix technique important (Proxmox vs bare-metal, k3s vs kubeadm, etc.) est documenté dans [docs/decisions/](docs/decisions/) au format ADR (Architecture Decision Record).

## Structure du repo

```
.
├── docs/                  # Documentation, architecture, specs matériel, ADRs
├── proxmox/               # Scripts/configs pour l'hyperviseur (Ansible à venir)
├── k3s/manifests/         # Manifests Kubernetes (apps, ingress, storage)
├── docker/                # Dockerfiles et docker-compose des applis dockerisées
├── cicd/                  # Pipelines CI + configuration ArgoCD (GitOps)
└── monitoring/            # Configuration Prometheus, Grafana, Loki
```

## Journal de bord

Ce README et la documentation associée sont mis à jour au fil du projet, pas rédigés a posteriori — l'idée est de garder une trace fidèle des décisions et des galères rencontrées.
