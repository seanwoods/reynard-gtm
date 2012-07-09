# Makefile to compile C extensions

# Expect $gtm_dist to be defined!

export LD_LIBRARY_PATH=$(gtm_dist)

GTMFLAGS=-I$(gtm_dist) -Ilib -L$(gtm_dist) -lgtmshr -I./include

all: dbserver gtm_fastcgi fastcgi.so digest.so foreign

dbserver:
	gcc src/dbserver.c -o bin/dbserver $(GTMFLAGS) -lzmq -Wall

gtm_fastcgi:
	gcc src/gtm_fastcgi.c \
		-o bin/fastcgi \
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

digest.so:
	gcc -c -fPIC -I$(gtm_dist) \
		-o bin/digest.o \
		src/digest.c
	gcc -o bin/digest.so -lgcrypt -shared bin/digest.o
	rm bin/digest.o

foreign:
	# Make foreign function call-in and external call tables.
	menv ci_gen
	menv xc_gen

clean:
	rm bin/dbserver bin/fastcgi.so bin/_fastcgi

# DO NOT DELETE THIS LINE
