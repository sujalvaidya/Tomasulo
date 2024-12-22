package instruction_pkg;
	typedef enum logic[2:0] {
        LOAD = 3'b001,
        ADD  = 3'b010,
        SUB  = 3'b011,
        MUL  = 3'b100,
        DIV  = 3'b101
    } opcode_t;
    
    typedef struct packed {
        opcode_t opcode;
        logic [2:0] dst;
        logic [2:0] src1;
        logic [2:0] src2;
    } instruction_t;

    localparam LD_LATENCY  = 2;
    localparam ADD_LATENCY = 2;
    localparam SUB_LATENCY = 2;
    localparam MUL_LATENCY = 6;
    localparam DIV_LATENCY = 25;
endpackage