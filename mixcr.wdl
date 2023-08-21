version 1.0

# ================================================================================
# Workflow accepts two fastq files for paired-end sequencing, with R1 and R2 reads
# ================================================================================
workflow mixcr {
input {
  File fastqR1 
  File fastqR2
  String license
  String outputFileNamePrefix = ""
}

String sampleID = if outputFileNamePrefix=="" then basename(fastqR1, ".fastq.gz") else outputFileNamePrefix

call alignReads {input: R1 = fastqR1, R2 = fastqR2, license = license}
call assemblePartial {input: alignments = alignReads.alignmentFile, license = license}
call extendAlignments {input: alignments_rescued = assemblePartial.alignments_rescued, license = license}
call assemble {input: extendedAlignments  = extendAlignments.extendedAlignments, customPrefix = sampleID, license = license}
call exportClones {input: assembledClones = assemble.assembledClones, customPrefix = sampleID, license = license}

parameter_meta {
  fastqR1: "Input file with the first mate reads."
  fastqR2: "Input file with the second mate reads."
  license: "Path to mi.licence file with license"
  outputFileNamePrefix: "Output prefix, customizable. Default is the first file's basename."
}

meta {
    author: "Peter Ruzanov"
    email: "pruzanov@oicr.on.ca"
    description: "MiXCR is a universal software for fast and accurate T- and B- cell receptor repertoire extraction. MiXCR support whole range of sequencing data sources, including specially prepared TCR/BCR libraries, RNA-Seq, WGS, single-cell, etc."
    dependencies: [
      {
        name: "mixcr/4.4.2",
        url: "https://github.com/milaboratory/mixcr/releases/download/v4.4.2/mixcr-4.4.2.zip"
      },
      {
        name: "java/14",
        url: "https://github.com/AdoptOpenJDK/openjdk8-upstream-binaries/releases/download/OpenJDK14U-jdk_x64_linux_8u222b10.tar.gz"
      }
    ]
    output_meta: {
        alignmentReport: "Reporting alignment metrics",
        rescuedReport: "Reporting rescued alignments results",
        exportedClones: "human-readable export of clone assembly results"
    }
}

output {
  File alignmentReport = alignReads.report
  File rescuedReport = assemblePartial.report
  File exportedClones = exportClones.exportedClones
}
}


# ====================
#    ALIGN
# ====================
task alignReads {
input {
  Int  jobMemory = 8
  Int  timeout   = 20
  Int? threads
  String parameters = "rna-seq"
  String organism = "hsa"
  String reportFile = "alignments.report"
  String license
  String? library
  String? allowPartial
  File R1
  File R2
  String modules = "mixcr/4.4.2"
}

command <<<
 set -euo pipefail
 unset _JAVA_OPTIONS
 export MI_LICENSE=$(cat ~{license})
 java -Xmx~{jobMemory - 4}G -Xms~{jobMemory - 5}G -jar $MIXCR_ROOT/bin/mixcr.jar align -p ~{parameters} -s ~{organism} ~{"-OallowPartialAlignments=" + allowPartial} ~{"-t " + threads} ~{"-b " + library} -r ~{reportFile} ~{R1} ~{R2} alignments.vdjca
>>>

parameter_meta {
 jobMemory: "Memory allocated to the task."
 organism: "Organism recognized by MIXCr, hsa, mmu or rat (others possible)."
 threads: "Optional threads parameter"
 license: "Path to mi.licence file with license"
 library: "Optional custom V D J library for customization of analysis"
 parameters: "Customize the type of the data analysis, possible values are rna-seq, kAligner2 and default"
 allowPartial: "A useful parameter to allow partial alignments, set to true if needed" 
 R1: "Input file with the first mate reads."
 R2: " Input file with the second mate reads."
 reportFile: "Optionally, specify a name of a report file"
 modules: "Names and versions of required modules."
 timeout: "Timeout in hours, needed to override imposed limits."
}

runtime {
  memory:  "~{jobMemory} GB"
  modules: "~{modules}"
  timeout: "~{timeout}"
}

output {
  File alignmentFile = "alignments.vdjca"
  File report = "~{reportFile}"
}
}

