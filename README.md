# 🧹 Script de Nettoyage Git

Ce script interactif permet de nettoyer en profondeur un dépôt Git. Il identifie les fichiers les plus volumineux dans l’historique, propose leur suppression avec BFG Repo-Cleaner, supprime les branches inutiles, nettoie les fichiers non suivis, exécute une garbage collection avancée, et peut générer un rapport HTML détaillé.

## 🔧 Fonctionnalités

- Analyse des fichiers les plus lourds dans l'historique Git
- Suppression sécurisée de fichiers avec [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)
- Suppression des branches locales fusionnées
- Nettoyage des références de branches distantes obsolètes
- Suppression des fichiers non suivis dans le répertoire
- Réduction de la taille du dépôt via `git gc`, `git repack`, `git prune`
- Force push automatisé si souhaité
- Génération d’un rapport HTML

## 🧱 Prérequis

- **Git** (dernière version recommandée)
- **BFG Repo-Cleaner** installé (disponible ici : https://rtyley.github.io/bfg-repo-cleaner/)
  - Assurez-vous que la commande `bfg` est accessible dans votre terminal (`$PATH`)

## ▶️ Utilisation

1. Rendez le script exécutable :

  ```bash
  chmod +x git-cleanup.sh
  ```
   
2. Lancez-le :

  ```bash
  ./git-cleanup.sh
  ```

Chaque étape est interactive : le script vous demande confirmation avant d’effectuer une opération potentiellement destructive.

## ⚠️ Conseils d’utilisation

Avant tout nettoyage :

- Travaillez sur un clone de test pour éviter toute perte de données.
- Prévenez votre équipe si vous réécrivez l’historique et effectuez un push --force.

Exemple de clone sécurisé :

```bash
git clone --mirror mon-projet.git mon-projet-clean
cd mon-projet-clean
../git-cleanup.sh
```

## 📝 Rapport HTML

À la fin de l’exécution, vous pouvez choisir de générer un rapport HTML (git-clean-report.html) contenant :

- Les opérations effectuées
- Les fichiers supprimés
- L’état initial et final du dépôt

##❗ Avertissement

Ce script effectue des opérations sensibles comme :

- La réécriture d’historique Git
- Le git push --force
- La suppression de branches locales ou fichiers

Utilisez-le en connaissance de cause, et faites toujours une sauvegarde avant.

🧼 Bon nettoyage !

