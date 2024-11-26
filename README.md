This repository is a collection of formal verification models using abstracted memory strategy.

formal_scoreboard.vhdl compares that two input streams (a_* and b_*) have same data content (sequence of those clock cycles when valid is high).<br>
Run `bash run_test_scoreboard.sh bmc` to demonstrate a bug.

formal_semaphore_mem.vhdl checks that an array of semaphores don't overflow / underflow.<br>
Run `bash run_test_semaphore_mem.sh bmc` to demonstrate a bug.
