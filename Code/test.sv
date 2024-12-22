`include "environment.sv"

program test(tomasulo_if.TB tif);
    environment env;
    
    initial begin
      env = new(tif);
        env.run();
        
        wait(env.drv.drv_done.triggered);
        repeat(NUM_CYCLES) @(posedge tif.clk);
      	tif.reset <= 1;
      	repeat(5) @(posedge tif.clk);
      	tif.reset <= 0;
        $finish;
    end
endprogram