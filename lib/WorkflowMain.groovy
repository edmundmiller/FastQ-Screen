/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

import org.yaml.snakeyaml.Yaml

class WorkflowMain {

    //
    // Citation string for pipeline
    //
    public static String citation(workflow) {
        return "If you use ${workflow.manifest.name} for your analysis, please cite:\n\n" +
            "* The pipeline\n" +
            "  ${workflow.manifest.doi}\n\n" +
            "* The nf-core framework\n" +
            "  https://doi.org/10.1038/s41587-020-0439-x\n\n" +
            "* Software dependencies\n" +
            "  https://github.com/${workflow.manifest.name}/blob/master/CITATIONS.md"
    }

    //
    // Validate parameters and print summary to screen
    //
    public static void initialise(workflow, params, log) {
        
        // Print workflow version and exit on --version
        if (params.version) {
            String version_string = ""

            if (workflow.manifest.version) {
                version_string += "${workflow.manifest.name} ${workflow.manifest.version}"
            }

            if (workflow.commitId) {
                version_string += " [${workflow.commitId}]"
            }

            log.info version_string
            System.exit(0)
        }

        // Print help message and exit on --help
        if (params.help) {
            def String command = "nextflow run ${workflow.manifest.name}"
            log.info Headers.nf_core(workflow, params, log)
            log.info Schema.params_help(workflow, command)
            System.exit(0)
        }

        // Validate workflow parameters via the JSON schema
        if (params.validate_params) {
            Schema.validateParameters(workflow, params, log)
        }

        // Check that a -profile or Nextflow config has been provided to run the pipeline
        NfcoreTemplate.checkConfigProvided(workflow, log)

        // Check that conda channels are set-up correctly
        if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
            Utils.checkCondaChannels(log)
        }

        // Check AWS batch settings
        NfcoreTemplate.awsBatch(workflow, params)

        // Check input has been provided
        if (!params.input) {
            log.error "Please provide an input samplesheet or FASTQ files to the pipeline e.g. '--input *.fastq.gz'"
            System.exit(1)
        }
    }
}

class Headers {

    //
    // nf-core logo
    //
    public static String nf_core(workflow, params, log) {

        // Log colors ANSI codes
        Map logColours = Headers.logColours(params.monochrome_logs)

        String.format(
            """\n
            ${logColours.blue}--${logColours.reset}
            ${logColours.blue}                                          ,--./,-.
            ${logColours.blue}          ___     __   __   __   ___     /,-._.--~'
            ${logColours.blue}    |\\ | |__  __ /  ` /  \\ |__) |__         }  {
            ${logColours.blue}    | \\| |       \\__, \\__/ |  \\ |___     \\`-._,-`-,
            ${logColours.blue}                                          `._,._,'
            ${logColours.blue}    ${workflow.manifest.name} v${workflow.manifest.version}
            ${logColours.blue}--${logColours.reset}
            """.stripIndent()
        )
    }

