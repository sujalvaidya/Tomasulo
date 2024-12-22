module tomasulo_coverage
(
    input wire clk,
    input wire reset,
    input wire [INSTR_WIDTH-1:0] instruction,
    input wire load_instruction,
    input wire loading_complete,
    input wire [NUM_INSTRUCTIONS-1:0] issue,
    input wire [NUM_INSTRUCTIONS-1:0] ex_start,
    input wire [NUM_INSTRUCTIONS-1:0] ex_comp,
    input wire [NUM_INSTRUCTIONS-1:0] write,
    input wire [NUM_INSTRUCTIONS-1:0] commit
);

    reg [2:0] opcode [0:NUM_INSTRUCTIONS-1];
    reg [2:0] dst_reg [0:NUM_INSTRUCTIONS-1];
    reg [2:0] src_reg1 [0:NUM_INSTRUCTIONS-1];
    reg [2:0] src_reg2 [0:NUM_INSTRUCTIONS-1];
    reg [INSTRUCTION_WIDTH-1:0] instr_count;
    
    reg [CYCLE_WIDTH-1:0] current_cycle;
    reg [CYCLE_WIDTH-1:0] issue_cycle [0:NUM_INSTRUCTIONS-1];
    reg [CYCLE_WIDTH-1:0] exec_start_cycle [0:NUM_INSTRUCTIONS-1];
    reg [CYCLE_WIDTH-1:0] exec_comp_cycle [0:NUM_INSTRUCTIONS-1];
    reg [CYCLE_WIDTH-1:0] write_cycle [0:NUM_INSTRUCTIONS-1];
    reg [CYCLE_WIDTH-1:0] commit_cycle [0:NUM_INSTRUCTIONS-1];
    
    reg [1:0] load_executing;
    reg [1:0] add_executing;
    reg [1:0] mul_executing;
  
    // Variables to store the timing values for coverpoint sampling
    reg [CYCLE_WIDTH-1:0] issue_to_exec_time;
    reg [CYCLE_WIDTH-1:0] write_to_commit_time;
    
    // Flags to ensure we only do coverage sampling at appropriate times
    reg timing_analysis_done;
    reg ordering_coverage_done;
    reg execution_coverage_done;
    
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

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_cycle <= 0;
            for (int i = 0; i < NUM_INSTRUCTIONS; i = i + 1) begin
                issue_cycle[i] = 0;
                exec_start_cycle[i] = 0;
                exec_comp_cycle[i] = 0;
                write_cycle[i] = 0;
                commit_cycle[i] = 0;
            end
        end
        else begin
            current_cycle <= current_cycle + 1;
        end
    end

    always @(posedge clk) begin
        if (loading_complete) begin
            for (int i = 0; i < NUM_INSTRUCTIONS; i++) begin
                if (issue[i] && issue_cycle[i] == 0) 
                    issue_cycle[i] = current_cycle;
                if (ex_start[i] && exec_start_cycle[i] == 0) 
                    exec_start_cycle[i] = current_cycle;
                if (ex_comp[i] && exec_comp_cycle[i] == 0) 
                    exec_comp_cycle[i] = current_cycle;
                if (write[i] && write_cycle[i] == 0) 
                    write_cycle[i] = current_cycle;
                if (commit[i] && commit_cycle[i] == 0) 
                    commit_cycle[i] = current_cycle;
            end
            analyze_pipeline_timing();
        end
    end
 
    always @(posedge clk) begin
        if (loading_complete) begin
            load_executing = 0;
            add_executing = 0;
            mul_executing = 0;
            
            for (int i = 0; i < NUM_INSTRUCTIONS; i++) begin
                if (ex_start[i] && !ex_comp[i]) begin
                    case (opcode[i])
                        LOAD: load_executing++;
                        ADD, SUB: add_executing++;
                        MUL, DIV: mul_executing++;
                    endcase
                end
            end
        end
    end

    covergroup cg_instruction_loading @(posedge clk iff !loading_complete);
        option.per_instance = 1;
        option.name = "Instruction Loading Coverage";
        
        cp_opcode: coverpoint instruction[11:9] {
            bins load = {LOAD};
            bins add = {ADD};
            bins sub = {SUB};
            bins mul = {MUL};
            bins div = {DIV};
        }
        
        cp_dst_reg: coverpoint instruction[8:6] {
            bins regs[] = {[0:NUM_REGISTERS-1]};
        }
        
        cp_src1_reg: coverpoint instruction[5:3] {
            bins regs[] = {[0:NUM_REGISTERS-1]};
        }
        
        cp_src2_reg: coverpoint instruction[2:0] {
            bins regs[] = {[0:NUM_REGISTERS-1]};
        }
        
        cross_reg_usage: cross cp_dst_reg, cp_src1_reg, cp_src2_reg;
    endgroup
  
    covergroup cg_execution_units @(posedge clk iff (loading_complete && !execution_coverage_done));
        option.per_instance = 1;
        option.name = "Execution Units Usage Coverage";
        
        cp_load_executing: coverpoint load_executing {
            bins idle = {0};
            bins busy = {1};
            illegal_bins invalid = {[2:$]};
        }
        
        cp_add_executing: coverpoint add_executing {
            bins idle = {0};
            bins busy = {1};
            illegal_bins invalid = {[2:$]};
        }
        
        cp_mul_executing: coverpoint mul_executing {
            bins idle = {0};
            bins busy = {1};
            illegal_bins invalid = {[2:$]};
        }
        
        cross_unit_usage: cross cp_load_executing, cp_add_executing, cp_mul_executing;
    endgroup

    covergroup cg_instruction_ordering;
        option.per_instance = 1;
        option.name = "Instruction Ordering Coverage";

        cp_issue_order: coverpoint check_issue_order() {
            bins in_order = {1};
            bins out_of_order = {0};
        }
        
        cp_ex_start_order: coverpoint check_ex_start_order() {
            bins in_order = {1};
            bins out_of_order = {0};
        }
        
        cp_ex_comp_order: coverpoint check_ex_comp_order() {
            bins in_order = {1};
            bins out_of_order = {0};
        }
        
        cp_write_order: coverpoint check_write_order() {
            bins in_order = {1};
            bins out_of_order = {0};
        }
        
        cp_commit_order: coverpoint check_commit_order() {
            bins in_order = {1};
            bins out_of_order = {0};
        }
    endgroup
  
    covergroup cg_pipeline_timing;
        option.per_instance = 1;
        option.name = "Pipeline Stage Timing Coverage";

        cp_issue_to_exec: coverpoint issue_to_exec_time {
            bins no_wait = {0};
            bins short_wait = {[1:5]};
            bins medium_wait = {[6:12]};
            bins long_wait = {[13:$]};
        }

        cp_write_to_commit: coverpoint write_to_commit_time {
            bins no_wait = {0};
            bins short_wait = {[1:5]};
            bins medium_wait = {[6:25]};
            bins long_wait = {[26:$]};
        }

        cross_wait_times: cross cp_issue_to_exec, cp_write_to_commit;
    endgroup

  	function bit check_issue_order();
        for (int i = 1; i < NUM_INSTRUCTIONS; i++) begin
            // If current instruction was issued before previous instruction
            if (issue_cycle[i] < issue_cycle[i-1] && issue_cycle[i] != 0) return 0;
        end
        return 1;
    endfunction
  
    function bit check_ex_start_order();
        for (int i = 1; i < NUM_INSTRUCTIONS; i++) begin
            // If current instruction started execution before previous instruction
            if (exec_start_cycle[i] < exec_start_cycle[i-1] && exec_start_cycle[i] != 0) return 0;
        end
        return 1;
    endfunction
    
    function bit check_ex_comp_order();
        for (int i = 1; i < NUM_INSTRUCTIONS; i++) begin
            // If current instruction completed execution before previous instruction
            if (exec_comp_cycle[i] < exec_comp_cycle[i-1] && exec_comp_cycle[i] != 0) return 0;
        end
        return 1;
    endfunction
  
    function bit check_write_order();
        for (int i = 1; i < NUM_INSTRUCTIONS; i++) begin
            // If current instruction wrote back before previous instruction
            if (write_cycle[i] < write_cycle[i-1] && write_cycle[i] != 0) return 0;
        end
        return 1;
    endfunction

    function bit check_commit_order();
        for (int i = 1; i < NUM_INSTRUCTIONS; i++) begin
            // If current instruction committed before previous instruction
            if (commit_cycle[i] < commit_cycle[i-1] && commit_cycle[i] != 0) return 0;
        end
        return 1;
    endfunction
  
    function bit all_instructions_committed();
        for (int i = 0; i < NUM_INSTRUCTIONS; i++) begin
            if (!commit[i]) return 0;
        end
        return 1;
    endfunction
  
    task analyze_pipeline_timing();
        if (!timing_analysis_done && all_instructions_committed()) begin
            timing_analysis_done = 1;
            
            // Sample pipeline timing coverage
            for (int i = 0; i < NUM_INSTRUCTIONS; i++) begin
                issue_to_exec_time = exec_start_cycle[i] - issue_cycle[i] - 1;
                write_to_commit_time = commit_cycle[i] - write_cycle[i] - 1;
                cg_timing.sample();
            end

            // Sample instruction ordering coverage once
            if (!ordering_coverage_done) begin
                ordering_coverage_done = 1;
                cg_order.sample();
            end

            // Mark execution coverage as done
            execution_coverage_done = 1;
        end
    endtask
  
    cg_instruction_loading cg_instr_load;
    cg_execution_units cg_exec;
    cg_instruction_ordering cg_order;
  	cg_pipeline_timing cg_timing;

    initial begin
        timing_analysis_done = 0;
        ordering_coverage_done = 0;
        execution_coverage_done = 0;
        cg_instr_load = new();
        cg_exec = new();
        cg_order = new();
        cg_timing = new();
    end

endmodule