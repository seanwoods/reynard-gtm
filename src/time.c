#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

/* A little program for testing time functions. */

int main() {
    struct timeval zTime1, zTime2;
    long int elapsed;
    int i;

    for (i = 0; i < 5; i++) {
        gettimeofday(&zTime1);
        sleep(1);
        gettimeofday(&zTime2);

        elapsed = zTime2.tv_usec - zTime1.tv_usec;

        printf("Trial #%d: %d\n", i, elapsed);
    }

    return 0;
}
