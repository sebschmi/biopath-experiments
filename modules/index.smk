#############
### INDEX ###
#############

DATASET_INDEX = os.path.join(INDEXDIR, "{dataset}.{algorithm}.index")
DATASET_INDEX_BENCHMARK = os.path.join(INDEXDIR, "{dataset}.{algorithm}.timings.json")
DATASET_INDEX_LOG = os.path.join(INDEXDIR, "{dataset}.{algorithm}.log")

rule biopath_index:
    input:
        dataset = DATASET,
        spqr_tree = SPQR_TREE,
        biopath = BIOPATH_BINARY,
    output:
        index = DATASET_INDEX,
        benchmark = DATASET_INDEX_BENCHMARK,
    log: DATASET_INDEX_LOG,
    wildcard_constraints:
        algorithm = "index",
    shell: """
        '{input.biopath}' index --word-size 64 --graph-gfa-in '{input.dataset}' --spqr-in '{input.spqr_tree}' --index-out '{output.index}' --timing-out '{output.benchmark}' > '{log}' 2>&1
    """