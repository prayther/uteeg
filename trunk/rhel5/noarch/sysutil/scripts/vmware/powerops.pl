#!/usr/bin/perl -w
#
# Copyright 2006 VMware, Inc.  All rights reserved.
#
# This script allows users to perform power operations on a VM.
# Supported operations are poweron, poweroff, suspend, reset, reboot, shutdown and
# standby. For more information, execute the script with --help option.
#
# Examples:
#    powerops.pl --operation poweron --vmname MyVM
#    powerops.pl --operation poweroff --filter "config.guestFullName=Windows.*"


use strict;
use warnings;

use VMware::VIRuntime;

my %opts = (
   'operation' => {
      type => "=s",
      help => "The power operation to perform on the virtual machine(s) specified",
      required => 1,
   },
   'vmname' => {
      type => "=s",
      help => "The name of the virtual machine",
      required => 0,
   },
   'filter' => {
      type => "=s",
      help => "The filter used to select matching virtual machines",
      required => 0,
   },
);
Opts::add_options(%opts);

Opts::parse();
Opts::validate();

# Additional validation
if (!defined (Opts::get_option('filter') || Opts::get_option('vmname'))) {
   print "ERROR: --filter or --vmname must be specified\n\n";
   &help();
   exit (1);
}

my ($property_name, $property_value);

# Filter can be user provided.  For example, --filter "config.guestFullName=Windows*"
if( !defined (Opts::get_option('filter')) ){
   $property_name = "config.name";
   $property_value = Opts::get_option('vmname');
}
elsif (defined (Opts::get_option('filter'))){
   ($property_name, $property_value) = split ("=", Opts::get_option('filter'));
}

Util::connect();

my $vm_views = Vim::find_entity_views(view_type => 'VirtualMachine',
                                      filter => {$property_name => $property_value});

my $op = Opts::get_option('operation');

foreach (@$vm_views) {   
   # power on
   if( $op eq "poweron" ){
#      if($_->runtime->powerState->val ne 'poweredOff' && 
#         $_->runtime->powerState->val ne 'suspended' ){
#          print "The current state of the VM " . $_->name . " is ".
#                $_->runtime->powerState->val." ".
#                "The poweron operation is not supported in this state\n";
#          next ;
#      }
#      print "Powering on " . $_->name . "\n";
      $_->PowerOnVM();
      print "Poweron successfully completed\n";
   }   
   # reset
   elsif( $op eq "reset" ){
      if($_->runtime->powerState->val ne 'poweredOn'){
         print "The current state of the VM " . $_->name . " is ".
         $_->runtime->powerState->val." ".
         "The reset operation is not supported in this state\n";
         next ;
      }
      print "Resetting the VM " . $_->name . "\n";
             $_->ResetVM();
      print "Reset successfully completed\n";
   }   
   # standby
   elsif( $op eq "standby" ){
      if($_->runtime->powerState->val ne 'poweredOn' ){
         print "The current state of the VM " . $_->name . " is ".
               $_->runtime->powerState->val." ".
               "The standby operation is not supported in this state\n";
         next ;
      }
      print "Standby VM " . $_->name . "\n";
      $_->StandbyGuest();
      print "Standby successfully completed\n";
   }
   
   # power off
   elsif( $op eq "poweroff" ){
      if($_->runtime->powerState->val ne 'poweredOn'){
         print "The current state of the VM " . $_->name . " is ".
               $_->runtime->powerState->val." ".
               "The poweroff operation is not supported in this state\n";
         next ;
      }
      print "Powering off " . $_->name . "\n";
      $_->PowerOffVM();
      print "Poweroff successfully completed\n";
   }   
   # suspend
   elsif( $op eq "suspend" ){
      if($_->runtime->powerState->val ne 'poweredOn'){
         print "The current state of the VM " . $_->name . " is ".
               $_->runtime->powerState->val." ".
               "The suspend operation is not supported in this state\n";
         next ;
      }
      print "Suspending VM " . $_->name . "\n";
      $_->SuspendVM();
      print "Suspend successfully completed\n";
   }
   # soft shutdown
   elsif( $op eq "shutdown" ){
      if($_->runtime->powerState->val ne 'poweredOn'){
         print "The current state of the VM " . $_->name . " is ".
               $_->runtime->powerState->val." ".
               "The shutdown operation is not supported in this state\n";
         next ;
      }
      print "Shutting down VM " . $_->name . "\n";
      $_->ShutdownGuest();
      print "Shutdown successfully completed\n";
   }   
   # reboot
   elsif( $op eq "reboot" ){
      if($_->runtime->powerState->val ne 'poweredOn'){
         print "The current state of the VM " . $_->name . " is ".
               $_->runtime->powerState->val." ".
               "The reboot operation is not supported in this state\n";
         next ;
      }
      print "Rebooting VM " . $_->name . "\n";
      $_->RebootGuest();
      print "Reboot successfully completed\n";
   }
   
   else{
      die "\nInvalid argument --operation: '$op'";
   }
}

Util::disconnect();

