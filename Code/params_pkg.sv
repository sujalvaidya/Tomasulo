package params_pkg;
    parameter NUM_INSTRUCTIONS = 31;
    parameter NUM_REGISTERS = 8;
    parameter INSTR_WIDTH = 12;
    parameter NUM_CYCLES = 500;
    parameter CYCLE_WIDTH = $clog2(NUM_CYCLES);
    parameter INSTRUCTION_WIDTH = $clog2(NUM_INSTRUCTIONS);
	parameter USE_HARDCODED = 1;
endpackage
