`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05.10.2024 09:54:10
// Design Name: 
// Module Name: tomasulo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Tomasulo Algorithm Implementation
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tomasulo #(
    parameter NUM_INSTRUCTIONS = 31,
    parameter NUM_REGISTERS = 8,
    parameter INSTR_WIDTH = 12,  // 3(opcode) + 3(dst) + 3(src1) + 3(src2)
    parameter NUM_CYCLES = 500,
    parameter CYCLE_WIDTH = $clog2(NUM_CYCLES),
    parameter INSTRUCTION_WIDTH = $clog2(NUM_INSTRUCTIONS)
)(
    input wire clk,
    input wire reset,
    input wire [INSTR_WIDTH-1:0] instruction,
    input wire load_instruction,
    input wire loading_complete,
    output reg [NUM_INSTRUCTIONS-1:0] issue,
    output reg [NUM_INSTRUCTIONS-1:0] ex_start,
    output reg [NUM_INSTRUCTIONS-1:0] ex_comp,
    output reg [NUM_INSTRUCTIONS-1:0] write,
    output reg [NUM_INSTRUCTIONS-1:0] commit
);

    localparam LOAD  = 3'b001, LD_LATENCY = 2;
    localparam ADD   = 3'b010, ADD_LATENCY = 2;
    localparam SUB   = 3'b011, SUB_LATENCY = 2;
    localparam MUL   = 3'b100, MUL_LATENCY = 6;
    localparam DIV   = 3'b101, DIV_LATENCY = 25;
    
    reg [2:0] opcode [0:NUM_INSTRUCTIONS-1];
    reg [2:0] dst_reg [0:NUM_INSTRUCTIONS-1];
    reg [2:0] src_reg1 [0:NUM_INSTRUCTIONS-1];
    reg [2:0] src_reg2 [0:NUM_INSTRUCTIONS-1];
    reg [INSTRUCTION_WIDTH - 1:0] instr_count;
    
    reg [NUM_REGISTERS-1:0] reg_busy;
    reg [INSTRUCTION_WIDTH - 1:0] reg_producer [0:NUM_REGISTERS-1];
    reg [CYCLE_WIDTH - 1:0] reg_write_cycle [0:NUM_REGISTERS-1];
    
    reg [INSTRUCTION_WIDTH - 1:0] src1_dep [0:NUM_INSTRUCTIONS-1];
    reg [INSTRUCTION_WIDTH - 1:0] src2_dep [0:NUM_INSTRUCTIONS-1];
    reg src1_has_dep [0:NUM_INSTRUCTIONS-1];
    reg src2_has_dep [0:NUM_INSTRUCTIONS-1];
    
    reg [1:0] load_rs_valid;
    reg [INSTRUCTION_WIDTH - 1:0] load_rs_instr [0:1];
    
    reg [1:0] add_rs_valid;
    reg [INSTRUCTION_WIDTH - 1:0] add_rs_instr [0:1];
    
    reg [1:0] mul_rs_valid;
    reg [INSTRUCTION_WIDTH - 1:0] mul_rs_instr [0:1];
    
    reg mem_unit_busy;
    reg [INSTRUCTION_WIDTH - 1:0] mem_unit_instr;
    reg [CYCLE_WIDTH - 1:0] mem_unit_finish_cycle;
    
    reg add_unit_busy;
    reg [INSTRUCTION_WIDTH - 1:0] add_unit_instr;
    reg [CYCLE_WIDTH - 1:0] add_unit_finish_cycle;
    
    reg mul_unit_busy;
    reg [INSTRUCTION_WIDTH - 1:0] mul_unit_instr;
    reg [CYCLE_WIDTH - 1:0] mul_unit_finish_cycle;
    
    reg [INSTRUCTION_WIDTH - 1:0] issue_ptr;
    reg [INSTRUCTION_WIDTH - 1:0] commit_ptr;
    reg [CYCLE_WIDTH - 1:0] current_cycle;
    
    reg [INSTRUCTION_WIDTH - 1:0] write_buffer [0:2];
    
    wire can_issue = (issue_ptr < NUM_INSTRUCTIONS) && !issue[issue_ptr];
    wire load_rs_full = load_rs_valid[0] && load_rs_valid[1];
    wire add_rs_full = add_rs_valid[0] && add_rs_valid[1];
    wire mul_rs_full = mul_rs_valid[0] && mul_rs_valid[1];
    
    // Instruction Loading Logic
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
        else begin
        end
    end
    
    // Main tomasulo implementation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            issue <= 0;
            ex_start <= 0;
            ex_comp <= 0;
            write <= 0;
            commit <= 0;
            
            load_rs_valid <= 0;
            add_rs_valid <= 0;
            mul_rs_valid <= 0;
            
            mem_unit_busy <= 0;
            add_unit_busy <= 0;
            mul_unit_busy <= 0;
            
            issue_ptr <= 0;
            commit_ptr <= 0;
            current_cycle <= 0;
            
            reg_busy <= 0;
            
        end else if (loading_complete) begin
            current_cycle <= current_cycle + 1;
            
            // Issue Stage
            if (can_issue) begin
                case (opcode[issue_ptr])
                    LOAD: begin
                        if (!load_rs_full) begin
                            issue[issue_ptr] <= 1;
                            if (!load_rs_valid[0]) begin
                                load_rs_valid[0] <= 1;
                                load_rs_instr[0] <= issue_ptr;
                            end else begin
                                load_rs_valid[1] <= 1;
                                load_rs_instr[1] <= issue_ptr;
                            end
                            
                            reg_busy[dst_reg[issue_ptr]] <= 1;
                            reg_producer[dst_reg[issue_ptr]] <= issue_ptr;
                            
                            issue_ptr <= issue_ptr + 1;
                        end
                        else begin
                        end
                    end
                    
                    ADD, SUB: begin
                        if (!add_rs_full) begin
                            src1_has_dep[issue_ptr] <= reg_busy[src_reg1[issue_ptr]];
                            src2_has_dep[issue_ptr] <= reg_busy[src_reg2[issue_ptr]];
                            if (reg_busy[src_reg1[issue_ptr]]) 
                                src1_dep[issue_ptr] <= reg_producer[src_reg1[issue_ptr]];
                            else begin
                            end
                             
                            if (reg_busy[src_reg2[issue_ptr]]) 
                                src2_dep[issue_ptr] <= reg_producer[src_reg2[issue_ptr]];
                            else begin
                            end
                            
                            issue[issue_ptr] <= 1;
                            if (!add_rs_valid[0]) begin
                                add_rs_valid[0] <= 1;
                                add_rs_instr[0] <= issue_ptr;
                            end else begin
                                add_rs_valid[1] <= 1;
                                add_rs_instr[1] <= issue_ptr;
                            end
                            
                            reg_busy[dst_reg[issue_ptr]] <= 1;
                            reg_producer[dst_reg[issue_ptr]] <= issue_ptr;
                            
                            issue_ptr <= issue_ptr + 1;
                        end
                        else begin
                        end
                    end
                    
                    MUL, DIV: begin
                        if (!mul_rs_full) begin
                            src1_has_dep[issue_ptr] <= reg_busy[src_reg1[issue_ptr]];
                            src2_has_dep[issue_ptr] <= reg_busy[src_reg2[issue_ptr]];
                            if (reg_busy[src_reg1[issue_ptr]]) 
                                src1_dep[issue_ptr] <= reg_producer[src_reg1[issue_ptr]];
                            else begin
                            end
                            if (reg_busy[src_reg2[issue_ptr]]) 
                                src2_dep[issue_ptr] <= reg_producer[src_reg2[issue_ptr]];
                            else begin
                            end
                            
                            issue[issue_ptr] <= 1;
                            if (!mul_rs_valid[0]) begin
                                mul_rs_valid[0] <= 1;
                                mul_rs_instr[0] <= issue_ptr;
                            end else begin
                                mul_rs_valid[1] <= 1;
                                mul_rs_instr[1] <= issue_ptr;
                            end
                            
                            reg_busy[dst_reg[issue_ptr]] <= 1;
                            reg_producer[dst_reg[issue_ptr]] <= issue_ptr;
                            
                            issue_ptr <= issue_ptr + 1;
                        end
                        else begin
                        end
                    end
                    default: begin
                    end
                endcase
            end
            else begin
            end
            
            // Execute Start Stage
            if (load_rs_valid[0] && !mem_unit_busy) begin
                ex_start[load_rs_instr[0]] <= 1;
                mem_unit_busy <= 1;
                mem_unit_instr <= load_rs_instr[0];
                mem_unit_finish_cycle <= current_cycle + LD_LATENCY;
                load_rs_valid[0] <= 0;
                
                if (load_rs_valid[1]) begin
                    load_rs_valid[0] <= 1;
                    load_rs_instr[0] <= load_rs_instr[1];
                    load_rs_valid[1] <= 0;
                end
                
                else begin
                end
            end
            else if (load_rs_valid[1] && !mem_unit_busy) begin
                ex_start[load_rs_instr[1]] <= 1;
                mem_unit_busy <= 1;
                mem_unit_instr <= load_rs_instr[1];
                mem_unit_finish_cycle <= current_cycle + LD_LATENCY;
                load_rs_valid[1] <= 0;
            end
            
            else begin
            end
            
            if (add_rs_valid[0] && !add_unit_busy) begin
                if ((!src1_has_dep[add_rs_instr[0]] || write[src1_dep[add_rs_instr[0]]]) &&
                    (!src2_has_dep[add_rs_instr[0]] || write[src2_dep[add_rs_instr[0]]])) begin
                    ex_start[add_rs_instr[0]] <= 1;
                    add_unit_busy <= 1;
                    add_unit_instr <= add_rs_instr[0];
                    add_unit_finish_cycle <= current_cycle + ADD_LATENCY;
                    add_rs_valid[0] <= 0;
                      
                    if (add_rs_valid[1]) begin
                        add_rs_valid[0] <= 1;
                        add_rs_instr[0] <= add_rs_instr[1];
                        add_rs_valid[1] <= 0;
                    end
                    else begin
                    end
                end
                else begin
                end
            end
            else if (add_rs_valid[1] && !add_unit_busy) begin
                if ((!src1_has_dep[add_rs_instr[1]] || write[src1_dep[add_rs_instr[1]]]) &&
                    (!src2_has_dep[add_rs_instr[1]] || write[src2_dep[add_rs_instr[1]]])) begin
                    ex_start[add_rs_instr[1]] <= 1;
                    add_unit_busy <= 1;
                    add_unit_instr <= add_rs_instr[1];
                    add_unit_finish_cycle <= current_cycle + ADD_LATENCY;
                    add_rs_valid[1] <= 0;
                end
                else begin
                end
            end
            else begin
            end
                
            
            if (mul_rs_valid[0] && !mul_unit_busy) begin
                if ((!src1_has_dep[mul_rs_instr[0]] || write[src1_dep[mul_rs_instr[0]]]) &&
                    (!src2_has_dep[mul_rs_instr[0]] || write[src2_dep[mul_rs_instr[0]]])) begin
                    ex_start[mul_rs_instr[0]] <= 1;
                    mul_unit_busy <= 1;
                    mul_unit_instr <= mul_rs_instr[0];
                    mul_unit_finish_cycle <= current_cycle + 
                        ((opcode[mul_rs_instr[0]] == MUL) ? MUL_LATENCY : DIV_LATENCY);
                    mul_rs_valid[0] <= 0;
                                    
                    if (mul_rs_valid[1]) begin
                        mul_rs_valid[0] <= 1;
                        mul_rs_instr[0] <= mul_rs_instr[1];
                        mul_rs_valid[1] <= 0;
                    end
                    else begin
                    end
                end
                else begin
                end
            end
            else if (mul_rs_valid[1] && !mul_unit_busy) begin
                if ((!src1_has_dep[mul_rs_instr[1]] || write[src1_dep[mul_rs_instr[1]]]) &&
                    (!src2_has_dep[mul_rs_instr[1]] || write[src2_dep[mul_rs_instr[1]]])) begin
                    ex_start[mul_rs_instr[1]] <= 1;
                    mul_unit_busy <= 1;
                    mul_unit_instr <= mul_rs_instr[1];
                    mul_unit_finish_cycle <= current_cycle + 
                        ((opcode[mul_rs_instr[1]] == MUL) ? MUL_LATENCY : DIV_LATENCY);
                    mul_rs_valid[1] <= 0;
                end
                else begin
                end
            end
            else begin
            end
            
            // Execute Complete Stage
            if (mem_unit_busy) begin //  && current_cycle == mem_unit_finish_cycle - 1
                ex_comp[mem_unit_instr] <= 1;
                mem_unit_busy <= 0;
                write_buffer[0] <= mem_unit_instr;
            end
            else begin
            end
            
            if (add_unit_busy) begin //  && current_cycle == add_unit_finish_cycle - 1
                ex_comp[add_unit_instr] <= 1;
                add_unit_busy <= 0;
                write_buffer[1] <= add_unit_instr;
            end
            else begin
            end
            
            if (mul_unit_busy && current_cycle == mul_unit_finish_cycle - 1) begin
                ex_comp[mul_unit_instr] <= 1;
                mul_unit_busy <= 0;
                write_buffer[2] <= mul_unit_instr;
            end
            else begin
            end
            
            // Write Stage
            if (write_buffer[0] !== {INSTRUCTION_WIDTH{1'bx}}) begin
                write[write_buffer[0]] <= 1;
                reg_busy[dst_reg[write_buffer[0]]] <= 0;
                write_buffer[0] <= {INSTRUCTION_WIDTH{1'bx}};
            end
            else begin
            end
            if (write_buffer[1] !== {INSTRUCTION_WIDTH{1'bx}}) begin
                write[write_buffer[1]] <= 1;
                reg_busy[dst_reg[write_buffer[1]]] <= 0;
                write_buffer[1] <= {INSTRUCTION_WIDTH{1'bx}};
            end
            else begin
            end
            if (write_buffer[2] !== {INSTRUCTION_WIDTH{1'bx}}) begin
                write[write_buffer[2]] <= 1;
                reg_busy[dst_reg[write_buffer[2]]] <= 0;
                write_buffer[2] <= {INSTRUCTION_WIDTH{1'bx}};
            end
            else begin
            end
            
            // Commit Stage
            if (write[commit_ptr] && !commit[commit_ptr] && (commit_ptr == 0 || commit[commit_ptr-1])) begin
                commit[commit_ptr] <= 1;
                commit_ptr <= commit_ptr + 1;
            end
            else begin
            end
        end
        
        else begin
        end
    end

endmodule
