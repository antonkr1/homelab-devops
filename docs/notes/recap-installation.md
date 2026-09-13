# Récap technique — Homelab DevOps (Proxmox + Kubernetes hard way)

## Phase 0-1 — Infrastructure de base

### Résolution du problème réseau critique
**Symptôme initial** : DNS et connectivité internet cassés sur Proxmox (`curl: Could not resolve host`, `ping: Destination Host Unreachable`).

**Cause racine (2 problèmes empilés)** :
1. **Mauvaise gateway** : le contexte projet indiquait `192.168.1.1`, mais la vraie passerelle Freebox est `192.168.1.254`. Sans la bonne route par défaut, aucun paquet ne sortait du réseau local.
2. **DNS invalide** : `/etc/resolv.conf` pointait vers `192.168.100.1`, une IP totalement hors de portée.

**Logique de diagnostic appliquée** (ordre important, du plus haut niveau réseau au plus bas) :
```
curl (DNS) → ping IP externe (routage) → ping gateway (L3 local) → ip route (config) → ip a (interface) → ip neigh (ARP/L2)
```
Ne jamais supposer qu'un problème est "juste DNS" sans vérifier la connectivité IP brute en premier.

**Correction appliquée** :
```bash
ip route add default via 192.168.1.254 dev vmbr0   # gateway corrigée
echo "nameserver 1.1.1.1" > /etc/resolv.conf         # DNS Cloudflare
```
Puis rendu permanent dans `/etc/network/interfaces` (gateway) — fichier lu au boot par Proxmox/Debian.

### Dépôts Proxmox (format `.sources`, Proxmox 8+)
Les dépôts `enterprise.proxmox.com` renvoient une 401 sans abonnement payant. Sur les versions récentes, la config est en `deb822` (`.sources`), pas `.list` — désactivation par **renommage** du fichier (`.sources.disabled`) plutôt que par édition, faute de ligne `Enabled:` dans ces fichiers-là. Basculé sur `pve-no-subscription`.

### Tailscale (VPN)
Installé sur l'hôte Proxmox pour un accès distant chiffré, indépendant du réseau local — utile une fois le serveur headless. IP Tailscale : `100.69.175.18`.

### SSH par clé
**Logique de sécurité appliquée, dans l'ordre strict** :
1. Générer la paire de clés (`ssh-keygen -t ed25519`) — **sur le PC client**, jamais sur le serveur
2. Copier la clé publique sur le serveur (`authorized_keys`)
3. **Tester** la connexion par clé, sans rien désactiver
4. **Sauvegarder** la clé privée à un 2e endroit
5. **Seulement après** validation des étapes 3 et 4 → désactiver `PasswordAuthentication` dans `sshd_config`

Cet ordre évite de se retrouver bloqué dehors si une étape échoue en cours de route. L'accès console Proxmox reste le filet de sécurité ultime en cas de casse totale de SSH.

**Point de vigilance non résolu** : le mot de passe de l'interface web Proxmox reste un accès équivalent root (bouton "Shell" intégré) — la sécurisation SSH ne protège pas contre une fuite de ce mot de passe. 2FA à activer en Phase 5.

### Sauvegarde de config (pas de vrai snapshot)
Hôte en **ext4** (pas ZFS) → pas de snapshot natif possible côté Proxmox. Palliatif : archive `tar.gz` des fichiers de config critiques modifiés (réseau, SSH, dépôts apt, DNS), copiée sur le PC via `scp` (hors du serveur, sinon la sauvegarde meurt avec le serveur en cas de crash disque).

---

## Phase 2 — Docker (VM dédiée)

### Pourquoi une VM séparée plutôt que Docker sur l'hôte Proxmox
Séparation hyperviseur / workloads : Proxmox ne doit gérer que les VMs, jamais faire tourner de containers lui-même — isolation en cas de crash/faille, cohérence avec l'architecture en VMs dédiées du reste du projet (comme les 3 VMs du futur cluster K8s).

### Points de blocage réseau typiques d'une VM clonée/fraîche
- Toujours vérifier la **gateway correcte** (`192.168.1.254`, pas `.1`) à chaque nouvelle install — erreur répétée plusieurs fois dans le projet
- Installation **Minimized** = pas de `nano` ni d'autres utilitaires de base par défaut, à installer manuellement

### Dockerisation de l'app Flask — erreur classique
**Symptôme** : app inaccessible depuis l'extérieur malgré le port mappé (`-p 8000:8000`).
**Cause** : `app.run()` sans `host='0.0.0.0'` fait écouter Flask uniquement sur `127.0.0.1` **à l'intérieur du container** — injoignable de l'extérieur même avec le bon port exposé.
**Fix** : `app.run(host='0.0.0.0', port=8000)`.

