`include "transaction.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"

class environment;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    
    mailbox #(transaction) gen2drv;
    mailbox #(logic [(5 * NUM_INSTRUCTIONS) - 1:0]) mon2scb;
    
    virtual tomasulo_if.TB vif;
    
    function new(virtual tomasulo_if.TB vif);
        this.vif = vif;
        
        gen2drv = new();
        mon2scb = new();
        
        gen = new(gen2drv);
        drv = new(vif, gen2drv);
        mon = new(vif, mon2scb);
        scb = new(mon2scb);
    endfunction
    
    task run();
        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        join_any
    endtask
endclass
