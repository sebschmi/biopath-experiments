################
### DATASETS ###
################

wildcard_constraints:
    dataset = "[^/]+",
    builder = "[^/]+",

DATASET = os.path.join(DATADIR, "{dataset}.gfa.gz")
ANCIENT_DATASET = os.path.join(ANCIENTDIR, "{dataset}.gfa.gz")
TEMPORARY_DATASET_DIR = os.path.join(TEMPDIR, "datasets", "{dataset}")
TEMPORARY_DATASET = os.path.join(TEMPORARY_DATASET_DIR, "dataset.gfa.gz")

DATASET_BUILDER_DIR = os.path.join(TEMPORARY_DATASET_DIR, "{builder}")
FINISHED_DATASET = os.path.join(DATASET_BUILDER_DIR, "dataset.gfa.gz")

localrules: create_all_datasets
rule create_all_datasets:
    input:  lambda wildcards: [DATASET.format(dataset=dataset) for dataset in DATASETS.keys()],

rule link_ancient_dataset:
    input:  dataset = ancient(ANCIENT_DATASET),
    output: dataset = DATASET,
    shell: """
        ln -sr '{input.dataset}' '{output.dataset}'
    """

rule finalize_dataset:
    input:  dataset = TEMPORARY_DATASET,
    output: dataset = ANCIENT_DATASET,
    params: temporary_dir = TEMPORARY_DATASET_DIR,
    shell: """
        cp '{input.dataset}' '{output.dataset}'
        rm -rf '{params.temporary_dir}'
    """

def choose_dataset_builder_fn(wildcards):
    try:
        if wildcards.dataset not in DATASETS:
            raise ValueError(f"No enabled dataset found with name {wildcards.dataset}")
        
        return safe_format(FINISHED_DATASET, builder=DATASETS[wildcards.dataset]["builder"])
    except Exception as e:
        print(f"Error in choose_dataset_builder_fn for dataset {wildcards.dataset}: {e}")
        traceback.print_exc()
        raise

rule choose_dataset_builder:
    input:  dataset = choose_dataset_builder_fn, # populates FINISHED_DATASET
    output: dataset = TEMPORARY_DATASET,
    shell: """
        ln -sr '{input.dataset}' '{output.dataset}'
    """

###########
### GFA ###
###########

rule download_gfa_gz_file:
    output: dataset = FINISHED_DATASET,
    params: url = lambda wildcards: DATASETS[wildcards.dataset]["urls"][0],
    wildcard_constraints:
        builder = "gfa_gz",
    shell: """
        wget --progress=dot:mega -O '{output.dataset}' '{params.url}'
    """

ZST_DATASET = os.path.join(DATASET_BUILDER_DIR, "dataset.gfa.zst")

rule convert_gfa_zst_to_gfa_gz:
    input: dataset = ZST_DATASET,
    output: dataset = FINISHED_DATASET,
    log: os.path.join(DATASET_BUILDER_DIR, "convert_gfa_zst_to_gfa_gz.log"),
    wildcard_constraints:
        builder = "gfa_zst",
    shell: """
        zstd -d --stdout '{input.dataset}' | gzip > '{output.dataset}' 2> '{log}'
    """

rule download_gfa_zst_file:
    output: dataset = ZST_DATASET,
    params: url = lambda wildcards: DATASETS[wildcards.dataset]["urls"][0],
    wildcard_constraints:
        builder = "gfa_zst",
    shell: """
        wget --progress=dot:mega -O '{output.dataset}' '{params.url}'
    """

##########
### VG ###
##########

VG_FILE = os.path.join(DATASET_BUILDER_DIR, "dataset.vg")

rule convert_vg_to_gfa:
    input: dataset = VG_FILE,
    output: dataset = FINISHED_DATASET,
    log: os.path.join(DATASET_BUILDER_DIR, "convert_vg_to_gfa.log"),
    wildcard_constraints:
        builder = "vg",
    shell: """
        vg convert -f '{input.dataset}' | gzip > '{output.dataset}' 2> '{log}'
    """

rule download_vg_file:
    output: dataset = VG_FILE,
    params: url = lambda wildcards: DATASETS[wildcards.dataset]["urls"][0],
    wildcard_constraints:
        builder = "vg",
    shell: """
        wget --progress=dot:mega -O '{output.dataset}' '{params.url}'
    """

