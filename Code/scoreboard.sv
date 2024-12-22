
class scoreboard;
    mailbox #(logic [(5 * NUM_INSTRUCTIONS) - 1:0]) mon2scb;
    int cycle_count;
    
    function new(mailbox #(logic [(5 * NUM_INSTRUCTIONS) - 1:0]) m2s);
        this.mon2scb = m2s;
        this.cycle_count = 0;
    endfunction
    
    task run();
        logic [(5 * NUM_INSTRUCTIONS) - 1:0] status;
        forever begin
            mon2scb.get(status);
            display_status(status);
            cycle_count++;
        end
    endtask
    
    task display_status(logic [(5 * NUM_INSTRUCTIONS) - 1:0] status);
      logic [NUM_INSTRUCTIONS - 1:0] issue, ex_start, ex_comp, write, commit;
        {issue, ex_start, ex_comp, write, commit} = status;
        
        $display("\n=== Cycle %0d ===", cycle_count);
        $display("Issue    : %b", issue);
        $display("Ex Start : %b", ex_start);
        $display("Ex Comp  : %b", ex_comp);
        $display("Write    : %b", write);
        $display("Commit   : %b", commit);
    endtask
endclass