**Point de logique clé** : modifier le code source sur le disque de la VM ne suffit jamais — l'image Docker est figée au moment du `docker build`. Toute modif de code nécessite un cycle complet : édition → rebuild → stop/rm ancien container → run nouveau container.

### Docker Hub
Repo `antnk/auto-gw-report` poussé en **privé** (app jugée non représentative pour un portfolio). `docker tag` nécessaire avant push : le nom d'image doit être préfixé par le username Docker Hub (`antnk/nom_image:tag`) pour que Docker Hub sache où le ranger.

---

## Phase 3 — Cluster Kubernetes (kubeadm, hard way)

### Stratégie de création des VMs : créer-valider-cloner
Ordre choisi et pourquoi : créer le master, installer et **valider** containerd + kubeadm/kubelet/kubectl dessus, **puis seulement** cloner 2 fois pour les workers. Éviter de cloner une VM Docker existante (mauvais runtime pour du kubeadm) ou de refaire 3 installs manuelles identiques (répétition d'erreurs).

**Piège du clonage identifié et corrigé** :
- Le clone hérite de la **même adresse MAC virtuelle... non**, en réalité Proxmox change la MAC, mais le fichier netplan du clone référence encore l'**ancienne MAC** via un bloc `match: macaddress:` — le matching échoue (`cannot find unique matching interface`). Fix : supprimer `match`/`set-name` du netplan, utiliser directement le nom d'interface réel (`ens18`) comme clé.
- Le clone hérite aussi du même **machine-id** → à régénérer (`rm /etc/machine-id && systemd-machine-id-setup`) pour éviter les conflits DHCP/réseau.
- Chaque clone doit avoir son **hostname** et son **IP fixe** changés individuellement avant de rejoindre quoi que ce soit.

### Prérequis systèmes obligatoires pour kubeadm (sur CHAQUE nœud)
1. **Swap désactivée** (`swapoff -a` + commenter la ligne dans `/etc/fstab`) — kubeadm refuse de démarrer sinon, car il gère lui-même l'allocation mémoire précisément et la swap fausserait ce contrôle
2. **Modules noyau** `overlay` et `br_netfilter` chargés — nécessaires respectivement pour le filesystem en couches des containers et pour que le trafic des bridges réseau soit vu par iptables
3. **Paramètres sysctl** (`ip_forward=1`, `bridge-nf-call-iptables=1`) — permettent le routage entre pods sur différents nœuds
4. **`conntrack` installé** — requis par kube-proxy, absent par défaut sur Ubuntu minimal, oublié dans le clone (installé sur le master après le clonage → obligation de le réinstaller séparément sur chaque worker)

### `kubeadm init` — le piège du CIDR
**Erreur évitée** : ne jamais utiliser un `--pod-network-cidr` qui chevauche le réseau physique local. Le premier essai (`192.168.0.0/16`) entrait en conflit direct avec le réseau domestique (`192.168.1.0/24`). Corrigé avec `10.244.0.0/16`, la plage standard attendue par Calico, totalement disjointe du réseau local.

### CNI Calico
Sans CNI, les pods n'ont pas d'IP interne fonctionnelle ni de routage entre nœuds → le node reste bloqué en `NotReady` même avec un control-plane sain. Installation via un manifeste officiel unique (`calico.yaml`), qui déploie daemonset + CRDs. Le passage `NotReady` → `Ready` du master confirme que le réseau de pods est opérationnel.

### `kubeadm join`
Le token généré à l'`init` (valide 24h) sert de preuve d'identité pour qu'un worker rejoigne le cluster en confiance (`--discovery-token-ca-cert-hash` vérifie l'authenticité du control-plane contacté). `kubectl` n'est utile/configuré **que sur le master** — les workers n'ont pas besoin d'accéder à l'API server pour eux-mêmes, ils reçoivent juste des ordres du control-plane.

### Résultat final
```
destiny-islands   Ready    control-plane   (master)
radiant-garden    Ready    <none>          (worker1)
twilight-town     Ready    <none>          (worker2)
```
`<none>` en ROLES pour les workers est normal — pas d'étiquette de rôle assignée par défaut, purement cosmétique.

---

## Fils conducteurs à retenir pour la suite du projet

- **Toujours vérifier la gateway/DNS en premier** sur toute nouvelle VM avant de chercher plus loin — erreur la plus répétée du projet
- **Un clone n'est jamais "prêt à l'emploi"** : hostname, IP, machine-id, et parfois des paquets installés après le clonage (conntrack) sont à revérifier systématiquement
- **Le code/la config vit dans l'image, pas sur le disque** : toute modif nécessite rebuild + redéploiement, que ce soit Docker ou Kubernetes
- **Sécurité en couches, jamais en un seul point** : SSH par clé ne suffit pas tant que l'accès web (mot de passe + accès shell intégré) reste une porte équivalente non sécurisée — à traiter en Phase 5
