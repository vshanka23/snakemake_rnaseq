#!/bin/bash
#
#SBATCH --job-name=<job name>
#SBATCH --ntasks=1   
#SBATCH --partition=<partition>
#SBATCH --time=<time for snakemake global controller>
#SBATCH --mem=2gb
#SBATCH --output=<path from DEST in the RNASeq.yaml>/log/RNASEQ_output_%j.txt
#SBATCH --error=<path from DEST in the RNASeq.yaml>/log/RNASEQ_error_%j.txt
#SBATCH --mail-type=all
#SBATCH --mail-user=<username@domain.space>

cd <path from DEST in the RNASeq.yaml>
#mkdir -p ./{log,logs_slurm}

source <path to conda.sh of the correct conda to initialize environmental variables>
conda activate <conda environment containing snakemake installation>

#--dag | display | dot
#-p -n \

snakemake \
-s Snakefile \
--profile slurm \
--configfile RNASeq.yaml
