#!/usr/bin/perl -w
#
# Copyright (c) 2007 VMware, Inc.  All rights reserved.


#use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";

use VMware::VIRuntime;
use AppUtil::VMUtil;

$SIG{__DIE__}=sub{Util::disconnect()};
$Util::script_version = "1.0";

sub create_hash;
sub get_vm_info;
sub print_log;

my %field_values = (
   'vmname'  => 'vmname',
   'numCpu'  =>  'numCpu',
   'memorysize' => 'memorysize' ,
   'virtualdisks' => 'virtualdisks',
   'template' => 'template',
   'vmPathName'=> 'vmPathName',
   'guestFullName'=> 'guestFullName',
   'guestId' => 'guestId',
   'hostName' => 'hostName',
   'ipAddress' => 'ipAddress',
   'toolsStatus' => 'toolsStatus',
   'overallCpuUsage' => 'overallCpuUsage',
   'hostMemoryUsage'=> 'hostMemoryUsage',
   'guestMemoryUsage'=> 'guestMemoryUsage',
   'overallStatus' => 'overallStatus',
);

my %toolsStatus = (
   'toolsNotInstalled' => 'VMware Tools has never been installed or has '
                           .'not run in the virtual machine.',
   'toolsNotRunning' => 'VMware Tools is not running.',
   'toolsOk' => 'VMware Tools is running and the version is current',
   'toolsOld' => 'VMware Tools is running, but the version is not current',
);

my %overallStatus = (
   'gray' => 'The status is unknown',
   'green' => 'The entity is OK',
   'red' => 'The entity definitely has a problem',
   'yellow' => 'The entity might have a problem',
);

my %opts = (
   'vmname' => {
      type => "=s",
      help => "The name of the virtual machine",
      required => 1,
   },
   'guestos' => {
      type => "=s",
      help => "The guest OS running on virtual machine",
      required => 0,
   },
   'ipaddress' => {
      type => "=s",
      help => "The IP address of virtual machine",
      required => 0,
   },
   'datacenter' => {
      type     => "=s",
      variable => "datacenter",
      help     => "Name of the datacenter",
      required => 0,
   },
   'pool'  => {
      type     => "=s",
      variable => "pool",
      help     => "Name of the resource pool",
      required => 0,
   },
   'host' => {
      type      => "=s",
      variable  => "host",
      help      => "Name of the host" ,
      required => 0,
   },
   'folder' => {
      type      => "=s",
      variable  => "folder",
      help      => "Name of the folder" ,
      required => 0,
   },
   'powerstatus' => {
      type     => "=s",
      variable => "powerstatus",
      help     => "State of the virtual machine: poweredOn or poweredOff",
   },
   'fields' => {
      type => "=s",
      help => "To specify vm properties for display",
      required => 0,
   },
   'out'=>{
      type => "=s",
      help => "The file name for storing the script output",
      required => 0,
   },
   'mode'=>{
      type => "=s",
      help => "mode disable/restore",
      required => 1,
   }
);

Opts::add_options(%opts);
Opts::parse();
Opts::validate(\&validate);

my @valid_properties;
my $filename;
my $vmname = Opts::get_option('vmname');
my $mode = Opts::get_option('mode');

Util::connect();
disable_vm_drs();
Util::disconnect();


