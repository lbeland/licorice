CC = gcc
DEFAULTFLAGS = -Wall 
CFLAGS =  -O3 $(DEFAULTFLAGS)
CFLAGSUNOPT = -O0 $(DEFAULTFLAGS)
# TODO test -Os again
CYFLAGS = -O0 -I /usr/include/python3.8 -I /home/linda/Documents/new_benchmark_test/Benchmark_IPC/licorice/venv/lib/python3.8/site-packages/numpy/core/include 
LDFLAGS = -levent -pthread -lsqlite3 -lrt
LDTESTFLAGS = -lsqlite3 -pthread
CYLDFLAGS = -Wl,-Bsymbolic-functions     -g -fwrapv -O2    -lsqlite3 -L/usr/lib/python3.8/config-3.8-x86_64-linux-gnu -L/usr/lib/x86_64-linux-gnu -lpython3.8 -lcrypt -ldl  -lm -lm -lrt # -lpthread -lm -lutil -ldl should be included in py_link_flags

all: timer producer consumer  #drivers

timer: timer.c utilityFunctions.c 
	$(CC) $(CFLAGS) timer.c utilityFunctions.c  -o timer $(LDFLAGS)

drivers:
	python setup_drivers.py build_ext --inplace

producer: producer.pyx utilityFunctions.c
	cython --embed -3 -o producer.c producer.pyx
	$(CC) $(CYFLAGS) -Wno-cpp producer.c  utilityFunctions.c -o producer $(CYLDFLAGS)
consumer: consumer.pyx utilityFunctions.c
	cython --embed -3 -o consumer.c consumer.pyx
	$(CC) $(CYFLAGS) -Wno-cpp consumer.c  utilityFunctions.c -o consumer $(CYLDFLAGS)
clean:
	rm -f timer  producer consumer 