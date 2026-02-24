##################
### STATISTICS ###
##################

DATASET_STATISTICS_JSON = os.path.join(STATISTICSDIR, "{dataset}", "statistics.json")
DATASET_STATISTICS_TOML = os.path.join(STATISTICSDIR, "{dataset}", "statistics.toml")
DATASET_STATISTICS_LOG = os.path.join(STATISTICSDIR, "{dataset}", "statistics.log")

rule all_statistics:
    input:  lambda wildcards: [DATASET_STATISTICS_JSON.format(dataset=dataset) for dataset in DATASETS.keys()],

def generate_test_datasets(wildcards):
    try:
        template = "random{node_count}_{edge_count}_{ensure_strongly_connected}_{seed}"
        safe_expand(template, node_count = range(10, 20), edge_count = range(20, 40), ensure_strongly_connected = False)
    except Exception as e:
        print(f"Error in generate_test_datasets for dataset {wildcards.dataset}: {e}")
        traceback.print_exc()
        raise

rule test_statistics:
    input:  generate_test_datasets,

rule biopath_statistics:
    input:
        dataset = DATASET,
        spqr_tree = SPQR_TREE,
        biopath = BIOPATH_BINARY,
    output:
        statistics_json = DATASET_STATISTICS_JSON,
        statistics_toml = DATASET_STATISTICS_TOML,
    log: DATASET_STATISTICS_LOG,
    shell: """
        '{input.biopath}' statistics --word-size 64 --graph-gfa-in '{input.dataset}' --spqr-in '{input.spqr_tree}' --statistics-json-out '{output.statistics_json}' --statistics-toml-out '{output.statistics_toml}' > '{log}' 2>&1
    """