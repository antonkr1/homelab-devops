# Configuration réseau

## Topologie physique
```
Box internet (Freebox)
    └── Switch TP-Link TL-SG105
        └── Boîtier CPL n°1
        └── Boîtier CPL n°2
            └── Serveur Proxmox (traverse-town)
```

## Plages IP

| Plage | Usage |
|---|---|
| 192.168.1.1 – 192.168.1.200 | DHCP (box, appareils du quotidien) |
| 192.168.1.201 – 192.168.1.229 | IP fixes du homelab (VMs) |
| 192.168.1.230 – 192.168.1.240 | Pool MetalLB (`.230` = ingress-nginx) |
| 192.168.1.241 – 192.168.1.253 | Réservée |
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
| ingress-nginx (MetalLB) | 192.168.1.230 | Point d'entrée HTTPS des applications du cluster |

Passerelle : `192.168.1.254`. DNS interne : Pi-hole sur `192.168.1.205`.

## Accès à l'interface Proxmox

https://192.168.1.201:8006

Certificat HTTPS auto-signé par défaut → avertissement navigateur normal. À corriger plus tard avec cert-manager ou via les certificats HTTPS de Tailscale.

## Accès distant — Tailscale

Tailscale permet d'accéder au homelab depuis l'extérieur sans ouvrir de port sur la box (pratique déconseillée pour une interface d'administration).

**Sur l'hôte Proxmox**
- Installation : `curl -fsSL https://tailscale.com/install.sh | sh` puis `tailscale up`
- Accès depuis l'extérieur : `https://100.69.175.18:8006`
- Amélioration possible : activer MagicDNS + HTTPS Certificates dans l'admin Tailscale pour obtenir un certificat valide (plus d'avertissement navigateur)
- Piste ultérieure : WireGuard natif Proxmox, pour comprendre la configuration VPN « à la main » en complément de Tailscale

**Subnet router — `gummi-ship`**

`gummi-ship` annonce la route `192.168.1.0/24` sur le tailnet : tout le réseau local devient joignable depuis un appareil connecté à Tailscale, même sans Tailscale installé sur la machine visée.

- Une route annoncée reste **« Awaiting Approval »** (inactive) tant qu'elle n'est pas approuvée dans la console d'admin Tailscale.
- Un réseau extérieur utilisant aussi `192.168.1.x` peut détourner le trafic hors du tunnel : en cas de doute, couper le WiFi et passer en 4G.
- Les adresses `100.x.x.x` appartiennent à la plage CGNAT `100.64.0.0/10`, un `/32` par appareil.

**Split DNS**

Le domaine `home` est envoyé vers le Pi-hole depuis la console Tailscale, donc les noms `.home` se résolvent aussi via le tailnet. Validé en local ; test depuis l'extérieur à faire.

## DNS local — Pi-hole

Déployé en container sur `gummi-workshop` (192.168.1.205). Résout les noms en `.home` vers les IP internes du homelab :

```
destiny-islands.home → 192.168.1.202
gummi-workshop.home  → 192.168.1.205
pom.home             → 192.168.1.230
grafana.home         → CNAME vers pom.home
argocd.home          → CNAME vers pom.home
```

**Point de vigilance** : les VMs issues du template cloud-init pointent par défaut vers un DNS public et ne résolvent pas les noms `.home` tant que ce n'est pas corrigé. À faire systématiquement sur toute nouvelle VM clonée, sauf celle qui héberge Pi-hole.

## Accès aux services du cluster

L'ingress-nginx est exposé en `LoadBalancer` par MetalLB (mode L2) sur **192.168.1.230**.

| URL | Service |
|---|---|
| `https://pom.home` | PoMAssistant |
| `https://grafana.home` | Grafana |
| `https://argocd.home` | ArgoCD |

Les NodePorts de l'ingress (30153 HTTP, 31850 HTTPS) restent ouverts en secours.

## Autres services

| Service | Adresse | Rôle |
|---|---|---|
| Gitea | `http://gummi-workshop.home:3000` (ou `192.168.1.205:3000`) | Git self-hosted |
| Gitea SSH | port `2222` (décalé du port SSH natif de la VM) | Clone/push en SSH |

## TLS interne — cert-manager

Une CA auto-signée (`internal-ca-issuer`) génère les certificats HTTPS des services en `.home`. Pour éviter l'avertissement navigateur, la CA doit être installée dans le magasin de confiance de chaque appareil client (testé sous Windows).

Les services exposés publiquement plus tard (site, serveur de jeu) utiliseront Let's Encrypt en parallèle : les deux CA coexistent, chacune sur son périmètre.

## Sécurité SSH

SSH par clé uniquement (mots de passe désactivés) sur : `destiny-islands`, `radiant-garden`, `twilight-town`, `gummi-workshop`, `hundred-acre-wood` (via playbook Ansible), et `gummi-ship` (configuré à la main). Proxmox est en clé seule depuis le début du projet.

Prérequis commun à l'automatisation : `/etc/sudoers.d/anton-nopasswd` sur les VMs gérées par Ansible (contournement du bug `sudo-rs`, voir notes Ansible).

## Démarrage automatique des VMs

| Ordre | VM | Rôle |
|---|---|---|
| 1 | gummi-workshop | Pi-hole, Gitea, runner CI |
| 2 | destiny-islands | Master K8s (délai le plus long, pour que l'API soit prête) |
| 3 | radiant-garden | Worker K8s |
| 4 | twilight-town | Worker K8s |
| 5 | hundred-acre-wood | Pelican / Wings / Minecraft |
| 6 | gummi-ship | Control node (Ansible, Tailscale) |

À l'arrêt, l'ordre est automatiquement inversé par Proxmox.

## Notes / galères rencontrées

- **Connexion Ethernet obligatoire** : Proxmox ne gère pas le WiFi par défaut, contrairement à un live Linux classique.
- **IP par défaut de l'installateur** : sans réseau détecté à l'installation, Proxmox propose `192.168.100.2/24`, déconnecté du vrai réseau local. Correction via `/etc/network/interfaces` + `systemctl restart networking`.
- **Certificat HTTPS auto-signé** : avertissement navigateur normal à la première connexion (`https://192.168.1.201:8006`), pas un vrai problème de sécurité en usage réseau local.