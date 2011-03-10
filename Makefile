shell-env.bin: shell-env.c
	cc -o shell-env.bin shell-env.c -DPREFIX=\"$(PREFIX)\" -I$(PREFIX)/include -L$(PREFIX)/lib  -llua -lm -ldl -lcrypt -lrt

#cc -o runlua runlua.c -I/home/sk/work/my/make_build/include -L/home/sk/work/my/make_build/lib  -llua -lm -ldl -lcrypt -lrt

