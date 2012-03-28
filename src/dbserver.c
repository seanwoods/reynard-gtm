#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <time.h>
#include <unistd.h>

#include "gtmci.h"
#include "gtmxc_types.h"

#include "zmq.h"
#include "zhelpers.h"

#define NOT_OK 0
#define OK 1
#define SHOULD_QUIT 2
#define ERROR_ENCOUNTERED 3

#define SEG_DELIM '\x1D'
#define REC_DELIM '\x1E'
#define FLD_DELIM '\x1F'

/* Terminal Stuff */

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

/* Performance Measuring */

long int perf_diff_time(struct timeval t1, struct timeval t2) {

    return   (t2.tv_sec + ( (double) t2.tv_usec / 1000000))
           - (t1.tv_sec + ( (double) t1.tv_usec / 1000000));
}

/* Call-In Wrappers */

static void handle_error(context_t *context) {
    
    gtm_zstatus(context->msgbuf, GTM_BUF_LEN);

    char eident[16];

    //gtm_zstatus(context->msgbuf, GTM_BUF_LEN);
    
    /*if (context->status != 0) {
        sprintf(context->out, "%s", context->msgbuf);
    }*/

    context->status = gtm_ci("err", &eident);

    if (context->status != 0) {
        sprintf(context->out, "An error occurred while processing the error"
        "trap.");
        fprintf(stderr, "An error occurred while processing the error trap.");
    }
    
    sprintf(context->out, "%s,%s", context->msgbuf, eident);
}

int gtm_initialize(context_t *context) {
    save_input_mode();

    context->status = gtm_init();

    if (context->status != 0) {
        handle_error(context);
        return 0;
    }

    return 1;

}

int gtm_teardown(context_t *context) {
    context->status = gtm_exit();

    if (context->status != 0) {
        handle_error(context);
        return 0;
    }
    
    return 1;
}

int gtm_exec(context_t *context, char *cmd, char *msg) {

    context->status = gtm_ci("exec", context->out, cmd, msg);
    
    if (context->status != 0) {
        handle_error(context);
        return 0;
    }
    
    return 1;

}

int gtm_msg_alloc(context_t *context) {

    context->status = gtm_ci("alloc", context->out);
    
    if (context->status != 0) {
        handle_error(context);
        return 0;
    }
    
    return 1;

}

int gtm_set_record(context_t *context, int msg_id, int group, int record, char *data)
{
    context->status = gtm_ci("setrec", context->out, msg_id, group, record, data);

    if (context->status != 0) {
        handle_error(context);
        return 0;
    }

    return 1;
}

int gtm_is_multipart(context_t *context) {
    return context->multipart;
}

int gtm_next(context_t *context, char *vn, char *sub) {
    context->status = gtm_ci("next", context->out, vn, sub);

    if (context->status != 0) {
        handle_error(context);
        return 0;
    }

    return 1;
}

int gtm_handle_message(context_t *context, int msg_id) {
    context->status = gtm_ci("handleMsg", context->out, msg_id);

    if (context->status != 0) {
        handle_error(context);
        return 0;
    }

    if ( strncmp(context->out, "\002\006\003\007", 4) == 0 ) {
        // We have a multi-part string on our hands.
        context->multipart = 1;
        char varname[64];
        
        strncpy( (char *) varname, context->out + (4 * sizeof(char)), 63);
        strncpy(context->out, (char *) varname, 64);
    }

    return 1;
}

