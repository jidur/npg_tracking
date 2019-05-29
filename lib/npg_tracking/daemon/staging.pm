package npg_tracking::daemon::staging;

use Moose;
use Readonly;

extends 'npg_tracking::daemon::staging_local';

our $VERSION = '0';

Readonly::Scalar our $SCRIPT_NAME => q[staging_area_monitor];

override 'command'      => sub {
  my ($self, $host) = @_;
  my $sfarea = $self->host_name2path($host);
  return join q[ ], $SCRIPT_NAME, $sfarea;
};

override 'daemon_name'  => sub { return $SCRIPT_NAME; };

no Moose;

1;
__END__

=head1 NAME

npg_tracking::daemon::staging

=head1 SYNOPSIS

=head1 DESCRIPTION

  Staging area daemon definition.

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose

=item Readonly

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Marina Gourtovaia E<lt>mg8@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 GRL, by Marina Gourtovaia

This file is part of NPG.

NPG is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut




