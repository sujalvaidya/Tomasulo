`include "instruction_pkg.sv"
`include "params_pkg.sv"
`include "tomasulo_if.sv"
`include "test.sv"
`include "tomasulo_assertions.sv"
`include "tomasulo_coverage.sv"

module tb_top;
  	import params_pkg::*;
  	import instruction_pkg::*;
    
    bit clk;
    always #5 clk = ~clk;
    
    tomasulo_if tif();
    assign tif.clk = clk;
    
    tomasulo #(
        .NUM_INSTRUCTIONS(NUM_INSTRUCTIONS),
        .NUM_REGISTERS(NUM_REGISTERS),
        .INSTR_WIDTH(INSTR_WIDTH),      
        .NUM_CYCLES(NUM_CYCLES),
        .CYCLE_WIDTH(CYCLE_WIDTH),
        .INSTRUCTION_WIDTH(INSTRUCTION_WIDTH)
    ) dut (
        .clk(tif.clk),
        .reset(tif.reset),
        .instruction(tif.instruction),
        .load_instruction(tif.load_instruction),
        .loading_complete(tif.loading_complete),
        .issue(tif.issue),
        .ex_start(tif.ex_start),
        .ex_comp(tif.ex_comp),
        .write(tif.write),
        .commit(tif.commit)
    );
  
    tomasulo_assertions assertions (
        .clk(tif.clk),
        .reset(tif.reset),
        .instruction(tif.instruction),
        .load_instruction(tif.load_instruction),
        .loading_complete(tif.loading_complete),
        .issue(tif.issue),
        .ex_start(tif.ex_start),
        .ex_comp(tif.ex_comp),
        .write(tif.write),
        .commit(tif.commit)
    );

    tomasulo_coverage coverage (
        .clk(tif.clk),
        .reset(tif.reset),
        .instruction(tif.instruction),
        .load_instruction(tif.load_instruction),
        .loading_complete(tif.loading_complete),
        .issue(tif.issue),
        .ex_start(tif.ex_start),
        .ex_comp(tif.ex_comp),
        .write(tif.write),
        .commit(tif.commit)
    );
    
    test t1(tif);
    
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0);
    end
endmodule