# Snakemake workflow: ancient-microbiome

[![Snakemake](https://img.shields.io/badge/snakemake-≥6.10.0-brightgreen.svg)](https://snakemake.bitbucket.io)
[![Tests](https://github.com/NBISweden/ancient-microbiome-smk/actions/workflows/main.yaml/badge.svg)](https://github.com/NBISweden/ancient-microbiome-smk/actions/workflows/main.yaml)

## About

Snakemake workflow for identifying microbe sequences in ancient DNA
samples. The workflow does:

- adapter trimming of sequences
- FastQC before and after trimming
- taxonomic sequence classification with KrakenUniq
- sequence alignment with Malt
- sequence damage analysis with Mapdamage2
- authentication of identified sequences

## Installation

Easiest is to install with pip:

	python -m pip install git+https://github.com/NBISweden/ancient-microbiome-smk@pyproject

Alternatively, clone the repo, create and edit the configuration files (see below)
and run

    cd /path/to/workdir
    snakemake -s /path/to/repo/workflow/Snakefile -j 100 --profile .profile --use-envmodules

## Usage

The workflow and additional commands run via the main entry point:

	amibo -h
	amibo config --init
	amibo run -j 1
	amibo run -j 1 --use-envmodules --envmodules-file=envmodules.yaml

See the subcommand help for more information.

## Authors

* Nikolay Oskolkov (@LeandroRitter)
* Claudio Mirabello (@clami66)
* Per Unneberg (@percyfal)

## Configuration

The workflow requires a configuration file, by default residing in
`config/config.yaml` relative to the working directory, that defines
location of samplesheet, what samples and analyses to run, and
location of databases. The configuration file is validated against a
schema (`workflow/schemas/config.schema.yaml`) that can be consulted
for more detailed information regarding configuration properties.

The `samplesheet` key points to a samplesheet file that consists of at
minimum two columns, sample and fastq:

    sample	fastq
    foo     data/foo.fq.gz
    bar     /path/to/data/bar.fq.gz

What samples to analyse can be constrained in the `samples` section
through the `include` and `exclude` keys, so that a global samplesheet
can be reused multiple times.

Analyses `mapdamage`, `authentication`, `malt`, and `krona` can be
individually turned on and off in the `analyses` section.

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
    samples:
      include:
        - foo
        - bar
      exclude:
        - foobar

    analyses:
      mapdamage: false
      authentication: false
      malt: false

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

## Testing

Test cases are in the subfolder `.test`. They are automatically
executed via continuous integration with [Github
Actions](https://github.com/features/actions) and can be run from the
cli:

	amibo run --test -j 1
