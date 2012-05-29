#include <stdlib.h>
#include <stdio.h>
#include "fcgi_config.h"
#include "fcgiapp.h"
#include "gtmfcgi.h"
#include "gtmxc_types.h"

char* get_param(int count, char *param) {
    return FCGX_GetParam(param, gtm_fcgi_req.envp);
}

int next_param(int count, int num) {
    if (num < 0) {
        num = 0;
    } else {
        num++;
    }

    if (gtm_fcgi_req.envp[num] == NULL) {
        return -1;
    }
    
    return num;

}

char* get_param_by_num(int count, int num) {
    if (gtm_fcgi_req.envp[num] == NULL) {
        return "PARAM_NOT_FOUND=INVALID";
    }

    return gtm_fcgi_req.envp[num];
}

int param_exists(int count, char *param) {
    if (get_param(count, param) == NULL) {
        return 0;
    } else {
        return 1;
    }
}

void send(int count, char *msg) {
    FCGX_PutS(msg, gtm_fcgi_req.out);
}

int get_char(int count) {
    return FCGX_GetChar(gtm_fcgi_req.in);
}
