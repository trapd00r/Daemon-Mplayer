#!/usr/bin/perl
package Daemon::Mplayer;
use vars qw($VERSION);

$VERSION = '0.007';

BEGIN {
  require Exporter;
  use vars qw(@ISA @EXPORT_OK);
  @ISA       = 'Exporter';
  @EXPORT_OK = qw(mplayer_play mplayer_stop);
}

use strict;
use Carp qw/croak/;


sub mplayer_play {
  _mplayer_daemonize(@_);
}


sub _mplayer_daemonize {
  my $mplayer = shift;

  my $pidfile = $mplayer->{pidfile} || '/tmp/mplayer_daemon.pid';
  my $logfile = $mplayer->{logfile} || '/dev/null';
  my $mp_path = $mplayer->{path}    || '/usr/bin/mplayer';


  use POSIX 'setsid';
  my $PID = fork();
  exit(0) if($PID); #parent
  exit(1) if(!defined($PID)); # out of resources

  setsid();
  $PID = fork();
  exit(1) if(!defined($PID));

  if($PID) { # parent
    open(my $fh, '>', $pidfile) or croak($!);
    print $fh $$;
    close($fh);

    waitpid($PID, 0);
    exit(0);
  }

  elsif($PID == 0) { # child
    open(my $fh, '>', $pidfile)
      or croak("Can not open pidfile '$pidfile': $!");

    print $fh $$;
    close($fh);

    open(STDOUT, '>>', $logfile)   unless $ENV{DEBUG};
    open(STDERR, '>', '/dev/null') unless $ENV{DEBUG};
    open(STDIN,  '<', '/dev/null') unless $ENV{DEBUG};

    exec($mp_path, @{ $mplayer->{args} });
  }
  return 0;
}

sub mplayer_stop {
  my $mplayer = shift;

  croak("Not a hashref: '$mplayer'") if ref($mplayer) ne 'HASH';

  my $pidfile = $mplayer->{pidfile} || '/tmp/mplayer_daemon.pid';
  
  if( (!-f $pidfile) and ($pidfile =~ m/^\d+$/) ) {
    if(kill(9, $pidfile)) {
      return 1;
    }
  }
  open(my $fh, '<', $pidfile)
    or croak("Can not open pidfile '$pidfile': $!");

  chomp(my $pid = <$fh>);
  close($fh);

  if($pid !~ /^\d+$/) {
    croak("PID '$pid' is not a valid PID");
  }

  if(kill(9, $pid)) {
    unlink($pidfile)
      or croak("Can not delete pidfile '$pidfile': $!");
    return 1;
  }
  else {
    croak("Can not kill PID $pid: $!");
  }
  return 0;
}


1;


__END__

=pod

=head1 NAME

Daemon::Mplayer - run mplayer daemonized

=head1 SYNOPSIS

  use Daemon::Mplayer;

  mplayer_play(
    {
      pidfile => $pidfile,
      logfile => $logfile,
      path    => '/usr/bin/mplayer',
      args    => [ @files ],
    }
  );

  ...

  mplayer_stop($pid);

=head1 DESCRIPTION

Daemon::Mplayer - Mplayer, daemonized

=head1 EXPORTS

None by default.

=head2 mplayer_play()

Parameters: $pidfile, $log, $path,  @mplayer_arguments

  mplayer_play(
    pidfile => $pidfile,      # /tmp/mplayer_daemon.pid
    logfile => $logfile,      # /dev/null
    path    => $mplayer_path, # /usr/bin/mplayer
    args    => $mplayer_opts  # None
  );

The B<pidfile> is used as a locking mechanism and will contain the PID of the
spawned mplayer process.

The B<logfile> is where the output from mplayer will be stored. The default is
B</dev/null>.

The B<path> is the full path to an mplayer executable. Defaults to
B</usr/bin/mplayer>.

B<args> takes an array reference that might contain optional parameters to
mplayer, as well as the file/URI to be played.


=head2 mplayer_stop()

Parameters: $pid | $pidfile

Returns: Boolean

Takes a PID or pidfile and tries to stop the corresponding process.

If a valid PID is encountered in the pidfile, tries to stop the process.
If this succeeds, the pidfile is removed.

=head1 AUTHOR

  Magnus Woldrich
  CPAN ID: WOLDRICH
  magnus@trapd00r.se
  http://japh.se

=head1 CONTRIBUTORS

None required yet.

=head1 COPYRIGHT

Copyright 2011 The Daemon::Mplayers L</AUTHOR> and L</CONTRIBUTORS> as listed
above.

=head1 LICENS
This library is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut
