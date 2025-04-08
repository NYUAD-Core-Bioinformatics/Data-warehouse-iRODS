#!/usr/bin/perl -w
use strict;
use File::Basename;

=Requirmet
Path:  /tempZone/home/rods/g42_WGS
1) Make distinct directories : RAW_FASTQ, Trimmed FASTQ,BAM,gvcf
2) Metadata
"description" : "G42_WGS",
        "tag":"$base", #Filename
        "storage_Size" :"$size",
        "path":"$Path"
	"filetype":"fastq/bam/vcf"
3) yCreate
=cut

#my $FILE="17_aug_2022.txt";    #"/phrcscratch/phrc/g42count_NCB-814/from_server_info/genotyping.txt";
my $FILE=$ARGV[0];    #"/phrcscratch/phrc/g42count_NCB-814/from_server_info/genotyping.txt";
my $FolderNAME="G42_WGS";
my $IrodesPath= "/tempZone/home/rods/$FolderNAME";
my $SI=0;
#my $RemovePath="/phrcscratch/phrc/from_server_bioinfo/data_rsync_17_Aug_2022/";
my $RemovePath="/phrcscratch/phrc/from_server_bioinfo/";
my %UniqPath=();
#### Creating Json File
open HNS, ">$FILE\.json";
print HNS "[\n";


### Opening the input file
open HN,"<$FILE";

while(<HN>)
{
	chomp;
	#print "$_\n";
	my($size,$Path)=(split " ",$_);
	#my $FileName=(split "/",$Path)[-1];
	my ($base, $dir, $ext) = fileparse($Path);
	$ext =$1 if($base=~/^\s*\w+\.(\D+.*)/);
	my $Sample_Name="Others";
	$Sample_Name=$1 if($dir=~/^\s*.*(PGP\d+).*\/.*/);
	$dir=~s/$RemovePath//gi;
	my $irodes_Folder="$IrodesPath$dir";
	$UniqPath{$dir}=1;
	if($ext eq ""){	$ext =$1 if($base=~/^\s*\S+\.(.*)/); $ext ="Others" if($ext eq "");}

	print HNS ",\n" if($SI>0);
	print HNS qq( \{"path":"$irodes_Folder$base",
"metadata" : \{
	"description" : "$FolderNAME",
        "file_name":"$base",
	"storage_Size" :"$size",
	"path":"$Path",
	"sample_name":"$Sample_Name",
	"file_type":"$ext"
	\}
\});
	$SI++;
}
print HNS "\n]\n";
close(HNS);

open HNS, ">$FILE\_makedir.sh";
foreach my $Path (sort keys %UniqPath)
{
	print HNS"mkdir -p /$FolderNAME/$Path\n";
}
close(HNS)