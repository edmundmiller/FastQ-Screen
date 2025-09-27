# Copilot Instructions for FastQ-Screen Nextflow Workflow

## Repository Overview

FastQ-Screen is a bioinformatics quality control tool that screens sequencing reads against multiple reference genomes to identify contamination and assess data quality. This repository contains both the original Perl implementation and a modern Nextflow DSL2 workflow implementation for improved scalability and reproducibility.

**Key characteristics:**
- **Type**: Bioinformatics workflow (Nextflow DSL2)
- **Languages**: Nextflow, Perl, Bash
- **Size**: ~150 files, mix of workflow code, documentation, and bioinformatics tools
- **Primary users**: Bioinformaticians, sequencing core facilities, researchers
- **Runtime**: Container-based execution (Docker/Singularity/Conda)

## Build, Test, and Run Instructions

### Prerequisites
**Always install these dependencies before attempting to build/test:**
```bash
# For Nextflow workflow (preferred method)
curl -s https://get.nextflow.io | bash  # Installs Nextflow >=23.04.0

# For container execution (Docker, Singularity, or Conda)
# Docker/Singularity: No additional setup needed
# For Conda profile: conda must be available

# For direct execution (not recommended)
sudo apt install bowtie2 bwa minimap2 samtools seqtk
```

### Testing the Workflow
**CRITICAL**: The test profile has dependency issues. Always use containers:

```bash
# WORKING: Test with conda profile (safest)
./nextflow run main.nf -profile test,conda --subset 100

# WORKING: Test with docker profile  
./nextflow run main.nf -profile test,docker --subset 100

# BROKEN: Direct execution without containers fails due to missing seqtk
./nextflow run main.nf -profile test --subset 100  # Will fail
```

**Expected test runtime**: 5-15 minutes depending on genome downloads

### Build Validation
```bash
# Validate Nextflow syntax
./nextflow run main.nf --help  # Should show parameter help

# Validate workflow structure 
perl validate_workflow.pl  # Custom validation script

# Check configuration
./nextflow config -profile test  # Shows resolved configuration
```

### Production Run Examples
```bash
# Basic QC run
./nextflow run main.nf --input '*.fastq.gz' -profile conda

# With custom configuration and filtering
./nextflow run main.nf --input 'sample.fastq.gz' \
  --conf custom.conf --filter '0010' --outdir results/ \
  -profile conda

# Bisulfite sequencing mode
./nextflow run main.nf --input 'bs_sample.fastq.gz' \
  --bisulfite --aligner bowtie2 -profile conda
```

**IMPORTANT**: Always specify a profile (`conda`, `docker`, or `singularity`) for reliable execution.

## Project Architecture and Layout

### Core Workflow Structure
```
main.nf                     # Entry point with DSL2 workflow definition
├── modules/               # Process definitions (DSL2 modules)
│   ├── fastq_screen_screen.nf   # Main screening process (uses container)
│   ├── subset_fastq.nf          # FASTQ subsetting with seqtk
│   ├── make_graphs.nf           # PNG graph generation  
│   ├── make_html_report.nf      # HTML report creation
│   └── environment.yml          # Conda dependencies specification
├── conf/                  # Configuration files
│   ├── base.config             # Resource requirements and process labels
│   ├── modules.config          # Module-specific publishing settings
│   └── test.config            # Test profile with limited resources
├── nextflow.config        # Main configuration with profiles and parameters
└── nextflow_schema.json   # Parameter validation schema
```

### Key Configuration Files
- **`nextflow.config`**: Main config defining profiles (conda/docker/singularity), resource limits, and default parameters
- **`conf/base.config`**: Process-specific CPU/memory/time requirements
- **`conf/test.config`**: Test profile with test dataset URL and reduced resources
- **`modules/environment.yml`**: Bioconda dependencies for containers

