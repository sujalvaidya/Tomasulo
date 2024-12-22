
class monitor;
    virtual tomasulo_if.TB vif;
  	mailbox #(logic [(5 * NUM_INSTRUCTIONS) - 1:0]) mon2scb;
    
    function new(virtual tomasulo_if.TB vif, mailbox #(logic [(5 * NUM_INSTRUCTIONS) - 1:0]) m2s);
        this.vif = vif;
        this.mon2scb = m2s;
    endfunction
    
    task run();
        forever begin
            @(posedge vif.clk);
            if (vif.loading_complete) begin
                mon2scb.put({vif.issue, vif.ex_start, vif.ex_comp, 
                            vif.write, vif.commit});
            end
        end
    endtask
endclass