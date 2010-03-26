#!/usr/bin/env perl
### This is a watchdog for snagc.pl

use strict;

use SNAG;
use XML::Simple;
use Mail::Sendmail;
use Sys::Hostname;
use Sys::Syslog;
use Data::Dumper;

use Getopt::Long;

our %options;
GetOptions(\%options, 'debug', 'nosyslog');
my $debug = delete $options{debug};
my $nosyslog = delete $options{nosyslog};

### Start snagc.pl
my $script = BASE_DIR . "/" . "snagc.pl";
print "Starting $script ... " if $debug;
system $script;
print "Done!\n" if $debug;

### Start any additional snags.pl or snagp.pl, if configured to run on this host
my $file = BASE_DIR . "/SNAG.xml";
my $conf = XMLin($file, ForceArray => ['server', 'poller']) or die "Could not open $file";

if($conf->{server})
{
  foreach my $server (keys %{$conf->{server}})
  {
    my $script_bin = $server . '_snags.pl';
    my $script_path = BASE_DIR . "/" . $script_bin;

    print "Starting $script_path ... " if $debug;
    system $script_path;
    print "Done!\n" if $debug;
  }
}

if($conf->{poller})
{
  foreach my $poller (keys %{$conf->{poller}})
  {
    my $script_bin = $poller . '_snagp.pl';
    my $script_path = BASE_DIR . "/" . $script_bin;

    print "Starting $script_path ... " if $debug;
    system $script_path;
    print "Done!\n" if $debug;
  }
}

exit 0 if $nosyslog;

print "Sending syslog heartbeat ... " if $debug;
openlog('snagw.pl', 'ndelay', 'user');
syslog('notice', 'syslog heartbeat from ' . HOST_NAME);
closelog();
print "Done!\n" if $debug;