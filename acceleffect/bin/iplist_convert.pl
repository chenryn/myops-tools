#!/usr/bin/perl -w
#my $ip = inet_aton("$ARGV[0]");
my $ip = inet_aton(get_test_ip());
my $file = $ARGV[1] || 'iplist.txt';
my $length = `cat $file | wc -l`;
 
my $code = get_area_code('quhao.txt');
my @isplist = qw(other ctc cnc edu mobile);
 
open my $fh, '<', "$file" or die "Cannot open $file\n";
my $line_len = '26';                       #=10+10+4+1+1£¬°üµ·ûâƪÊ³ö˺ÿ´¶à¿ո񣬿ÉÔ¾µômy $first = 0;
my $last = $length - 1;                    #ͳһʹÓSEEK_SET,ËÒ×ºóеÄð»ÖÊlength-1 
my $result = 1;
while ($result) {
    my $middle = sprintf("%.0f",($last-$first) / 2 + $first);    #Õ°ëÖ£¬³ýûÓsprintf±È±½Ónt¾«ȷ
    seek $fh, $line_len * $middle, 0;                            #Ò¶¯µ½Õ°ëÖ 
    sysread $fh, $begin_ip, 10;                                  #´Ó۰봦¶Á¡10λ 
    sysread $fh, $end_ip, 10;                                    #½ÓÅٶÁ0λ,È¹û¿ոñҪÏseekÒ¶¯1λ,Â·³ 
    #¸ù´óö´Îòöòë   if ( $ip < $begin_ip ) {
        $last = $middle;
        next;
    } elsif ( $ip > $end_ip ) {
        $first = $middle;
        next;
    } else {
    #Õµ½ÏӦÇ¼䣬¶Á¡ÇºźÍËªÉºÅ        sysread $fh, $area, 4;
        sysread $fh, $isp, 1;
        printf "%010s %s %s\n", $ip, $code->{"$area"}, $isplist[$isp];
        $result = 0;                                             #É¶¨$resultΪ¼٣¬Í³ö· 
    };
};
 
close $fh;
 
sub inet_aton {
    my $ip = shift;
    my $short = sprintf "%010s", $1 * 256**3 + $2 * 256**2 + $3 * 256 + $4 if $ip =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/;
    return $short;
};
#¶Ô¦ÇºźÍ¡·ݣ¬¸úµÄvÏ·´
sub get_area_code {
    my $file = shift;
    my $area_code = { '0000' => 'other' };
    open my $fh,'<',"$file" or die "Cannot open $file";
    while (<$fh>) {
	chomp;
        my($area,$code) = split;
	$area_code->{"$code"} = "$area";
    }
    close $fh;
    return $area_code;
};
#É³É»¸öú·¨ipµØ·
sub get_test_ip {
    return join '.', map int rand 256, 1..4;
}
