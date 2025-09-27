process MAKE_HTML_REPORT {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/perl:5.26.2' :
        'biocontainers/perl:5.26.2' }"

    input:
    tuple val(meta), path(results)
    tuple val(meta), path(png), optional: true

    output:
    tuple val(meta), path("*.html"), emit: html
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    
    """
    # Extract HTML report generation functionality
    # In the original Perl script, this is handled by the make_html subroutine
    
    cat > make_html_report.pl << 'EOF'
#!/usr/bin/env perl

use warnings;
use strict;
use File::Basename;

my \$results_file = \$ARGV[0] || die "Usage: \$0 <results.txt>\\n";
my \$output_file = \$results_file;
\$output_file =~ s/\\.txt\$/\\.html/;

# Read the template
my \$template_path = "${projectDir}/fastq_screen_summary_template.html";
my \$template_content = "";

if (-e \$template_path) {
    open(TEMPLATE, '<', \$template_path) or die "Cannot read template: \$!";
    \$template_content = do { local \$/; <TEMPLATE> };
    close TEMPLATE;
} else {
    # Create a basic HTML template if the original is not found
    \$template_content = qq{
<!DOCTYPE html>
<html>
<head>
    <title>FastQ Screen Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .header { background-color: #4CAF50; color: white; padding: 20px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>FastQ Screen Report</h1>
    </div>
    <h2>Results for: ${prefix}</h2>
    <div id="results-content">
        <!-- Results will be inserted here -->
    </div>
</body>
</html>
};
}

# Read results and create HTML content
open(RESULTS, '<', \$results_file) or die "Cannot read results file: \$!";
my \$results_content = "";
while (my \$line = <RESULTS>) {
    chomp \$line;
    next if \$line =~ /^#/;  # Skip comments
    \$results_content .= \$line . "<br>\\n";
}
close RESULTS;

# Replace placeholder in template or insert into basic template
if (\$template_content =~ /results-content/) {
    \$template_content =~ s/<div id="results-content">.*?<\\/div>/<div id="results-content">\$results_content<\\/div>/s;
}

# Write HTML output
open(HTML, '>', \$output_file) or die "Cannot write HTML file: \$!";
print HTML \$template_content;
close HTML;

print "HTML report generated: \$output_file\\n";
EOF

    chmod +x make_html_report.pl
    perl make_html_report.pl ${results}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        perl: \$(perl --version | grep -oE 'v[0-9]+\\.[0-9]+\\.[0-9]+' | head -1)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo '<!DOCTYPE html><html><head><title>FastQ Screen Report</title></head><body><h1>FastQ Screen Report</h1><p>Report for ${prefix}</p></body></html>' > ${prefix}_screen.html
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        perl: v5.32.1
    END_VERSIONS
    """
}