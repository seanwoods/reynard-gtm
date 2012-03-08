# Makefile to compile C extensions

# Expect $gtm_dist to be defined!

export LD_LIBRARY_PATH=$(gtm_dist)

GTMFLAGS=-I$(gtm_dist) -Ilib -L$(gtm_dist) -lgtmshr -lzmq

all: gtmci

gtmci:
	gcc src/dbserver.c -o bin/_dbserver $(GTMFLAGS) -Wall

# DO NOT DELETE THIS LINE
