#!/usr/bin/perl -w

use strict;
use Data::Dumper;

use LWP::UserAgent;
use XML::Simple;
use Net::Telnet ();


my $todays_weather = get_bbc_xml_weather();
#my $todays_weather = "Yeah it's sunny and warm :)";

my $t = create_connection();

my $roku_time = get_time($t);

my $minutes = get_minutes($t);
$t->cmd("sketch -c marquee \"$todays_weather\"");

while ($minutes < 50) {
    $t->cmd("sketch -c text c c \"$roku_time\"");
    sleep(5);
    $t->cmd("sketch -c marquee \"$todays_weather\"");
    $minutes = get_minutes($t);
    $roku_time = get_time($t);
}

$t->cmd("sketch -c quit");
$t->cmd("exit");

exit;

####################
# F U N C T I O N S 
####################

sub create_connection {
    my $t = new Net::Telnet(
                            Port => 4444,
                            Timeout=> 10000,
                            Prompt=> '/SoundBridge>/'
                            );
                            
    $t->open("192.168.1.11");  
    $t->cmd("sketch -c quit");
    
    return $t;
}

sub get_time {
    my $t = shift;
    $t->cmd("time");    
    $t->lastline =~ /(\d{1,2}:\d{1,2}):[\d\. ]*$/;
    return $1;
}

sub get_minutes {
    my $t = shift;
    my $roku_time = get_time($t);
    $roku_time =~ /(\d{1,2}):(\d{1,2})/;
    return $2;
}

sub get_bbc_xml_weather {
    my $ua = LWP::UserAgent->new;
    $ua->timeout(10);
    $ua->env_proxy;
     
    my $response = $ua->get('http://feeds.bbc.co.uk/weather/feeds/rss/5day/id/3561.xml');
     
    unless ($response->is_success) {
        die $response->status_line;
    }   

    my $xs      = XML::Simple->new();
    my $xml_ref = $xs->XMLin($response->content);
    
    return $xml_ref->{channel}->{item}->[0]->{title}; 
}



