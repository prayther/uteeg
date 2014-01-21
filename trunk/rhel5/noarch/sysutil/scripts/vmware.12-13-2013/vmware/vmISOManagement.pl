#!/usr/bin/perl -w
# William Lam
# 10/26/2009
# http://engineering.ucsb.edu/~duonglt/vmware/
# http://communities.vmware.com/docs/DOC-9852
##################################################

use strict;
use warnings;
use VMware::VILib;
use VMware::VIRuntime;

$SIG{__DIE__} = sub{Util::disconnect();};

my %opts = (
   operation => {
      type => "=s",
      help => "[queryiso|mount|umount]",
      required => 1,
   },
   vmname => {
      type => "=s",
      help => "Name of VM to either mount or unmount the ISO",
      required => 1,
   },
   datastore => {
      type => "=s",
      help => "Name of the datastore containing the ISO (use operation queryiso if not sure)",
      required => 0,
   },
   filename => {
      type => "=s",
      help => "Path to name of the .iso file (use operation queryiso if not sure)",
      required => 0,
   },
);

Opts::add_options(%opts);
Opts::parse();
Opts::validate();
Util::connect();

my $operation = Opts::get_option('operation');
my $vmname = Opts::get_option('vmname');
my $datastore = Opts::get_option('datastore');
my $filename = Opts::get_option('filename');

my ($vm_view);

$vm_view = Vim::find_entity_view(view_type => 'VirtualMachine', filter => {"config.name" => $vmname});

unless($vm_view) {
	Util::disconnect();
	die "Unable to locate VM: \"$vmname\"\n";
}

if($operation eq "mount") {
	unless($datastore && $filename) {
		Util::disconnect();
		die "For \"mount\" operation, you need the following parmas defined: datastore and filename!\n";
	}
	&mountISO($vm_view,$datastore,$filename);
} elsif($operation eq "umount") {
	&umountISO($vm_view);
} elsif($operation eq "queryiso") {
	&queryISO($vm_view);
} else {
	print "Invalid selection!\n";
}

Util::disconnect();

sub queryISO {
	my ($vm) = @_;

	print "Datatstore Name & ISO Path:\n";
	print "-----------------------------------------------------------------\n";

	my $host = Vim::get_view(mo_ref => $vm->runtime->host);
        my $datastores =  Vim::get_views(mo_ref_array => $host->datastore);
        foreach my $ds (@$datastores) {
		my $browser = Vim::get_view (mo_ref => $ds->browser);
		my $ds_path = "[" . $ds->info->name . "]";
		my $file_query = FileQueryFlags->new(fileOwner => 0, fileSize => 0,fileType => 0,modification => 0);
		my $searchSpec = HostDatastoreBrowserSearchSpec->new(details => $file_query,matchPattern => ["*.iso"]);
		my $search_res = $browser->SearchDatastoreSubFolders(datastorePath => $ds_path,searchSpec => $searchSpec);
		foreach my $result (@$search_res) {
			my $files = $result->file;
			foreach my $file (@$files) {
				print $result->folderPath . $file->path . "\n";
			}
		}
		
	}
}

sub umountISO {
	my ($vm) = @_;

	my $cdrom_device = &find_cdrom_device(vm => $vm);

   	if($cdrom_device) {
		my $dev_con_info = VirtualDeviceConnectInfo->new(startConnected => 'false', connected => 'false', allowGuestControl => 'false');
		my $cdrom_backing_info = VirtualCdromRemoteAtapiBackingInfo->new(deviceName => '');

		my $cdrom = VirtualCdrom->new(backing => $cdrom_backing_info, connectable => $dev_con_info, controllerKey => $cdrom_device->controllerKey, key => $cdrom_device->key, unitNumber => $cdrom_device->unitNumber);

     		my $devspec = VirtualDeviceConfigSpec->new(operation => VirtualDeviceConfigSpecOperation->new('edit'),
                	device => $cdrom,
		);

		my $vmspec = VirtualMachineConfigSpec->new(deviceChange => [$devspec] );
        	eval {
                	print "Umounting ISO from VM: \"" . $vm->name . "\" ...\n";
                	my $task = $vm->ReconfigVM_Task( spec => $vmspec );
                	my $msg = "\tSuccessfully unmounted ISO from VM!\n";
                	&getStatus($task,$msg);
        	};
        	if($@) {
                	print "Error: " . $@ . "\n";
        	}
   	} else {
                print "Error: Unable to umount ISO from VM: \"" . $vm->name . "\"\n";
        }
}

sub mountISO {
	my ($vm,$dsname,$file) = @_;

	my $cdrom_device = &find_cdrom_device(vm => $vm);
	my $ds = &find_datastore(vm => $vm, dsname => $dsname);
	
	unless($ds) {
		Util::disconnect();
		print "Error: Unable to locate datastore: \"" . $dsname . "\"!\n";
	}

	my $path = "[" . $dsname . "] " . $file;

	if($cdrom_device) {
		my $cdrom_backing_info = VirtualCdromIsoBackingInfo->new(datastore => $ds, fileName => $path);
		my $dev_con_info = VirtualDeviceConnectInfo->new(startConnected => 'true', connected => 'true', allowGuestControl => 'false');

		my $cdrom = VirtualCdrom->new(backing => $cdrom_backing_info, connectable => $dev_con_info, controllerKey => $cdrom_device->controllerKey, key => $cdrom_device->key, unitNumber => $cdrom_device->unitNumber);

		my $devspec = VirtualDeviceConfigSpec->new(operation => VirtualDeviceConfigSpecOperation->new('edit'),
                        device => $cdrom
                );

		my $vmspec = VirtualMachineConfigSpec->new(deviceChange => [$devspec] );
                eval {
			print "Mounting ISO: \"" . $path . "\" to VM: \"" . $vm->name . "\" ...\n";
                  	my $task = $vm->ReconfigVM_Task( spec => $vmspec );
			my $msg = "\tSuccessfully added mounted ISO to VM!\n";
			&getStatus($task,$msg);
                };
		if($@) {
			print "Error: " . $@ . "\n";
		}

	} else {
		print "Error: Unable to mount ISO: \"" . $path . "\" to VM: \"" . $vm->name . "\"\n";
	}
}

sub find_datastore {
	my %args = @_;
	my $vm = $args{vm};
	my $dsname = $args{dsname};

	my $host = Vim::get_view(mo_ref => $vm->runtime->host);
	my $datastores =  Vim::get_views(mo_ref_array => $host->datastore);
	foreach(@$datastores) {
                if($_->summary->name eq $dsname) {
                        return $_;
                }
        }
	return undef
}

sub find_cdrom_device {
	my %args = @_;
	my $vm = $args{vm};

   	my $devices = $vm->config->hardware->device;
   	foreach my $device (@$devices) {
		if($device->isa('VirtualCdrom')) {
			return $device;
		}
   	}
   	return undef;
}

sub getStatus {
        my ($taskRef,$message) = @_;

        my $task_view = Vim::get_view(mo_ref => $taskRef);
        my $taskinfo = $task_view->info->state->val;
        my $continue = 1;
        while ($continue) {
                my $info = $task_view->info;
                if ($info->state->val eq 'success') {
                        print $message,"\n";
                        return $info->result;
                        $continue = 0;
                } elsif ($info->state->val eq 'error') {
                        my $soap_fault = SoapFault->new;
                        $soap_fault->name($info->error->fault);
                        $soap_fault->detail($info->error->fault);
                        $soap_fault->fault_string($info->error->localizedMessage);
                        die "$soap_fault\n";
                }
                sleep 5;
                $task_view->ViewBase::update_view_data();
        }
}

