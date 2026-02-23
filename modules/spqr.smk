##########################
### SPQR TREE BUILDING ###
##########################

SPQR_TREE = os.path.join(DATADIR, "{dataset}.spqr")

rule build_spqr_tree:
    input:
        dataset = DATASET,
        bubblefinder = BUBBLEFINDER_BINARY,
    output:
        spqr_tree = SPQR_TREE,
    log: SPQR_TREE + ".log",
    shell: """
        '{input.bubblefinder}' spqr-tree -g '{input.dataset}' -o '{output.spqr_tree}' > '{log}' 2>&1
    """