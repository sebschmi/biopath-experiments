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
    DATASETS = { dataset["name"]: dataset for dataset in DATASET_LIST if dataset["enabled"] and dataset["builder"] in ["gfa_gz", "vg", "gbz", "gfa_zst", "vg_from_vcf"] }

with open("config/software.yml", "r") as f:
    SOFTWARE_CONFIG = yaml.safe_load(f)["software"]

# Data paths
BASEDIR = os.getcwd()
if "datadir" in config:
    BASEDIR = config["datadir"]
print(f"BASEDIR = {BASEDIR}")

SOFTWAREDIR = os.path.join(BASEDIR, "software")
DATADIR = os.path.join(BASEDIR, "data")
ANCIENTDIR = os.path.join(BASEDIR, "ancient")
TEMPDIR = os.path.join(BASEDIR, "temp")

include: "modules/datasets.smk"
include: "modules/software.smk"