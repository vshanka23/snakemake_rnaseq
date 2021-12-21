# Description
This is a repository for the snakemake version of the [bash RNASeq pipeline](https://github.com/chg-bsl/bash_rnaseq) compatible with the Clemson University's Center for Human Genetics' High Performance Computing (HPC) cluster.

- *slurm/config.yaml*: config file for HPC architecture and slurm compatibility
- *snakemake_submitter.sh*: initiates conda environment and submits the snakemake job to snakemake
- *initiator.sh*: sets up the directory and launches the *snakemake_submitted.sh*
- *Snakefile*: pipeline
- *RNASeq.yaml*: environmental variables for the pipeline

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
## Adding user- and project- specific information
***generally, add information encompassed by "<>" in the files below***
- *slurm/config.yaml*: 
    - add max number of jobs ([integer(](https://en.wikipedia.org/wiki/Integer_(computer_science)))
    - partition name ([string](https://docs.microsoft.com/en-us/dotnet/api/system.string?view=net-6.0))
    - max number of cpus (integer) and max RAM (integer in MB). Contact systems administrators for these values and do not edit once established
- *RNASeq.yaml*: fill out all information except EXT
- *snakemake_submitter.sh*:
    - sbatch parameters: 
        - add job name (string)
        - partition name (string)
        - time (in Hr:Min:Sec format)
        - output and error (add path to working directory, same as DEST from *RNASeq.yaml*, but leave the /log... parts unchanged)
        - mail-user (add user email address)
    - CD line: add path to working directory (same as DEST from *RNASeq.yaml*)
    - source line: add path to conda initiation script (*conda.sh*) to choose the right conda
    - conda activate line: add the name of the environment with a working snakemake installation (on Secretariat it is "snakemake")

# How to run (don't skip previous step!)

## I. Test run (head/master/login node)

1. Open ssh shell (using [MobaXterm](https://mobaxterm.mobatek.net/download-home-edition.html) or [Putty](https://www.putty.org/)) on master/node.
2. Copy *Snakefile*, *snakemake_submitter.sh*, *RNASeq.yaml*, *slurm/config.yaml* and *initiator.sh*
3. Make sure the variables encompassed by "<>" in *slurm/config.yaml*, *RNASeq.yaml* and *snakemake_submitter.sh*
4. In the ssh shell and run:
```
source <path to conda initialization script>
conda activate <name of conda environment with snakemake installation>

cd <working directory containing analysis pipeline files>
```
Generate DAG figure:
```
snakemake -n -p -s Snakefile --configfile RNASeq.yaml --profile slurm --dag | display | dot
```
Generate the workflow:
```
snakemake -n -p -s Snakefile --configfile RNASeq.yaml --profile slurm
```

## II. Actual run (head/master/login node)

If *Generate the DAG figure* and *Generate the workflow* commands in the test run do not generate any errors (red text), run:
```
./initiator.sh
```

# Tracking progress
There are three places to check for progress:
1. ```squeue```
2. In the *log* directory, look for *output_<job_ID>.txt* and *error_<job_ID>.txt* for current status of the run. When the run is successful, the last line should contain 
3. In the *logs_slurm* directory, look for the log files with specific rule names on the file names for current status. 

## Future additions
Make a link to image showing what the directory should look like
Create a rule to grep *module add* to summarize a session info
Create hyperlinks for prereqs
Add string and integer hyperlink
