########################
### QUERY BENCHMARKS ###
########################

wildcard_constraints:
    algorithm = "dijkstra|index",

QUERY_BENCHMARK = os.path.join(BENCHMARKSDIR, "{dataset}.{algorithm}.timings.json")
QUERY_RESULTS = os.path.join(BENCHMARKSDIR, "{dataset}.{algorithm}.query_results.gz")
QUERY_BENCHMARK_LOG = os.path.join(BENCHMARKSDIR, "{dataset}.{algorithm}.timings.log")

rule all_benchmarks:
    input:  lambda wildcards: [QUERY_BENCHMARK.format(dataset=dataset) for dataset in DATASETS.keys()],

def spqr_tree_input(wildcards):
    try:
        if wildcards.algorithm == "dijkstra":
            return ""
        elif wildcards.algorithm == "index":
            return SPQR_TREE
        else:
            raise ValueError(f"Unknown algorithm {wildcards.algorithm}")
    except Exception as e:
        print(f"Error in generate_test_datasets for dataset {wildcards.dataset}: {e}")
        traceback.print_exc()
        raise

def index_input(wildcards):
    try:
        if wildcards.algorithm == "dijkstra":
            return ""
        elif wildcards.algorithm == "index":
            return DATASET_INDEX
        else:
            raise ValueError(f"Unknown algorithm {wildcards.algorithm}")
    except Exception as e:
        print(f"Error in generate_test_datasets for dataset {wildcards.dataset}: {e}")
        traceback.print_exc()
        raise

rule query_benchmarks:
    input:
        dataset = DATASET,
        spqr_tree = spqr_tree_input,
        index = index_input,
        queries = DATASET_QUERIES,
        biopath = BIOPATH_BINARY,
    output:
        benchmark = QUERY_BENCHMARK,
        query_results = QUERY_RESULTS,
    params:
        spqr_tree = lambda wildcards, input: f"--spqr-in '{input.spqr_tree}'" if len(input.spqr_tree) > 0 else "",
        index = lambda wildcards, input: f"--index-in '{input.index}'" if len(input.index) > 0 else "",
    log: QUERY_BENCHMARK_LOG,
    shell: """
        '{input.biopath}' query --word-size 64 --graph-gfa-in '{input.dataset}' {params.spqr_tree} {params.index} --query-in '{input.queries}' --query-out '{output.query_results}' --timing-out '{output.benchmark}' > '{log}' 2>&1
    """