# Configuration réseau

## Topologie physique
```
Box internet (Freebox)
    └── Switch TP-Link TL-SG105
        └── Boîtier CPL n°1
    ⚡ liaison courant porteur (inter-étages) ⚡
        └── Boîtier CPL n°2
            └── Serveur Proxmox (traverse-town)
```

## Plages IP

| Plage | Usage |

| 192.168.1.1 – 192.168.1.200 | DHCP (box, appareils du quotidien) |
| 192.168.1.201 – 192.168.1.253 | Réservée aux IP fixes du homelab |
| 192.168.1.254 | Gateway de la box |

## Adressage du homelab

| Machine | IP | Rôle |
|---|---|---|
| traverse-town | 192.168.1.201 | Hyperviseur (Proxmox VE) |
| destiny-islands | 192.168.1.202 | Control plane Kubernetes (kubeadm) |
| radiant-garden | 192.168.1.203 | Nœud worker Kubernetes |
| twilight-town | 192.168.1.204 | Nœud worker Kubernetes |
| gummi-workshop | 192.168.1.205 | VM Docker (conteneurisation) |
| Réservé futurs services | 192.168.1.206 – 210 | — |

## Accès à l'interface Proxmox

https://192.168.1.201:8006


Certificat HTTPS auto-signé par défaut → avertissement navigateur normal (voir note plus bas). À corriger plus tard avec cert-manager (Phase 5) ou via les certificats HTTPS de Tailscale.

## Accès distant — Tailscale

Un VPN Tailscale est installé directement sur l'hôte Proxmox pour permettre l'accès au homelab depuis l'extérieur du réseau local, sans ouverture de port sur la box (pratique déconseillée pour l'interface d'admin d'un serveur).

- Installation : `curl -fsSL https://tailscale.com/install.sh | sh` puis `tailscale up`
- Accès depuis l'extérieur : `https://100.69.175.18:8006`
- Amélioration possible plus tard : activer MagicDNS + HTTPS Certificates dans l'admin Tailscale pour obtenir un vrai certificat HTTPS valide (plus d'avertissement navigateur)
- Approfondissement prévu en Phase 5 : WireGuard natif Proxmox, pour comprendre la configuration VPN "à la main" en complément de Tailscale

## Accès aux services du cluster

| Service | Adresse | Statut |
|---|---|---|
| Ingress HTTP | `http://192.168.1.202:30153` (ou `.203`/`.204`, NodePort identique sur les 3 nœuds) | ✅ fonctionnel |
| Ingress HTTPS | `https://192.168.1.202:31850` | ⏳ déployé, pas encore configuré |
| App de test (`auto-gw-report`) | via Ingress HTTP ci-dessus | ✅ validée de bout en bout |

Accès actuel via IP + port brut — un DNS local (Pi-hole) est prévu pour remplacer ça par un nom de domaine interne cohérent avec le thème du homelab (ex: `auto-gw-report.traverse-town.local`).

## DNS local — Pi-hole

Déployé en container sur `gummi-workshop` (192.168.1.205). Résout les noms en `.home` vers les IP internes du homelab, ex : 

destiny-islands.home → 192.168.1.202
gummi-workshop.home → 192.168.1.205

## Services Phase 4

| Service | Adresse | Rôle |
|---|---|---|
| Gitea | `http://gummi-workshop.home:3000` (ou `192.168.1.205:3000`) | Git self-hosted, dépôt `auto-gw-report` |
| Gitea SSH | port `2222` (décalé du port SSH natif de la VM) | Clone/push en SSH |
| ArgoCD | NodePort sur le cluster (443 → port custom) | Interface GitOps |

## Notes / galères rencontrées

- **Connexion Ethernet obligatoire** : Proxmox ne gère pas le WiFi par défaut, contrairement à un live Linux classique — piège classique de débutant.
- **IP par défaut de l'installateur** : si aucun réseau n'est détecté au moment de l'installation (ex: pas encore d'Ethernet branché), Proxmox propose par défaut `192.168.100.2/24`, complètement déconnecté du vrai réseau local. Correction faite via `/etc/network/interfaces` + `systemctl restart networking`.
- **Certificat HTTPS auto-signé** : avertissement navigateur normal à la première connexion (`https://192.168.1.201:8006`), pas un vrai problème de sécurité en usage réseau local.