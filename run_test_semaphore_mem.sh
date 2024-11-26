#!/bin/bash

docker run -v $PWD:/formal -w /formal --rm -it -u $(id -u):$(id -g) hdlc/formal:all bash -c "sby --yosys 'yosys -m ghdl' -f formal_semaphore_mem.sby $@"