sub disable_vm_drs {

   my ($config,$vm_key, $current_status, $tempconfig, $clusterConfigSpec);
   my $vm_in_array = 'false';
   my $cluster_view = Vim::find_entity_views(view_type => 'ClusterComputeResource');
   my $vm = Vim::find_entity_view(view_type => 'VirtualMachine',
                                         filter => {'name'=> $vmname});
   #get vm_key from name
   foreach($vm){
      my $vm = $_;
       foreach $config ($_->summary){
  
             $vm_key = $config->vm->value;
             
       }#eo fe
   
      
   }#eo fe

   # find the drs enabled/disabled status of the vm
   foreach(@$cluster_view){
      my $cluster_view = $_;
      if (defined $_->configurationEx->drsVmConfig){
       $vm_in_array = 'true';
       foreach $tempconfig (@{$_->configurationEx->drsVmConfig}){
             if($tempconfig->key->value eq $vm_key){ 
                $config = $tempconfig;
                if($tempconfig->enabled == 1){
                   $current_status = "enabled";
                }#eo if               
                else{
                   $current_status = "disabled";
                }#eo else

             }#eo if
             else{
               $current_status = "enabled";
             }#eo else
       }#eo fe
     }#eo if
    else{
        $current_status = "enabled";
    }#eo else

   #disable mode action
   if($mode eq 'disable'){

   #writes the vmname and status to a temp directory.
   open (MYFILE, '>>temp' . $vmname);
   #print MYFILE $vmname . "\n";
   print MYFILE $current_status;
   close(MYFILE);
  

     if($vm_in_array eq 'true'){
         my $disabled_config = ClusterDrsVmConfigInfo->new(enabled => 0,
                                                           key=> $vm);
         my $clusterDrsVmConfigSpec = ClusterDrsVmConfigSpec->new(operation => ArrayUpdateOperation->new('edit'),info => $disabled_config); 
         my $clusterConfigSpec = ClusterConfigSpecEx->new(drsVmConfigSpec => [$clusterDrsVmConfigSpec]); 
         $cluster_view->ReconfigureComputeResource(spec => $clusterConfigSpec,modify => 'true');     
     }else{
         my $disabled_config = ClusterDrsVmConfigInfo->new(enabled => 0,
                                                           key=> $vm);
         my $clusterDrsVmConfigSpec = ClusterDrsVmConfigSpec->new(operation => ArrayUpdateOperation->new('add'),info => $disabled_config); 
         my $clusterConfigSpec = ClusterConfigSpecEx->new(drsVmConfigSpec => [$clusterDrsVmConfigSpec]); 
         $cluster_view->ReconfigureComputeResource(spec => $clusterConfigSpec,modify => 'true');  
     }
     
   }#eo if

   #disable mode action
   if($mode eq 'restore'){

   #writes the vmname and status to a temp directory.
   open (MYFILE, '>>temp' . $vmname);
   #print MYFILE $vmname . "\n";
   print MYFILE $current_status;
   close(MYFILE);


     if($vm_in_array eq 'true'){
         my $disabled_config = ClusterDrsVmConfigInfo->new(enabled => 1,
                                                           key=> $vm);
         my $clusterDrsVmConfigSpec = ClusterDrsVmConfigSpec->new(operation => ArrayUpdateOperation->new('edit'),info => $disabled_config);
         my $clusterConfigSpec = ClusterConfigSpecEx->new(drsVmConfigSpec => [$clusterDrsVmConfigSpec]);
         $cluster_view->ReconfigureComputeResource(spec => $clusterConfigSpec,modify => 'true');
     }else{
         my $disabled_config = ClusterDrsVmConfigInfo->new(enabled => 0,
                                                           key=> $vm);
         my $clusterDrsVmConfigSpec = ClusterDrsVmConfigSpec->new(operation => ArrayUpdateOperation->new('add'),info => $disabled_config);
         my $clusterConfigSpec = ClusterConfigSpecEx->new(drsVmConfigSpec => [$clusterDrsVmConfigSpec]);
         $cluster_view->ReconfigureComputeResource(spec => $clusterConfigSpec,modify => 'true');
     }
     
   }#eo if


#   #restore mode action
#   if($mode eq 'restore'){
#     my $status_from_file;
#     #reads the status from a temp directory   
#     open (MYFILE, 'temp' . $vmname);
#      while (<MYFILE>){
#         chomp;
#         $status_from_file = $_;
#      }
#     close(MYFILE);
#     unlink("temp" . $vmname);
#     
#     if($status_from_file eq 'enabled'){
#         my $disabled_config = ClusterDrsVmConfigInfo->new(enabled => 1,
#                                                           key=> $vm);
#         my $clusterDrsVmConfigSpec = ClusterDrsVmConfigSpec->new(operation => ArrayUpdateOperation->new('edit'),info => $disabled_config); 
#         my $clusterConfigSpec = ClusterConfigSpecEx->new(drsVmConfigSpec => [$clusterDrsVmConfigSpec]); 
#         $cluster_view->ReconfigureComputeResource(spec => $clusterConfigSpec,modify => 'true');     
#        
#       
#     }
#     if($status_from_file eq 'disabled'){
#        #do nothing    
#     }
#   }
  }#eo fe
   

   
}# eo sub

# validate the host's fields to be displayed
# ===========================================
sub validate {
   my $valid = 1;
   my @properties_to_add;
   my $length =0;

   if (Opts::option_is_set('fields')) {
      my @filter_Array = split (',', Opts::get_option('fields'));
      foreach (@filter_Array) {
         if ($field_values{ $_ }) {
            $properties_to_add[$length] = $field_values{$_};
            $length++;
         }
         else {
            Util::trace(0, "\nInvalid property specified: " . $_ );
         }
      }
      @valid_properties =  @properties_to_add;
      if (!@valid_properties) {
         $valid = 0;
      }
   }
   else {
      @valid_properties = ("vmname",
                           "numCpu",
                           "memorysize",
                           "virtualdisks",
                           "template",
                           "vmPathName",
                           "guestFullName",
                           "guestId",
                           "hostName",
                           "ipAddress",
                           "toolsStatus",
                           "overallCpuUsage",
                           "hostMemoryUsage",
                           "guestMemoryUsage",
                           "overallStatus",
                           "mode"
                            );
   }
   if (Opts::option_is_set('out')) {
     my $filename = Opts::get_option('out');
     if ((length($filename) == 0)) {
        Util::trace(0, "\n'$filename' Not Valid:\n$@\n");
        $valid = 0;
     }
     else {
        open(OUTFILE, ">$filename");
        if ((length($filename) == 0) ||
          !(-e $filename && -r $filename && -T $filename)) {
           Util::trace(0, "\n'$filename' Not Valid:\n$@\n");
           $valid = 0;
        }
        else {
           print OUTFILE  "<Root>\n";
        }
     }
  }
  return $valid;   
}   

__END__	
