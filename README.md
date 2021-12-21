# Description
This is a repository for the snakemake version of the bash RNASeq pipeline compatible with the CUCHG's HPC.

- slurm/config.yaml: config file for HPC architecture and slurm compatibility
- snakemake_submitter.sh: initiates conda environment and submits the snakemake job to snakemake
- initiator.sh: sets up the directory and launches the snakemake_submitted.sh
- Snakefile: pipeline
- RNASeq.yaml: Environmental variables for the pipeline

# Prerequisites

- conda
- snakemake
- fastp
- java_jdk/>=1.8
- bbmap/>=38.73
- gmap_gsnap
- samtools/>=1.10
- subread/>=1.6.4
- slurm

# Instructions
## Adding user- and project- specific information (generally, add information encompassed by "<>" in the files below)

- slurm/config.yaml: add max number of jobs (integer), partition name (string), max number of cpus (integer), max RAM (integer in MB)
- RNASeq.yaml: fill out all information except EXT
- snakemake_submitter.sh:
    - sbatch parameters: add job name (string), partition name (string), time (in Hr:Min:Sec format), output and error (add path to working directory, same as DEST from RNASeq.yaml, but leave the /log... parts unchanged) and mail-user (add user email address).
    - CD line: add path to working directory (same as DEST from RNASeq.yaml), source line: add path to conda initiation script (conda.sh) to choose the right conda, conda activate line: add the name of the environment with a working snakemake installation (on Secretariat it is "snakemake")

# How to run (don't skip previous step!)

## Test run (head/master node)

Copy Snakefile, snakemake_submitter.sh, RNASeq.yaml, slurm/config.yaml and initiator.sh
Open ssh shell on master/node and run:

```
source <path to conda initialization script>
conda activate <name of conda environment with snakemake installation>

cd <working directory containing analysis pipeline files>
##Save the figure
snakemake -n -p -s Snakefile --configfile RNASeq.yaml --profile slurm --dag | display | dot
##Check for errors
snakemake -n -p -s Snakefile --configfile RNASeq.yaml --profile slurm
```

## Actual run (head/master node)

If both commands in the test run do not generate any errors (red text), run:

```
./initiator.sh
```