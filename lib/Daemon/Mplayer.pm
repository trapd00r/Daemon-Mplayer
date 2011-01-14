#!/usr/bin/perl
package Daemon::Mplayer;
use vars qw($VERSION);

$VERSION = '0.002';

BEGIN {
  require Exporter;
  use vars qw(@ISA @EXPORT_OK);
  @ISA    = 'Exporter';
  @EXPORT = qw(mplayer_play mplayer_stop);
}

use strict;
use Carp;

sub mplayer_play {
  my($pidfile, $log, @mplayer_args) = @_;

  croak if !$pidfile;
  croak if !$log;

  _mplayer_daemonize($pidfile, $log, @mplayer_args);
}


sub _mplayer_daemonize {
  my($pidfile, $daemon_log, @mplayer_args) = @_;

  not defined $pidfile    and $pidfile    = '/tmp/mplayer_daemon.pid';
  not defined $daemon_log and $daemon_log = '/dev/null';

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
    #player_init();
    exit(0);
  }
  elsif($PID == 0) { # child
    open(my $fh, '>', "$pidfile")
      or croak("Can not open pidfile '$pidfile': $!");

    print $fh $$;
    close($fh);

    open(STDOUT, '>>',  $daemon_log);
    open(STDERR, '>', '/dev/null'); #    unless $ENV{DEBUG};
    open(STDIN,  '<', '/dev/null'); #   unless $ENV{DEBUG};

    exec('mplayer', @mplayer_args);
  }
  return 0;
}

sub mplayer_stop {
  my $pidfile = shift;

  if(!defined($pidfile)) {
    croak("Pidfile please");
  }
  open(my $fh, '<', $pidfile)
    or croak("Can not open pidfile '$pidfile': $!");

  chomp(my $pid = <$fh>);
  close($fh);

  if(kill(9, $pid)) {
    print "SUCCESS: $pid\n";
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

  mplayer_play( $pidfile, $logfile, @mplayer_args );

  ...

  mplayer_stop($pid);

=head1 DESCRIPTION

B<Daemon::Mplayer> ... 

=head1 EXPORTS

=head2 mplayer_play()

=head2 mplayer_stop()

=head1 AUTHOR

  Magnus Woldrich
  CPAN ID: WOLDRICH
  magnus@trapd00r.se
  http://japh.se

=cut

=head1 COPYRIGHT

Copyright 2011 Magnus Woldrich <magnus@trapd00r.se>. This program is free
software; you may redistribute it and/or modify it under the same terms as Perl
itself.

=head1 SEE ALSO

=cut
