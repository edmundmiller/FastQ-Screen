# FastQ-Screen Nextflow Workflow

A modern Nextflow implementation of FastQ Screen - a tool for multi-genome mapping and quality control.

## Overview

This workflow provides a Nextflow implementation of FastQ Screen with improved parallelization, resource management, and reproducibility. It leverages container technology and modern workflow management for scalable bioinformatics analysis.

## Quick Start

```bash
# Run with default settings
nextflow run main.nf --input '*.fastq.gz'

# Run with specific configuration
nextflow run main.nf --input 'sample.fastq.gz' --conf custom.conf --aligner bowtie2 --threads 8

# Run with subsetting for quick analysis
nextflow run main.nf --input '*.fastq.gz' --subset 10000

# Run with filtering
nextflow run main.nf --input 'sample.fastq.gz' --tag --filter '0010' --outdir results/
```

## Parameters

### Input/Output
- `--input`: Input FASTQ files (supports glob patterns)
- `--outdir`: Output directory (default: `./results`)
- `--conf`: FastQ Screen configuration file

### FastQ Screen Options
- `--aligner`: Sequence aligner to use (`bowtie`, `bowtie2`, `bwa`, `minimap2`) [default: `bowtie2`]
- `--threads`: Number of threads for alignment [default: 4]
- `--subset`: Subset to N reads for analysis
- `--top`: Extract top N reads from input
- `--bisulfite`: Run in bisulfite sequencing mode
- `--paired`: Process paired-end reads
- `--illumina1_3`: Use Illumina 1.3+ quality encoding
- `--get_genomes`: Download standard reference genomes

### Advanced Options
- `--tag`: Tag reads with genome mapping information
- `--filter`: Filter reads based on mapping pattern (e.g., `0010`)
- `--pass`: Minimum number of filters a read must pass
- `--inverse`: Invert filter results
- `--nohits`: Output reads that don't map to any genome
- `--force`: Overwrite existing output files

### Aligner-Specific Options
- `--bowtie_opts`: Additional Bowtie options
- `--bowtie2_opts`: Additional Bowtie2 options
- `--bwa_opts`: Additional BWA options
- `--minimap2_opts`: Additional minimap2 options
- `--bismark_opts`: Additional Bismark options (for bisulfite mode)

## Configuration

The workflow uses the same configuration file format as the original FastQ Screen:

```bash
# Example configuration file
BOWTIE2    /path/to/bowtie2
THREADS    8

DATABASE   Human      /path/to/human_index/basename
DATABASE   Mouse      /path/to/mouse_index/basename
DATABASE   Ecoli      /path/to/ecoli_index/basename
DATABASE   PhiX       /path/to/phix_index/basename
```

## Profiles

### Test Profile
```bash
nextflow run main.nf -profile test
```
Runs with the official FastQ Screen test dataset and limited resources.

### Other Profiles
- `docker`: Run with Docker containers
- `singularity`: Run with Singularity containers  
- `conda`: Run with Conda environments

## Output Files

The workflow produces the same output files as the original FastQ Screen:

- `*_screen.txt`: Tabular results showing mapping statistics
- `*_screen.html`: HTML report with interactive graphs  
- `*_screen.png`: Bar chart visualization (if GD::Graph available)
- `*.tagged.fastq`: Tagged reads (if `--tag` specified)
- `*_filter.fastq`: Filtered reads (if `--filter` specified)

## Architecture

### Key Design Decisions

1. **Container-First**: Uses the official fastq-screen bioconda package for reproducible execution
2. **Modular Design**: Different aspects (subsetting, screening, graphing, reporting) are separated into distinct processes
3. **Resource Optimization**: Nextflow handles parallelization and resource allocation efficiently
4. **Reproducibility**: Container support and environment management ensure consistent results

### Workflow Structure

```
main.nf                          # Entry point
├── workflows/fastq_screen.nf    # Main workflow logic
├── modules/                     # Process definitions
│   ├── fastq_screen_screen.nf   # Core screening using fastq-screen package
│   ├── subset_fastq.nf          # FASTQ subsetting with seqtk
│   ├── make_graphs.nf           # Graph generation  
│   ├── make_html_report.nf      # HTML report creation
│   └── filter_reads.nf          # Read filtering
├── conf/                        # Configuration files
└── lib/                         # Library functions
```

## Requirements

- Nextflow >= 23.04.0
- One of the supported aligners: Bowtie, Bowtie2, BWA, or minimap2
- Container engine (Docker, Singularity) or Conda

## Installation

1. Install Nextflow:
```bash
curl -s https://get.nextflow.io | bash
```

2. Clone this repository:
```bash
git clone https://github.com/edmundmiller/FastQ-Screen.git
cd FastQ-Screen
```

3. Run with your preferred profile:
```bash
nextflow run main.nf -profile conda --input '*.fastq.gz'
```

## Development with GitHub Copilot

This repository is configured for optimal GitHub Copilot experience. See [docs/COPILOT_GUIDE.md](docs/COPILOT_GUIDE.md) for:
- Setup instructions for VS Code and Copilot
- Best practices for bioinformatics workflow development
- Code snippets for common Nextflow patterns
- Tips for effective Copilot usage in computational biology

## Citation

If you use this workflow, please cite both the original FastQ Screen publication and this Nextflow implementation:

> Wingett SW and Andrews S. FastQ Screen: A tool for multi-genome mapping and quality control [version 2; referees: 4 approved]. F1000Research 2018, 7:1338 (https://doi.org/10.12688/f1000research.15931.2)

## Support

- Issues: https://github.com/edmundmiller/FastQ-Screen/issues
- Original FastQ Screen: https://www.bioinformatics.babraham.ac.uk/projects/fastq_screen/