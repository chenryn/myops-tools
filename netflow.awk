BEGIN{
    system("touch /tmp/if_flow.txt");
    flow="netstat -idbnf inet";
    while( (flow) | getline) {
        now_in[$1]=$7;
        now_out[$1]=$10
    };
    time='`date +%s`';
}

{
    if_in[$1]=(now_in[$1]-$2)*8/(time-$4);
    if_out[$1]=(now_out[$1]-$3)*8/(time-$4)
}

END{
    printf "OK. The flow is %.2f,%.2f,%.2f,%.2f Kbps | bce0_in=%d;0;0;0;0 bce0_out=%d;0;0;0;0 bce1_in=%d;0;0;0;0 bce1_out=%d;0;0;0;0",
    if_in["bce0"]/1024, if_out["bce0"]/1024, if_in["bce1"]/1024, if_out["bce1"]/1024,
    if_in["bce0"], if_out["bce0"], if_in["bce1"], if_out["bce1"];

    for(i in now_in){
        print i,now_in[i],now_out[i],time > "/tmp/if_flow.txt"
    }
}
