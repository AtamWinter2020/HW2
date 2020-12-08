obj-m += de.o
de-objs += de_main.o de_utils.o de_handler.o

all: de.ko calc

de.ko:
	make -C /lib/modules/$(shell uname -r)/build M=$(shell pwd) modules
clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(shell pwd) clean
	rm -f calc

calc: calc.c
	as hw2_sol.asm -o hw2_sol.o
	gcc -no-pie $^ hw2_sol.o -o $@

$(KBUILD_EXTMOD)/de_handler.o: de_handler.asm
	as -o $@ $^
