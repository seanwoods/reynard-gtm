#include <stdlib.h>
#include <stdio.h>
#include "fcgi_config.h"
#include "fcgiapp.h"
#include "gtmci.h"
#include "gtmxc_types.h"

extern char **environ;

int gtm_initialize(context_t *context) {
    context->status = gtm_init();

    if (context->status != 0) {
        //TODO handle_error(context);
        return 0;
    }

    return 1;

}

int gtm_teardown(context_t *context) {
    context->status = gtm_exit();

    if (context->status != 0) {
        //TODO handle_error(context);
        return 0;
    }
    
    return 1;
}
/*
static int gtm_set(context_t *context, char *key, char *value) {
    context->status = gtm_ci("set", key, value);

    if (context->status != 0) {
        handle_error(context);
        return 0;
    }

    return 1;
}

static int gtm_get(context_t *context, char *key) {
    context->status = gtm_ci("get", key);

    if (context->status != 0) {
        handle_error(context);
        return 0;
    }

    return 1;
}

static int gtm_do(context_t *context, char *routine) {
    context->status = gtm_ci("do", routine);

    if (context->status != 0) {
        handle_error(context);
        return 0;
    }

    return 1;
}
*/
int main (int argc, char *argv[]) {

    FCGX_Stream *in, *out, *err;
    FCGX_ParamArray envp;
    
    context_t context;

    gtm_initialize(&context);

    while (FCGX_Accept(&in, &out, &err, &envp) >=0) {
        // FCGX_GetParam(param_name, envp);
        // FCGX_FPrintF(stream, char *);
        // FCGX_GetChar(stream);
        FCGX_FPrintF(out, "Content-type: text/plain\r\n\r\n");
        FCGX_FPrintF(out, "Hello, world!\r\n");
    }
    
    gtm_teardown(&context);

    return 0;

}
