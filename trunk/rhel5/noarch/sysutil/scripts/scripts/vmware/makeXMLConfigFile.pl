#!/usr/bin/perl -w
#
# makeXMLConfigFile.pl
#
# convert hosts file from CSV format to the XML format
# recognized by the VMCreate utility
#
use Text::ParseWords; sub parse_csv { return quotewords(",",0, $_[0]); }
use XML::Simple;

# setup data structure to get the format we need
my $virtualmachines = {
    'Virtual-Machine' => {}
};

# parse input file; fill out hash for XML creation
open (my $in, "<", "makeXMLConfigFile.in");
while (<$in>) {
    chomp;
    @fields = parse_csv($_);

    my $projectname = $fields[12];
    my $hostname    = $fields[0];
    my $vmhost      = $fields[5];
    my $datacenter  = $fields[30];
    my $guestid     = $fields[10];
    my $datastore   = $fields[8];
    my $disksize    = $fields[6];
    my $memory      = $fields[7];
    my $num_cpus    = $fields[13];
    my $nic_network = $fields[11];
    my $rolename    = $fields[25];
    my $nic_poweron = $fields[31];
    my $env         = $fields[32];
    my $vmname      = "$projectname-$rolename-$env-$hostname";

    $virtualmachines->{ 'Virtual-Machine' }{ $vmname } = {
        'Host'        => $vmhost,
        'Datacenter'  => $datacenter,
        'Guest-Id'    => $guestid,
        'Datastore'   => $datastore,
        'Disksize'    => $disksize,
        'Memory'      => $memory,
        'Number-of-Processor' => $num_cpus,
        'Nic-Network' => $nic_network,
        'Nic-Poweron' => $nic_poweron,
    }
}
close ($in);

# create XML file
open (my $tmp, "+>", "vmcreate_tmp.xml");
open (my $out, "+>", "vmcreate.xml");
XMLout($virtualmachines, OutputFile => $tmp,
           RootName   => 'Virtual-Machines',
           NoAttr     => 1,
           XMLDecl    => '<?xml version="1.0"?>', );
seek ($tmp, 0, 0); # rewind file
while (<$tmp>) {
    s/name/Name/g;
    print {$out} $_;
}
close ($tmp);
unlink("vmcreate_tmp.xml"); # delete temp file
close ($out);
