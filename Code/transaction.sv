import instruction_pkg::*;

class transaction;
    
    rand opcode_t opcode;
    rand logic [2:0] dst, src1, src2;
    
    constraint valid_registers {
        dst inside {[0:NUM_REGISTERS-1]};
        src1 inside {[0:NUM_REGISTERS-1]};
        src2 inside {[0:NUM_REGISTERS-1]};
    }
    
    function instruction_t pack();
        instruction_t instr;
        instr.opcode = opcode;
        instr.dst = dst;
        instr.src1 = src1;
        instr.src2 = src2;
        return instr;
    endfunction
endclass