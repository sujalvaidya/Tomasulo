module tomasulo_assertions
(
    input logic clk,
    input logic reset,
    input logic [INSTR_WIDTH-1:0] instruction,
    input logic load_instruction,
    input logic loading_complete,
    input logic [NUM_INSTRUCTIONS-1:0] issue,
    input logic [NUM_INSTRUCTIONS-1:0] ex_start,
    input logic [NUM_INSTRUCTIONS-1:0] ex_comp,
    input logic [NUM_INSTRUCTIONS-1:0] write,
    input logic [NUM_INSTRUCTIONS-1:0] commit
);

    reg [2:0] opcode [0:NUM_INSTRUCTIONS-1];
    reg [2:0] dst_reg [0:NUM_INSTRUCTIONS-1];
    reg [2:0] src_reg1 [0:NUM_INSTRUCTIONS-1];
    reg [2:0] src_reg2 [0:NUM_INSTRUCTIONS-1];
    reg [INSTRUCTION_WIDTH - 1:0] instr_count;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            instr_count <= 0;
        end
        else if (!loading_complete && load_instruction) begin
            opcode[instr_count] <= instruction[11:9];
            dst_reg[instr_count] <= instruction[8:6];
            src_reg1[instr_count] <= instruction[5:3];
            src_reg2[instr_count] <= instruction[2:0];
            instr_count <= instr_count + 1;
        end
    end

    property reset_behavior;
        @(posedge clk) reset |-> (!issue && !ex_start && !ex_comp && !write && !commit);
    endproperty
    assert_reset: assert property(reset_behavior) else 
        $error("Reset behavior failed: Outputs not zero during reset");

    property valid_opcode;
        @(posedge clk) load_instruction |-> 
            (instruction[11:9] inside {LOAD, ADD, SUB, MUL, DIV});
    endproperty
    assert_opcode: assert property(valid_opcode) else 
        $error("Invalid opcode detected during instruction loading");

    genvar i;
    generate
        for (i = 1; i < NUM_INSTRUCTIONS; i++) begin : issue_order_check
            property issue_order;
                @(posedge clk) (issue[i] && !reset) |-> issue[i-1];
            endproperty
            assert_issue_order: assert property(issue_order) else 
                $error($sformatf("Out of order issue detected at instruction %0d", i));
        end
    endgenerate

    generate
        for (i = 1; i < NUM_INSTRUCTIONS; i++) begin : commit_order_check
            property commit_order;
                @(posedge clk) (commit[i] && !reset) |-> commit[i-1];
            endproperty
            assert_commit_order: assert property(commit_order) else 
                $error($sformatf("Out of order commit detected at instruction %0d", i));
        end
    endgenerate

    property single_issue_per_cycle;
        @(posedge clk) $onehot0($changed(issue));
    endproperty
    assert_single_issue: assert property(single_issue_per_cycle) else 
        $error("Multiple instructions issued in same cycle");

    property single_commit_per_cycle;
        @(posedge clk) $onehot0($changed(commit));
    endproperty
    assert_single_commit: assert property(single_commit_per_cycle) else 
        $error("Multiple instructions committed in same cycle");

    generate
        for (i = 0; i < NUM_INSTRUCTIONS; i++) begin : latency_checks
            property load_latency;
                @(posedge clk) 
              (ex_start[i] && opcode[i] == LOAD && !ex_comp[i]) |-> 
                ##[1:LD_LATENCY] ex_comp[i];
            endproperty
            
            property add_sub_latency;
                @(posedge clk) 
                (ex_start[i] && (opcode[i] inside {ADD, SUB}) && !ex_comp[i]) |-> 
                ##[1:ADD_LATENCY] ex_comp[i];
            endproperty
            
            property mul_latency;
                @(posedge clk) 
                (ex_start[i] && opcode[i] == MUL && !ex_comp[i]) |-> 
                ##[1:MUL_LATENCY] ex_comp[i];
            endproperty
            
            property div_latency;
                @(posedge clk) 
                (ex_start[i] && opcode[i] == DIV && !ex_comp[i]) |-> 
                ##[1:DIV_LATENCY] ex_comp[i];
            endproperty
            
            assert_load_latency: assert property(load_latency) else 
                $error($sformatf("LOAD latency violation at instruction %0d: Execution exceeded LD_LATENCY cycles", i));
            assert_add_sub_latency: assert property(add_sub_latency) else 
                $error($sformatf("ADD/SUB latency violation at instruction %0d: Execution exceeded ADD_LATENCY cycles", i));
            assert_mul_latency: assert property(mul_latency) else 
                $error($sformatf("MUL latency violation at instruction %0d: Execution exceeded MUL_LATENCY cycles", i));
            assert_div_latency: assert property(div_latency) else 
                $error($sformatf("DIV latency violation at instruction %0d: Execution exceeded DIV_LATENCY cycles", i));
        end
    endgenerate

    generate
        for (i = 0; i < NUM_INSTRUCTIONS; i++) begin : stage_progression
            property issue_to_ex_start;
                @(posedge clk) ex_start[i] |-> ##[0:$] issue[i];
            endproperty
            
            property ex_start_to_ex_comp;
                @(posedge clk) ex_comp[i] |-> ##[0:$] ex_start[i];
            endproperty
            
            property ex_comp_to_write;
                @(posedge clk) write[i] |-> ##[0:$] ex_comp[i];
            endproperty
            
            property write_to_commit;
                @(posedge clk) commit[i] |-> ##[0:$] write[i];
            endproperty
            
            assert_issue_to_ex_start: assert property(issue_to_ex_start) else 
                $error($sformatf("Pipeline violation at instruction %0d: Execute started before issue", i));
            assert_ex_start_to_ex_comp: assert property(ex_start_to_ex_comp) else 
                $error($sformatf("Pipeline violation at instruction %0d: Execute completed before starting", i));
            assert_ex_comp_to_write: assert property(ex_comp_to_write) else 
                $error($sformatf("Pipeline violation at instruction %0d: Write attempted before execute completion", i));
            assert_write_to_commit: assert property(write_to_commit) else 
                $error($sformatf("Pipeline violation at instruction %0d: Commit attempted before write", i));
        end
    endgenerate

    function automatic int count_active_load_instructions;
        int count = 0;
        for (int i = 0; i < NUM_INSTRUCTIONS; i++) begin
            if ((ex_start[i] && !ex_comp[i]) &&
                (opcode[i] == LOAD)) begin
                count++;
            end
        end
        return count;
    endfunction

    function automatic int count_active_add_sub_instructions;
        int count = 0;
        for (int i = 0; i < NUM_INSTRUCTIONS; i++) begin
            if ((ex_start[i] && !ex_comp[i]) &&
                (opcode[i] inside {ADD, SUB})) begin
                count++;
            end
        end
        return count;
    endfunction

    function automatic int count_active_mul_div_instructions;
        int count = 0;
        for (int i = 0; i < NUM_INSTRUCTIONS; i++) begin
            if ((ex_start[i] && !ex_comp[i]) && 
                (opcode[i] inside {MUL, DIV})) begin
                count++;
            end
        end
        return count;
    endfunction

    property single_load_execution;
        @(posedge clk) count_active_load_instructions() <= 1;
    endproperty
    
    property single_add_sub_execution;
        @(posedge clk) count_active_add_sub_instructions() <= 1;
    endproperty
    
    property single_mul_div_execution;
        @(posedge clk) count_active_mul_div_instructions() <= 1;
    endproperty
    
    assert_load_resource: assert property(single_load_execution) else 
        $error("Resource conflict: Multiple LOAD instructions executing simultaneously");
    assert_add_sub_resource: assert property(single_add_sub_execution) else 
        $error("Resource conflict: Multiple ADD/SUB instructions executing simultaneously");
    assert_mul_div_resource: assert property(single_mul_div_execution) else 
        $error("Resource conflict: Multiple MUL/DIV instructions executing simultaneously");

    property valid_registers;
        @(posedge clk) load_instruction |-> 
            (instruction[8:6] < NUM_REGISTERS) && 
            (instruction[5:3] < NUM_REGISTERS) && 
            (instruction[2:0] < NUM_REGISTERS);
    endproperty
    assume_registers: assume property(valid_registers) else
        $warning("Assumption violated: Register indices must be less than NUM_REGISTERS");

    property loading_complete_stable;
        @(posedge clk) loading_complete |=> loading_complete;
    endproperty
    assume_loading: assume property(loading_complete_stable) else
        $warning("Assumption violated: loading_complete signal unexpectedly deasserted");

    property reset_duration;
        @(posedge clk) $rose(reset) |-> reset[*5];
    endproperty
    assume_reset: assume property(reset_duration) else
        $warning("Assumption violated: Reset duration must be at least 5 clock cycles");
      
    property consecutive_load_instructions;
        @(posedge clk) load_instruction |=> !load_instruction;
    endproperty
    assume_load_spacing: assume property(consecutive_load_instructions) else
        $warning("Assumption violated: Instructions must not be loaded in consecutive cycles");

    property no_load_after_complete;
        @(posedge clk) loading_complete |=> !load_instruction;
    endproperty
    assume_no_late_load: assume property(no_load_after_complete) else
        $warning("Assumption violated: No instructions should be loaded after loading_complete is asserted");

    property max_instruction_count;
        @(posedge clk) instr_count <= NUM_INSTRUCTIONS;
    endproperty
    assume_max_instructions: assume property(max_instruction_count) else
        $warning("Assumption violated: Instruction count exceeded maximum allowed instructions");

    property valid_loading_sequence;
        @(posedge clk) load_instruction |-> !loading_complete;
    endproperty
    assume_loading_sequence: assume property(valid_loading_sequence) else
        $warning("Assumption violated: Cannot load instructions after loading is complete");

    property valid_arithmetic_sources;
        @(posedge clk) load_instruction && (instruction[11:9] inside {ADD, SUB, MUL, DIV}) |->
            instruction[5:3] != instruction[2:0]; // src1 != src2
    endproperty
    assume_arithmetic_sources: assume property(valid_arithmetic_sources) else
        $warning("Assumption violated: Source registers must be different for arithmetic operations");

endmodule