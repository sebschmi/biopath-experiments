######################
### RANDOM QUERIES ###
######################

DATASET_QUERIES = os.path.join(QUERIESDIR, "{dataset}.queries.gz")
DATASET_QUERIES_LOG = os.path.join(QUERIESDIR, "{dataset}.queries.log")

rule generate_queries:
    input: 
        dataset = DATASET,
        biopath = BIOPATH_BINARY,
    output:
        queries = DATASET_QUERIES,
    log: DATASET_STATISTICS_LOG,
    shell:  """
        '{input.biopath}' generate-queries --word-size 64 --graph-gfa-in '{input.dataset}' --query-out '{output.queries}' > '{log}' 2>&1
        """