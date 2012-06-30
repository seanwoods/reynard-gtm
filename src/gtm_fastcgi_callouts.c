#include <stdlib.h>
#include <stdio.h>
#include "fcgi_config.h"
#include "fcgiapp.h"
#include "gtmfcgi.h"
#include "gtmxc_types.h"

/* @gtmxc-module fastcgi */

/* @gtmxc getParam: xc_char_t* get_param(I:xc_char_t*) */
char* get_param(int count, char *param) {
    return FCGX_GetParam(param, gtm_fcgi_req.envp);
}

/* @gtmxc nextParam: int next_param(I:xc_int_t) */
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

/* @gtmxc getParamByNum: xc_char_t* get_param_by_num(I:xc_int_t) */
char* get_param_by_num(int count, int num) {
    if (gtm_fcgi_req.envp[num] == NULL) {
        return "PARAM_NOT_FOUND=INVALID";
    }

    return gtm_fcgi_req.envp[num];
}

/* @gtmxc paramExists: int param_exists(I:xc_char_t*) */
int param_exists(int count, char *param) {
    if (get_param(count, param) == NULL) {
        return 0;
    } else {
        return 1;
    }
}

/* @gtmxc send: void send(I:xc_char_t*) */
void send(int count, char *msg) {
    FCGX_PutS(msg, gtm_fcgi_req.out);
}

/* @gtmxc getChar: xc_int_t get_char() */
int get_char(int count) {
    return FCGX_GetChar(gtm_fcgi_req.in);
}
