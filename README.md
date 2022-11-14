![Logo](aMeta.png)

# aMeta: an accurate and memory-efficient ancient Metagenomic profiling workflow

[![Snakemake](https://img.shields.io/badge/snakemake-≥6.10.0-brightgreen.svg)](https://snakemake.bitbucket.io)
[![Tests](https://github.com/NBISweden/ancient-microbiome-smk/actions/workflows/main.yaml/badge.svg)](https://github.com/NBISweden/ancient-microbiome-smk/actions/workflows/main.yaml)

## About

aMeta is a Snakemake workflow for identifying microbial sequences in ancient DNA shotgun metagenomics samples. The workflow performs:

- trimming adapter sequences and removing reads shorter than 30 bp with Cutadapt
- quaity control before and after trimming with FastQC and MultiQC
- taxonomic sequence kmer-based classification with KrakenUniq
- sequence alignment with Bowtie2 and screening for common microbial pathogens
- deamination pattern analysis with MapDamage2
- Lowest Common Ancestor (LCA) sequence alignment with Malt
- authentication and validation of identified microbial species with MaltExtract

When using aMeta and / or pre-built databases provided together with the wokflow for your research projects, please cite our preprint: https://www.biorxiv.org/content/10.1101/2022.10.03.510579v1

## Authors

* Nikolay Oskolkov (@LeandroRitter) nikolay.oskolkov@scilifelab.se
* Claudio Mirabello (@clami66) claudio.mirabello@scilifelab.se
* Per Unneberg (@percyfal) per.unneberg@scilifelab.se

## Installation

Clone the repository, then create and activate aMeta conda environment:

    git clone https://github.com/NBISweden/aMeta
    cd aMeta
    conda env create -f workflow/envs/environment.yaml
    # alternatively : mamba env create -f workflow/envs/environment.yaml
    conda activate aMeta

Run a test to make sure that the workflow was installed correctly:

    cd .test
    ./runtest.sh -j 20

Here, and below, by `-j` you can specify the number of threads that the workflow can use.

## Quick start

To run the worflow you need to prepare a sample-file `config/samples.tsv` and a configuration file `config/config.yaml`, below we provide examples for both files. 

Here is an example of `samples.tsv`, this implies that the fastq-files files are located in `aMeta/data` folder:

    sample	fastq
    foo	data/foo.fq.gz
    bar	data/bar.fq.gz

Below is an example of `config.yaml`, here you will need to download a few databases that we made public (or build databases yourself).

    samplesheet: "config/samples.tsv"

    # KrakenUniq Microbial NCBI NT database (if you are interested in prokaryotes only)
    # can be downloaded from https://doi.org/10.17044/scilifelab.20518251
    krakenuniq_db: resources/DBDIR_KrakenUniq_MicrobialNT

    # KrakenUniq full NCBI NT database (if you are interested in prokaryotes and eukaryotes)
    # can be downloaded from https://doi.org/10.17044/scilifelab.20205504
    #krakenuniq_db: resources/DBDIR_KrakenUniq_Full_NT

    # Bowtie2 index and helping files for following up microbial pathogens 
    # can be downloaded from https://doi.org/10.17044/scilifelab.21185887
    bowtie2_patho_db: resources/library.pathogen.fna
    pathogenomesFound: resources/pathogensFound.very_inclusive.tab
    pathogenome_seqid2taxid_db: resources/seqid2taxid.pathogen.map

    # Bowtie2 index for full NCBI NT (for quick followup of prokaryotes and eukaryotes)
    # can be downloaded from https://doi.org/10.17044/scilifelab.21070063
    #bowtie2_patho_db: resources/library.fna

    # Helping files for building Malt database 
    # can be downloaded from https://doi.org/10.17044/scilifelab.21070063
    malt_nt_fasta: resources/library.fna
    malt_seqid2taxid_db: resources/seqid2taxid.map.orig
    malt_accession2taxid: resources/nucl_gb.accession2taxid

    # A path for downloading NCBI taxonomy files (performed automatically)
    # you do not need to change this line
    ncbi_db: resources/ncbi

    # Breadth and depth of coverage filters 
    # default thresholds are very conservative, can be tuned by users
    n_unique_kmers: 1000
    n_tax_reads: 200


After you have prepared the sample- and configration-file, the workflow can can be run using the following command line:

    cd aMeta
    snakemake --snakefile workflow/Snakefile -j 20


In the next sections we will give a detailed explanation of all parameters in the configuration file.


## More details on configuration

The workflow can be run as:

    snakemake --snakefile workflow/Snakefile -j 100 --profile .profile --use-envmodules

The workflow requires a configuration file, by default residing in `config/config.yaml` relative to the working directory, that defines location of samplesheet, what samples and analyses to run, and
location of databases. The configuration file is validated against a schema (`workflow/schemas/config.schema.yaml`) that can be consulted for more detailed information regarding configuration properties.

The `samplesheet` key points to a samplesheet file that consists of at minimum two columns, sample and fastq:

    sample	fastq
    foo     data/foo.fq.gz
    bar     /path/to/data/bar.fq.gz

What samples to analyse can be constrained in the `samples` section
through the `include` and `exclude` keys, so that a global samplesheet
can be reused multiple times.

Analyses `mapdamage`, `authentication`, `malt`, and `krona` can be
individually turned on and off in the `analyses` section.

Adapter sequence can be defined in the `adapters` configuration
section. The keys `config['adapters']['illumina']` (default `true`)
and `config['adapters']['nextera']` (default `false`) are switches
that turn on/off adapter trimming of illumina (`AGATCGGAAGAG`) and
nextera (`AGATCGGAAGAG`) adapter sequences. Addional custom adapter
sequences can be set in the configuration key
`config['adapters']['custom']` which must be an array of strings.

Database locations are defined by the following keys:

`krakenuniq_db`: path to KrakenUniq database

`bowtie2_patho_db`: Full path to Bowtie2 pathogenome database

`pathogenome_path`: Path to Bowtie2 pathogenome database, excluding
the database name

`pathogenomesFound`: List of pathogens to keep when filtering
KrakenUniq output

`malt_seqid2taxid_db`: Sequence id to taxonomy mapping

`malt_nt_fasta`: Fasta library

`malt_accession2taxid`: Accession to taxonomy id mapping

A minimal configuration example is shown below:

    samplesheet: resources/samples.tsv

    # one can include or exclude samples
    samples:
      include:
        - foo
      exclude:
        - bar

    # one can include or exclude certain types of analysis
    analyses:
      mapdamage: true
      authentication: true
      malt: true

    # one can specify type of adapters to trim
    adapters:
      illumina: true
      nextera: false
      # custom is a list of adapter sequences
      custom: []

    # Databases
    krakenuniq_db: resources/KrakenUniq_DB
    bowtie2_patho_db: resources/ref.fa
    pathogenome_path: resources
    pathogenomesFound: resources/pathogenomesFound.tab
    malt_seqid2taxid_db: resources/KrakenUniq_DB/seqid2taxid.map
    malt_nt_fasta: resources/ref.fa
    malt_accession2taxid: resources/accession2taxid.map

### Environment module configuration

If the workflow is run on a HPC with the `--use-envmodules` option
(see
[using-environment-modules](https://snakemake.readthedocs.io/en/stable/snakefiles/deployment.html#using-environment-modules)),
the workflow will check for an additional configuration file that
configures environment modules. By default, the file is
`config/envmodules.yaml`, but a custom location can be set with the
environment variable `ANCIENT_MICROBIOME_ENVMODULES`.

envmodules configurations are placed in a configuration section
`envmodules` with key-value pairs that map a dependency set to a list
of environment modules. The dependency sets are named after the rule's
corresponding conda environment file, such that a dependency set may
affect multiple rules. For instance, the following example shows how
to define modules for rules depending on fastqc, as it would be
implemented on the [uppmax](https://uppmax.uu.se/) compute cluster:

    envmodules:
      fastqc:
        - bioinfo-tools
        - FastQC

See the configuration schema file
(`workflows/schema/config.schema.yaml`) for more information.

### Runtime configuration

Most individual rules define the number of threads to run. Although
the number of threads for a given rule can be tweaked on the command
line via the option `--set-threads`, it is advisable to put all
runtime configurations in a
[profile](https://snakemake.readthedocs.io/en/stable/snakefiles/best_practices.html).
At its simplest, a profile is a directory (e.g. `.profile` in the
working directory) containing a file `config.yaml` which consists of
command line option settings. In addition to customizing threads, it
enables the customization of resources, such as runtime and memory. An
example is shown here:

    # Rerun incomplete jobs
    rerun-incomplete: true
    # Restart jobs once on failure
    restart-times: 1
    # Set threads for mapping and fastqc
    set-threads:
      - Bowtie2_Pathogenome_Alignment=10
      - FastQC_BeforeTrimming=5
    # Set resources (runtime in minutes, memory in mb) for malt
    set-resources:
      - Malt:runtime=7200
      - Malt:mem_mb=512000
    # Set defalt resources that apply to all rules
    default-resources:
      - runtime=120
      - mem_mb=16000
      - disk_mb=1000000

For more advanced profiles for different hpc systems, see
[Snakemake-Profiles github
page](https://github.com/snakemake-profiles).

## Usage

If you use this workflow in a paper, don't forget to give credits to
the authors by citing the URL of this (original) repository and, if
available, its DOI (see above).

### Step 1: Obtain a copy of this workflow

1. Create a new github repository using this workflow [as a
   template](https://help.github.com/en/articles/creating-a-repository-from-a-template).
2. [Clone](https://help.github.com/en/articles/cloning-a-repository)
   the newly created repository to your local system, into the place
   where you want to perform the data analysis.

### Step 2: Configure workflow

Configure the workflow according to your needs via editing the files
in the `config/` folder. Adjust `config.yaml` to configure the
workflow execution, and `samples.tsv` to specify your sample setup.

### Step 3: Install Snakemake

Install Snakemake using
[conda](https://conda.io/projects/conda/en/latest/user-guide/install/index.html):

    conda create -c bioconda -c conda-forge -n snakemake snakemake

For installation details, see the [instructions in the Snakemake
documentation](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html).

### Step 4: Execute workflow

Activate the conda environment:

    conda activate snakemake

Test your configuration by performing a dry-run via

    snakemake --use-conda -n

Execute the workflow locally via

    snakemake --use-conda --cores $N

using `$N` cores or run it in a cluster environment via

    snakemake --use-conda --cluster qsub --jobs 100

or

    snakemake --use-conda --drmaa --jobs 100

If you not only want to fix the software stack but also the underlying OS, use

    snakemake --use-conda --use-singularity

in combination with any of the modes above. See the [Snakemake
documentation](https://snakemake.readthedocs.io/en/stable/executable.html)
for further details.

### Step 5: Investigate results

After successful execution, you can create a self-contained
interactive HTML report with all results via:

    snakemake --report report.html

This report can, e.g., be forwarded to your collaborators. An example
(using some trivial test data) can be seen
[here](https://cdn.rawgit.com/snakemake-workflows/rna-seq-kallisto-sleuth/master/.test/report.html).

### Step 6: Commit changes

Whenever you change something, don't forget to commit the changes back
to your github copy of the repository:

    git commit -a
    git push

### Step 7: Obtain updates from upstream

Whenever you want to synchronize your workflow copy with new
developments from upstream, do the following.

1. Once, register the upstream repository in your local copy: `git
   remote add -f upstream
   git@github.com:snakemake-workflows/ancient-microbiome-smk.git` or
   `git remote add -f upstream
   https://github.com/snakemake-workflows/ancient-microbiome-smk.git`
   if you do not have setup ssh keys.
2. Update the upstream version: `git fetch upstream`.
3. Create a diff with the current version: `git diff HEAD
   upstream/master workflow > upstream-changes.diff`.
4. Investigate the changes: `vim upstream-changes.diff`.
5. Apply the modified diff via: `git apply upstream-changes.diff`.
6. Carefully check whether you need to update the config files: `git
   diff HEAD upstream/master config`. If so, do it manually, and only
   where necessary, since you would otherwise likely overwrite your
   settings and samples.


### Step 8: Contribute back

In case you have also changed or added steps, please consider
contributing them back to the original repository:

1. [Fork](https://help.github.com/en/articles/fork-a-repo) the
   original repo to a personal or lab account.
2. [Clone](https://help.github.com/en/articles/cloning-a-repository)
   the fork to your local system, to a different place than where you
   ran your analysis.
3. Copy the modified files from your analysis to the clone of your
   fork, e.g., `cp -r workflow path/to/fork`. Make sure to **not**
   accidentally copy config file contents or sample sheets. Instead,
   manually update the example config files if necessary.
4. Commit and push your changes to your fork.
5. Create a [pull
   request](https://help.github.com/en/articles/creating-a-pull-request)
   against the original repository.

## Testing

Test cases are in the subfolder `.test`. They are automatically
executed via continuous integration with [Github
Actions](https://github.com/features/actions).
