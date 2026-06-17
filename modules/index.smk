#############
### INDEX ###
#############

DATASET_INDEX = os.path.join(INDEXDIR, "{dataset}.index")
DATASET_INDEX_BENCHMARK = os.path.join(INDEXDIR, "{dataset}.{algorithm}.timings.json")
DATASET_INDEX_LOG = os.path.join(INDEXDIR, "{dataset}.index")

rule biopath_statistics:
    input:
        dataset = DATASET,
        spqr_tree = SPQR_TREE,
        biopath = BIOPATH_BINARY,
    output:
        index = DATASET_INDEX,
        benchmark = DATASET_INDEX_BENCHMARK,
    log: DATASET_INDEX_LOG,
    shell: """
        '{input.biopath}' index --word-size 64 --graph-gfa-in '{input.dataset}' --spqr-in '{input.spqr_tree}' --index-out '{output.index}' --timing-out '{output.benchmark}' > '{log}' 2>&1
    """