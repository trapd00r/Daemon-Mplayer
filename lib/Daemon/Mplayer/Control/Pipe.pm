#!/usr/bin/perl
package Daemon::Mplayer::Control::Pipe;
use vars qw($VERSION);

$VERSION = '0.001';

BEGIN {
  require Exporter;
  use vars qw(@ISA @EXPORT_OK);
  @ISA    = 'Exporter';
  @EXPORT = qw(mplayer_cmd);
}

use strict;
use Carp qw/croak/;


my %mplayer_options = (
  next  => 'pt_step 1',
  prev  => 'pt_step -1',
);


sub mplayer_cmd {
  my $option = shift;
  
  croak() if ref $option ne 'HASH';

  my $fifo = $option->{fifo};

  if(!-p $fifo) {
    croak("No such fifo '$fifo'");
  }

  my($command, @args) = @{ $option->{commands} };

  print "Command: $command\nArguments: @args\n";

  open(my $fh, '>', $fifo) or croak("Can not open fifo '$fifo': $!");
  print $fh "$command @args\n";
  close($fh);
}


1;

__END__

=pod

=head1 NAME

Daemon::Mplayer::Control::Pipe - control mplayer with named pipes

=head1 SYNOPSIS

  use Daemon::Mplayer;
  use Daemon::Mplayer::Control::Pipe;

  mplayer_play( $pidfile, $logfile, @mplayer_args );

  ...

  mplayer_cmd({
    fifo     => $fifo,
    commands => [ 'next', 3 ],
  });

  ...

  mplayer_stop($pid);

=head1 DESCRIPTION

B<Daemon::Mplayer::Control::Pipe> ... 

=head1 EXPORTS

=head2 mplayer_cmd()

  mplayer_cmd(
    fifo     => $fifo,
    commands => [ 'next', 3 ],
  );

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

L<Daemon::Mplayer>

=cut

