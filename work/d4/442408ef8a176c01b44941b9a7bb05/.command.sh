#!/bin/bash -euo pipefail
# Use FastQ Screen directly from the container
fastq_screen \
    --conf fastq_screen.conf.example \
    --aligner bowtie2 \
    --threads 4 \
     \
     \
     \
     \
     \
    --force \
     \
     \
     \
     \
     \
     \
     \
     \
     \
     \
     \
    test.fastq

cat <<-END_VERSIONS > versions.yml
"EDMUNDMILLER_FASTQSCREEN:FASTQ_SCREEN_SCREEN":
    fastq_screen: $(fastq_screen --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
END_VERSIONS
