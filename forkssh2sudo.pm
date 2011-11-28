#°üç×pmµĻ°£¬±Øë(.*).pmµÄûÑ
package forkssh2sudo;
use Parallel::ForkManager;
use Expect;
#Exporterģ¿éperlÌ¹©µĵ¼Èģ¿鷽·¨µĹ¤¾ßuse base 'Exporter';
#ExporterÓ}¸ö飬@EXPORTÀ´æÊģ¿ésub£¬@EXPORT_OKÀ´æÊģ¿évar£»
#ʹÓģ¿éֻÄµ÷âÊ×ÀÓ¶¨ÒµĶ«Î
our @EXPORT = qw/new cluster/;
#һ°ã¿鶼Óһ¸ö·½·¨4½øʼ»¯¶¨Ò
sub new {
#ËÓsub´«ÈµĵÚ»¸öý¾É£¬ËÒҪÏshift³ö¬Ȼºóǽű¾Ïʽ´«ÈµĲÎýclass = shift;
#½«²Îýþϣ·½ʽ£¬²¢·µ»Ø»¸öã»
#Õ¹æ·¨Ӧ¸ÃÚâָ¶¨һЩ±ØëÓµĲÎýçsswd => %args{'passwd'} || '123456'
my $self = {@_};
#blessÉÃ·µ»صĹþϣÒÓµ½×¼º£¬Ô´«µݳö»ÒºóâÍµĵط½£¬ʹÓ±»bless¹ýlfʱ×¶¯¾͹ØªÉnewÀµÄý£
#ÕÀÎдµļ«¼򵥣¬¿´±ȽÏý£¿é·¢£¬ÕÀ¶Ôclass»¹ҪÓref();Å¶Ïǲ»ÊÒÓµÈreturn bless $self,$class;
}
 
sub cluster {
#ÕÀµÄself¾ÍÇÏ汻bless¹ý    my ($self, $command) = @_;
    my %remote_result;
    my $pm = Parallel::ForkManager->new( $self->{fork}, '/tmp/');
    $pm->run_on_finish (
    sub {
        my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $reference) = @_;
        if (defined($reference)) {
            my @data = @$reference;
            $remote_result{"$data[0]"} = $data[1];
        } else {
            print qq|No message received from child process $pid!\n|;
        }
    }
    );
#ֱ½Ó¹Óbless¹ýlf½âÓ³öÄostsÁ±íoreach my $remote_host (@{$self->{hosts}}) {
    $pm->start and next;
#ʹÓbless¹ýlfµÄubÍ³Éxpect¹¦Ä
    my @check = ($remote_host, $self->pexpect($remote_host, $command));
    $pm->finish(0, \@check);
}
$pm->wait_all_children;
 
return %remote_result;
}
 
sub pexpect {
#»¹ÊͬÑµÄself£¬ȻºóÇÏæÓʱ´«µݵÄhostºÍshell
my ($self, $host, $shell) = @_;
#ʹÓnewÀÌ¹©µÄasswd
my $password = $self->{passwd};
my $exp = Expect->new;
$exp = Expect->spawn("ssh -l admin -i /usr/local/admin/conf/id_rsa -o ConnectTimeout=5 $host");
$ENV{TERM}="xterm";
$exp->raw_pty(1);
#ʹÓnewÀÌ¹©µĿª¹Ø$exp->exp_internal("$self->{debug}");
$exp->log_stdout("$self->{output}");
$exp->expect(2,[
                    '\$',
                    sub {
                            my $self = shift;
                            $self->send("su -\n");
                        }
                ],
                [
                    '\(yes/no\)\?',
                    sub {
                            my $self = shift;
                            $self->send("yes\n");
			    exp_continue;
                         }
                ]
            );
 
$exp->expect(2, [
		    'Password:',
		    sub {
			    my $self = shift;
			    $self->send("${password}\n");
			    exp_continue;
		        }
		],
		[
		    '#',
		    sub {
			    my $self = shift;
			    $self->send("${shell}\n");
			}
		]
	    );
$exp->send("exit\n") if ($exp->expect(undef,'#'));
#ÒΪshellÃÁִÐµÄä¿ÉÜÐͺóùǰºóä
my $read = $exp->before() . $exp->after();
$read =~ s/\[.+\@.+\]//;
$exp->send("exit\n") if ($exp->expect(undef,'$'));
$exp->soft_close();
return $read;
}
#package½á£¬±Øëturnһ¸öԭÒδ֪¡­¡­
1;
