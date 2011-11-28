#!/usr/bin/perl
use warnings;
use strict;
use autodie;
use Sys::Hostname;
use YAML::Syck;
use Net::IP::Match::Regexp qw( create_iprange_regexp match_ip );
use Stanford::DNS;
use Stanford::DNSserver;
$SIG{'HUP'} = 'catch_hup';
my $need_reload;
my $hostmaster = 'domain.chenlinux.com';
my $soa        = rr_SOA(hostname(), $hostmaster, time(), 3600, 1800, 86400, 0);
my $ns         = Stanford::DNSserver->new( listen_on => [ hostname() ],
#                                           debug     => 1,
                                           loopfunc  => \&conf_reload,
#                                           daemon    => 'no',
                                         );
my $regexp;
my @domains;
my $arealist;
my $templist;
my $config_path = '/data/chenlinux.com/perl/';
my $ns_domain = 'test.domain.chenlinux.com';
$ns->add_dynamic("$domain" => \&dyn_lb ) foreach my $domain ( @domains );
$ns->add_static( "$ns_domain", T_SOA, $soa);
$ns->add_static( "$ns_domain", T_NS, rr_NS($hostmaster));
 
$ns->answer_queries();
 
sub catch_hup {
    $need_reload = 1;
};
 
sub conf_reload {
    if( $need_reload ) {
        load_config();
        $need_reload = 0;
    };
};
 
sub load_config {
    $regexp = ip2area("ip.list");
    @domains = grep {s/${config_path}config-(.+?)\.yml/$1/} glob("${config_path}*");
    foreach my $domain ( @domains ) {
      $arealist->{"$domain"} = LoadFile("${config_path}config-${domain}.yml");
      @{$templist->{"$domain"}->{"$_"}} = @{$arealist->{"$domain"}->{"$_"}->{'per'}} foreach keys %{$arealist->{"$domain"}};
  };
};
 
sub dyn_lb {
    my ($domain,$residual,$qtype,$qclass,$dm,$from) = @_;
    my $ttl = 3600;
    my $ip = area2resolv($domain, $from);
    $dm->{'answer'} .= dns_answer(QPTR, T_A, C_IN, $ttl, rr_A($ip));
    $dm->{'ancount'} += 1;
    return 1;
};
 
sub ip2area {
    my $file = shift;
    my $area = {};
    my $last_area;
    open my $fh, '<', $file;
    while(<$fh>){
        if ( /^acl (\w+)/ ) {
            $last_area = $1;
        } elsif ( /^((\d{1,3}\.?){4});/ ) {
            $area->{"$1"} = $last_area;
        } else {
            next;
        };
    };
    my $regexp = create_iprange_regexp($area);
    return $regexp;
};
 
sub area2resolv {
    my $from = shift;
    my $area = match_ip( "$from", $regexp );
    my $ip;
    my $len = $#{$arealist->{"$domain"}->{"$area"}->{'per'}};
    for ( 0 .. $len ) {
        if ( $arealist->{"$domain"}->{"$area"}->{'per'}->[$_] ) {
            $ip = $arealist->{"$domain"}->{"$area"}->{'ip'}->[$_];
            $arealist->{"$domain"}->{"$area"}->{'per'}->[$_]--;
            last;
        };
        if ( $_ == $len ) {
            @{$arealist->{"$domain"}->{"$area"}->{'per'}} = @{$templist->{"$domain"}->{"$area"}};
            redo;
        };
    };
    return ip_conv("$ip");
};
 
sub ip_conv {
    my $ip = shift;
    return ($1<<24)|($2<<16)|($3<<8)|$4 if $ip =~ m/(\d+)\.(\d+)\.(\d+)\.(\d+)/;
}
