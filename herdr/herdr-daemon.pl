#!/usr/bin/perl
# Run a command as a session leader under launchd.
#
# launchd spawns each job as a process-group leader, so setsid() fails with
# EPERM inside the job itself. Fork first: the child is not a group leader, so
# it can setsid() and then exec the real command. This parent stays alive as a
# thin supervisor so launchd's KeepAlive still tracks the job, forwards
# TERM/INT/HUP to the child, and exits with the child's status.
#
# herdr checks getsid(0) == getpid() to advertise detached_server_daemon=true;
# without it every remote attach asks to restart the server.
use strict;
use warnings;
use POSIX ();

my @cmd = @ARGV or die "usage: herdr-daemon.pl <command> [args...]\n";

my $pid = fork();
die "fork failed: $!\n" unless defined $pid;

if ($pid == 0) {
    defined POSIX::setsid() or die "setsid failed: $!\n";
    exec { $cmd[0] } @cmd;
    die "exec $cmd[0] failed: $!\n";
}

for my $sig (qw(TERM INT HUP)) {
    $SIG{$sig} = sub { kill 'TERM', $pid };
}

while ((my $waited = waitpid($pid, 0)) != $pid) {
    last if $waited == -1 && $! !~ /Interrupted/;
}

my $status = $?;
exit(($status & 127) ? 128 + ($status & 127) : ($status >> 8));
