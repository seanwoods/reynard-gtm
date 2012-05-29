#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <termios.h>
#include <unistd.h>

#include "fcgi_config.h"
#include "fcgiapp.h"
#include "gtmci.h"
#include "gtmfcgi.h"
#include "gtmxc_types.h"

extern char **environ;

struct termios term_settings;

void reset_input_mode(void) {
    tcsetattr(STDIN_FILENO, TCSANOW, &term_settings);
}

void save_input_mode(void) {
    if (isatty(STDIN_FILENO)) {
        tcgetattr(STDIN_FILENO, &term_settings);
        atexit( (void(*)()) reset_input_mode );
    }
}

int gtm_initialize(context_t *context) {
    save_input_mode();
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

static int gtm_set(context_t *context, char *key, char *value) {
    context->status = gtm_ci("set", key, value);

    if (context->status != 0) {
        return 0;
    }

    return 1;
}

/*
static int gtm_get(context_t *context, char *key) {
    context->status = gtm_ci("get", key);

    if (context->status != 0) {
        handle_error(context);
        return 0;
    }

    return 1;
}
*/

static int gtm_do(context_t *context, char *routine) {
    context->status = gtm_ci("do", routine);

    if (context->status != 0) {
        return 0;
    }

    return 1;
}

FCGX_Request gtm_fcgi_req;

int main (int argc, char *argv[]) {

    context_t context;
    int socket;
    
    FCGX_Init();
    socket = FCGX_OpenSocket(":6070", 5);

    // TODO error check

    FCGX_InitRequest(&gtm_fcgi_req, socket, 0);

    gtm_initialize(&context);

    while (FCGX_Accept_r(&gtm_fcgi_req) >= 0) {
        gtm_do(&context, "^%FastCGI");
    }
    
    FCGX_Finish_r(&gtm_fcgi_req);

    gtm_teardown(&context);

    return 0;

}
