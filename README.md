# Description
This is a repository for the snakemake version of the [bash RNASeq pipeline](https://github.com/chg-bsl/bash_rnaseq) compatible with the Clemson University's Center for Human Genetics (CUCHG) High Performance Computing (HPC) cluster.

- *slurm/config.yaml*: config file for HPC architecture and slurm compatibility
- *snakemake_submitter.sh*: initiates conda environment and submits the snakemake job to snakemake
- *initiator.sh*: sets up the directory and launches the *snakemake_submitted.sh*
- *Snakefile*: the pipeline
- *RNASeq.yaml*: environmental variables for the pipeline

# Prerequisites 
***only install these if not running the pipeline on CUCHG's HPC***

- [Anaconda3/miniconda3](https://docs.anaconda.com/anaconda/install/linux/)
- [snakemake](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html)
- [fastp](https://github.com/OpenGene/fastp)
- [java_jdk/>=1.8](https://www.oracle.com/java/technologies/javase/javase8-archive-downloads.html)
- [bbmap/>=38.73](https://jgi.doe.gov/data-and-tools/bbtools/)
- [gmap_gsnap](https://github.com/juliangehring/GMAP-GSNAP)
- [samtools/>=1.10](https://github.com/samtools/samtools)
- [subread/>=1.6.4](http://subread.sourceforge.net/)
- [slurm](https://slurm.schedmd.com/sbatch.html)

# Instructions
## Adding user- and project- specific information
***generally, add information encompassed by "<>" in the files below***
- *slurm/config.yaml*: 
    - add max number of jobs ([integer](https://en.wikipedia.org/wiki/Integer_(computer_science)))
    - partition name ([string](https://wlm.userweb.mwn.de/Stata/wstavart.htm))
    - max number of cpus (integer) and max RAM (integer in MB): contact systems administrators for these values and do not edit once established
- *RNASeq.yaml*: fill out all information except EXT
- *snakemake_submitter.sh*:
    - sbatch parameters: 
        - add job name (string)
        - partition name (string)
        - time (in Hr:Min:Sec format)
        - output and error (add path to working directory, same as DEST from *RNASeq.yaml*, but leave the /log... parts unchanged)
        - mail-user (add user email address)
    - ```cd``` line: add path to working directory (same as DEST from *RNASeq.yaml*)
    - source line: add path to conda initiation script (*conda.sh*) to choose the right conda
    - conda activate line: add the name of the environment with a working snakemake installation (on Secretariat it is "snakemake")

# How to run (don't skip previous step!)

## I. Test run (head/master/login node)

1. Open ssh shell (using [MobaXterm](https://mobaxterm.mobatek.net/download-home-edition.html) or [Putty](https://www.putty.org/)) on head/master/login node
2. Make a working directory for the analysis and git clone this repository [(git clone https://github.com/chg-bsl/snakemake_rnaseq.git)]
3. Copy *Snakefile*, *snakemake_submitter.sh*, *RNASeq.yaml*, *slurm/config.yaml* and *initiator.sh* to working directory
4. Make sure the variables encompassed by "<>" in *slurm/config.yaml*, *RNASeq.yaml* and *snakemake_submitter.sh* have been modified to reflect info specific to your run (eg: working directory, raw data location, etc)
5. Open a ssh shell and run:
    ```
    ##Initialize the correct conda and bring conda into bash environment
    source <path to conda initialization script>
    ##Activate the correct conda environment containing snakemake installation
    conda activate <snakemake conda environment>

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

If step 5 in test run (*Generate the DAG figure* and *Generate the workflow* commands) do not generate any errors (red text), run:
```
./initiator.sh
```

# Tracking progress
There are three places to check for progress:
1. ```squeue```
2. This pipeline (when run successfully) will create *log* and *logs_slurm* directories within the working directory. In the *log* directory, look for *output_<job_ID>.txt* and *error_<job_ID>.txt* for current status of the run. When the run is successful, the last line should contain a *x of x steps (100%) done*.
3. In the *logs_slurm* directory, the most current log files with specific rule names on the file names represent the current statuses. 

## Future additions
- Make a link to image showing what the directory should look like
- Create a rule to grep *module add* to summarize a session info