# Specs matériel

## Composants

| Composant       | Modèle                          | Source              | Coût   |
|-----------------|----------------------------------|----------------------|--------|
| CPU             | Intel i5-9600KF @ 3.70GHz        | Récupéré            | 0 €    |
| RAM             | 16 Go DDR4 3200MHz Corsair Vengeance | Existant         | 0 €    |
| RAM (upgrade)   | +16 Go DDR4 3200MHz (à assortir) | Occasion            | ~80 €  |
| Stockage        | SSD SATA 1 To (récup. NVMe upgrade PC principal) | Récupéré | 0 €    |
| Alimentation    | 450-550W 80+ Bronze               | Occasion            | ~25 €  |
| Boîtier         | (ancien boîtier PC principal)     | Récupéré            | 0 €    |
| GPU             | GTX 1660 (install initiale uniquement, serveur headless ensuite) | Existant | 0 € |

## Notes

- CPU sans GPU intégré (KF) → GPU nécessaire uniquement pour l'installation initiale, le serveur tournera ensuite headless (SSH).
- RAM à assortir en fréquence/CL avec le kit existant pour éviter les instabilités.
- SSD obligatoire pour l'OS/etcd — jamais de HDD mécanique pour le stockage système Kubernetes.

## Budget total estimé

~105 € (hors pièces déjà en main)
