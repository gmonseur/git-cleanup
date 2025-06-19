#!/bin/bash

set -e

LOGFILE="git-clean-report.txt"
HTMLREPORT="git-clean-report.html"
DATE=$(date +"%Y-%m-%d %H:%M:%S")
exec > >(tee -a "$LOGFILE") 2>&1

echo "=== 🧹 Nettoyage supervisé du dépôt Git ==="
echo "📅 Date : $DATE"
echo "📂 Répertoire : $(pwd)"

# Étape 1 : Lancement du script
read -p "⚠️  Ce script modifie potentiellement l’historique. Continuer ? [y/N] " confirm
[[ $confirm =~ ^[Yy]$ ]] || exit 1

echo -e "\n➡️ Taille actuelle du dépôt Git :"
du -sh .git

echo -e "\n➡️ Objets Git actuels :"
git count-objects -vH

# Étape 2 : Gros fichiers
read -p $'\n🔍 Voir les 20 plus gros blobs dans l’historique ? [y/N] ' show_blobs
if [[ $show_blobs =~ ^[Yy]$ ]]; then
  echo "📦 Les 20 plus gros fichiers (dans tout l’historique) :"

  mapfile -t blobs < <(
    git rev-list --objects --all |
    git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' |
    grep '^blob' |
    sort -k3 -n |
    tail -n 20
  )

  for i in "${!blobs[@]}"; do
    IFS=' ' read -r type sha size path <<<"${blobs[$i]}"
    hr_size=$(numfmt --to=iec-i --suffix=B "$size")
    echo "$((i+1)). $hr_size - $path"
  done

  read -p $'\n🧨 Sélectionne les fichiers à supprimer (numéros séparés par espaces), ou rien pour passer : ' selections

  if [[ -n "$selections" ]]; then
    files_to_delete=""
    for num in $selections; do
      if (( num >= 1 && num <= ${#blobs[@]} )); then
        IFS=' ' read -r _ _ _ path <<<"${blobs[$((num-1))]}"
        files_to_delete+="${files_to_delete:+,}$path"
      else
        echo "⚠️ Numéro invalide ignoré: $num"
      fi
    done

    if [[ -n "$files_to_delete" ]]; then
      echo -e "\n🚀 Lancement de BFG pour supprimer : $files_to_delete"
      echo "Commande: bfg --delete-files \"$files_to_delete\" ."
      bfg --delete-files "$files_to_delete" .
      echo "✅ BFG terminé."
    fi
  else
    echo "Aucun fichier sélectionné, passage."
  fi
fi

# Étape 4 : GC
read -p $'\n♻️ Lancer git gc agressif ? [y/N] ' run_gc
if [[ $run_gc =~ ^[Yy]$ ]]; then
  git reflog expire --expire=now --all
  git gc --aggressive --prune=now
  echo "✅ Garbage collection effectuée."
fi

# Étape 5 : Branches locales
read -p $'\n🪓 Supprimer les branches locales fusionnées ? [y/N] ' prune_local
if [[ $prune_local =~ ^[Yy]$ ]]; then
  set +e
  merged_branches=$(git branch --merged | grep -v "\*")
  for branch in $merged_branches; do
    echo "Suppression de la branche locale : $branch"
    git branch -d "$branch" || echo "⚠️ Impossible de supprimer $branch."
  done
  set -e
fi

# Étape 6 : Branches distantes
read -p $'\n🧼 Nettoyer les références de branches distantes ? [y/N] ' prune_remote
if [[ $prune_remote =~ ^[Yy]$ ]]; then
  git remote prune origin
fi

# Étape 7 : Fichiers non suivis
read -p $'\n🧽 Lister les fichiers non suivis à nettoyer ? [y/N] ' clean_preview
if [[ $clean_preview =~ ^[Yy]$ ]]; then
  git clean -ndx
  read -p "Souhaites-tu supprimer ces fichiers ? (git clean -fdx) [y/N] " clean_confirm
  if [[ $clean_confirm =~ ^[Yy]$ ]]; then
    git clean -fdx
  fi
fi

# Étape 8 : Push forcé
read -p $'\n🚀 Pousser les changements (force push) vers le dépôt distant ? [y/N] ' push_confirm
if [[ $push_confirm =~ ^[Yy]$ ]]; then
  echo "📡 Envoi des branches (force push)..."
  git push origin --force --all
  echo "🏷️  Envoi des tags (force push)..."
  git push origin --force --tags
  echo "✅ Push forcé terminé. ⚠️ Préviens les autres développeurs !"
else
  echo "❌ Push non effectué. Tu peux le faire manuellement :"
  echo "    git push origin --force --all && git push origin --force --tags"
fi

# Étape 9 : Repack
read -p $'\n📦 Repack Git pour compression ? [y/N] ' repack
if [[ $repack =~ ^[Yy]$ ]]; then
  git repack -Ad
  git prune
  echo "✅ Repack terminé."
fi

# Résultats finaux
echo -e "\n✅ Taille finale :"
du -sh .git
git count-objects -vH

# Étape 10 : Rapport HTML
read -p $'\n📝 Générer un rapport HTML ? [y/N] ' gen_html
if [[ $gen_html =~ ^[Yy]$ ]]; then
  echo "<!DOCTYPE html>
<html lang='fr'>
<head>
  <meta charset='UTF-8'>
  <title>Rapport de nettoyage Git</title>
  <style>
    body { font-family: sans-serif; padding: 2em; background: #f5f5f5; }
    pre { background: #fff; padding: 1em; border: 1px solid #ccc; overflow-x: auto; }
  </style>
</head>
<body>
  <h1>Rapport de nettoyage Git</h1>
  <p><strong>Date :</strong> $DATE</p>
  <p><strong>Dossier :</strong> $(pwd)</p>
  <h2>Journal des opérations :</h2>
  <pre>$(cat "$LOGFILE" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')</pre>
</body>
</html>" > "$HTMLREPORT"
  echo "📄 Rapport HTML généré : $HTMLREPORT"
fi

echo -e "\n🎉 Nettoyage terminé."
