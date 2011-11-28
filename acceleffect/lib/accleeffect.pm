use Dancer ':syntax';
use Dancer::Plugin::Database;
use POSIX qw(strftime);
 
get '/xml' => sub {
    my $begin_time = date_format(params->{begin});
    my $end_time = date_format(params->{end});
    my $type = params->{type};
    my $color = { chinacache => '1D8BD1',
                  dnion      => 'F1683C',
                  fastweb    => '2AD62A',
                };
    my $xml_head = "<graph caption='Response Time' subcaption='from $begin_time to $end_time' hovercapbg='FFECAA' hovercapborder='F47E00' formatNumberScale='0' decimalPrecision='0' showvalues='0' numdivlines='3' numVdivlines='0' yaxisminvalue='1000' yaxismaxvalue='1800'  rotateNames='1'>\n<categories >\n";
    my $group;
    if ( $type eq 'time' ) {
        $group = 'cur_date';
    } elsif ( $type eq 'isp' ) {
        $group = 'isp';
    } elsif ( $type eq 'area' ) {
        $group = 'area';
    } else {
        return 'Error';
    };
    my $xml = cdn_select($begin_time, $end_time, $group, $color, $xml_head);
    return $xml;
};
 
sub get_area_code {
    my $file = shift;
    my $area_code = { '0000' => 'ÆË' };
    open my $fh,'<',"$file" or die "Cannot open $file";
    while (<$fh>) {
	chomp;
        my($area,$code) = split;
	$area_code->{"$code"} = "$area";
    }
    close $fh;
    return $area_code;
};
 
sub cdn_select {
    my ($begin_time, $end_time, $group, $color, $xml) = @_;
    my $sql = "SELECT ${group},AVG(avg_time) avg FROM cdn_cron_record WHERE cdn = ? AND cur_date BETWEEN ? AND ? GROUP BY ${group} ORDER BY ${group}";
    my $sth = database->prepare($sql);
    my $i = 0;
    for my $cdn (qw{chinacache dnion fastweb}) {
        $sth->execute($cdn, $begin_time, $end_time);
        unless($i) {
            my @values;
            while ( my $ref = $sth->fetchrow_hashref ) {
                my ($avg_time, $type) = ($ref->{'avg'}, $ref->{"$group"});
                $xml .= "<category name='convert_group($group, $type)' />\n";
                push @values, $avg_time;
            };
            $xml .= "</category>\n";
            $xml .= "<dataset seriesName='$cdn' color='$color->{$cdn}'>\n";
            $xml .= "<set value='$_' />\n" for @values;
            $xml .= "</dataset>\n";
        } else {
            $xml .= "<dataset seriesName='$cdn' color='$color->{$cdn}'>\n";
            while ( my $ref = $sth->fetchrow_hashref ) {
                $xml .= "<set value='$ref->{avg}' />\n";
            };
            $xml .= "</dataset>\n";
        };
        $i++;
    };
    $xml .= '</graph>';
    return $xml;
};
 
sub convert_group {
    my ($group, $origin) = @_;
    if ($group eq 'cur_date') {
        return $origin;
    } elsif ($group eq 'isp') {
        my @isplist = qw(other ctc cnc mobile edu);
        return $isplist[$origin];
    } elsif ($group eq 'area') {
        my $arealist = get_area_code('quhao.txt');
        my $code = sprintf("%04s",$origin);
        return $arealist->{$code};
    } else {
        return 'Error';
    };
};
 
sub date_format {
    my $time = shift;
    return strftime("%F %H:%M",localtime($time)) if $time =~ m/\d+/;
};
use Time::Local;
get '/cdncharts' => sub {
    my $type = params->{chartstype};
    my $begin = unix_time_format(params->{timefrom});
    my $end = unix_time_format(params->{timeto});
    my $req_url = "/xml?begin=${begin}&end=${end}&type=${type}";
    my $line = 1 if $type eq 'time';
    template 'charts', { line => $line, url => "$req_url", };
};
 
sub unix_time_format {
    my $time = shift;
    if ( $time =~ m/^(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2})/ ) {
        return timelocal('00',$5,$4,$3,$2-1,$1-1900);
    };
};
