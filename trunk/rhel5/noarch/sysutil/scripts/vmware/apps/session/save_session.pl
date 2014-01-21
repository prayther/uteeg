#!/usr/bin/perl -w
#
# Copyright 2007 VMware, Inc.  All rights reserved.
#
# This script demonstrates how to save session state to a file after login 

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";

use VMware::VIRuntime;

$Util::script_version = "1.0";

# read/validate options
Opts::parse();
Opts::validate();
if (!Opts::option_is_set('savesessionfile')) {
   print STDERR "Error: Must specify --savesessionfile option for this utility.\n";
   exit 1;
}

# connect to the server
my $url = Opts::get_option('url');
my $username = Opts::get_option('username');
my $password = Opts::get_option('password');
Vim::login(service_url => $url, user_name => $username, password => $password);

# save the session to a file
my $file = Opts::get_option('savesessionfile');
if (defined($file)) {
   Vim::save_session(session_file => $file);
   print "Session information saved.\n";
} else {
   print STDERR "Error: Must specify --savesessionfile option for this utility.\n";
   exit 1;
}

__END__

## bug 217605

=head1 NAME

save_session.pl - Connects to a host and saves session state to a file.

=head1 SYNOPSIS

 save_session.pl [options]

=head1 DESCRIPTION

This VI Perl command-line utility connects to a host and saves session state to a file.

=head1 OPTIONS

=over

=item B<savesessionfile>

Required. Name of the file to save the session state.

=back

=head1 EXAMPLES

 save_session.pl --url https://<host>:<port>/sdk/vimService
          --username myuser --password mypassword --savesessionfile mysavedsessionfile

=head1 SUPPORTED PLATFORMS

All operations work with VMware VirtualCenter 2.0.1 or later.

All operations work with VMware ESX 3.0.1 or later.

