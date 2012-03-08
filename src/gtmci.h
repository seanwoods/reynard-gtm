#include "gtmxc_types.h"

#define GTM_BUF_LEN 1024
#define GTM_OUT_LEN_KB 20

typedef struct {

    char out[sizeof (char *) * 1024 * GTM_OUT_LEN_KB];
    gtm_status_t status;
    char msgbuf[GTM_BUF_LEN];

    // Flag for multi-part output.  Exact semantics determined by the GT.M
    // routine that sets `out`.  For example, the routine could set `out` to:
    //     $C(2,6,3,7)_nameOfArray
    int multipart;

} context_t;

int gtm_initialize(context_t *context);
int gtm_teardown(context_t *context);
