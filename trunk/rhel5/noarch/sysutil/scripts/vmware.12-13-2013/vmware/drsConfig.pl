#!/usr/bin/perl -w
#################################################################################
# drsConfig.pl
#    list or edit DRS settings for a cluster
#     --server <name> --username <u> --password <pwd>
#	--cluster <name>                   Cluster name to change
#     [--level <manual|partial|full>]    Automation level
#     [--enable]                         Enable DRS
#     [--disable]                        Disable DRS
#
#	Script provided as a sample.
#	DISCLAIMER. THIS SCRIPT IS PROVIDED TO YOU "AS IS" WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, 
#     WHETHER ORAL OR WRITTEN, EXPRESS OR IMPLIED. THE AUTHOR SPECIFICALLY DISCLAIMS ANY IMPLIED WARRANTIES 
#     OR CONDITIONS OF MERCHANTABILITY, SATISFACTORY QUALITY, NON-INFRINGEMENT AND FITNESS FOR A PARTICULAR PURPOSE. 
###################################################################################

use strict;
use warnings;
use Getopt::Long;
use VMware::VIRuntime;
use VMware::VILib;

my %opts = (
   cluster  => {
      type     => "=s",
      variable => "clusterName",
      help     => "Name of cluster",
      required => 1},
   level  => {
      type     => "=s",
      variable => "automationLevel",
      help     => "Automation Level (manual, partial, full)"},
   enable => {
      type     => "",
      variable => "enable",
      help     => "Enable DRS"},
   disable => {
      type     => "",
      variable => "disable",
      help     => "disable DRS"},
   rate => {
      type     => "=i",
      variable => 'rate',
      help     => 'VMotion Rate'}
      );

my %levels = (
      'full'    => 'fullyAutomated',
      'manual'  => 'manual',
      'partial' => 'partiallyAutomated');



# validate options, and connect to the server
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
#
#	validate the parameters
#
die ("Cannot set enable and disable, select only one.\n") 
     if ((Opts::option_is_set ('enable')) && (Opts::option_is_set ('disable')));
die ("Invalid setting for level.  Select manual, partial, or full.\n") 
     if ((Opts::option_is_set ('level')) && (! exists ($levels{Opts::get_option('level')})));
die ("Invalid setting for rate.  VMotion rate must be between 1 and 5.\n") 
     unless ((Opts::option_is_set ('rate')) && ((Opts::get_option('rate') >= 1) && (Opts::get_option('rate') <= 5)));
Util::connect();


my $clusterName = Opts::get_option ('cluster');
my $cluster = Vim::find_entity_view (view_type => "ClusterComputeResource", 
                                     filter => {name => "^$clusterName\$"});
Fail ("Cluster $clusterName not found.\n") unless ($cluster);
my $change = 0;
my $config = $cluster->configuration->drsConfig;
my $enable = $config->enabled;
my $level = $config->defaultVmBehavior->val;
my $rate = $config->vmotionRate;
if (Opts::option_is_set ('enable')) {
    $change = 1;
    $enable = 1;
    }
if (Opts::option_is_set ('disable')) {
    $change = 1;
    $enable = 0;
    }
if (Opts::option_is_set ('level')) {
    $change = 1;
    $level = $levels{Opts::get_option ('level')};
    }
if (Opts::option_is_set ('rate')) {
    $change = 1;
    $rate = Opts::get_option ('rate');
    }

if ($change) {
    print "Modifying cluster settings.\n";
    my $clusterDrsConfigInfo = new ClusterDrsConfigInfo (enabled => $enable, 
                                                         defaultVmBehavior => DrsBehavior->new ($level),
                                                         vmotionRate => $rate);
    my $clusterConfigSpec = new ClusterConfigSpec (drsConfig => $clusterDrsConfigInfo);
    eval {$cluster->ReconfigureCluster (spec => $clusterConfigSpec, modify => 1);};
    if ($@) {
       print "Modifications failed.\n$@"; }
   $cluster->update_view_data();
    }
print "\nSettings for Cluster:   $clusterName\n";
print "Enabled:                ", ($enable) ? 'Yes' : 'No', "\n";
print "Automation Level:       ", $level, "\n";
print "VMotion Rate:           ", $rate, "\n";



# logout
Util::disconnect();


sub Fail {
    my ($msg) = @_;
    Util::disconnect();
    die ($msg);
    exit ();
}
