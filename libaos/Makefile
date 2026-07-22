
OBJECTS=aos.o block.o crypto.o md5.o flash.o

all: libaos.a

.c.o:
	gcc -c -I/usr/include/openssl1.1 -L/usr/lib -lssl1.1 $*.c

libaos.a: $(OBJECTS)
	ar crs libaos.a $(OBJECTS)

clean:
	rm -f libaos.a *.o
