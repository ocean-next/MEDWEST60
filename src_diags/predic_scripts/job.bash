#!/bin/bash
#SBATCH --job-name=crps             # nom du job
#SBATCH --nodes=1                   # nombre de noeuds
#SBATCH --ntasks-per-node=1         # nombre de taches MPI par noeud
#SBATCH --time=10:00:00             # temps d execution maximum demande (HH:MM:SS)
#SBATCH --output=crps%j.out         # nom du fichier de sortie
#SBATCH --error=crps%j.out          # nom du fichier d'erreur (ici en commun avec la sortie)
#SBATCH -A egi@cpu
 
set -x
 
#./crps_score.ksh
./locerror.ksh