int process_msg(context_t *context, int msg_id, char *msg, int len) {
    int b = 0, group = 0, record = 0, i = 0;
    char *buffer;

    if (len == 0) {
        return NOT_OK;                     /* No-op */
    }

    if ( strncmp(msg, "QUIT", strlen("QUIT")) == 0 ) {
        gtm_set_record(context, msg_id, 1, 1, "QUIT received.");

        return SHOULD_QUIT;
    }

    /* The buffer is "too big," but it doesn't really matter.
       It's better than allocating based on a guess and constantly
       reallocating (right?). */
    buffer = malloc(len * sizeof (char));

    if (buffer == NULL) {
        perror("Could not allocate memory.\n");
    }
    
    for (i = 0; i < len; i++) {
        if (msg[i] == 29) {             /* Group */

            buffer[b] = 0;
            if (!gtm_set_record(context, msg_id, group, record, buffer)) {
                return ERROR_ENCOUNTERED;
            }
            
            /* Reset Buffer */
            b = 0;
            buffer[b] = 0;

            group++;
            record = 0;

        } else if (msg[i] == 30) {      /* Record */

            buffer[b] = 0;
            if (!gtm_set_record(context, msg_id, group, record, buffer)) {
                return ERROR_ENCOUNTERED;
            }
            
            /* Reset Buffer */
            b = 0;
            buffer[b] = 0;

            record++;

        } else {

            buffer[b] = msg[i];
            b++;

        }
    }
    
    buffer[b] = 0;
    
    if (!gtm_set_record(context, msg_id, group, record, buffer)) {
        return ERROR_ENCOUNTERED;
    }

    free(buffer);
    
    return OK;
}

void dbserver_loop(char *bind_to) {
    context_t gtm_context;
    int quit = 0;
    unsigned int msg_id;

    struct timeval perf_time_1, perf_time_2, perf_time_3;
    //long int perf_interval_1, perf_interval_2;
    
    gtm_initialize(&gtm_context);
    void *zmq_context = zmq_init(1);
    void *responder = zmq_socket(zmq_context, ZMQ_REP);
    zmq_bind(responder, bind_to);

    while (quit != SHOULD_QUIT) {
        zmq_msg_t message;
        zmq_msg_init(&message);

        if(zmq_recv (responder, &message, 0)) {
            if (errno == EINTR) {
                continue;
            }

            printf("Failure trying to receive 0MQ message: %s\n",
                   zmq_strerror(errno));
        }
        
        gettimeofday(&perf_time_1, NULL);

        if (gtm_msg_alloc(&gtm_context)) {

            msg_id = atoi(gtm_context.out);
            gtm_context.multipart = 0;

            quit = process_msg(&gtm_context,
                               msg_id,
                               zmq_msg_data(&message),
                               zmq_msg_size(&message));

        } else {
            perror("Message ID could not be allocated.\n");
        }
        
        gettimeofday(&perf_time_2, NULL);

        zmq_msg_close(&message);
        
        if (quit == SHOULD_QUIT) {
            s_send(responder, "BYE");
        } else if (quit == ERROR_ENCOUNTERED) {
            s_send(responder, gtm_context.msgbuf);
        } else {
            // This will set context.multipart if applicable
            gtm_handle_message(&gtm_context, msg_id);

            if (gtm_is_multipart(&gtm_context)) {
                
                char sub[16] = "";
                
                do {
                    gtm_next(&gtm_context, "out", sub);

                    if ( strcmp(sub, "") != 0 ) {  // i.e. sub != ""
                        s_sendmore(responder, gtm_context.out);
                    } else {
                        s_send(responder, gtm_context.out);
                        break;
                    }
                } while (1);

            } else {
                s_send(responder, gtm_context.out);
            }
        }

        gettimeofday(&perf_time_3, NULL);
        
        // perf_interval_1 = perf_diff_time(perf_time_1, perf_time_2);
        // perf_interval_2 = perf_diff_time(perf_time_3, perf_time_3);

        // printf("P1: %10li P2%10li:\n", perf_interval_1, perf_interval_2);

    }

    zmq_close(responder);
    zmq_term(zmq_context);
    gtm_teardown(&gtm_context);

}

int main(int argc, char *argv[]) {
    char *bind_to = "tcp://*:1841";

    dbserver_loop(bind_to);

    return 0;
}
