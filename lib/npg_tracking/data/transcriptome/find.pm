#############
# Created By: Jillian Durham (jillian)
# Created On: 2014-03-20

package npg_tracking::data::transcriptome::find;

use strict;
use warnings;
use Moose::Role;
use Carp;
use Cwd 'abs_path';

our $VERSION = do { my ($r) = q$Revision$ =~ /(\d+)/smx; $r; };

Readonly::Scalar our $ENSEMBL_RELEASE_VERSION => q[default];

with qw/ npg_tracking::data::reference::find 
/;

has '_organism_dir' => ( isa => q{Maybe[Str]},
                         is => q{ro},
                         lazy_build => 1,
                       );

sub _build__organism_dir {
    my $self = shift;
    
    my ($organism, $strain) = $self->_parse_reference_genome($self->lims->reference_genome);
    
    if ($organism){
        return($self->transcriptome_repository . "/$organism");
    }
}


has '_version_dir' => ( isa => q{Maybe[Str]},
                         is => q{ro},
                         lazy_build => 1,
                       );

sub _build__version_dir {
    my $self = shift;
    my ($organism, $strain) = $self->_parse_reference_genome($self->lims->reference_genome);
    
    if ($organism && $strain){
        return($self->_organism_dir . "/$ENSEMBL_RELEASE_VERSION/$strain");
    }
}

has 'gtf_path'     => ( isa => q{Maybe[Str]},
                        is => q{ro},
                        lazy_build => 1,
                        documentation => 'Path to the transcriptome GTF (GFF2) folder',);

sub _build_gtf_path {
    my $self = shift;
    ## symbolic link to default resolved with abs_path
    return abs_path($self->_version_dir . "/gtf");
}

has 'gtf_file' => ( isa => q{Maybe[Str]},
                    is => q{ro},
                    lazy_build => 1,
                    documentation => 'full name of GTF file',);

sub _build_gtf_file {
   my $self = shift;
   my @gtf_files;
   if ($self->gtf_path) { @gtf_files = glob $self->gtf_path . '/*.gtf'; }
   if (scalar @gtf_files > 1) { croak 'More than 1 gtf file in ' . $self->gtf_path; }

   if (scalar @gtf_files == 0) {
      if (-d $self->_organism_dir) {
         $self->messages->push('Directory ' . $self->_organism_dir . ' exists, but GTF file not found');
      }
      return;
   }
   return $gtf_files[0];
}

#transcriptomes/Homo_sapiens/ensembl_release_75/1000Genomes_hs37d5/tophat2/
has 'transcriptome_index_path' => ( isa => q{Maybe[Str]},
                                    is => q{ro},
                                    lazy_build => 1,
                                    documentation => 'Path to the tophat2 (bowtie2) indices folder',
                                  );

sub _build_transcriptome_index_path {
    my $self = shift;
    return abs_path($self->_version_dir . "/tophat2");
}
#e.g. 1000Genomes_hs37d5.known (from 1000Genomes_hs37d5.known.1.bt2, 1000Genomes_hs37d5.known.2.bt2 ...)
has 'transcriptome_index_name' => ( isa => q{Maybe[Str]},
                                    is => q{ro},
                                    lazy_build => 1,
                                    documentation => 'Full path + prefix of files in the tophat2 (bowtie2) indices folder',
                                   );

sub _build_transcriptome_index_name {
  my $self = shift;
  my @indices;
  if ($self->transcriptome_index_path){ @indices = glob $self->transcriptome_index_path . '/*.bt2'}

  if (scalar @indices == 0){
     if (-d $self->_organism_dir) {
         $self->messages->push('Directory ' . $self->_organism_dir . ' exists, but GTF file not found');
      }
     return;
  }

  ##return up to prefix (remove everything after 'known')
  my $index_prefix = $indices[0];
     $index_prefix =~ s/known(\S+)$/known/smxi;
  return $index_prefix;
}


1;
__END__

=head1 NAME

npg_tracking::data::transcriptome::find

=head1 VERSION

$Revision$

=head1 SYNOPSIS

  package MyPackage;
  use Moose;
  with qw{npg_tracking::data::transcriptome::find};


=head1 DESCRIPTION

A Moose role for finding the location of transcriptome files.

These are the gtf file and the tophat2 index file prefix (including paths).

Documentation on GTF (GFF version2) format http://www.ensembl.org/info/website/upload/gff.html

=head1 SUBROUTINES/METHODS

=head2 gtf_path

=head2 transcriptome_index_name

=head2 transcriptome_index_path

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item Moose::Role

=item Carp

=item Cwd

=item npg_tracking::data::reference::find

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 Jillian Durham (jillian@sanger.ac.uk)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.