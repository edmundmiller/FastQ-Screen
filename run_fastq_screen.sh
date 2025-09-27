#!/bin/bash

# FastQ Screen Nextflow Wrapper Script
# This script provides a simple way to run the Nextflow version of FastQ Screen

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
INPUT=""
CONFIG=""
OUTDIR="./results"
ALIGNER="bowtie2"
THREADS="4"
PROFILE="conda"
OTHER_ARGS=""

# Function to show usage
show_usage() {
    echo -e "${BLUE}FastQ Screen Nextflow Wrapper${NC}"
    echo ""
    echo "Usage: $0 [OPTIONS] INPUT_FILES"
    echo ""
    echo "Required:"
    echo "  INPUT_FILES                  FASTQ files to process (can use glob patterns)"
    echo ""
    echo "Options:"
    echo "  -c, --conf FILE             Configuration file"
    echo "  -o, --outdir DIR            Output directory (default: ./results)"
    echo "  -a, --aligner ALIGNER       Aligner: bowtie, bowtie2, bwa, minimap2 (default: bowtie2)"
    echo "  -t, --threads N             Number of threads (default: 4)"
    echo "  -p, --profile PROFILE       Nextflow profile (default: conda)"
    echo "  --subset N                  Subset to N reads"
    echo "  --bisulfite                 Run in bisulfite mode"
    echo "  --get-genomes               Download standard genomes"
    echo "  --test                      Run with test dataset"
    echo "  -h, --help                  Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 '*.fastq.gz'"
    echo "  $0 -c config.txt -t 8 sample.fastq.gz"
    echo "  $0 --test"
    echo "  $0 --get-genomes '*.fastq.gz'"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--conf)
            CONFIG="$2"
            shift 2
            ;;
        -o|--outdir)
            OUTDIR="$2"
            shift 2
            ;;
        -a|--aligner)
            ALIGNER="$2"
            shift 2
            ;;
        -t|--threads)
            THREADS="$2"
            shift 2
            ;;
        -p|--profile)
            PROFILE="$2"
            shift 2
            ;;
        --subset)
            OTHER_ARGS="$OTHER_ARGS --subset $2"
            shift 2
            ;;
        --bisulfite)
            OTHER_ARGS="$OTHER_ARGS --bisulfite"
            shift
            ;;
        --get-genomes)
            OTHER_ARGS="$OTHER_ARGS --get_genomes"
            shift
            ;;
        --test)
            PROFILE="test"
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            echo -e "${RED}Error: Unknown option $1${NC}" >&2
            show_usage
            exit 1
            ;;
        *)
            if [[ -z "$INPUT" ]]; then
                INPUT="$1"
            else
                echo -e "${RED}Error: Multiple input arguments provided${NC}" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if Nextflow is available
if ! command -v nextflow &> /dev/null; then
    echo -e "${RED}Error: Nextflow not found. Please install Nextflow first:${NC}"
    echo "  curl -s https://get.nextflow.io | bash"
    exit 1
fi

# Validate input for non-test runs
if [[ "$PROFILE" != "test" && -z "$INPUT" ]]; then
    echo -e "${RED}Error: Input files must be specified${NC}" >&2
    show_usage
    exit 1
fi

# Build the nextflow command
NF_CMD="nextflow run main.nf"
NF_CMD="$NF_CMD --outdir $OUTDIR"
NF_CMD="$NF_CMD --aligner $ALIGNER"
NF_CMD="$NF_CMD --threads $THREADS"
NF_CMD="$NF_CMD -profile $PROFILE"

if [[ "$PROFILE" != "test" ]]; then
    NF_CMD="$NF_CMD --input '$INPUT'"
fi

if [[ -n "$CONFIG" ]]; then
    NF_CMD="$NF_CMD --conf $CONFIG"
fi

if [[ -n "$OTHER_ARGS" ]]; then
    NF_CMD="$NF_CMD $OTHER_ARGS"
fi

echo -e "${BLUE}FastQ Screen Nextflow Workflow${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo -e "${YELLOW}Running command:${NC}"
echo "$NF_CMD"
echo ""

# Execute the command
eval "$NF_CMD"

if [[ $? -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}✓ FastQ Screen analysis completed successfully!${NC}"
    echo -e "${GREEN}Results are available in: $OUTDIR${NC}"
else
    echo ""
    echo -e "${RED}✗ FastQ Screen analysis failed${NC}" >&2
    exit 1
fi