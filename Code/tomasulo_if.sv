import params_pkg::*;

interface tomasulo_if;
    logic clk;
    logic reset;
  	logic [11:0] instruction;
    logic load_instruction;
    logic loading_complete;
    logic [NUM_INSTRUCTIONS-1:0] issue;
    logic [NUM_INSTRUCTIONS-1:0] ex_start;
    logic [NUM_INSTRUCTIONS-1:0] ex_comp;
    logic [NUM_INSTRUCTIONS-1:0] write;
    logic [NUM_INSTRUCTIONS-1:0] commit;
    
  modport DUT (
        input clk, reset, instruction, load_instruction, loading_complete,
        output issue, ex_start, ex_comp, write, commit
    );
    
    modport TB (
        output clk, reset, instruction, load_instruction, loading_complete,
        input issue, ex_start, ex_comp, write, commit
    );
endinterface