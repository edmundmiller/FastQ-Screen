process FILTER_READS {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl:5.26.2' :
        'biocontainers/perl:5.26.2' }"

    input:
    tuple val(meta), path(tagged_reads)
    val filter
    val pass
    val inverse

    output:
    tuple val(meta), path("*_filter.fastq*"), emit: filtered
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def is_gzipped = tagged_reads.toString().endsWith('.gz')
    def output_ext = is_gzipped ? '.fastq.gz' : '.fastq'
    
    """
    # Create a Perl script to handle read filtering based on tags
    # This extracts the filtering logic from the original fastq_screen script
    
    cat > filter_reads.pl << 'EOF'
#!/usr/bin/env perl

use warnings;
use strict;
use File::Basename;

my \$tagged_file = \$ARGV[0];
my \$filter_string = \$ARGV[1];
my \$pass_threshold = \$ARGV[2] || 1;
my \$inverse = \$ARGV[3] || 0;

die "Usage: \$0 <tagged_file> <filter_string> [pass_threshold] [inverse]\\n" unless \$tagged_file && \$filter_string;

my \$output_file = basename(\$tagged_file);
\$output_file =~ s/\\.gz\$//;
\$output_file =~ s/\\.(tagged\\.)?fastq\$/\\_filter.fastq/;
\$output_file .= '.gz' if (\$tagged_file =~ /\\.gz\$/);

# Open input and output files
my \$input_fh;
if (\$tagged_file =~ /\\.gz\$/) {
    open(\$input_fh, "gunzip -c '\$tagged_file' |") or die "Cannot open \$tagged_file: \$!";
} else {
    open(\$input_fh, '<', \$tagged_file) or die "Cannot open \$tagged_file: \$!";
}

my \$output_fh;
if (\$output_file =~ /\\.gz\$/) {
    open(\$output_fh, "| gzip > '\$output_file'") or die "Cannot create \$output_file: \$!";
} else {
    open(\$output_fh, '>', \$output_file) or die "Cannot create \$output_file: \$!";
}

# Process reads
my \$reads_processed = 0;
my \$reads_passed = 0;

while (my \$header = <\$input_fh>) {
    chomp \$header;
    next unless \$header =~ /^@/;
    
    my \$sequence = <\$input_fh>;
    my \$plus = <\$input_fh>;
    my \$quality = <\$input_fh>;
    
    \$reads_processed++;
    
    # Extract tag from header (last field after colon)
    my \$tag = "";
    if (\$header =~ /:([0-9]+)\$/) {
        \$tag = \$1;
    } else {
        warn "No tag found in header: \$header\\n";
        next;
    }
    
    # Apply filter logic (simplified version of the original)
    my \$passes_filter = pass_filter(\$tag, \$filter_string, \$pass_threshold);
    \$passes_filter = !!\$passes_filter ^ !!\$inverse;  # Apply inverse if specified
    
    if (\$passes_filter) {
        print \$output_fh \$header . "\\n";
        print \$output_fh \$sequence;
        print \$output_fh \$plus;
        print \$output_fh \$quality;
        \$reads_passed++;
    }
}

close \$input_fh;
close \$output_fh;

print "Processed \$reads_processed reads, \$reads_passed passed filter\\n";

sub pass_filter {
    my (\$tag, \$filter_string, \$pass_threshold) = @_;
    
    return 0 unless length(\$tag) == length(\$filter_string);
    
    my \$passes = 0;
    for my \$i (0 .. length(\$filter_string) - 1) {
        my \$filter_char = substr(\$filter_string, \$i, 1);
        my \$tag_char = substr(\$tag, \$i, 1);
        
        next if \$filter_char eq '-';  # Skip inactive filters
        
        if (\$filter_char eq '0' && \$tag_char eq '0') { \$passes++; }     # No mapping
        elsif (\$filter_char eq '1' && \$tag_char eq '1') { \$passes++; }  # Unique mapping
        elsif (\$filter_char eq '2' && \$tag_char eq '2') { \$passes++; }  # Multi-mapping
        elsif (\$filter_char eq '3' && (\$tag_char eq '1' || \$tag_char eq '2')) { \$passes++; }  # Any mapping
        elsif (\$filter_char eq '4' && (\$tag_char eq '0' || \$tag_char eq '1')) { \$passes++; }  # No/unique mapping
        elsif (\$filter_char eq '5' && (\$tag_char eq '0' || \$tag_char eq '2')) { \$passes++; }  # No/multi mapping
    }
    
    return \$passes >= \$pass_threshold;
}
EOF

    chmod +x filter_reads.pl
    perl filter_reads.pl ${tagged_reads} "${filter}" ${pass} ${inverse ? '1' : '0'}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        perl: \$(perl --version | grep -oE 'v[0-9]+\\.[0-9]+\\.[0-9]+' | head -1)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def is_gzipped = tagged_reads.toString().endsWith('.gz')
    def output_ext = is_gzipped ? '.fastq.gz' : '.fastq'
    """
    touch ${prefix}_filter${output_ext}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        perl: v5.32.1
    END_VERSIONS
    """
}