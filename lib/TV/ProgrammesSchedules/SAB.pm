package TV::ProgrammesSchedules::SAB;

use Moose;
use MooseX::Params::Validate;
use Moose::Util::TypeConstraints;
use namespace::clean;

use Carp;
use Readonly;
use Data::Dumper;

use HTTP::Request;
use LWP::UserAgent;
use Time::localtime;
use HTML::TokeParser::Simple;

=head1 NAME

TV::ProgrammesSchedules::SAB - Interface to SAB TV Programmes Schedules.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';
Readonly my $BASE_URL => 'http://www.sabtv.com/comedy/';

=head1 DESCRIPTION

SAB TV is an Indian  general  entertainment  television channel that is owned  by Multi Screen
Media (P) Ltd & based in Mumbai Maharashtra. It was launched on April 23, 2000 by Sri Adhikari 
Brothers as a general entertainment channel. In March 2005, SAB TV was acquired by SET and was 
transformed into a youth-centric channel.

=cut

has 'browser' => (is => 'rw', isa => 'LWP::UserAgent', default => sub { return LWP::UserAgent->new(agent => 'Mozilla/5.0'); });

=head1 METHODS

=head2 get_listings()

Returns the  programmes  listings for the given day. It expects integer optionally as the only
parameter. If missing then it assumes it is 0, which means today. If passed 1 then it means +1
day from today. If passed -2 then it means -2 day from today. Data would be in XML format.

    use strict; use warnings;
    use TV::ProgrammesSchedules::SAB;
    
    my $sab      = TV::ProgrammesSchedules::SAB->new();
    # SAB TV todays listings.
    my $listings = $sab->get_listings();

=cut

sub get_listings
{
    my $self  = shift;
    my ($day) = pos_validated_list(\@_,
                { isa => 'Int', default => 0 },
                MX_PARAMS_VALIDATE_NO_CACHE => 1);

    my ($url, $request, $response, $content);
    my ($listings, $program, $stream, $data);
    my ($token, $tag, $attr, $attrseq, $rawtxt);
    
    
    $url      = $BASE_URL . 'schedule.php?for=' . $day;
    $request  = HTTP::Request->new(GET => $url);
    $response = $self->{browser}->request($request);
    croak("ERROR: Couldn't fetch programmes schedules [$url][".$response->status_line."]\n")
        unless $response->is_success;
    $content  = $response->content;
    croak("ERROR: Data not found [$url].\n")
        unless $content;

    $stream = HTML::TokeParser::Simple->new(string => $content);
    while ($token = $stream->get_tag('td')) 
    {
        ($tag, $attr, $attrseq, $rawtxt) = @{$token};
        if (ref($attr) && exists($attr->{class}) && ($attr->{class} =~ /\bws\_title\b|\bws\_time\b/))
        {
            $data = $stream->get_token();
            ($tag, $attr, $attrseq, $rawtxt) = @{$data};
            if ($tag eq 'T')
            {
                if ($attr =~ /\d{2}\:\d{2}/)
                {
                    push @{$listings}, $program if defined $program;
                    $program = {};
                    $program->{time} = $attr;
                }
                else
                {
                    $program->{title} = $attr;
                }
            }
            elsif ($tag eq 'S')
            {
                $token = $stream->get_token();
                $program->{title} = $token->[1];
                $program->{url}   = $BASE_URL . '/'. $data->[2]->{href};
            }    
        }
    }
    
    warn("WARN: No schedule information found.\n") && return
        unless defined $listings;
        
    $self->{listings} = _toXML($listings);
    return $self->{listings};
}

sub _toXML
{
    my $data = shift;
    my $xml  = qq {<?xml version="1.0" encoding="UTF-8"?>\n};
    $xml.= qq {<programmes>\n};
    foreach (@{$data})
    {
        $xml .= qq {\t<programme>\n};
        $xml .= qq {\t\t<time> $_->{time} </time>\n};
        $xml .= qq {\t\t<title> $_->{title} </title>\n};
        $xml .= qq {\t\t<url> $_->{href} </url>\n} if exists($_->{href});
        $xml .= qq {\t</programme>\n};
    }
    $xml.= qq {</programmes>};
    return $xml;
}

=head1 AUTHOR

Mohammad S Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-tv-programmesschedules-sab at rt.cpan.org> 
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=TV-ProgrammesSchedules-SAB>.
I will be notified and then you'll automatically be notified of progress on your bug as I make
changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TV::ProgrammesSchedules::SAB

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=TV-ProgrammesSchedules-SAB>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/TV-ProgrammesSchedules-SAB>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/TV-ProgrammesSchedules-SAB>

=item * Search CPAN

L<http://search.cpan.org/dist/TV-ProgrammesSchedules-SAB/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Mohammad S Anwar.

This  program  is  free  software; you can redistribute it and/or modify it under the terms of
either:  the  GNU  General Public License as published by the Free Software Foundation; or the
Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 DISCLAIMER

This  program  is  distributed in the hope that it will be useful,  but  WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

__PACKAGE__->meta->make_immutable;
no Moose; # Keywords are removed from the TV::ProgrammesSchedules::SAB package

1; # End of TV::ProgrammesSchedules::SAB