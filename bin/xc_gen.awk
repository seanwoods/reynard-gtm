#!/usr/bin/awk -f

/^\/\*\s*@gtmxc-module/ {
    print ENVIRON["mumps_root"] "/bin/" $3 ".so"
}

/^\/\*\s*@gtmxc\s+/ {
    for (i = 3; i < NF; i++) {
        printf "%s ", $i
    }

    printf "\n"
}
