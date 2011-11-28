#!/usr/bin/perl
use strict;
use warnings;
use IO::Socket;
use Getopt::Long;
use POSIX qw(strftime);
#Init
my %traf;
my ($warning,$interval,$usage,$silent);
my ($eth0_in,$eth0_out,$eth1_in,$eth1_out);
my $alarm = 0;
$warning = "1000,2000,10000,80000";
$interval = 10;
#get options
Getopt::Long::Configure('bundling');
GetOptions(
"h" => $usage, "v" => $usage,
"s" => $silent,
"w=s" => $warning,
"H=s" => $peer,
"t=f" => $interval,
);
if ($usage) {
&usage;
}
if ($warning) {
&usage unless $warning =~ /d+,d+,d+,d+/;
}
my ($eth0_in_warn,$eth0_out_warn,$eth1_in_warn,$eth1_out_warn) = split(/,/,$warning);
#fork
defined(my $pid=fork) or die "Cant fork:$!";
unless($pid){
}else{
exit 0;
}
#main
while (1) {
#ÕµãÆ¹֣¬±¾´òÑainÀͷµĶ«Îֱ½Ó´ÔwhileÀµģ¬ÔÐȴһֱûÊ³ö»Ҫ¶¨Ò³Éub£¬bÂ¾ͺÃá­¡­
&main;
}
#functions
sub main {
($eth0_in,$eth0_out,$eth1_in,$eth1_out) = &count;
#ÿ5·Öӱ£´浽tmpÎ¼þ£¬¹©nrpe¶Á¡Ê¾ݣ¬¸øos»­ͼÓ
my $nrpetime = strftime("%M%S",localtime);
if ($nrpetime =~ /d(5|0)0d/) {
&write_for_nrpe;
}
&alarm unless($silent);
}
sub count {
&data;
$traf{"eth0In_old"} = $traf{eth0In};
$traf{"eth1In_old"} = $traf{eth1In};
$traf{"eth0Out_old"} = $traf{eth0Out};
$traf{"eth1Out_old"} = $traf{eth1Out};
sleep $interval;
&data;
my $eth0_in_flow = sprintf "%.2f",($traf{eth0In}-$traf{"eth0In_old"})/$interval*8/1024;
my $eth1_in_flow = sprintf "%.2f",($traf{eth1In}-$traf{"eth1In_old"})/$interval*8/1024;
my $eth0_out_flow = sprintf "%.2f",($traf{eth0Out}-$traf{"eth0Out_old"})/$interval*8/1024;
my $eth1_out_flow = sprintf "%.2f",($traf{eth1Out}-$traf{"eth1Out_old"})/$interval*8/1024;
return $eth0_in_flow,$eth0_out_flow,$eth1_in_flow,$eth1_out_flow;
}
sub data {
open DEV,"</proc/net/dev" || die "Cannot open procfs!";
while (defined(my $ifdata=<DEV>)){
next if $ifdata !~ /eth/;
my @data = split (/:|s+/,$ifdata);
$traf{"$data[1]In"} = $data[2];
$traf{"$data[1]Out"} = $data[10];
}
close DEV;
}
sub write_for_nrpe {
open FH,">/tmp/if_flow.txt" || die $!;
print FH "$eth0_in|$eth0_out|$eth1_in|$eth1_out";
close FH;
}
sub alarm {
#¿¼Âµ½ĬÈ10sȡֵһ´Σ¬ͻ·¢ÁÈ¹û100s£¬¾ͻásocket·¢Ë10´Σ¬ËÒ½ø¶¨£¬ֻÔͻ·¢¿ªʼºÍ»·¢½áʱ·¢ËwarnºÍk¡£дµĺܳ����­¡­
my $alarm_int = 0;
$alarm_int = 1 if ($eth0_in-$eth0_in_warn>0);
$alarm_int = 1 if ($eth0_out-$eth0_out_warn>0);
$alarm_int = 2 if ($eth1_in-$eth1_in_warn>0);
$alarm_int = 2 if ($eth1_out-$eth1_out_warn>0);
next if $alarm_int == $alarm;
&call_sniffer("eth0:WARN") if ($alarm_int-$alarm==1);
&call_sniffer("eth1:WARN") if ($alarm_int-$alarm==2);
&call_sniffer("eth0:OK") if ($alarm_int-$alarm==-1);
&call_sniffer("eth1:OK") if ($alarm_int-$alarm==-2);
$alarm = $alarm_int;
}
sub call_sniffer {
my $message = shift;
my $socket = IO::Socket::INET->new(PeerAddr => $peer,
PeerPort => 12345,
Proto    => 'tcp')
or die $@;
print $socket "${message}n";
$socket->shutdown(1);
my $answer=<$socket>;
if ($answer) {
print $answer;
}
$socket->close or die $!;
}
sub usage {
print "Version: check_eth_flow.pl v0.1n";
print "Usage: check_eth_flow.pl -w 1000,2000,10000,80000 -t 10n";
print "tt-w Warning Value: eth0_in,eth0_out,eth1_in,eth1_out;n";
print "tt-t Interval Time;n";
print "tt-s Silent write for nagios;n"
print "tt-H Host address of peer;n";
print "tt-h Print this usage.n";
exit 0;
}