    //
    // Return ANSI log colours
    //
    public static Map logColours(monochrome_logs = true) {
        Map colorcodes = [:]

        // Reset / Meta
        colorcodes['reset']      = monochrome_logs ? '' : "\033[0m"
        colorcodes['bold']       = monochrome_logs ? '' : "\033[1m"
        colorcodes['dim']        = monochrome_logs ? '' : "\033[2m"
        colorcodes['underlined'] = monochrome_logs ? '' : "\033[4m"
        colorcodes['blink']      = monochrome_logs ? '' : "\033[5m"
        colorcodes['reverse']    = monochrome_logs ? '' : "\033[7m"
        colorcodes['hidden']     = monochrome_logs ? '' : "\033[8m"

        // Regular Colors
        colorcodes['black']      = monochrome_logs ? '' : "\033[0;30m"
        colorcodes['red']        = monochrome_logs ? '' : "\033[0;31m"
        colorcodes['green']      = monochrome_logs ? '' : "\033[0;32m"
        colorcodes['yellow']     = monochrome_logs ? '' : "\033[0;33m"
        colorcodes['blue']       = monochrome_logs ? '' : "\033[0;34m"
        colorcodes['purple']     = monochrome_logs ? '' : "\033[0;35m"
        colorcodes['cyan']       = monochrome_logs ? '' : "\033[0;36m"
        colorcodes['white']      = monochrome_logs ? '' : "\033[0;37m"

        // Bold
        colorcodes['bblack']     = monochrome_logs ? '' : "\033[1;30m"
        colorcodes['bred']       = monochrome_logs ? '' : "\033[1;31m"
        colorcodes['bgreen']     = monochrome_logs ? '' : "\033[1;32m"
        colorcodes['byellow']    = monochrome_logs ? '' : "\033[1;33m"
        colorcodes['bblue']      = monochrome_logs ? '' : "\033[1;34m"
        colorcodes['bpurple']    = monochrome_logs ? '' : "\033[1;35m"
        colorcodes['bcyan']      = monochrome_logs ? '' : "\033[1;36m"
        colorcodes['bwhite']     = monochrome_logs ? '' : "\033[1;37m"

        // Underline
        colorcodes['ublack']     = monochrome_logs ? '' : "\033[4;30m"
        colorcodes['ured']       = monochrome_logs ? '' : "\033[4;31m"
        colorcodes['ugreen']     = monochrome_logs ? '' : "\033[4;32m"
        colorcodes['uyellow']    = monochrome_logs ? '' : "\033[4;33m"
        colorcodes['ublue']      = monochrome_logs ? '' : "\033[4;34m"
        colorcodes['upurple']    = monochrome_logs ? '' : "\033[4;35m"
        colorcodes['ucyan']      = monochrome_logs ? '' : "\033[4;36m"
        colorcodes['uwhite']     = monochrome_logs ? '' : "\033[4;37m"

        // High Intensity
        colorcodes['iblack']     = monochrome_logs ? '' : "\033[0;90m"
        colorcodes['ired']       = monochrome_logs ? '' : "\033[0;91m"
        colorcodes['igreen']     = monochrome_logs ? '' : "\033[0;92m"
        colorcodes['iyellow']    = monochrome_logs ? '' : "\033[0;93m"
        colorcodes['iblue']      = monochrome_logs ? '' : "\033[0;94m"
        colorcodes['ipurple']    = monochrome_logs ? '' : "\033[0;95m"
        colorcodes['icyan']      = monochrome_logs ? '' : "\033[0;96m"
        colorcodes['iwhite']     = monochrome_logs ? '' : "\033[0;97m"

        // Bold High Intensity
        colorcodes['biblack']    = monochrome_logs ? '' : "\033[1;90m"
        colorcodes['bired']      = monochrome_logs ? '' : "\033[1;91m"
        colorcodes['bigreen']    = monochrome_logs ? '' : "\033[1;92m"
        colorcodes['biyellow']   = monochrome_logs ? '' : "\033[1;93m"
        colorcodes['biblue']     = monochrome_logs ? '' : "\033[1;94m"
        colorcodes['bipurple']   = monochrome_logs ? '' : "\033[1;95m"
        colorcodes['bicyan']     = monochrome_logs ? '' : "\033[1;96m"
        colorcodes['biwhite']    = monochrome_logs ? '' : "\033[1;97m"

        return colorcodes
    }
}

// Placeholder classes - these would normally come from nf-core template
class Schema {
    public static void validateParameters(workflow, params, log) {
        log.info "Parameter validation skipped"
    }
    
    public static String params_help(workflow, command) {
        return """
        FastQ Screen Nextflow Pipeline

        Usage:
            ${command} --input '*.fastq.gz' [options]

        Input/output options:
            --input                 Path to FASTQ files (can use glob patterns)
            --outdir                Output directory (default: ./results)
            --conf                  FastQ Screen configuration file

        FastQ Screen options:
            --subset                Subset to N reads for analysis
            --aligner               Aligner to use: bowtie, bowtie2, bwa, minimap2 (default: bowtie2)
            --threads               Number of threads (default: 4)
            --bisulfite             Run in bisulfite mode
            --tag                   Tag reads with genome hits
            --filter                Filter reads based on genome hits
            --nohits                Output unmapped reads
            --get_genomes           Download standard genomes

        Other options:
            --help                  Show this help message and exit
            --version               Show pipeline version and exit
        """
    }
}

class NfcoreTemplate {
    public static void checkConfigProvided(workflow, log) {
        // Skip this check for now
    }
    
    public static void awsBatch(workflow, params) {
        // Skip AWS batch checks for now
    }
}

class Utils {
    public static void checkCondaChannels(log) {
        // Skip conda channel checks for now
    }
}