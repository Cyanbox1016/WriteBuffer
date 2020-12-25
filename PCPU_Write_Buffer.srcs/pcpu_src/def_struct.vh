`ifndef def_struct_vh
`define def_struct_vh

typedef struct {
    logic RegWrite;
    logic [1:0]MemtoReg;
} WB_Signal;

typedef struct {
    logic MemWrite;
    logic MemRead;
    logic [1:0]PCSrc;
    logic [2:0]Funct3; // extend for LB and lBU
} MEM_Signal;

typedef struct {
    logic ALUSrc;
    logic [3:0]ALUop;
    logic Branch;
    logic B_Type;
} EX_Signal;


`endif