# =========================
#   ASSEMBLE PARTIAL
# =========================
task assemblePartial {
input {
  Int  jobMemory = 8
  Int  timeout   = 20
  Int? threads
  String reportFile = "rescued_allignments.report"
  String license
  File alignments
  String modules = "mixcr/4.4.2"
}

command <<<
 set -euo pipefail
 unset _JAVA_OPTIONS
 export MI_LICENSE=$(cat ~{license})
 java -Xmx~{jobMemory - 4}G -Xms~{jobMemory - 5}G -jar $MIXCR_ROOT/bin/mixcr.jar assemblePartial ~{alignments} ~{"-t " + threads} alignments_rescued_1.vdjca
 java -Xmx~{jobMemory - 4}G -Xms~{jobMemory - 5}G -jar $MIXCR_ROOT/bin/mixcr.jar assemblePartial alignments_rescued_1.vdjca ~{"-t " + threads} -r ~{reportFile} alignments_rescued_2.vdjca
>>>

parameter_meta {
 jobMemory: "Memory allocated to the task."
 threads: "Threads param for fastqc"
 alignments: "File with alignments produced in the previous step"
 license: "Path to mi.licence file with license"
 modules: "Names and versions of required modules."
 reportFile: "Optionally, specify a name of a report file"
 timeout: "Timeout in hours, needed to override imposed limits."
}

runtime {
  memory:  "~{jobMemory} GB"
  modules: "~{modules}"
  timeout: "~{timeout}"
}

output {
  File alignments_rescued = "alignments_rescued_2.vdjca"
  File report = "~{reportFile}"
}
}


# =================================
#     EXTEND ALIGNMENTS
# =================================
task extendAlignments {
input {
  Int  jobMemory = 8
  File alignments_rescued
  Int timeout    = 1
  String license
  String modules = "mixcr/4.4.2"
}

parameter_meta {
 alignments_rescued: "Input file, output from the previous step."
 jobMemory: "Memory allocated to this task."
 license: "Path to mi.licence file with license"
 timeout: "Timeout, in hours, needed to override imposed limits."
 modules: "Names and versions of required modules."
}

command <<<
 set -euo pipefail
 unset _JAVA_OPTIONS
 export MI_LICENSE=$(cat ~{license})
 java -Xmx~{jobMemory - 4}G -Xms~{jobMemory - 5}G -jar $MIXCR_ROOT/bin/mixcr.jar extend ~{alignments_rescued} alignments_rescued_extended.vdjca
>>>

runtime {
  memory:  "~{jobMemory} GB"
  modules: "~{modules}"
  timeout: "~{timeout}"
}


output {
  File extendedAlignments = "alignments_rescued_extended.vdjca"
}
}

# ===============================
#     ASSEMBLE
# ===============================
task assemble {
input {
  Int  jobMemory = 8
  File extendedAlignments
  String customPrefix = "ASSEMBLED_"
  Int timeout = 1
  String license
  String modules = "mixcr/4.4.2"
}

parameter_meta {
 extendedAlignments: "Input file, extended alignments from the previous step."
 customPrefix: "Prefix for making a file."
 jobMemory: "Memory allocated to this task."
 license: "Path to mi.licence file with license"
 timeout: "Timeout, in hours, needed to override imposed limits."
 modules: "Names and versions of required modules."
}

command <<<
 set -euo pipefail
 unset _JAVA_OPTIONS
 export MI_LICENSE=$(cat ~{license})
 java -Xmx~{jobMemory - 4}G -Xms~{jobMemory - 5}G -jar $MIXCR_ROOT/bin/mixcr.jar assemble ~{extendedAlignments} ~{customPrefix + "_clones.clns"}
>>>

runtime {
  memory:  "~{jobMemory} GB"
  modules: "~{modules}"
  timeout: "~{timeout}"
}


output {
  File assembledClones = "~{customPrefix}_clones.clns"
}
}

# ===============================
#     EXPORT CLONES
# ===============================
task exportClones {
input {
  Int jobMemory = 8
  Int timeout = 1
  File assembledClones
  String license
  String? preset
  String customPrefix = "EXPORTED_"
  String modules = "mixcr/4.4.2"
 }

parameter_meta {
 assembledClones: "Input file with assembled clones."
 customPrefix: "Prefix for making a file."
 license: "Path to mi.licence file with license"
 preset: "Optional string specifying preset for output scope, full (default) min, fullImputed or minImpute"
 jobMemory: "Memory allocated to this task."
 modules: "Names and versions of required modules."
 timeout: "Timeout, in hours, needed to override imposed limits."
}

command <<<
 set -euo pipefail
 unset _JAVA_OPTIONS
 export MI_LICENSE=$(cat ~{license})
 java -Xmx~{jobMemory - 4}G -Xms~{jobMemory - 5}G -jar $MIXCR_ROOT/bin/mixcr.jar exportClones ~{assembledClones} -v ~{"-p " + preset} ~{customPrefix + "_clones.det.txt"}
>>>

runtime {
  memory:  "~{jobMemory} GB"
  modules: "~{modules}"
  timeout: "~{timeout}"
}


output {
  File exportedClones = "~{customPrefix}_clones.det.txt"
}
}
