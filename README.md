# mixcr

MiXCR is a universal software for fast and accurate T- and B- cell receptor repertoire extraction. MiXCR support whole range of sequencing data sources, including specially prepared TCR/BCR libraries, RNA-Seq, WGS, single-cell, etc.

## Dependencies

* [mixcr 4.4.2](https://github.com/milaboratory/mixcr/releases/download/v4.4.2/mixcr-4.4.2.zip)
* [java 14](https://github.com/AdoptOpenJDK/openjdk8-upstream-binaries/releases/download/OpenJDK14U-jdk_x64_linux_8u222b10.tar.gz)


## Usage

### Cromwell
```
java -jar cromwell.jar run mixcr.wdl --inputs inputs.json
```

### Inputs

#### Required workflow parameters:
Parameter|Value|Description
---|---|---
`fastqR1`|File|Input file with the first mate reads.
`fastqR2`|File|Input file with the second mate reads.
`license`|String|Path to mi.licence file with license


#### Optional workflow parameters:
Parameter|Value|Default|Description
---|---|---|---
`outputFileNamePrefix`|String|""|Output prefix, customizable. Default is the first file's basename.


#### Optional task parameters:
Parameter|Value|Default|Description
---|---|---|---
`alignReads.jobMemory`|Int|8|Memory allocated to the task.
`alignReads.timeout`|Int|20|Timeout in hours, needed to override imposed limits.
`alignReads.threads`|Int?|None|Optional threads parameter
`alignReads.parameters`|String|"rna-seq"|Customize the type of the data analysis, possible values are rna-seq, kAligner2 and default
`alignReads.organism`|String|"hsa"|Organism recognized by MIXCr, hsa, mmu or rat (others possible).
`alignReads.reportFile`|String|"alignments.report"|Optionally, specify a name of a report file
`alignReads.library`|String?|None|Optional custom V D J library for customization of analysis
`alignReads.allowPartial`|String?|None|A useful parameter to allow partial alignments, set to true if needed
`alignReads.modules`|String|"mixcr/4.4.2"|Names and versions of required modules.
`assemblePartial.jobMemory`|Int|8|Memory allocated to the task.
`assemblePartial.timeout`|Int|20|Timeout in hours, needed to override imposed limits.
`assemblePartial.threads`|Int?|None|Threads param for fastqc
`assemblePartial.reportFile`|String|"rescued_allignments.report"|Optionally, specify a name of a report file
`assemblePartial.modules`|String|"mixcr/4.4.2"|Names and versions of required modules.
`extendAlignments.jobMemory`|Int|8|Memory allocated to this task.
`extendAlignments.timeout`|Int|1|Timeout, in hours, needed to override imposed limits.
`extendAlignments.modules`|String|"mixcr/4.4.2"|Names and versions of required modules.
`assemble.jobMemory`|Int|8|Memory allocated to this task.
`assemble.timeout`|Int|1|Timeout, in hours, needed to override imposed limits.
`assemble.modules`|String|"mixcr/4.4.2"|Names and versions of required modules.
`exportClones.jobMemory`|Int|8|Memory allocated to this task.
`exportClones.timeout`|Int|1|Timeout, in hours, needed to override imposed limits.
`exportClones.preset`|String?|None|Optional string specifying preset for output scope, full (default) min, fullImputed or minImpute
`exportClones.modules`|String|"mixcr/4.4.2"|Names and versions of required modules.


### Outputs

Output | Type | Description
---|---|---
`alignmentReport`|File|Reporting alignment metrics
`rescuedReport`|File|Reporting rescued alignments results
`exportedClones`|File|human-readable export of clone assembly results


## Commands
 
 This section lists command(s) run by MIXCr workflow
 
 * Running MIXCr
 
 In its current implementation MIXCr workflow runs with RNAseq data as it's only type of input
 The same analysis may be conducted with a single wrapper command *analyze shotgun* but for the sake of
 flexibility and better control the analysis is divided into several tasks
 
 ALIGN
 
 ```
  java -jar mixcr.jar align -p ~{parameters} -s ~{organism} ~{"-OallowPartialAlignments=" + allowPartial} \
                         ~{"-t " + threads} ~{"-b " + library} ~{"-r " + reportFile} FASTQ_R1 FASTQ_R2 alignments.vdjca
 ```
 ASSEMBLE PARTIAL
 
 ```
  java -jar mixcr.jar assemblePartial ~{alignments} ~{"-t " + threads} ~{"-r " + reportFile} alignments_rescued_1.vdjca
  java -jar mixcr.jar assemblePartial alignments_rescued_1.vdjca ~{"-t " + threads} ~{"-r " + reportFile} alignments_rescued_2.vdjca
 
 ```
 
 EXTEND
 
 ```
  java -jar mixcr.jar extend ~{alignments_rescued} alignments_rescued_extended.vdjca
 
 ```
 
 ASSEMBLE
 
 ```
  java -jar mixcr.jar assemble ~{extendedAlignments} ~{customPrefix + "_clones.clns"}
 
 ```
 
 EXPORT CLONES
 
 ```
  java -jar mixcr.jar exportClones ~{assembledClones} -v ~{"-p " + preset} ~{customPrefix + "_clones.det.txt"}
 
 ````
 ## Support

For support, please file an issue on the [Github project](https://github.com/oicr-gsi) or send an email to gsi@oicr.on.ca .

_Generated with generate-markdown-readme (https://github.com/oicr-gsi/gsi-wdl-tools/)_
