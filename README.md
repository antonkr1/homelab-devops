# Homelab DevOps — Proxmox + Kubernetes (kubeadm) + GitOps

> Serveur maison monté à partir de pièces récupérées, utilisé comme terrain d'apprentissage DevOps/Kubernetes en conditions quasi réelles (cluster multi-nœuds, CI/CD, observabilité, sécurité). Kubernetes installé "à la main" via kubeadm plutôt qu'une distribution allégée, pour comprendre chaque composant en profondeur.

## Objectif du projet

Monter un homelab complet, du matériel jusqu'à un cluster Kubernetes en production personnelle, en documentant chaque étape et chaque décision technique. Le but : développer des compétences DevOps concrètes et transférables au monde professionnel.

## Statut actuel

🚧 En cours — Phases 1 à 5 terminées, projets annexes (Minecraft, provisioning automatisé) en cours

- ✅ Infrastructure complète : Proxmox, cluster Kubernetes 3 nœuds, CI/CD GitOps, observabilité, sécurité (voir ROADMAP.md pour le détail par phase)
- ✅ Serveur Minecraft (Pelican + Wings) accessible en local et depuis l'extérieur, sans port à préciser (nom de domaine + SRV)
- ✅ Provisioning automatisé : Terraform opérationnel (template cloud-init + clonage automatique de VM en quelques secondes), depuis une VM control node dédiée (`gummi-ship`)
- 🚧 En cours : Ansible (configuration post-provisioning), HTTPS pour Pelican/Wings (accès géré via Tailscale pour l'instant)

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
.
├── .gitea/workflows/      # Pipelines CI (Gitea Actions)
├── docs/
│   ├── decisions/         # ADR — décisions d'architecture structurantes
│   └── notes/             # Notes techniques et journal de bord par sujet
├── backups/config/        # Snapshots de configuration par hôte
├── proxmox/               # Scripts/configs pour l'hyperviseur
├── k8s/manifests/         # Manifests Kubernetes (apps, ingress, storage, cert-manager)
├── docker/                # Dockerfiles et docker-compose des applis
├── cicd/argocd/           # Manifestes ArgoCD (Application, config repo)
├── terraform/             # Configuration Terraform (provisioning VMs)
└── monitoring/            # Configuration Prometheus, Grafana, Loki
```

## Journal de bord

Ce README et la documentation associée sont mis à jour au fil du projet, pas rédigés a posteriori — l'idée est de garder une trace fidèle des décisions et des galères rencontrées.