#!/usr/bin/perl -w
# William Lam
# 02/02/2009
# http://engineering.ucsb.edu/~duonglt/vmware/
##################################################

use strict;
use warnings;
use Term::ANSIColor;
use VMware::VILib;
use VMware::VIRuntime;

$SIG{__DIE__} = sub{Util::disconnect();};

my %opts = (
   vmname => {
      type => "=s",
      help => "Name of VM",
      required => 1,
   },
   mac => {
      type => "=s",
      help => "MAC Address",
      required => 1,
   },
);

Opts::add_options(%opts);
Opts::parse();
Opts::validate();
Util::connect();

my $vmname = Opts::get_option('vmname');
my $mac = Opts::get_option('mac');

my $vm_view = Vim::find_entity_view(
	view_type => 'VirtualMachine',
	filter => {
	'name' =>  $vmname
	}
);

my $devices = $vm_view->config->hardware->device;

my ($key,$unitNumber,$backing,$controllerKey,$type);

#figure out the eth device you want to edit and 
#grab all attributes 
foreach my $device (@$devices){
	if($device->isa("VirtualEthernetCard")) {
		if($device->isa('VirtualE1000')) {
			$type = "VirtualE1000";
		}elsif($device->isa('VirtualPCNet32')) {
			$type = "VirtualPCNet32";
		}elsif($device->isa('VirtualVmxnet3')) {
			$type = "VirtualVmxnet3"
		}elsif($device->isa('VirtualVmxnet2')) {
			$type = "VirtualVmxnet2";
		}
		$key = $device->key;
		$controllerKey = $device->controllerKey;
		$unitNumber = $device->unitNumber;
		$backing = $device->backing;
	}
}

my $specOp = VirtualDeviceConfigSpecOperation->new('edit');
my $virtualdevice;

if($type eq "VirtualE1000") {
	$virtualdevice = VirtualE1000->new(
	        controllerKey => $controllerKey,
	        key => $key,
        	backing => $backing,
	        unitNumber => $unitNumber,
        	macAddress => $mac,
	        addressType => 'Manual'
	);
}elsif($type eq "VirtualPCNet32") {
	$virtualdevice = VirtualPCNet32->new(
                controllerKey => $controllerKey,
                key => $key,
                backing => $backing,
                unitNumber => $unitNumber,
                macAddress => $mac,
                addressType => 'Manual'
        );	
}elsif($type eq "VirtualVmxnet3") {
	$virtualdevice = VirtualVmxnet3->new(
                controllerKey => $controllerKey,
                key => $key,
                backing => $backing,
                unitNumber => $unitNumber,
                macAddress => $mac,
                addressType => 'Manual'
        );
}elsif($type eq "VirtualVmxnet2") {
	$virtualdevice = VirtualVmxnet2->new(
                controllerKey => $controllerKey,
                key => $key,
                backing => $backing,
                unitNumber => $unitNumber,
                macAddress => $mac,
                addressType => 'Manual'
        );
}

my $virtdevconfspec = VirtualDeviceConfigSpec->new(
	device => $virtualdevice,
	operation => $specOp
);

my $virtmachconfspec = VirtualMachineConfigSpec->new(
	deviceChange => [$virtdevconfspec],
);

eval {
	$vm_view->ReconfigVM_Task( spec => $virtmachconfspec );
	Util::trace(0,"\nVirtual machine '" . $vm_view->name
			  . "' reconfigured successfully.\n");
};

if ($@) {
	Util::trace(0, "\nReconfiguration failed: ");
	if (ref($@) eq 'SoapFault') {
		if (ref($@->detail) eq 'TooManyDevices') {
			Util::trace(0, "\nNumber of virtual devices exceeds "
				  . "the maximum for a given controller.\n");
		}
		elsif (ref($@->detail) eq 'InvalidDeviceSpec') {
			Util::trace(0, "The Device configuration is not valid\n");
			Util::trace(0, "\nFollowing is the detailed error: \n\n$@");
		}
		elsif (ref($@->detail) eq 'FileAlreadyExists') {
			Util::trace(0, "\nOperation failed because file already exists");
		}
		else {
			Util::trace(0, "\n" . $@ . "\n");
		}
	}
} else {
	Util::trace(0, "\n" . $@ . "\n");
}

Util::disconnect();

