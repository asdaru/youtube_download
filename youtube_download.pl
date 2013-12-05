#!/usr/bin/env perl

use lib "/home/asda/workspace/wms/mojo/lib";
use Mojo::UserAgent;
use Mojo::DOM;
use Mojo::URL;
use Data::Dumper;
use v5.10;
use strict;
use warnings;
$ENV{MOJO_MAX_MESSAGE_SIZE} = 1073741824;

sub parse_page {
	my $page          = shift;
	my $ua            = Mojo::UserAgent->new;
	my $res           = $ua->get( $page => { DNT => 1 } )->res;
	my $dom           = Mojo::DOM->new( $res->body );
	my @youtubes_http = ();

	for my $iframe ( $dom->find("iframe")->each ) {
		if ( $iframe->{src} =~ /youtube\.com/ ) {
			push @youtubes_http, $iframe->{src};
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
	say "title: $name";
	my $filename = $name;
	$filename =~ s/\//_/g;
	$filename =~ s/\./_/g;
	$filename =~ s/\%/_/g;
	$filename =~ s/\*/_/g;
	$filename =~ s/\?/_/g;

	if ( !-f "./$filename.mp4" ) {

		#$res = $ua->get( "http://ru.savefrom.net/#url=http://youtube.com/watch?v=$youtube_id&utm_source=youtube.com&utm_medium=short_domains&utm_campaign=www.ssyoutube.com" => { DNT => 1 } )->res;
		$res = $ua->get( 'http://keepvid.com/?url=http%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3D' . $youtube_id => { DNT => 1 } )->res;

		$dom = Mojo::DOM->new( $res->body );
		my @mp4 = ();

		for my $a ( $dom->find("a")->each ) {
			push @mp4, $a->{href} if $a->text =~ /Download MP4/;
		}

		if ( $mp4[1] ) {
			$res = $ua->get( $mp4[1] )->res;
		} elsif ( $mp4[0] ) {
			$res = $ua->get( $mp4[0] )->res;
		}

		#$res->headers->content_disposition =~ /"(.+)"/;
		#my $filename = $1;

		say "download: $filename";
		$res->content->asset->move_to("./$filename.mp4");
	}
}

sub main {
	my @links = @_;
	foreach my $link (@links) {
		say "page: $link";
		my @youtubes_http = parse_page($link);
		foreach (@youtubes_http) {
			say "youtube link: $_";
			download($_);
		}
	}
}

main(<STDIN>);
