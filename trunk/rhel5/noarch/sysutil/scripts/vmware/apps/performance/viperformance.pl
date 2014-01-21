#!/usr/bin/perl -w
#
# Copyright (c) 2007 VMware, Inc.  All rights reserved.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../";

use VMware::VIRuntime;
use AppUtil::HostUtil;
use AppUtil::VMUtil;

$Util::script_version = "1.0";

sub retrieve_performance;

my %opts = (
   'host' => {
      type => "=s",
      help => "Name of the host",
      required => 1,
   },
   'countertype' => {
      type => "=s",
      help => "Counter type [cpu | mem | net | disk | sys]",
      required => 1,
   },
   'interval' => {
      type => "=i",
      help => "Interval in seconds",
      required => 0,
   },
   'instance' => {
      type => "=s",
      help => "Name of instance to query",
      required => 0,
   },
   'samples' => {
      type => "=s",
      help => "Number of samples to retrieve",
      required => 0,
      default => 10,
   },
   'out' => {
      type => "=s",
      help => "Name of file to hold output",
      required => 0,
   },
);

Opts::add_options(%opts);
Opts::parse();
Opts::validate(\&validate);

Util::connect();

my $all_counters;
retrieve_performance();

Util::disconnect();

sub retrieve_performance() {
   my $host = Vim::find_entity_view(view_type => "HostSystem",
                                    filter => {'name' => Opts::get_option('host')});
   if (!defined($host)) {
      Util::trace(0,"Host ".Opts::get_option('host')." not found.\n");
      return;
   }
   
   my $perfmgr_view = Vim::get_view(mo_ref => Vim::get_service_content()->perfManager);
   
   my @perf_metric_ids = get_perf_metric_ids(perfmgr_view=>$perfmgr_view,
                                             host => $host,
                                             type => Opts::get_option('countertype'));
 
   my $perf_query_spec;
   if(defined Opts::get_option('interval')) {
      $perf_query_spec = PerfQuerySpec->new(entity => $host,
                                            metricId => @perf_metric_ids,
                                            'format' => 'csv',
                                            intervalId => Opts::get_option('interval'),
                                            maxSample => Opts::get_option('samples'));
   }
   else {
      my $intervals = get_available_intervals(perfmgr_view => $perfmgr_view,
                                              host => $host);
      $perf_query_spec = PerfQuerySpec->new(entity => $host,
                                            metricId => @perf_metric_ids,
                                            'format' => 'csv',
                                            intervalId => shift @$intervals,
                                            maxSample => Opts::get_option('samples'));
   }

   if(defined Opts::get_option('out')) {
      my $filename = Opts::get_option('out');
      open(OUTFILE, ">$filename");
   }
   my $perf_data;
   eval {
       $perf_data = $perfmgr_view->QueryPerf( querySpec => $perf_query_spec);
   };
   if ($@) {
      if (ref($@) eq 'SoapFault') {
         if (ref($@->detail) eq 'InvalidArgument') {
            Util::trace(0,"Specified parameters are not correct");
         }
      }
      return;
   }
   if (! @$perf_data) {
      Util::trace(0,"Either Performance data not available for requested period "
                    ."or instance is invalid\n");
      my $intervals = get_available_intervals(perfmgr_view=>$perfmgr_view,
                                           host => $host);
      Util::trace(0,"\nAvailable Intervals\n");
      foreach(@$intervals) {
         Util::trace(0,"Interval " . $_ . "\n");
      }
      return;
   }
   foreach (@$perf_data) {
      print_log("Performance data for: " . $host->name . "\n");
      my $time_stamps = $_->sampleInfoCSV;
      my $values = $_->value;
      foreach (@$values) {
         print_counter_info($_->id->counterId, $_->id->instance);
         print_log("Sample info : " . $time_stamps);
         print_log("Value: " . $_->value . "\n");
      }
   }
}

sub print_counter_info {
   my ($counter_id, $instance) = @_;
   my $counter = $all_counters->{$counter_id};
   print_log("Counter: " . $counter->nameInfo->label);
   if (defined $instance) {
      print_log("Instance : " . $instance);
   }
   print_log("Description: " . $counter->nameInfo->summary);
   print_log("Units: " . $counter->unitInfo->label);
}

