#!/usr/bin/perl -w
use POE qw(Wheel::FollowTail);
use Log::Syslog::Fast qw(:all);
 
defined(my $pid = fork) or die "Cant fork:$!";
unless($pid){  
}else{
         exit 0;
}
 
POE::Session->create(
    inline_states => {
      _start => sub {
        $_[HEAP]{tailor} = POE::Wheel::FollowTail->new(
          Filename => "/root/.mysql_history",
          InputEvent => "got_log_line",
          ResetEvent => "got_log_rollover",
        );
      },
      got_log_line => sub {
        to_rsyslog($_[ARG0]);
      },
      got_log_rollover => sub {
        to_rsyslog('roll');
      },
    }
);
 
POE::Kernel->run();
exit;
 
sub to_rsyslog {
  $message = join' ',@_;
#rsyslog¿ªµÄÇDPµÄ14¶˿ڣ»¶øLOCAL0ºÍOG_INFO¶¼Êsyslog¶¨Òµģ¬ÂдµĻ°»á¶¯¹ékernel | alert
  my $logger = Log::Syslog::Fast->new(LOG_UDP, "10.0.0.123", 514, LOG_LOCAL0, LOG_INFO, "mysql_231", "mysql_monitor");
  $logger->send($message ,time);
};
