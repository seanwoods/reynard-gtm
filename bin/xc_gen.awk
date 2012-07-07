#!/usr/bin/awk -f

/^\/\*[[:space:]]*@gtmxc-module/ {
    print ENVIRON["mumps_root"] "/bin/" $3 ".so"
}

/^\/\*[[:space:]]*@gtmxc[[:space:]]+/ {
    for (i = 3; i < NF; i++) {
        printf "%s ", $i
    }

    printf "\n"
}