###########
### GBZ ###
###########

GBZ_FILE = os.path.join(DATASET_BUILDER_DIR, "dataset.gbz")

rule convert_gbz_to_gfa:
    input: dataset = GBZ_FILE,
    output: dataset = FINISHED_DATASET,
    log: os.path.join(DATASET_BUILDER_DIR, "convert_gbz_to_gfa.log"),
    wildcard_constraints:
        builder = "gbz",
    shell: """
        vg convert -f '{input.dataset}' | gzip > '{output.dataset}' 2> '{log}'
    """

rule download_gbz_file:
    output: dataset = GBZ_FILE,
    params: url = lambda wildcards: DATASETS[wildcards.dataset]["urls"][0],
    wildcard_constraints:
        builder = "gbz",
    shell: """
        wget --progress=dot:mega -O '{output.dataset}' '{params.url}'
    """

#######################
### PGGB from FASTA ###
#######################

rule gzip_pggb_gfa:
    input: dataset = os.path.join(DATASET_BUILDER_DIR, "dataset.pggb.gfa"),
    output: dataset = FINISHED_DATASET,
    log: os.path.join(DATASET_BUILDER_DIR, "gzip_pggb_gfa.log"),
    wildcard_constraints:
        builder = "pggb_from_fasta",
    shell: """
        gzip -kc '{input.dataset}' > '{output.dataset}' 2> '{log}'
    """

rule pggb_build:
    # message: "Build pangenome GFA with pggb for {wildcards.dataset}"
    input:
        fa_gz = os.path.join(DATASET_BUILDER_DIR, "dataset.fa.gz"),
        fai = os.path.join(DATASET_BUILDER_DIR, "dataset.fa.gz.fai"),
    output:
        gfa = os.path.join(DATASET_BUILDER_DIR, "dataset.pggb.gfa"),
    params:
        outdir = os.path.join(DATASET_BUILDER_DIR, "pggb_out"),
    log: os.path.join(DATASET_BUILDER_DIR, "pggb_out", "{dataset}.pggb.log"),
    threads: workflow.cores * 0.25
    shell:
        """
        mkdir -p '{params.outdir}'
        pggb -t {threads} -i '{input.fa_gz}' -o '{params.outdir}' > '{log}' 2>&1

        # Sélectionner un GFA produit par pggb
        out_gfa=""
        for pat in \
          "{params.outdir}"/*.smooth.final.gfa \
          "{params.outdir}"/*/*.smooth.final.gfa \
          "{params.outdir}"/*.smooth.gfa \
          "{params.outdir}"/*/*.smooth.gfa \
          "{params.outdir}"/*.gfa \
          "{params.outdir}"/*/*.gfa
        do
          if [ -f "$pat" ]; then
            out_gfa="$pat"
            break
          fi
        done

        if [ -z "$out_gfa" ]; then
          echo "[ERROR] No .gfa produced by pggb in {params.outdir}" >> {log}
          exit 1
        fi

        cp "$out_gfa" {output.gfa}
        """

rule samtools_faidx:
    input: fasta_gz = os.path.join(DATASET_BUILDER_DIR, "dataset.fa.gz"),
    output: fai = os.path.join(DATASET_BUILDER_DIR, "dataset.fa.gz.fai"),
    log: os.path.join(DATASET_BUILDER_DIR, "samtools_faidx.log"),
    wildcard_constraints:
        builder = "pggb_from_fasta",
    shell: """
        samtools faidx '{input.fasta_gz}' > '{log}' 2>&1
    """

rule download_fasta_gz_file:
    output: fasta_gz = os.path.join(DATASET_BUILDER_DIR, "dataset.fa.gz"),
    params: url = lambda wildcards: DATASETS[wildcards.dataset]["urls"][0],
    wildcard_constraints:
        builder = "pggb_from_fasta",
    shell: """
        wget --progress=dot:mega -O '{output.fasta_gz}' '{params.url}'
    """

###################
### VG from VCF ###
###################

