{
    a[substr($4,14,5)]+=$10
}

END{
    n=asort(a);
    print a[n]*8/60/1024/1024
}
