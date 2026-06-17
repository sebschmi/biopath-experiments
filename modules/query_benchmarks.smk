########################
### QUERY BENCHMARKS ###
########################

wildcard_constraints:
    algorithm = "dijkstra|index",

QUERY_BENCHMARK = os.path.join(BENCHMARKSDIR, "{dataset}.{algorithm}.timings.json")
QUERY_RESULTS = os.path.join(BENCHMARKSDIR, "{dataset}.{algorithm}.query_results.gz")
QUERY_BENCHMARK_LOG = os.path.join(BENCHMARKSDIR, "{dataset}.{algorithm}.timings.log")

def all_benchmarks_input(wildcards):
    try:
        requirements = []

        parameters = {
            "dataset": list(DATASETS.keys()),
            "algorithm": ["dijkstra", "index"],
        }
        
        requirements += expand(QUERY_BENCHMARK, **parameters)

        return requirements
    except Exception as e:
        print(f"Error in all_benchmarks_input: {e}")
        traceback.print_exc()
        raise

rule all_benchmarks:
    input:  all_benchmarks_input,

def spqr_tree_input(wildcards):
    try:
        if wildcards.algorithm == "dijkstra":
            return []
        elif wildcards.algorithm == "index":
            return SPQR_TREE
        else:
            raise ValueError(f"Unknown algorithm {wildcards.algorithm}")
    except Exception as e:
        print(f"Error in spqr_tree_input: {e}")
        traceback.print_exc()
        raise

def index_input(wildcards):
    try:
        if wildcards.algorithm == "dijkstra":
            return []
        elif wildcards.algorithm == "index":
            return DATASET_INDEX
        else:
            raise ValueError(f"Unknown algorithm {wildcards.algorithm}")
    except Exception as e:
        print(f"Error in index_input: {e}")
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
        '{input.biopath}' query --graph-gfa-in '{input.dataset}' {params.spqr_tree} {params.index} --query-in '{input.queries}' --query-out '{output.query_results}' --timing-out '{output.benchmark}' > '{log}' 2>&1
    """