################
### SOFTWARE ###
################

wildcard_constraints:
    software_name = "[^/]+",

RUST_DIR = os.path.join(SOFTWAREDIR, "rust", "{software_name}")
RUST_BINARY = os.path.join(RUST_DIR, "target", "release", "{software_name}")

BIOPATH_DIR = safe_format(RUST_DIR, software_name = "biopath")
BIOPATH_BINARY = safe_format(RUST_BINARY, software_name = "biopath")

############
### RUST ###
############

rule download_rust:
    output: cargo_toml = os.path.join(RUST_DIR, "Cargo.toml"),
    params:
        software_dir = RUST_DIR,
        repo = lambda wildcards: SOFTWARE_CONFIG[wildcards.software_name]["repo"],
        version = lambda wildcards: SOFTWARE_CONFIG[wildcards.software_name]["version"],
    shell: """
        mkdir -p '{params.software_dir}'
        rm -rf '{params.software_dir}'

        git clone {params.repo} '{params.software_dir}'
        cd '{params.software_dir}'
        git checkout {params.version}
        
        cargo fetch --locked
    """

rule build_rust:
    input:  cargo_toml = os.path.join(RUST_DIR, "Cargo.toml"),
    output: binary = RUST_BINARY,
    params: software_dir = RUST_DIR,
    threads: workflow.cores * 0.25
    shell:  """
        cd '{params.software_dir}'
        cargo build --release -j {threads} --offline
        """