rule convert_vcf_vg_to_gfa:
    input: os.path.join(DATASET_BUILDER_DIR, "dataset.vg"),
    output: FINISHED_DATASET,
    log: os.path.join(DATASET_BUILDER_DIR, "convert_vg_to_gfa.log"),
    wildcard_constraints:
        builder = "vg_from_vcf",
    shell: """
        vg convert -f '{input}' | gzip > '{output}' 2> '{log}'
    """

rule vg_construct:
    input:
        fasta = os.path.join(DATASET_BUILDER_DIR, "dataset.fa"),
        vcf_gz = os.path.join(DATASET_BUILDER_DIR, "dataset.vcf.gz"),
        vcf_tbi = os.path.join(DATASET_BUILDER_DIR, "dataset.vcf.gz.tbi"),
    output: dataset = os.path.join(DATASET_BUILDER_DIR, "dataset.vg"),
    log: os.path.join(DATASET_BUILDER_DIR, "vg_construct.log"),
    params:
        region = lambda wildcards: DATASETS[wildcards.dataset]["vg"]["region"],
        max_node_length = lambda wildcards: DATASETS[wildcards.dataset]["vg"]["max_node_length"],
    threads: workflow.cores * 0.75
    wildcard_constraints:
        builder = "vg_from_vcf",
    shell: """
        vg construct -t {threads} -r '{input.fasta}' -v '{input.vcf_gz}' -R {params.region} -m {params.max_node_length} > '{output.dataset}' 2> '{log}'
    """

rule tabix_index_vcf:
    input: vcf_gz = os.path.join(DATASET_BUILDER_DIR, "dataset.vcf.gz"),
    output: tbi = os.path.join(DATASET_BUILDER_DIR, "dataset.vcf.gz.tbi"),
    log: os.path.join(DATASET_BUILDER_DIR, "tabix_index_vcf.log"),
    wildcard_constraints:
        builder = "vg_from_vcf",
    shell: """
        tabix -f -p vcf '{input.vcf_gz}' > '{log}' 2>&1
    """

rule convert_vcf_gz_to_vcf_bgzf:
    input: vcf_gz = os.path.join(DATASET_BUILDER_DIR, "dataset.vcf.sgz"),
    output: vcf_bgzf = os.path.join(DATASET_BUILDER_DIR, "dataset.vcf.gz"),
    log: os.path.join(DATASET_BUILDER_DIR, "convert_vcf_gz_to_vcf_bgzf.log"),
    wildcard_constraints:
        builder = "vg_from_vcf",
    shell: """
        gzip -cd '{input.vcf_gz}' | bgzip -c > '{output.vcf_bgzf}' 2> '{log}'
    """

rule download_vcf_gz_file:
    output: vcf_gz = os.path.join(DATASET_BUILDER_DIR, "dataset.vcf.sgz"),
    params: url = lambda wildcards: DATASETS[wildcards.dataset]["urls"]["vcf_gz"],
    wildcard_constraints:
        builder = "vg_from_vcf",
    shell: """
        wget --progress=dot:mega -O '{output.vcf_gz}' '{params.url}'
    """

rule uncompress_vcf_fasta_gz_file:
    input: fasta_gz = os.path.join(DATASET_BUILDER_DIR, "dataset.fa.gz"),
    output: fasta = os.path.join(DATASET_BUILDER_DIR, "dataset.fa"),
    log: os.path.join(DATASET_BUILDER_DIR, "uncompress_vcf_fasta_gz_file.log"),
    wildcard_constraints:
        builder = "vg_from_vcf",
    shell: """
        set +e
        gzip -cd '{input.fasta_gz}' > '{output.fasta}' 2> '{log}'
        RC=$?
        set -e
        if [ $RC -ne 0 ] && [ $RC -ne 2 ]; then
            echo "[ERR] gzip returned $RC while decompressing {input.fasta_gz}" >&2
            exit $RC
        fi
    """

rule download_vcf_fasta_gz_file:
    output: fasta_gz = os.path.join(DATASET_BUILDER_DIR, "dataset.fa.gz"),
    params: url = lambda wildcards: DATASETS[wildcards.dataset]["urls"]["fa_gz"],
    wildcard_constraints:
        builder = "vg_from_vcf",
    shell: """
        wget --progress=dot:mega -O '{output.fasta_gz}' '{params.url}'
    """