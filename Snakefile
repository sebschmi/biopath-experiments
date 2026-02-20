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
    datasets = yaml.safe_load(f)["datasets"]

# Data paths
BASEDIR = os.getcwd()
if "datadir" in config:
    BASEDIR = config["datadir"]
print(f"BASEDIR = {BASEDIR}")

DATADIR = os.path.join(BASEDIR, "data")


localrules: create_all_datasets
rule create_all_datasets:
    input:  