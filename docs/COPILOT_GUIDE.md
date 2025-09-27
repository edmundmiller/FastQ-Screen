# GitHub Copilot Development Guide for FastQ-Screen

This repository has been configured for optimal GitHub Copilot experience when developing bioinformatics workflows with Nextflow.

## Setup

### Prerequisites
1. Install [Visual Studio Code](https://code.visualstudio.com/)
2. Install the [GitHub Copilot extension](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot)
3. Install the [GitHub Copilot Chat extension](https://marketplace.visualstudio.com/items?itemName=GitHub.copilot-chat)

### Recommended Extensions
The repository includes VS Code extension recommendations. When you open the project, VS Code will suggest installing:
- GitHub Copilot & Copilot Chat
- Nextflow Language Support
- Perl Language Support
- YAML and JSON support

### Configuration Files
- **`.copilotignore`**: Excludes binary files, test data, and generated content from Copilot suggestions
- **`.vscode/settings.json`**: Configures Copilot for bioinformatics development
- **`.vscode/extensions.json`**: Recommends useful extensions

## Using Copilot Effectively

### For Nextflow Development
When working with `.nf` files, Copilot is configured to understand:
- Process definitions and workflows
- Channel operations and data flow
- Container specifications (Docker/Singularity)
- Resource requirements and configurations

Example prompt for Copilot Chat:
```
Create a Nextflow process that runs FastQ Screen with the following parameters:
- Input: FASTQ files and configuration
- Output: Results and HTML report
- Use container: quay.io/biocontainers/fastq-screen
```

### For Perl Scripts
The original FastQ Screen is written in Perl. When working with Perl files:
- Copilot understands bioinformatics file formats (FASTQ, SAM, BAM)
- Provides suggestions for file parsing and processing
- Helps with regular expressions for sequence data

### For Configuration Files
When editing configuration files (`.config`, `.conf`):
- Copilot suggests appropriate database paths
- Helps with aligner-specific parameters
- Provides examples of genome database configurations

## Best Practices

### 1. Use Descriptive Comments
Write comments that describe the biological context:
```nextflow
// Process FASTQ files for contamination screening against multiple reference genomes
process FASTQ_SCREEN_SCREEN {
    // ... process definition
}
```

### 2. Leverage Copilot Chat
Use Copilot Chat for complex bioinformatics questions:
- "How to handle paired-end reads in Nextflow?"
- "What are the best practices for memory allocation in bioinformatics workflows?"
- "How to implement bisulfite sequencing mode?"

### 3. Context-Aware Development
Copilot works best when you provide context about:
- The type of sequencing data (RNA-seq, DNA-seq, bisulfite)
- The expected input/output formats
- Resource constraints and parallelization needs

## Excluded Files
The following files are excluded from Copilot suggestions to improve performance:
- Binary files (logos, fonts)
- Large JavaScript libraries
- Test data files (FASTQ, FASTA)
- Generated output directories
- Nextflow work directories

## Troubleshooting

### If Copilot Suggestions Seem Off
1. Check that you're using the correct file extensions (.nf for Nextflow)
2. Ensure your comments describe the bioinformatics context
3. Use Copilot Chat for complex workflow questions

### Performance Issues
If Copilot is slow:
1. Check that large data files are properly excluded
2. Close unused Nextflow work directories
3. Restart VS Code if necessary

## Contributing
When contributing to this repository:
1. Use Copilot to help write tests for new features
2. Let Copilot assist with documentation
3. Use Copilot Chat to understand existing code patterns

For questions about the Copilot configuration, please open an issue in the repository.