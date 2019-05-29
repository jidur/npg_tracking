package npg_tracking::Schema::Retriever;

use Moose::Role;
use DateTime;
use DateTime::TimeZone;
use Carp;
use List::MoreUtils qw{any};
use Readonly;

our $VERSION = '0';

Readonly::Scalar my $PIPELINE_USER_NAME => q[pipeline];

sub get_time_now {
  return DateTime->now(time_zone=> DateTime::TimeZone->new(name => q[local]));
}

sub get_user_row {
  my ($self, $username, $default2pipeline_user) = @_;

  if ( !$username ) {
    if ($default2pipeline_user) {
      $username = $PIPELINE_USER_NAME;
    } else {
      croak 'Username should be provided';
    }
  }

  my $row = $self->result_source->schema()->resultset('User')
              ->search({username => $username,})->next;
  if (!$row) {
    croak "User $username does not exist";
  }
  return $row;
}

sub get_user_id {
  my ($self, $username, $default2pipeline_user) = @_;
  return $self->get_user_row($username, $default2pipeline_user)->id_user;
}

sub pipeline_user_name {
  return $PIPELINE_USER_NAME;
}

sub pipeline_id {
  my ($self) = @_;
  return $self->get_user_row($PIPELINE_USER_NAME)->id_user;
}

sub get_status_dict_row {
  my ($self, $resultset_name, $description) = @_;

  if (!$resultset_name) {
    croak 'Resultset name should be provided';
  }  
  if (!$description) {
    croak 'Description should be provided';
  }
  my $schema = $self->result_source->schema();
  my $row = $schema->resultset($resultset_name)->search({description => $description,})->next;
  if (!$row) {
    croak "Status '$description' does not exist in $resultset_name";
  }
  return $row;
}

sub status_is_duplicate {
  my ($self, $status_description, $status_date) = @_;

  my $statuses_rel_name    = 'statuses';
  my $status_dict_rel_name = 'status_dict';

  my $class = ref $self;
  if (!$self->can($statuses_rel_name)) {
    croak qq['$statuses_rel_name' relationship should be defined for $class];
  }
  $class .= 'Status';
  if (!$class->can($status_dict_rel_name)) {
    croak qq['$status_dict_rel_name' relationship should be defined for $class];
  }

  my @same_statuses = $self->related_resultset( $statuses_rel_name )->search(
             { $status_dict_rel_name.q{.description} => $status_description,},
             { prefetch                              => $status_dict_rel_name,
               order_by                              => { -desc => 'date'},},
  )->all;

  if (@same_statuses) {
    if ( any { $_->date == $status_date || ($_->iscurrent && $_->date < $status_date)} @same_statuses ) {
      return 1;
    }
  }
  return 0;
}

sub current_status_is_outdated {
  my ($self, $current_record, $new_status_date) = @_;
  return ($current_record && ($new_status_date < $current_record->date)) ? 0 : 1;
}

no Moose::Role;
1;
__END__

=head1 NAME

npg_tracking::Schema::Retriever

=head1 SYNOPSIS

=head1 DESCRIPTION

 A Moose role containing (1) helper functions for retrieving
 single rows from dictionaries and other basic tables,
 (2) providing common methods for dealing with statuses.

=head1 SUBROUTINES/METHODS

=head2 get_time_now

 Returns a DateTime object for current time. Time is local.

 my $new = $row->get_time_now();

=head2 compare_date

 Compares the value in the date column of the first argument with the
 date represented by the DateTime object in the second argument. Returns
 zero if date timestamps are the same, 1 if the date in the database
 record is older than the given date and -1 the given date is older than
 the database date..

 my $is_older = $self->compare_date($status_row, $some_date); 

=head2 get_user_row

 Returns a table row representing a user. If the username is not given, but
 the flag is set to default to the pipeline user, returns a row representing
 a 'pipeline' user. If neitehr the username is given, nor the flag to use the
 defauylt user is not set, an error is raised.

 my $urow = $row->get_user_row(q[some_user]);
 my $default2pipeline_user = 1;
 my $urow = $row->get_user_row(q[], $default2pipeline_user);
 $row->get_user_row(); #throws an error

=head2 get_user_id

 Returns the id of the user. Calls get_user_row() and has the
 same interface.

=head2 pipeline_user_name

 Returns username of the pipeline user

=head2 pipeline_id

 Returns the id of the user whose username is returned by pipeline_user_name()

=head2 get_status_dict_row

 Returns a database row corresponding to a status given as an argument.
 The resultset name to use shoudl be given as the first argument. Valid
 for 'InstrumentStatusDict', 'RunStatusDict' and 'RunLaneStatusDict'
 resultsets. Raises an error if any of the arguments are missing and
 on a failure to retrieve a row.

 my $srow = $row->get_status_dict_row(q[RunStatusDict], q[qc complete]);

=head2 status_is_duplicate

 Given a new status description and date, returns true if such a record
 already exists, false otherwise.
 

=head2 current_status_is_outdated

 Given the current status row and a date for the new status record, returns true
 if the current status has to be reset to a new record, false otherwise.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item DateTime

=item DateTime::TimeZone

=item Carp

=item List::MoreUtils

=item Readonly

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Marina Gourtovaia E<lt>mg8@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 Genome Research Limited

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
