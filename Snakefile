import yaml, os, traceback, itertools

# Safe formatting

class SafeDict(dict):
    def __missing__(self, key):
        return '{' + key + '}'

def safe_format(str, **kwargs):
    return str.format_map(SafeDict(kwargs))

def safe_expand(str, **kwargs):
    items = []
    for key, values in kwargs.items():
        if type(values) is str or type(values) is not list:
            values = [values]
        items.append([(key, value) for value in values])

    for combination in itertools.product(*items):
        yield safe_format(str, **dict(combination))

def wildcard_format(str, wildcards):
    return str.format(**dict(wildcards.items()))

# Load config
with open("config/datasets.yml", "r") as f:
    DATASET_LIST = yaml.safe_load(f)["datasets"]
    DATASETS = { dataset["name"]: dataset for dataset in DATASET_LIST if dataset["enabled"] and dataset["builder"] in ["gfa_gz", "vg", "gbz"] }


# Data paths
BASEDIR = os.getcwd()
if "datadir" in config:
    BASEDIR = config["datadir"]
print(f"BASEDIR = {BASEDIR}")

DATADIR = os.path.join(BASEDIR, "data")
ANCIENTDIR = os.path.join(BASEDIR, "ancient")
TEMPDIR = os.path.join(BASEDIR, "temp")

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
    output: dataset = FINISHED_DATASET,
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