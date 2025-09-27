# FastQ-Screen Tests

This directory contains tests for the FastQ-Screen Nextflow pipeline using the [nf-test](https://github.com/askimed/nf-test) framework.

## Structure

- `nextflow.config` - Test-specific Nextflow configuration
- `main.nf.test` - Pipeline-level tests
- `modules/` - Module-specific tests (future)

## Running Tests

### Prerequisites

- Java 11+
- Nextflow 23.04.0+
- nf-test

### Local Testing

```bash
# Install nf-test
curl -fsSL https://get.nf-test.com | bash

# Run all tests
./nf-test test

# Run specific test file
./nf-test test tests/main.nf.test

# List available tests
./nf-test list
```

### CI/CD

Tests are automatically run in GitHub Actions using:
- `nf-core/setup-nextflow@v2`
- `nf-core/setup-nf-test@v1`

See `.github/workflows/git_actions.yml` for the complete CI configuration.

## Test Configuration

The test configuration disables containers for local testing and sets resource limits appropriate for CI environments. For tests requiring specific tools or containers, use stub tests or ensure the required dependencies are available.

## Adding Tests

1. Create test files with the `.nf.test` extension
2. Follow nf-test syntax for `nextflow_process`, `nextflow_workflow`, or `nextflow_pipeline` blocks
3. Use stub tests when external dependencies are not available
4. Update `nf-test.config` triggers if new critical files are added