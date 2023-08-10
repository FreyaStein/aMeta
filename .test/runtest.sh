if [[ -z "$@" ]]; then
    echo "No snakemake options supplied. To run the tests, at least set the number of threads (e.g. -j 1)"
    echo "Example usage: "
    echo
    echo "./runtest.sh -j 1"
    echo
fi
# check if we are running CI; if not, initialize databases
if [[ -z "$CI" ]]; then
    if [[ ! -e ".initdb" ]]; then
        echo "This looks like the first test run... Installing bioconda packages..."
        snakemake --use-conda --show-failed-logs -j 2 --conda-cleanup-pkgs cache --conda-create-envs-only -s ../workflow/Snakefile

        source $(dirname $(dirname $CONDA_EXE))/etc/profile.d/conda.sh

        ##############################
        # Krakenuniq database
        ##############################
        echo Building krakenuniq data
        env=$(grep krakenuniq .snakemake/conda/*yaml | awk '{print $1}' | sed -e "s/.yaml://g")
        conda activate $env
        krakenuniq-build --db resources/KrakenUniq_DB --kmer-len 21 --minimizer-len 11 --jellyfish-bin $(pwd)/$env/bin/jellyfish
        conda deactivate

        ##############################
        # Krona taxonomy
        ##############################
        echo Building krona taxonomy
        env=$(grep krona .snakemake/conda/*yaml | awk '{print $1}' | sed -e "s/.yaml://g" | head -1)
        conda activate $env
        cd $env/opt/krona
        ./updateTaxonomy.sh taxonomy
        cd -
        conda deactivate

        ##############################
        # Adjust malt max memory usage
        ##############################
        echo Adjusting malt max memory usage
        env=$(grep hops .snakemake/conda/*yaml | awk '{print $1}' | sed -e "s/.yaml://g" | head -1)
        conda activate $env
        version=$(conda list malt --json | grep version | sed -e "s/\"//g" | awk '{print $2}')
        cd $env/opt/malt-$version
        sed -i -e "s/-Xmx64G/-Xmx3G/" malt-build.vmoptions
        sed -i -e "s/-Xmx64G/-Xmx3G/" malt-run.vmoptions
        cd -
        conda deactivate

        touch .initdb
    fi
fi

echo Running workflow...
echo snakemake --use-conda --conda-frontend mamba --show-failed-logs --conda-cleanup-pkgs cache -s ../workflow/Snakefile $@
snakemake --use-conda --conda-frontend mamba --show-failed-logs --conda-cleanup-pkgs cache -s ../workflow/Snakefile $@

echo Generating report...
echo snakemake -s ../workflow/Snakefile --report --report-stylesheet ../workflow/report/custom.css
snakemake -s ../workflow/Snakefile --report --report-stylesheet ../workflow/report/custom.css
