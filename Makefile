# Makefile to compile C extensions

# Expect $gtm_dist to be defined!

export LD_LIBRARY_PATH=$(gtm_dist)

GTMFLAGS=-I$(gtm_dist) -Ilib -L$(gtm_dist) -lgtmshr -L/home/swoods/lib -I/home/swoods/include

all: dbserver gtm_fastcgi

dbserver:
	gcc src/dbserver.c -o bin/_dbserver $(GTMFLAGS) -lzmq -Wall

gtm_fastcgi:
	gcc src/gtm_fastcgi.c -o bin/gtm_fastcgi $(GTMFLAGS) -lfcgi -Wall

# DO NOT DELETE THIS LINE
