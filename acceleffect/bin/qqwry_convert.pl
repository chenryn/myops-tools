#!/usr/bin/perl -w
my($quhao, $qqwry) = @ARGV;
$code = read_area_code($quhao);
overwrite_iplist($qqwry, $code);
sub inet_aton {
    my $ip = shift;
    my $short = sprintf "%010s", $1 * 256**3 + $2 * 256**2 + $3 * 256 + $4 if $ip =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/;
    return $short;
};
 
sub read_area_code {
    my $file = shift;
    my $area_code = {};
    open my $fh,'<',"$file" or die "Cannot open $file";
    while (<$fh>) {
	chomp;
        my($area,$code) = split;
	$area_code->{"$area"} = "$code";
    }
    close $fh;
    return $area_code;
};
 
sub overwrite_iplist {
    my($iplist, $area_code) = @_;
    my($last_begin_ip_n, $last_end_ip_n, $last_province_n, $last_isp_n);
    open my $fh,'<',"$iplist" or die "Cannoet open $iplist";
    while (<$fh>) {
	chomp;
	my($begin_ip, $end_ip, $area, $isp) = split;
	my($province_n, $isp_n);
	my $begin_ip_n = &inet_aton("$begin_ip");
	my $end_ip_n = &inet_aton("$end_ip");
        next if ($end_ip_n - $begin_ip_n) < 32;
	if ( $area =~ /ѧ/ ) {
	    $isp_n = 4;                                          #½Ìýò廪±±´ó§У¼Ç¼ÔareaÀÁ£¬ËÒÕ²½ÌǰÉ¶¨ 
	};
	if ( $isp =~ m/µç/ ) {
	    $isp_n = 1;                                          #µç 
	} elsif ( $isp =~ m/jͨ/ ) {
            $isp_n = 2;                                          #jͨ(°üø
	} elsif ( $isp =~ m/Ìͨ|Ò¶¯/ ) {
	    $isp_n = 3;                                          #Ò¶¯(°üú
	} elsif ( $isp =~ m/ѧ/ ) {
	    $isp_n = 4;                                          #½Ìý} else {
	    $isp_n = 0;                                          #¹úַ¼°ÆËδÄʶ±ðúӪÉ 
	};
 
        my $province = substr($area, 0, 4);                      #ÖÎÓ2×½ڣ¬ËÒ¶Ô­ʼ¼Ç¼»ñ°Ë×½ڼ´Ϊʡ·Ýû ( exists $area_code->{"$province"} ) {
	    $province_n = $area_code->{"$province"};             #¹ú֪µ绰ÇºŵÄ¡·Ý
	} else {
	    $province_n = '0000';                                #¸۰Ä¨¼°Í¹úÄÓÆËδÄʶ±ðúַ 
	};
        #Ï¶Îªºϲ¢Í¶Σ¬֮ǰdnsʱҲÓ¹ý(!$last_province_n) {
	    ($last_begin_ip_n, $last_end_ip_n, $last_province_n, $last_isp_n) = ($begin_ip_n, $end_ip_n, $province_n, $isp_n);
	};
        if ( $last_province_n == $province_n && $last_isp_n == $isp_n ) {
	    $last_end_ip_n = $end_ip_n;
	} else {
	    printf "%010s %010s %04s %s\n", $last_begin_ip, $last_end_ip, $last_province_n, $last_isp_n;
	    ($last_begin_ip_n, $last_end_ip_n, $last_province_n, $last_isp_n) = ($begin_ip_n, $end_ip_n, $province_n, $isp_n);
	};
    };
    close $fh;
};
