#!/usr/bin/perl
use strict;
use warnings;

# https://perldoc.perl.org/Getopt::Long
use Getopt::Long;
use List::Util qw(first);
use LWP::UserAgent;
use JSON;

my $heliumApiUrl = 'https://api.helium.io/v1/hotspots';

my $sleepTime = 2;      # Sleep time for the helium API requests
my $hotspotid;          # The ID of the suspected hotspot
my $hide_names;
my @mainArray;          # The main array created from the first hotspot

# Hotspots I know/saw they exist
my @knownHotspots = ();


# Parse long options variables 
GetOptions (
    'id=s'       => \$hotspotid,
    'hide-names' => \$hide_names,
    'help'       => \&printHelp
);

sub printHelp {
    my $USAGE =<<USAGE;

     Usage:

        $0 [--hide-names] --id b58-address
        $0 [--help]

        where:

            --help:                 print this help
            --id <b58 address>:     define the suspected hotspot b58 address
            --hide-names:           hide the hotspot names on output

USAGE
    print $USAGE;
    exit 0;
}

sub send_request {
    my ($url) = @_;

    my $ua   = LWP::UserAgent->new;
    my $req  = HTTP::Request->new(GET => $url);
    my $resp = $ua->request($req);
    if ($resp->is_success) {
        my $message = $resp->decoded_content;
        return $message;
    } else {
        print "HTTP GET error code: ", $resp->code, "n";
        print "HTTP GET error message: ", $resp->message, "n";
    }
}

# Get hotspot info. 
sub getHotspotByid {
    my ($address) = @_;
    my $res = send_request($heliumApiUrl.'/'.$address);

    # We need this to format the one hotspot in JSON Array
    my $json_sc = JSON->new()->decode($res)->{'data'};
    my $result  = JSON->new()->pretty->encode($json_sc);

    return JSON->new()->decode($result);
}

sub getSpaces {
    my $integer = shift;
    if( $integer > 99 ) { return ""; }
    if( $integer > 9 ) { return " "; }
    if( $integer < 10 ) { return "  "; }
    return "";
}

sub getWitnessed {
    my ($address) = @_;
    # Wait for X seconds until the next request to avoid
    # HTTP GET error code: 429nHTTP GET error message: Too Many Requests
    sleep($sleepTime);
    my $res = send_request($heliumApiUrl.'/'.$address.'/witnessed');

    # We need this to format the hotspots in JSON Array
    my $json_sc = JSON->new()->decode($res)->{'data'};
    my $result  = JSON->new()->pretty->encode($json_sc);

    print("\tFound:".getSpaces(scalar @{JSON->new()->decode($result)}).scalar @{JSON->new()->decode($result)}." witnessed hotspots. ");

    my $count = 0;
    # Add every found hotspot to the array, only if not already added
    foreach my $hotspot ( @{JSON->new()->decode($result)} ) {
        my ($p) = grep { $hotspot->{'address'} eq $_->{'address'} } @mainArray;
        if(defined $p) {
            # print Dumper $p;
        } else {
            $count++;
            push(@mainArray, $hotspot);
        }
    }
    print("Added:".getSpaces($count).$count."\n");
}

##### Main #####
# Get all info from hotspot
if( ! defined $hotspotid ) {
    print("No Hotspot ID provided. Exit.\n");
    exit 2;
}

# Put the suspected host as first element
push(@mainArray, getHotspotByid($hotspotid));

# Counter to know how much elements we got
my $counter = 1;

# Iterate over every array element and add his witnessed hotspots
foreach my $hotspot ( @mainArray ) {
    my $line;

    # If we have match against the known hosts, just exit with message
    # It makes no sense to search further.
    if( first { $_ eq $hotspot->{'address'} } @knownHotspots ) {
        print($counter." Hotspot: ".$hotspot->{'name'}." found in known hotspots. This is not closed cluster. Exit.");
        exit 0;
    }

    if( ! defined $hide_names ) {
        $line = "Analyze: ".$hotspot->{'name'}."                              ";
        $line = substr($line, 0, 37);
    } else {
        $line = "Analyze: ";
    }

    print($counter++.". ".$line);
    getWitnessed($hotspot->{'address'});
}

print("\n\n\n\n");
print("Print the array with ".($#mainArray + 1)." elements\n");
foreach (@mainArray) {
    print($_->{'address'}."\n");
}
