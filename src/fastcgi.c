#include <stdlib.h>
#include <stdio.h>
#include "fcgi_config.h"
#include "fcgiapp.h"

extern char **environ;

static void PrintEnv(FCGX_Stream *out, char *label, char **envp) {
    FCGX_FPrintF(out, "%s\r\n", label);
    for ( ; *envp != NULL; envp++) {
        FCGX_FPrintF(out, "%s\r\n", *envp);
    }
    FCGX_FPrintF(out, "\r\n\r\n");
}

int main (int argc, char *argv[]) {

    FCGX_Stream *in, *out, *err;
    FCGX_ParamArray envp;
    
    int count = 0;

    while (FCGX_Accept(&in, &out, &err, &envp) >=0) {
        char * content_length = FCGX_GetParam("CONTENT_LENGTH", envp);
        int len = 0;

        FCGX_FPrintF(out,
            "Content-type: text/plain\r\n"
            "\r\n"
            "FastCGI echo (fcgiapp version)\r\n\r\n"
            "Request number %d, Process ID: %d\r\n", ++count, getpid());

        if (content_length != NULL) len = strtol(content_length, NULL, 10);

        if (len <= 0) {
            FCGX_FPrintF(out, "No data from standard input.\r\n");
        } else {
            int i, ch;

            FCGX_FPrintF(out, "Standard input:\r\n");
            for (i = 0; i < len; i++) {
                if ((ch = FCGX_GetChar(in)) < 0) {
                    FCGX_FPrintF(out, "Not enough bytes!");
                    break;
                }
                FCGX_PutChar(ch, out);
            }
            FCGX_FPrintF(out, "\r\n\r\n");
        }

        PrintEnv(out, "Request Environment", envp);
        PrintEnv(out, "Initial Environment", environ);
    }

    return 0;

}
