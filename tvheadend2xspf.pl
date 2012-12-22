#!/usr/bin/env perl

use strict;
use XML::Writer;
use encoding 'utf8';
use Getopt::Std;

sub main::HELP_MESSAGE {
    print "Tvheadend channels list to XSPF playlist converter\n";
    print "Usage:\n$0 -s[wupPN] [tvheadend_channels_direcotory] out_playlist_file\n";
    print "By default as tvheadend_channels_directory uses ~/.hts/tvheadend/channels\n";
    print "\nOptions:\n -h show this messages\n";
    print " -w print debug information\n";
    print " -s tvheadend server\n";
    print " -u user for login\n";
    print " -p password for login\n";
    print " -P port used by thveadend (default - 9981)\n";
    print " -N playlist name\n";
    exit;
}

sub main::VERSION_MESSAGE {
    print "tvheadend2xspf v0.1 by Bigg Ars\n\n";
};

#Extract keys form command line and define vars first 
getopts('whs:u:p:P:N:');
our($opt_w, $opt_h, $opt_s, $opt_u, $opt_p, $opt_P, $opt_N);

#Show help message
&main::HELP_MESSAGE() if ( @ARGV == 0 ) || ( defined ( $opt_h ) || ( !defined ( $opt_s ) ) );

my $host = defined ( $opt_s ) ? $opt_s : "127.0.0.1";
my $port = defined ( $opt_P ) ? ":" . $opt_P : ":9981"; 
my $user = defined ( $opt_u ) ? $opt_u : '';
my $pl_name = defined ( $opt_N ) ? $opt_N : "DVB-S\/S2 channels list";
my $password = '';
if ( defined ($opt_p) )
{
    $password = ":" . $opt_p . "\@";
}
else
{
    $user .= "\@" if defined ( $opt_u );
}

my ($dir, $out_file) = @ARGV == 2 ? ( $ARGV[0], $ARGV[1] ) : ( "$ENV{HOME}/.hts/tvheadend/channels", $ARGV[0] );
my $index = 0;

opendir ( IN_DIR, $dir ) || die "\nCan not open input directory:\n$!\n";
open ( my $OUTF , ">" , $out_file ) || die "\nCan not create output file:\n$!\n";

#XSPF playlist output format
my $writer = new XML::Writer(OUTPUT      => $OUTF,
                             ENCODING    => "UTF-8",
                             DATA_MODE   => 1,
                             DATA_INDENT => 4);
$writer->xmlDecl("UTF-8");
$writer->startTag("playlist",
                  "version"   => "1",
                  "xmlns"     => "http://xspf.org/ns/0/",
                  "xmlns:vlc" => "http://www.videolan.org/vlc/playlist/ns/0/");
$writer->startTag("title");
$writer->characters($pl_name);
$writer->endTag("title");
$writer->startTag("trackList");

while ( readdir IN_DIR )
{
    #skip current and parent folder names
    next if ( ( $_ eq '.' ) || ( $_ eq '..' ) );
    open ( CF , "<", $dir . "\/" . $_ ) or die "Can not open $dir\/$_ :\n$!\n";
    chomp ( my @lines = <CF> );
    foreach my $line (@lines)
    {        
        if ( $line =~ m/^.*\"name\": +\"(.*)\",$/i )
        {
            print STDERR "Channel \"$1\" finded\n" if ( $opt_w );
            $writer->startTag("track");
            $writer->startTag("title");
            $writer->characters($1);
            $writer->endTag("title");
            $writer->startTag("location");
            $writer->characters("http:\/\/$user$password$host$port\/playlist\/channelid\/$_");
            $writer->endTag("location");
            $writer->startTag("extension", "application" => "http://www.videolan.org/vlc/playlist/0");
            $writer->startTag("vlc:id");
            $writer->characters($index);
            $writer->endTag("vlc:id");
            $writer->startTag("vlc:option");
            $writer->characters("network-caching=1000");
            $writer->endTag("vlc:option");
            $writer->endTag("extension");
            $writer->endTag("track");
            $index++;
            last;
        }
    }    
    close ( CF );
}

print "Complete. $index channels finded & processed.\n";

$writer->endTag("trackList");
$writer->endTag("playlist");
$writer->end();

closedir IN_DIR;
close OUTF;