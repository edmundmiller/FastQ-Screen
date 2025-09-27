# FastQ-Screen: Perl vs Nextflow Comparison

## Overview

This document demonstrates the transformation from the original Perl-based FastQ Screen to the new Nextflow implementation.

## Architecture Comparison

### Original Perl Implementation
```
fastq_screen (single monolithic Perl script ~2700 lines)
├── Command-line parsing
├── Configuration file reading  
├── FASTQ file processing
├── Multi-aligner support (Bowtie/Bowtie2/BWA/minimap2)
├── Result aggregation
├── Graph generation
├── HTML report creation
└── Read filtering and tagging
```

### New Nextflow Implementation
```
main.nf (workflow orchestration)
├── workflows/fastq_screen.nf (main workflow logic)
├── modules/
│   ├── fastq_screen_screen.nf (core screening - wraps original Perl)
│   ├── subset_fastq.nf (FASTQ subsetting with seqtk) 
│   ├── make_graphs.nf (graph generation)
│   ├── make_html_report.nf (HTML reporting)
│   └── filter_reads.nf (read filtering)
├── conf/ (configuration management)
└── lib/ (workflow libraries)
```

## Command Comparison

### Running Basic Analysis

**Original Perl:**
```bash
fastq_screen --conf config.txt sample.fastq.gz
```

**New Nextflow:**
```bash
nextflow run main.nf --input sample.fastq.gz --conf config.txt
```

### Running with Multiple Options

**Original Perl:**
```bash
fastq_screen --conf config.txt --aligner bowtie2 --threads 8 --subset 10000 --bisulfite --tag sample.fastq.gz
```

**New Nextflow:**
```bash
nextflow run main.nf --input sample.fastq.gz --conf config.txt --aligner bowtie2 --threads 8 --subset 10000 --bisulfite --tag
```

### Batch Processing

**Original Perl:**
```bash
for file in *.fastq.gz; do
    fastq_screen --conf config.txt "$file"
done
```

**New Nextflow:**
```bash
nextflow run main.nf --input '*.fastq.gz' --conf config.txt
```

## Key Improvements

### 1. Workflow Management
- **Before**: Manual loop for multiple files
- **After**: Automatic parallelization of multiple samples

### 2. Resource Management  
- **Before**: Fixed resource allocation per run
- **After**: Dynamic resource allocation per process with retry logic

### 3. Reproducibility
- **Before**: Dependency on local system configuration
- **After**: Container support (Docker/Singularity) and Conda environments

### 4. Scalability
- **Before**: Single-machine execution only  
- **After**: Support for HPC clusters, cloud computing, and local execution

### 5. Error Handling
- **Before**: Script fails completely on any error
- **After**: Process-level error handling with retry capabilities

### 6. Monitoring
- **Before**: Limited logging and progress tracking
- **After**: Comprehensive execution reports, timelines, and resource usage tracking

## Configuration Compatibility

The Nextflow version maintains 100% compatibility with existing configuration files:

```bash
# Same configuration file works with both versions
DATABASE    Human    /path/to/human/index
DATABASE    Mouse    /path/to/mouse/index  
DATABASE    Ecoli    /path/to/ecoli/index

BOWTIE2     /usr/local/bin/bowtie2
THREADS     8
```

## Output Compatibility

Both versions produce identical output files:
- `*_screen.txt` - Tabular results
- `*_screen.html` - HTML report  
- `*_screen.png` - Visualization
- `*.tagged.fastq` - Tagged reads (if requested)
- `*_filter.fastq` - Filtered reads (if requested)

## Migration Strategy

The migration strategy maintains maximum compatibility:

1. **Core Logic Preservation**: The original Perl screening logic is wrapped, not rewritten
2. **Parameter Compatibility**: All command-line options are preserved
3. **Output Format Consistency**: Results maintain identical formats
4. **Configuration Reuse**: Existing config files work without modification

## Performance Benefits

### Parallelization
- **Before**: Sequential processing of files
- **After**: Parallel processing of multiple files and workflow steps

### Resource Optimization
- **Before**: Fixed resource allocation regardless of file size
- **After**: Dynamic resource scaling based on input characteristics

### Resume Capability
- **Before**: Restart entire analysis on failure
- **After**: Resume from last successful checkpoint

## Example Workflows

### Quality Control Pipeline
```bash
# Process multiple samples with standard QC
nextflow run main.nf \
  --input 'samples/*.fastq.gz' \
  --get_genomes \
  --subset 100000 \
  --outdir qc_results/
```

### Contamination Screening
```bash  
# Full analysis with filtering
nextflow run main.nf \
  --input 'contaminated.fastq.gz' \
  --conf custom_contaminants.conf \
  --tag \
  --filter '0010' \
  --outdir cleaned/
```

### Bisulfite Analysis
```bash
# Bisulfite-seq specific analysis
nextflow run main.nf \
  --input 'bisulfite_*.fastq.gz' \
  --bisulfite \
  --aligner bowtie2 \
  --get_genomes \
  --outdir bisulfite_results/
```

## Summary

The Nextflow implementation provides all the benefits of modern workflow management while preserving the proven functionality of the original FastQ Screen. Users get improved performance, scalability, and reproducibility without sacrificing compatibility or reliability.