#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;

# Simple syntax validation script for Nextflow files
# This checks basic syntax and structure

print "Validating Nextflow workflow files...\n";

my @nf_files = (
    'main.nf',
    'workflows/fastq_screen.nf',
    'modules/fastq_screen_screen.nf',
    'modules/make_graphs.nf',
    'modules/make_html_report.nf',
    'modules/subset_fastq.nf',
    'modules/filter_reads.nf'
);

my @config_files = (
    'nextflow.config',
    'conf/base.config',
    'conf/modules.config',
    'conf/test.config'
);

my $errors = 0;

print "\nChecking Nextflow files:\n";
foreach my $file (@nf_files) {
    print "  $file ... ";
    if (-e $file) {
        open(my $fh, '<', $file) or die "Cannot open $file: $!";
        my $content = do { local $/; <$fh> };
        close $fh;
        
        # Basic syntax checks
        my $syntax_ok = 1;
        my @issues = ();
        
        # Check for balanced braces
        my $open_braces = () = $content =~ /{/g;
        my $close_braces = () = $content =~ /}/g;
        if ($open_braces != $close_braces) {
            push @issues, "Unbalanced braces (open: $open_braces, close: $close_braces)";
            $syntax_ok = 0;
        }
        
        # Check for required DSL2 elements in main files
        if ($file eq 'main.nf') {
            unless ($content =~ /nextflow\.enable\.dsl\s*=\s*2/) {
                push @issues, "Missing DSL2 declaration";
                $syntax_ok = 0;
            }
        }
        
        # Check for process structure in module files
        if ($file =~ /^modules\//) {
            unless ($content =~ /process\s+\w+\s*{/) {
                push @issues, "Missing process definition";
                $syntax_ok = 0;
            }
            
            unless ($content =~ /input:/ && $content =~ /output:/ && $content =~ /script:/) {
                push @issues, "Missing required process sections (input/output/script)";
                $syntax_ok = 0;
            }
        }
        
        if ($syntax_ok) {
            print "OK\n";
        } else {
            print "ISSUES: " . join(", ", @issues) . "\n";
            $errors++;
        }
    } else {
        print "FILE NOT FOUND\n";
        $errors++;
    }
}

print "\nChecking config files:\n";
foreach my $file (@config_files) {
    print "  $file ... ";
    if (-e $file) {
        print "OK\n";
    } else {
        print "FILE NOT FOUND\n";
        $errors++;
    }
}

print "\nValidation complete.\n";
if ($errors == 0) {
    print "✓ All files passed basic validation\n";
    exit 0;
} else {
    print "✗ Found $errors issues\n";
    exit 1;
}