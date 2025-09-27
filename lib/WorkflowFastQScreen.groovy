/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

class WorkflowFastQScreen {

    //
    // Check and validate parameters
    //
    public static void initialise(params, log) {
        
        // Check input files exist
        if (params.input) {
            if (!params.input.contains('*')) {
                def inputFile = new File(params.input)
                if (!inputFile.exists()) {
                    log.error "Input file does not exist: ${params.input}"
                    System.exit(1)
                }
            }
        }

        // Validate aligner choice
        if (params.aligner && !['bowtie', 'bowtie2', 'bwa', 'minimap2'].contains(params.aligner)) {
            log.error "Invalid aligner specified: ${params.aligner}. Must be one of: bowtie, bowtie2, bwa, minimap2"
            System.exit(1)
        }

        // Validate filter format if provided
        if (params.filter && !params.filter.matches(/^[012345-]+$/)) {
            log.error "Invalid filter format: ${params.filter}. Must contain only digits 0-5 and hyphens."
            System.exit(1)
        }

        // Validate threads
        if (params.threads && params.threads < 1) {
            log.error "Number of threads must be >= 1"
            System.exit(1)
        }

        // Validate subset count
        if (params.subset && params.subset < 1) {
            log.error "Subset count must be >= 1"
            System.exit(1)
        }

        // Check for required dependencies when using specific aligners
        if (params.bisulfite && params.aligner && !['bowtie', 'bowtie2'].contains(params.aligner)) {
            log.error "Bisulfite mode only supports bowtie and bowtie2 aligners"
            System.exit(1)
        }
    }

    //
    // Function to validate config file format
    //
    public static Boolean isValidConfig(configFile) {
        def validConfig = true
        
        try {
            def lines = new File(configFile).readLines()
            def hasDatabase = false
            
            lines.each { line ->
                line = line.trim()
                if (line.startsWith('DATABASE')) {
                    hasDatabase = true
                }
            }
            
            if (!hasDatabase) {
                validConfig = false
            }
        } catch (Exception e) {
            validConfig = false
        }
        
        return validConfig
    }
}