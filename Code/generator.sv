
class generator;
    transaction trans;
    mailbox #(transaction) gen2drv;
    int num_transactions;
    event gen_done;
  
  	transaction hardcoded_instructions[$];
    
  	function new(mailbox #(transaction) g2d);
        this.gen2drv = g2d;
        this.trans = new();
    	if (USE_HARDCODED) begin
            trans = new();
            trans.opcode = MUL; 
            trans.dst = 3'd3; 
            trans.src1 = 3'd2; 
            trans.src2 = 3'd1; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = DIV; 
            trans.dst = 3'd5; 
            trans.src1 = 3'd3; 
            trans.src2 = 3'd7; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = MUL; 
            trans.dst = 3'd6; 
            trans.src1 = 3'd4; 
            trans.src2 = 3'd2; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = ADD; 
            trans.dst = 3'd1; 
            trans.src1 = 3'd2; 
            trans.src2 = 3'd3; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = SUB; 
            trans.dst = 3'd5; 
            trans.src1 = 3'd6; 
            trans.src2 = 3'd7; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = ADD; 
            trans.dst = 3'd3; 
            trans.src1 = 3'd4; 
            trans.src2 = 3'd5; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = LOAD; 
            trans.dst = 3'd3; 
            trans.src1 = 3'd3; 
            trans.src2 = 3'd3; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = LOAD; 
            trans.dst = 3'd4; 
            trans.src1 = 3'd4; 
            trans.src2 = 3'd4; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = LOAD; 
            trans.dst = 3'd5; 
            trans.src1 = 3'd5; 
            trans.src2 = 3'd5; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = ADD; 
            trans.dst = 3'd1; 
            trans.src1 = 3'd3; 
            trans.src2 = 3'd5; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = MUL; 
            trans.dst = 3'd7; 
            trans.src1 = 3'd1; 
            trans.src2 = 3'd3; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = SUB; 
            trans.dst = 3'd5; 
            trans.src1 = 3'd4; 
            trans.src2 = 3'd7; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = DIV; 
            trans.dst = 3'd3; 
            trans.src1 = 3'd7; 
            trans.src2 = 3'd5; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = ADD; 
            trans.dst = 3'd7; 
            trans.src1 = 3'd5; 
            trans.src2 = 3'd3; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = MUL; 
            trans.dst = 3'd5; 
            trans.src1 = 3'd3; 
            trans.src2 = 3'd7; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = DIV; 
            trans.dst = 3'd4; 
            trans.src1 = 3'd3; 
            trans.src2 = 3'd2; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = ADD; 
            trans.dst = 3'd3; 
            trans.src1 = 3'd5; 
            trans.src2 = 3'd7; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = SUB; 
            trans.dst = 3'd4; 
            trans.src1 = 3'd6; 
            trans.src2 = 3'd2; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = MUL; 
            trans.dst = 3'd3; 
            trans.src1 = 3'd2; 
            trans.src2 = 3'd4; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = DIV; 
            trans.dst = 3'd1; 
            trans.src1 = 3'd3; 
            trans.src2 = 3'd4; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = ADD; 
            trans.dst = 3'd5; 
            trans.src1 = 3'd3; 
            trans.src2 = 3'd1; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = MUL; 
            trans.dst = 3'd7; 
            trans.src1 = 3'd1; 
            trans.src2 = 3'd2; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = SUB; 
            trans.dst = 3'd6; 
            trans.src1 = 3'd5; 
            trans.src2 = 3'd3; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = ADD; 
            trans.dst = 3'd3; 
            trans.src1 = 3'd4; 
            trans.src2 = 3'd5; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = DIV; 
            trans.dst = 3'd7; 
            trans.src1 = 3'd4; 
            trans.src2 = 3'd3; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = LOAD; 
            trans.dst = 3'd4; 
            trans.src1 = 3'd4; 
            trans.src2 = 3'd4; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = LOAD; 
            trans.dst = 3'd3; 
            trans.src1 = 3'd3; 
            trans.src2 = 3'd3; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = DIV; 
            trans.dst = 3'd2; 
            trans.src1 = 3'd5; 
            trans.src2 = 3'd3; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = MUL; 
            trans.dst = 3'd6; 
            trans.src1 = 3'd5; 
            trans.src2 = 3'd3; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = SUB; 
            trans.dst = 3'd7; 
            trans.src1 = 3'd5; 
            trans.src2 = 3'd6; 
            hardcoded_instructions.push_back(trans);

            trans = new();
            trans.opcode = LOAD; 
            trans.dst = 3'd0; 
            trans.src1 = 3'd0; 
            trans.src2 = 3'd0; 
            hardcoded_instructions.push_back(trans);

        end
    endfunction
    
    task run();
        if (USE_HARDCODED) begin
          	foreach (hardcoded_instructions[i]) begin
              	gen2drv.put(hardcoded_instructions[i]);
            end
            $display("Sent all instructions");
            -> gen_done;
        end else begin
          	repeat(NUM_INSTRUCTIONS) begin
                trans = new();
                assert(trans.randomize()) else $error("Randomization failed");
                $display("Generated transaction: %p", trans);
                gen2drv.put(trans);
            end
            -> gen_done;
        end
    endtask
endclass