### Original FastQ Screen Components
```
fastq_screen                    # Original Perl implementation (executable)
fastq_screen.conf.example      # Configuration template
fastq_screen_test.conf         # Test configuration
fastq_screen_summary_template.html  # HTML template for reports
interactive_graphs.js          # JavaScript for interactive plots
Misc/remove_tags.pl            # Utility to remove FastQ Screen tags from headers
```

## GitHub Actions and Validation

### Continuous Integration
- **File**: `.github/workflows/git_actions.yml`
- **Issues**: Basic CI setup but outdated (uses Ubuntu packages, actions/checkout@v2)
- **Dependencies**: Installs bowtie2, GD::Graph Perl module
- **Tests**: Downloads test dataset, runs basic FastQ Screen commands

**Known CI Problems:**
- Uses deprecated GitHub Actions versions
- Bisulfite testing is commented out due to memory/time constraints
- No Nextflow workflow testing in CI

### Manual Validation
```bash
# Syntax validation
perl validate_workflow.pl

# Parameter validation
./nextflow run main.nf --help

# Preview workflow execution
./nextflow run main.nf -profile test,conda --subset 100 -preview
```

## Common Build Issues and Workarounds

### 1. Missing seqtk Dependency
**Error**: `seqtk: command not found` in SUBSET_FASTQ process
**Solution**: Always use container profiles (`-profile conda` or `-profile docker`)
```bash
# WRONG - will fail
./nextflow run main.nf -profile test

# CORRECT - works
./nextflow run main.nf -profile test,conda
```

### 2. Container Pull Issues  
**Error**: Container image download failures
**Workaround**: Specify alternative registries
```bash
# Edit nextflow.config registry settings if needed
apptainer.registry = 'quay.io'
docker.registry = 'quay.io'
```

### 3. Resource Limitations
**Error**: Process killed due to resource limits
**Solution**: Adjust in `conf/base.config` or override:
```bash
./nextflow run main.nf --max_memory 8.GB --max_cpus 4 -profile conda
```

### 4. Missing Configuration File
**Error**: "Configuration file not found"
**Solution**: Use `--conf` parameter or ensure `fastq_screen.conf` exists:
```bash
# Use built-in test config
./nextflow run main.nf -profile test,conda

# Or specify custom config
./nextflow run main.nf --conf fastq_screen_test.conf -profile conda
```

## Development Guidelines

### Code Style and Standards
- Follow Nextflow DSL2 best practices
- Use appropriate process labels (`process_single`, `process_medium`, etc.)
- Include version outputs in all processes
- Use containers for all dependencies
- Test changes with validation script: `perl validate_workflow.pl`

### Adding New Features
1. **New processes**: Add to `modules/` directory with appropriate container
2. **Parameters**: Update `nextflow_schema.json` for validation
3. **Testing**: Ensure works with test profile
4. **Documentation**: Update README_NEXTFLOW.md

### Critical Files to Never Modify
- `main.nf` structure (DSL2 workflow definition)
- `nextflow.config` profile definitions
- Original Perl `fastq_screen` executable
- Test configuration files

## Dependencies and Versions

### Container Dependencies (Bioconda)
```yaml
# From modules/environment.yml
- fastq-screen=0.15.3      # Main FastQ Screen tool
- bowtie2=2.4.5           # Primary aligner 
- bowtie=1.3.1            # Legacy aligner
- bwa=0.7.17              # BWA aligner
- minimap2=2.24           # Long-read aligner
- samtools=1.16.1         # SAM/BAM processing
- bismark=0.24.0          # Bisulfite sequencing
```

### Nextflow Requirements
- **Minimum version**: 23.04.0
- **DSL version**: DSL2 (declared in main.nf)
- **Java**: Compatible with Nextflow's Java requirements

## Trust These Instructions

These instructions have been validated through comprehensive testing of the repository build process, workflow execution, and analysis of the codebase structure. The documented workarounds address real issues encountered during testing.

**Only perform additional exploration if:**
- Instructions appear outdated (check git history)
- Specific functionality mentioned here fails
- You need details not covered in this comprehensive guide

**Always prefer container-based execution** over local installations for reliability and reproducibility.