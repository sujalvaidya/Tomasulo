
class driver;
    virtual tomasulo_if.TB vif;
    mailbox #(transaction) gen2drv;
    event drv_done;
    
    function new(virtual tomasulo_if.TB vif, mailbox #(transaction) g2d);
        this.vif = vif;
        this.gen2drv = g2d;
    endfunction
    
    task reset();
        vif.reset = 1;
        vif.load_instruction = 0;
        vif.loading_complete = 0;
      	repeat(5) @(posedge vif.clk);
        vif.reset = 0;
    endtask
    
    task run();
        transaction trans;
        instruction_t packed_instr;
        
        reset();
        
        forever begin
            @(posedge vif.clk);
            if (gen2drv.try_get(trans)) begin
              $display("Driving transaction: %p", trans);
              packed_instr = trans.pack();
              vif.instruction = {packed_instr.opcode, packed_instr.dst, 
                                 packed_instr.src1, packed_instr.src2};
              vif.load_instruction = 1;
              @(posedge vif.clk);
              vif.load_instruction = 0;
            end else begin
              $display("Completed loading instructions");
              vif.loading_complete = 1;
              -> drv_done;
              break;
            end
        end
    endtask
endclass