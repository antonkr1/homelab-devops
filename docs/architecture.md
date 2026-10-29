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

Cluster monté « à la main » via **kubeadm** plutôt qu'une distribution allégée type k3s, pour comprendre chaque composant en profondeur.

- **Container runtime** : containerd
- **CNI (réseau des pods)** : Calico
- **Ingress** : ingress-nginx (chart Helm, déployé par ArgoCD)
- **Load balancer** : MetalLB (chart Helm, déployé par ArgoCD)

## Réseau

- Connexion Ethernet obligatoire (Proxmox ne gère pas le WiFi) : serveur à l'étage relié à la box via kit CPL + switch TP-Link TL-SG105
- Plage DHCP de la box : 192.168.1.1 à 192.168.1.200
- Plage réservée aux IP fixes du homelab : 192.168.1.201 – 253, dont le pool MetalLB `.230 – .240` (voir [network.md](network.md))
- Accès SSH par clé uniquement, sans mot de passe

### Flux d'une requête

```
Navigateur → Pi-hole (résolution de pom.home) → 192.168.1.230 (MetalLB)
          → ingress-nginx → Service → Pods
```

Depuis l'extérieur : Tailscale → subnet router `gummi-ship` → même chemin.

## Couches applicatives sur le cluster Kubernetes

- **CI/CD** : GitHub Actions → GHCR → ArgoCD (GitOps, sur le cluster). ArgoCD surveille le dossier `apps/<nom>` de ce dépôt.
- **Réseau cluster** : MetalLB (pool `192.168.1.230 – 240`, mode L2) donne l'IP `192.168.1.230` à ingress-nginx.
- **DNS local** : Pi-hole (sur `gummi-workshop`), résolution des `.home` ; split DNS Tailscale pour y accéder à distance.
- **Observabilité** : Prometheus + Grafana (Helm, namespace `monitoring`) + Loki/Promtail (Helm, même namespace). Grafana est accessible sur `https://grafana.home`.
- **Sécurité** :
  - Vault (Helm, mode persistant) : secrets centralisés sous `homelab/` (KV v2)
  - cert-manager + CA interne auto-signée : TLS pour les services `.home`, coexistera avec Let's Encrypt pour les futurs services exposés publiquement
  - Network Policies (Calico) : restriction du trafic pod-à-pod, seul l'Ingress peut atteindre les services applicatifs
  - 2FA (TOTP) sur l'interface web Proxmox
- **Stockage** : `local-path-provisioner`, StorageClass par défaut du cluster
- **Apps hébergées** : PoMAssistant (Vue 3 / Supabase, image sur GHCR, HTTPS via CA interne sur `https://pom.home`)

## Flux GitOps

```
Push sur main ou dev (GitHub)
   → GitHub Actions : build de l'image Docker + push sur GHCR
   → ArgoCD détecte le changement dans apps/<nom> (polling ~3 min, ou refresh manuel)
   → Synchronisation automatique sur le cluster
```

Applications gérées par ArgoCD :

| Application | Source | Rôle |
|---|---|---|
| pomassistant | `apps/pomassistant` | Application |
| metallb | chart Helm 0.15.2 | Services LoadBalancer |
| metallb-config | `apps/metallb-config` | Pool d'IP, mode L2 |
| ingress-nginx | chart Helm 4.15.1 | Contrôleur d'ingress |
| monitoring-ingress | `apps/monitoring-ingress` | Accès Grafana |
| argocd-ingress | `apps/argocd-ingress` | Accès ArgoCD |

Les `Application` sont définies dans `cicd/argocd/` et appliquées une fois avec `kubectl apply`.