#!/usr/bin/perl -w
#
# Copyright 2007 VMware, Inc.  All rights reserved.
#
# This script demonstrates how to use a saved session state file

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";

use VMware::VIRuntime;

$Util::script_version = "1.0";

# read/validate options
Opts::parse();
Opts::validate();
if (!Opts::option_is_set('sessionfile')) {
   print "Must specify sessionfile for this sample\n";
   Opts::usage();
}

# load the session from the file
my $url = Opts::get_option('url');
my $file = Opts::get_option('sessionfile');
Vim::load_session(service_url => $url, session_file => $file);

# get views of all VM's
my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine');
foreach (@$vm_views) {      
   print $_->name . ": " . $_->config->guestFullName . "\n";
}
print "\nSession information loaded and tested.\n";

__END__

## bug 217605

=head1 NAME

load_session.pl - Loads a saved session to a host.

=head1 SYNOPSIS

 load_session.pl [options]

=head1 DESCRIPTION

This VI Perl command-line utility connects to a host using a saved session file.

=head1 OPTIONS

=over

=item B<sessionfile>

Required. Name of the saved session file.

=back

=head1 EXAMPLES

 load_session.pl --url https://<host>:<port>/sdk/vimService
          --username myuser --password mypassword --sessionfile mysavedsessionfile

=head1 SUPPORTED PLATFORMS

All operations work with VMware VirtualCenter 2.0.1 or later.

All operations work with VMware ESX 3.0.1 or later.

