#!/usr/bin/env perl
#
# Andrey Mamaev
#
# How use downloader
# 1. make file with web pages each link in new line 
# 2. Start download "cat link.txt | ./youtube_download.pl"
# 3. Videos will download and call by title 
#
#

use Mojo::UserAgent;
use Mojo::DOM;
use Mojo::URL;
use Data::Dumper;
use v5.10;
use strict;
use warnings;
$ENV{MOJO_MAX_MESSAGE_SIZE} = 1024*1024*1042*20; #2G

sub parse_page {
	my $page          = shift;
	my $ua            = Mojo::UserAgent->new(max_redirects => 10);
	my $res           = $ua->get( $page => { DNT => 1 } )->res;
	my $dom           = Mojo::DOM->new( $res->body );
	my @youtubes_http = ();

	for my $iframe ( $dom->find("iframe")->each ) {
		if ( $iframe->{src} =~ /youtube\.com/ ) {
			push @youtubes_http, $iframe->{src};
		}elsif ($iframe->{src} =~ /l\.lj-toys\.com/){
			$iframe->{src} =~/vid=(.+)&mod/;
			push @youtubes_http, "http://www.youtube.com/embed/$1?wmode=opaque&wmode=opaque"
		}
	}

	return @youtubes_http;
}

sub download {
	my $youtube_http = shift;
	$youtube_http =~ /embed\/(.+)\?/;
	my $youtube_id = ($1);
	my $ua         = Mojo::UserAgent->new;
	my $res        = $ua->get( "http://www.youtube.com/watch?v=$youtube_id" => { DNT => 1 } )->res;
	my $dom        = Mojo::DOM->new( $res->body );
	my $name       = "";
	for my $span ( $dom->find("span")->each ) {

		if ( $span->{id} && $span->{id} eq "eow-title" ) {
			$name = $span->{title};
			last;
		}
	}
	my $filename = $name;
	$filename =~ s/\//_/g;
	$filename =~ s/\./ /g;
	$filename =~ s/\%/_/g;
	$filename =~ s/\*/_/g;
	$filename =~ s/\?/_/g;
	$filename =~ s/\:/ /g;

	if ( !-f "./$filename.mp4" ) {
		say "youtube link: $youtube_http";
		say "title: $name";

		system('youtube-dl -q --no-progress  --max-quality --no-mtime '.$youtube_id." && mv $youtube_id.mp4 \"$filename.mp4\"" ); 
		
	}else{
		say "Уже загружен $filename.mp4"
	}
}

sub main {
	my @links = @_;
	foreach my $link (@links) {
		#say "page: $link";
		my @youtubes_http = parse_page($link);
		foreach (@youtubes_http) {
			#say "youtube link: $_";
			download($_);
		}
	}
}

main(<STDIN>);