sub get_perf_metric_ids {
   my %args = @_;
   my $perfmgr_view = $args{perfmgr_view};
   my $entity = $args{host};
   my $type = $args{type};

   my $counters;
   my @filtered_list;
   my $perfCounterInfo = $perfmgr_view->perfCounter;
   my $availmetricid = $perfmgr_view->QueryAvailablePerfMetric(entity => $entity);
   
   foreach (@$perfCounterInfo) {
      my $key = $_->key;
      $all_counters->{ $key } = $_;
      my $group_info = $_->groupInfo;
      if ($group_info->key eq $type) {
         $counters->{ $key } = $_;
      } 
   }
   
   foreach (@$availmetricid) {
      if (exists $counters->{$_->counterId}) {
         #push @filtered_list, $_;
         my $metric = PerfMetricId->new (counterId => $_->counterId,
                                          instance => (Opts::get_option('instance') || ''));
         push @filtered_list, $metric;
      }
   }
   return \@filtered_list;
}

sub get_available_intervals {
   my %args = @_;
   my $perfmgr_view = $args{perfmgr_view};
   my $entity = $args{host};
   
   my $historical_intervals = $perfmgr_view->historicalInterval;
   my $provider_summary = $perfmgr_view->QueryPerfProviderSummary(entity => $entity);
   my @intervals;
   if ($provider_summary->refreshRate) {
      push @intervals, $provider_summary->refreshRate;
   }
   foreach (@$historical_intervals) {
      push @intervals, $_->samplingPeriod;
   }
   return \@intervals;
}

sub validate {
   my $valid = 1;
   if (Opts::option_is_set('countertype')) {
      my $ctype = Opts::get_option('countertype');
      if(!(($ctype eq 'cpu') || ($ctype eq  'mem') || ($ctype eq 'net')
         || ($ctype eq 'disk') || ($ctype eq 'sys'))) {
         Util::trace(0,"counter type must be [cpu | mem | net | disk | sys]");
         $valid = 0;
      }
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
     }
  }
  return $valid;
}

sub print_log {
   my ($prop) = @_;
   if (defined (Opts::get_option('out'))) {
      print OUTFILE  $prop."\n";
   }
   else {
      Util::trace(0, $prop." \n");
   }
}

__END__

## bug 217605

=head1 NAME

viperformance.pl - Retrieves performance counters from a host.

=head1 SYNOPSIS

 viperformance.pl [options]

=head1 DESCRIPTION

This VI Perl command-line utility provides an interface to retrieve
performance counters from the specified host. Performance counters
shows these primary attributes: CPU Usage, Memory Usage, Disk I/O Usage,
Network I/O Usage, and System Usage.

=head1 OPTIONS

=over

=item B<Host>

Required. Name of the host.

=item B<countertype>

Required. Counter type [cpu | mem | net | disk | sys].

=item B<interval>

Optional. Interval in seconds. 

=item B<samples>

Optional. Number of samples to retrieve. Default: 10

=item B<instance>

Optional. Name of instance to query. Default: Aggregate of all instance.
          Specify '*' for all the instances.

=item B<out>

Optional. Name of the filename to hold the output.

=back

=head1 EXAMPLES

Retrieve performance counter for countertype 'cpu' from host 'Host123'

 viperformance.pl --url https://<host>:<port>/sdk/vimService
                --username myuser --password mypassword
                --host Host123 --countertype cpu

Retrieve performance counter for countertype 'net' from host 'Host123'.
Let the interval be 30 seconds and the number of samples be 3.

 viperformance.pl --url https://<host>:<port>/sdk/vimService
                --username myuser --password mypassword
                --host Host123 --countertype net --interval 30
                --samples 3

Retrieve performance counter for countertype 'net' from host 'Host123' for
cpu instance 1.

 viperformance.pl --url https://<host>:<port>/sdk/vimService
                --username myuser --password mypassword
                --host Host123 --countertype net --interval 30
                --samples 3 --instance 1

Retrieve performance counter for countertype 'net' from host 'Host123' for
all the cpu instances.

 viperformance.pl --url https://<host>:<port>/sdk/vimService
                --username myuser --password mypassword
                --host Host123 --countertype net --interval 30
                --samples 3 --instance *

=head1 SUPPORTED PLATFORMS

All operations work with VMware VirtualCenter 2.0.1 or later.

All operations work with VMware ESX 3.0.1 or later.

