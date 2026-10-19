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
| traverse-town | 192.168.1.201 (Tailscale 100.69.175.18) | Hôte Proxmox VE |
| destiny-islands | 192.168.1.202 | Master Kubernetes (control-plane) |
| radiant-garden | 192.168.1.203 | Worker K8s 1 |
| twilight-town | 192.168.1.204 | Worker K8s 2 |
| gummi-workshop | 192.168.1.205 | VM Docker : Pi-hole (DNS), Gitea, runner CI |
| hundred-acre-wood | 192.168.1.206 | Pelican Panel + Wings + serveur Minecraft |
| gummi-ship | 192.168.1.207 | Control node : Ansible, Terraform, subnet router Tailscale |
| terraform-minimal | 192.168.1.210 | VM de test Terraform, actuellement éteinte, hors inventaire |
| ubuntu-cloud-template | ID Proxmox 9000 | Template cloud-init Ubuntu 24.04 |

Passerelle : `192.168.1.254` (correction — pas `.1`). DNS interne : Pi-hole sur `192.168.1.205`.

## Accès distant — Tailscale (subnet router)

En plus de l'accès direct à l'hôte Proxmox, `gummi-ship` fait office de **subnet router** : il annonce la route `192.168.1.0/24` sur le tailnet, ce qui rend tout le réseau local joignable depuis n'importe quel appareil connecté à Tailscale, pas seulement les machines ayant Tailscale installé dessus.

Points clés :
- Une route annoncée reste **« Awaiting Approval »** (donc inactive) tant qu'elle n'est pas approuvée manuellement dans la console d'admin Tailscale.
- Un réseau extérieur utilisant aussi `192.168.1.x` peut détourner le trafic hors du tunnel Tailscale — à tester en coupant le WiFi et en passant en 4G si un accès distant semble ne pas passer par le bon chemin.
- Les adresses `100.x.x.x` attribuées par Tailscale appartiennent à la plage CGNAT `100.64.0.0/10`, un `/32` par appareil.
- Noms `.home` résolus à distance via Tailscale : pas encore en place (piste identifiée : Split DNS Tailscale vers le Pi-hole).

## Sécurité SSH

SSH par clé uniquement (mots de passe désactivés) sur : `destiny-islands`, `radiant-garden`, `twilight-town`, `gummi-workshop`, `hundred-acre-wood` (via playbook Ansible), et `gummi-ship` (configuré à la main). Proxmox est en clé seule depuis le début du projet.

Prérequis commun à l'automatisation : `/etc/sudoers.d/anton-nopasswd` sur les VMs gérées par Ansible (contournement du bug `sudo-rs`, voir notes Ansible).

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

## TLS interne — cert-manager

Une CA auto-signée (`internal-ca-issuer`) génère les certificats HTTPS pour les services en `.home`. Pour éviter l'avertissement navigateur, la CA doit être installée dans le magasin de confiance de chaque appareil client (testé et validé sous Windows).

Les services exposés publiquement plus tard (site, serveur de jeu) utiliseront Let's Encrypt en parallèle — les deux CA coexistent sans conflit, chacune sur son périmètre.

## Démarrage automatique des VMs

| VM | Rôle | Ordre |
|---|---|---|
| gummi-workshop | Pi-hole, Gitea, runner CI | 1 |
| destiny-islands | Master K8s | 2 (délai le plus long, pour que l'API soit prête) |
| radiant-garden | Worker K8s | 3 |
| twilight-town | Worker K8s | 4 |
| hundred-acre-wood | Pelican / Wings / Minecraft | 5 |
| gummi-ship | Control node (Ansible, Tailscale) | 6 |

À l'arrêt, l'ordre est automatiquement inversé par Proxmox.

## Point de vigilance DNS
Les VMs issues du template cloud-init pointent par défaut vers un DNS public plutôt que le Pi-hole local, et ne résolvent donc pas les noms `.home` tant que ce n'est pas corrigé manuellement. Correction à appliquer systématiquement sur toute nouvelle VM clonée (sauf celle qui héberge Pi-hole elle-même).

## Notes / galères rencontrées

- **Connexion Ethernet obligatoire** : Proxmox ne gère pas le WiFi par défaut, contrairement à un live Linux classique — piège classique de débutant.
- **IP par défaut de l'installateur** : si aucun réseau n'est détecté au moment de l'installation (ex: pas encore d'Ethernet branché), Proxmox propose par défaut `192.168.100.2/24`, complètement déconnecté du vrai réseau local. Correction faite via `/etc/network/interfaces` + `systemctl restart networking`.
- **Certificat HTTPS auto-signé** : avertissement navigateur normal à la première connexion (`https://192.168.1.201:8006`), pas un vrai problème de sécurité en usage réseau local.