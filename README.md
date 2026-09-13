# Homelab DevOps — Proxmox + Kubernetes (kubeadm) + GitOps

> Serveur maison monté à partir de pièces récupérées, utilisé comme terrain d'apprentissage DevOps/Kubernetes en conditions quasi réelles (cluster multi-nœuds, CI/CD, observabilité, sécurité). Kubernetes installé "à la main" via kubeadm plutôt qu'une distribution allégée, pour comprendre chaque composant en profondeur.

## Objectif du projet

Monter un homelab complet, du matériel jusqu'à un cluster Kubernetes en production personnelle, en documentant chaque étape et chaque décision technique. Le but : développer des compétences DevOps concrètes et transférables au monde professionnel.

## Statut actuel

🚧 En cours — Phase 2 quasi terminée (conteneurisation Docker), Phase 3 (Kubernetes) à démarrer

- ✅ Serveur assemblé et fonctionnel (i5-9600KF, 32 Go RAM, SSD 1 To)
- ✅ Proxmox VE installé et accessible (hostname `traverse-town`, 192.168.1.201)
- ✅ Réseau configuré (Ethernet via kit CPL, IP fixe hors plage DHCP)
- ✅ Accès distant sécurisé via Tailscale
- ✅ SSH sécurisé par clé ed25519 uniquement
- ✅ VM Docker (`gummi-workshop`, 192.168.1.205) : première app Flask dockerisée et poussée sur Docker Hub
- 🚧 Prochaine étape : création des VMs Kubernetes (master + 2 workers), installation kubeadm

## Architecture visée
```
Serveur physique (traverse-town)
└── Proxmox VE (hyperviseur) — 192.168.1.201
      ├── VM master : Ubuntu Server → Kubernetes via kubeadm — 192.168.1.202
      ├── VM worker1 : Ubuntu Server → Kubernetes via kubeadm — 192.168.1.203
      └── VM worker2 : Ubuntu Server → Kubernetes via kubeadm — 192.168.1.204
            └── CI/CD (Gitea + ArgoCD)
            └── Observabilité (Prometheus + Grafana + Loki)
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

## Structure du repo

```
├── docs/                  # Documentation, architecture, specs matériel, réseau, ADRs
│   └── notes/             # Notes techniques et journal de bord au fil du projet
├── backups/config/        # Snapshots de configuration par hôte (ex: traverse-town/)
├── proxmox/               # Scripts/configs pour l'hyperviseur (Ansible à venir)
├── k8s/manifests/         # Manifests Kubernetes (apps, ingress, storage)
├── docker/                # Dockerfiles et docker-compose des applis dockerisées
├── cicd/                  # Pipelines CI + configuration ArgoCD (GitOps)
└── monitoring/            # Configuration Prometheus, Grafana, Loki
```

## Journal de bord

Ce README et la documentation associée sont mis à jour au fil du projet, pas rédigés a posteriori — l'idée est de garder une trace fidèle des décisions et des galères rencontrées.