# Contributing to FastQ-Screen

Thank you for your interest in contributing to FastQ-Screen! This guide will help you get started with development.

## Development Setup

### Prerequisites
- Git
- Nextflow (≥ 23.04.0)
- One of the supported aligners: Bowtie, Bowtie2, BWA, or minimap2
- Container engine (Docker, Singularity) or Conda

### Getting Started
1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/FastQ-Screen.git
   cd FastQ-Screen
   ```

### GitHub Copilot Setup
This repository is configured for optimal GitHub Copilot experience:

1. **Install VS Code and Copilot**: Follow the setup guide in [docs/COPILOT_GUIDE.md](docs/COPILOT_GUIDE.md)
2. **Open the project**: VS Code will automatically suggest installing recommended extensions
3. **Use the snippets**: Type `nf-` in Nextflow files to see available code snippets
4. **Leverage Copilot Chat**: Ask bioinformatics-specific questions for better assistance

The repository includes:
- `.copilotignore`: Excludes binary files and test data from suggestions
- VS Code settings optimized for bioinformatics development
- Code snippets for common Nextflow patterns
- File associations for Nextflow and configuration files

### Development Workflow

1. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes using VS Code with Copilot enabled

3. Test your changes:
   ```bash
   # Run basic validation
   ./validate_workflow.pl
   
   # Test with sample data
   nextflow run main.nf -profile test
   ```

4. Commit your changes with descriptive messages

5. Push and create a Pull Request

## Code Style

- Use descriptive comments that provide biological context
- Follow Nextflow best practices for process and workflow definitions
- Leverage Copilot suggestions but always review them for accuracy
- Include version collection in all processes
- Use appropriate resource labels

## Testing

- Run the validation script before committing: `./validate_workflow.pl`
- Test with the provided test profile: `nextflow run main.nf -profile test`
- Ensure new features work with different container engines

## Questions?

- Check the [docs/COPILOT_GUIDE.md](docs/COPILOT_GUIDE.md) for Copilot usage tips
- Open an issue for bugs or feature requests
- Use GitHub Discussions for questions about development

Thank you for contributing!