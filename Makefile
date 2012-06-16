# Makefile to compile C extensions

# Expect $gtm_dist to be defined!

export LD_LIBRARY_PATH=$(gtm_dist)

GTMFLAGS=-I$(gtm_dist) -Ilib -L$(gtm_dist) -lgtmshr -I./include

all: dbserver gtm_fastcgi fastcgi.so

dbserver:
	gcc src/dbserver.c -o bin/_dbserver $(GTMFLAGS) -lzmq -Wall

gtm_fastcgi:
	gcc src/gtm_fastcgi.c \
		-o bin/_fastcgi \
		$(GTMFLAGS) \
		-lfcgi \
        -rdynamic \
		-Wall

fastcgi.so:
	gcc -c -fPIC -I$(gtm_dist) -I./include \
		-lfcgi \
		-o bin/fastcgi.o \
		src/gtm_fastcgi_callouts.c
	gcc -o bin/fastcgi.so -shared bin/fastcgi.o
	rm bin/fastcgi.o

# DO NOT DELETE THIS LINE
