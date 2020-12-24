`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/03 16:53:41
// Design Name: 
// Module Name: PCPU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "def_struct.vh"

module PCPU(
    input clk,
    input rst,
    input [31:0]Inst_In,    // Instruction Memory output
    input [31:0]Data_In,    // Data Memory output
    input [4:0]Debug_Addr,  // register number(address) for debug
    input d_cache_stall, // d_cache miss stall
    input i_cache_stall, // i_cache miss stall
    output [31:0]Addr_Out,  // Data Memory address input
    output [31:0]Data_Out, // Data Memory Data input
    output [31:0]PC_Out,   // Instruction Memory input
    output [31:0]Debug_Data, // register value to display for debug
    output MemWrite, // Data Memory write
    output MemRead // Data Memory Read
    );
    
    // struct Stage_Signal means signals used in the Stage
    // CurStage_DesStage_Signal means signals used in destination DesStage is in current CurStage
    WB_Signal ID_WB_Signal, EX_WB_Signal, MEM_WB_Signal, WB_WB_Signal;
    MEM_Signal ID_MEM_Signal, EX_MEM_Signal, MEM_MEM_Signal;
    EX_Signal ID_EX_Signal, EX_EX_Signal;

    logic [31:0]ALU_Out, IF_PC_Plus_4, ALU_Data_B, ALU_Data_A, PC_In;
    logic overflow;
    logic [4:0]WB_Reg_Write_Addr;
    logic [4:0]MEM_Reg_Write_Addr;
    logic [31:0]WB_Reg_Write_Data;
    logic PCWrite, IF_ID_Write, Inst_Nop, ID_EX_Write, EX_MEM_Write, MEM_WB_Write;
    logic IF_ID_Flush, ID_EX_Flush;
    logic [31:0]MEM_ALU_Out;
    logic [1:0]Reg_Data_Src_1, Reg_Data_Src_2;
    logic [31:0]EX_ALU_Out;
    logic MEM_cache_stall;
    logic cache_stall;
    logic [31:0]WB_Reg_Write_Data_Temp;
    
    // stall for cache miss(for both i_cache and d_cache)
    // stall PC, IF_ID, ID_EX, EX_MEM exclude MEM_WB
    assign cache_stall = d_cache_stall | i_cache_stall;
    
    // IF
    add32 Add_PC_And_4 (
        .a(PC_Out),
        .b(32'd4),
        .c(IF_PC_Plus_4)
    );

    logic [1:0]PCSrc;
    logic PC_Branch;
    logic PC_Jal;
    logic PC_Jalr;
    always_comb begin
        PCSrc = 2'b00;
        if(PC_Branch) begin
            PCSrc = 2'b10;
        end
        else if(PC_Jal) begin
            PCSrc = 2'b10;
        end
        else if(PC_Jalr) begin
            PCSrc = 2'b01;
        end
    end
    
    logic [31:0]ID_PC_Plus_Imm;
    MUX4T1_32 PC_Mux (
        .I0(IF_PC_Plus_4),
        .I1(EX_ALU_Out), // JALR -> ALU_Out
        .I2(ID_PC_Plus_Imm), // PC_Relative_Out
        .I3(0), // preserved
        .s(PCSrc), // Branch ? {B_Type == zero, 1'b0} : PCSrc
        .o(PC_In)
    );

    logic not_first_pc;
    logic [31:0]PC_In_Mux;
    always_ff @(posedge clk or posedge rst) begin
        if(rst) not_first_pc = 1'b0;
        else not_first_pc = 1'b1;
    end
    assign PC_In_Mux = not_first_pc ? PC_In : 32'b0;
    REG32 PC (
        .clk(clk),
        .rst(rst),
        .CE(PCWrite),   // enabled
        .D(PC_In_Mux),
        .Q(PC_Out)
    );
    
    // ID
    logic[31:0] ID_PC, ID_Inst, ID_PC_Plus_4;
    logic [4:0]EX_Reg_Write_Addr;
    logic [4:0]ID_Reg_Rs_1, ID_Reg_Rs_2;
    assign ID_Reg_Rs_1 = ID_Inst[19:15];
    assign ID_Reg_Rs_2 = ID_Inst[24:20];
    logic ID_WB_RegWrite;
    logic [1:0]ID_WB_MemtoReg;
    logic ID_MEM_MemWrite, ID_MEM_MemRead, ID_EX_Branch, ID_EX_B_Type;
    logic [1:0]ID_MEM_PCSrc;
    logic ID_EX_ALUSrc;
    logic [3:0]ID_EX_ALUop;

    IF_ID_Reg IF_ID(
        .clk(clk),
        .rst(rst),
        .IF_ID_Flush(IF_ID_Flush),
        .we(IF_ID_Write),
        .IF_PC(PC_Out),
        .IF_Inst(Inst_In),
        .IF_PC_Plus_4(IF_PC_Plus_4),
        .ID_PC(ID_PC),
        .ID_Inst(ID_Inst),
        .ID_PC_Plus_4(ID_PC_Plus_4)
    );

    // detect read after write(load)
    Hazard_Detect_Unit hazard_detect(
        .ID_Rs_1(ID_Reg_Rs_1),
        .ID_Rs_2(ID_Reg_Rs_2),
        .EX_Rd(EX_Reg_Write_Addr),
        .MEM_Rd(MEM_Reg_Write_Addr),
        .EX_MemRead(EX_MEM_Signal.MemRead),
        .MEM_MemRead(MEM_MEM_Signal.MemRead),
        .EX_RegWrite(EX_WB_Signal.RegWrite),
        .ID_Branch(ID_EX_Branch),
        .ID_MemWrite(ID_MEM_MemWrite),
        .MEM_cache_stall(MEM_cache_stall),
        .PCWrite(PCWrite),
        .IF_ID_Write(IF_ID_Write),
        .Inst_Nop(Inst_Nop), // make the current stage excute nop
        .ID_EX_Write(ID_EX_Write),
        .EX_MEM_Write(EX_MEM_Write),
        .MEM_WB_Write(MEM_WB_Write)
    );

    
    logic [31:0]ID_Reg_Read_Data_1, ID_Reg_Read_Data_2;
    logic RegWrite;
    Regs Registers(
        .clk(~clk), // WB hazard
        .rst(rst),
        .we(RegWrite),
        .R_addr_A(ID_Reg_Rs_1),
        .R_addr_B(ID_Reg_Rs_2),
        .Wt_addr(WB_Reg_Write_Addr),
        .debug_addr(Debug_Addr), // register number
        .Wt_data(WB_Reg_Write_Data),
        .rdata_A(ID_Reg_Read_Data_1),
        .rdata_B(ID_Reg_Read_Data_2),
        .debug_data(Debug_Data) // register value
    );
    
    logic [31:0]ID_Imm;
    Imm_Generator Imm_Gen(
        .Inst(ID_Inst),
        .Imm(ID_Imm)
    );

    add32 Add_PC_And_IMM (
        .a(ID_PC),
        .b(ID_Imm), // Imm( shift left in Imm_Generator )
        .c(ID_PC_Plus_Imm)
    );

    
    Control_RV32I Control ( 
        .Opcode(ID_Inst[6:0]),
        .Funct3(ID_Inst[14:12]),
        .Funct7_5(ID_Inst[30]),
        .PCSrc(ID_MEM_PCSrc),
        .RegWrite(ID_WB_RegWrite),
        .ALUSrc(ID_EX_ALUSrc),
        .ALUop(ID_EX_ALUop),
        .MemtoReg(ID_WB_MemtoReg),
        .MemWrite(ID_MEM_MemWrite),
        .MemRead(ID_MEM_MemRead),
        .Branch(ID_EX_Branch),
        .B_Type(ID_EX_B_Type)
    );


    logic [31:0]ID_Branch_Reg_Data_1, ID_Branch_Reg_Data_2;
    MUX4T1_32 Branch_Data_1_MUX_Forward(
        .I0(ID_Reg_Read_Data_1), // from IF/ID
        .I1(MEM_ALU_Out), // from EX/MEM
        .I2(WB_Reg_Write_Data), // from MEM/WB
        .I3(32'b0), // from WB temp -disabled(use WB stall is more convenient)
        .s(Reg_Data_Src_1),
        .o(ID_Branch_Reg_Data_1)
    );

    MUX4T1_32 Branch_Data_2_MUX_Forward(
        .I0(ID_Reg_Read_Data_2), // from IF/ID
        .I1(MEM_ALU_Out), // from EX/MEM
        .I2(WB_Reg_Write_Data), // from MEM/WB
        .I3(32'b0), // from WB temp -disabled
        .s(Reg_Data_Src_2),
        .o(ID_Branch_Reg_Data_2)
    );
    
    // flush
    always_comb begin // todo: add forwarding -done!/ can be optimized to reduce logic delay
        IF_ID_Flush = 1'b0;
        ID_EX_Flush = 1'b0;
        PC_Branch = 1'b0;
        PC_Jal = 1'b0;
        PC_Jalr = 1'b0;
        if(!cache_stall) begin // wait for mem stall end, then to flush
            if(ID_EX_Branch && !Inst_Nop && (ID_EX_B_Type == (ID_Branch_Reg_Data_1 - ID_Branch_Reg_Data_2 == 0 ? 1'b1 : 1'b0))) begin // alter in 2020/12/17 fix flush and stall hazard
                IF_ID_Flush = 1'b1;
                PC_Branch = 1'b1;
            end
            if(ID_MEM_PCSrc == 2'b10) begin // Jal
                IF_ID_Flush = 1'b1;
                PC_Jal = 1'b1;
            end
            if(EX_MEM_Signal.PCSrc == 2'b01) begin // Jalr -debug
                IF_ID_Flush = 1'b1;
                ID_EX_Flush = 1'b1;
                PC_Jalr = 1'b1;
            end
        end
        
    end

    // 2-to-1 multiplexer
    always_comb begin
        ID_WB_Signal = '{ID_WB_RegWrite, ID_WB_MemtoReg};
        ID_MEM_Signal = '{ID_MEM_MemWrite, ID_MEM_MemRead, ID_MEM_PCSrc, ID_Inst[14:12]};
        ID_EX_Signal = '{ID_EX_ALUSrc, ID_EX_ALUop, ID_EX_Branch, ID_EX_B_Type};
        if(Inst_Nop) begin // can be optimized
            ID_WB_Signal = '{default:0};
            ID_MEM_Signal = '{default:0};
            ID_EX_Signal = '{default:0};
        end
    end
    

    // EX
    logic [4:0]ID_Reg_Write_Addr;
    assign ID_Reg_Write_Addr = ID_Inst[11:7];
    logic [31:0]EX_PC, EX_Reg_Read_Data_1, EX_Reg_Read_Data_2, EX_Imm, EX_PC_Plus_4, EX_PC_Plus_Imm;
    logic [4:0]EX_Reg_Rs_1, EX_Reg_Rs_2;
    

    ID_EX_Reg ID_EX (
        .clk(clk),
        .rst(rst),
        .ID_EX_Flush(ID_EX_Flush),
        .unlock(ID_EX_Write),

        .ID_WB_Signal(ID_WB_Signal),
        .ID_MEM_Signal(ID_MEM_Signal),
        .ID_EX_Signal(ID_EX_Signal),

        .ID_PC(ID_PC),
        .ID_Reg_Read_Data_1(ID_Reg_Read_Data_1),
        .ID_Reg_Read_Data_2(ID_Reg_Read_Data_2),
        .ID_Imm(ID_Imm),
        .ID_PC_Plus_4(ID_PC_Plus_4),
        .ID_PC_Plus_Imm(ID_PC_Plus_Imm),
        .ID_Reg_Write_Addr(ID_Reg_Write_Addr),
        .ID_Reg_Rs_1(ID_Reg_Rs_1),
        .ID_Reg_Rs_2(ID_Reg_Rs_2),

        .EX_WB_Signal(EX_WB_Signal),
        .EX_MEM_Signal(EX_MEM_Signal),
        .EX_EX_Signal(EX_EX_Signal),

        .EX_PC(EX_PC),
        .EX_Reg_Read_Data_1(EX_Reg_Read_Data_1),
        .EX_Reg_Read_Data_2(EX_Reg_Read_Data_2),
        .EX_Imm(EX_Imm),
        .EX_PC_Plus_4(EX_PC_Plus_4),
        .EX_PC_Plus_Imm(EX_PC_Plus_Imm),
        .EX_Reg_Write_Addr(EX_Reg_Write_Addr),
        .EX_Reg_Rs_1(EX_Reg_Rs_1),
        .EX_Reg_Rs_2(EX_Reg_Rs_2)
    );

    
    logic [1:0]Forward_ALUSrc_A, Forward_ALUSrc_B;
    Forward_Unit forwording(
        .EX_Rs_1(EX_Reg_Rs_1),
        .EX_Rs_2(EX_Reg_Rs_2),
        .ID_Rs_1(ID_Reg_Rs_1),
        .ID_Rs_2(ID_Reg_Rs_2),
        .MEM_Rd(MEM_Reg_Write_Addr),
        .MEM_RegWrite(MEM_WB_Signal.RegWrite),
        .WB_Rd(WB_Reg_Write_Addr),
        .WB_RegWrite(WB_WB_Signal.RegWrite),
        .WB_Temp_Valid(Temp_Valid),
        .ALUSrc_A(Forward_ALUSrc_A), // 00 -> ID; 01 -> EX; 10 -> MEM; 11 -> WB(MEM) temp
        .ALUSrc_B(Forward_ALUSrc_B), // 00 -> ID; 01 -> EX; 10 -> MEM; 11 -> WB(MEM) temp
        .Reg_Data_Src_1(Reg_Data_Src_1),
        .Reg_Data_Src_2(Reg_Data_Src_2)
    );
    // assign ALU_Data_A = EX_Reg_Read_Data_1;

    

    MUX4T1_32 ALU_Src_A_MUX_Forward (
        .I0(EX_Reg_Read_Data_1), // from ID/EX
        .I1(MEM_ALU_Out), // from EX/MEM
        .I2(WB_Reg_Write_Data), // from MEM/WB
        .I3(32'b0), // from WB temp reg - disabled
        .s(Forward_ALUSrc_A),
        .o(ALU_Data_A)
    );

    logic [31:0]ALU_Data_B_Forward;
    MUX4T1_32 ALU_Src_B_MUX_Forward (
        .I0(EX_Reg_Read_Data_2), // from ID/EX
        .I1(MEM_ALU_Out), // from EX/MEM
        .I2(WB_Reg_Write_Data), // from MEM/WB
        .I3(32'b0), // from WB temp reg - disa bled
        .s(Forward_ALUSrc_B),
        .o(ALU_Data_B_Forward)
    );

    MUX2T1_32 ALU_Src_B_MUX (
        .I0(ALU_Data_B_Forward),
        .I1(EX_Imm),
        .s(EX_EX_Signal.ALUSrc),
        .o(ALU_Data_B)
    );

    logic EX_Zero;
    ALU ALU_M (
        .A(ALU_Data_A),
        .B(ALU_Data_B),
        .ALU_operation(EX_EX_Signal.ALUop),
        .res(EX_ALU_Out),
        .zero(EX_Zero),
        .overflow(overflow)
    );
    logic [31:0]EX_ALU_Out_Or_Imm; // for LUI forwarding
    assign EX_ALU_Out_Or_Imm = EX_WB_Signal.MemtoReg == 2'b01 ? EX_Imm : EX_ALU_Out; // LUI forwarding

    // MEM
    logic MEM_Zero;
    logic [31:0]MEM_PC_Plus_Imm, MEM_Reg_Read_Data_2, MEM_Imm, MEM_PC_Plus_4;
    

    EX_MEM_Reg EX_MEM(
        .clk(clk),
        .rst(rst),
        .unlock(EX_MEM_Write),

        .EX_WB_Signal(EX_WB_Signal),
        .EX_MEM_Signal(EX_MEM_Signal),
        .EX_Zero(EX_Zero),

        .EX_PC_Plus_Imm(EX_PC_Plus_Imm),
        .EX_ALU_Out(EX_ALU_Out_Or_Imm),
        .EX_Reg_Read_Data_2(EX_Reg_Read_Data_2),
        .EX_Imm(EX_Imm),
        .EX_PC_Plus_4(EX_PC_Plus_4),
        .EX_Reg_Write_Addr(EX_Reg_Write_Addr),

        .MEM_WB_Signal(MEM_WB_Signal),
        .MEM_MEM_Signal(MEM_MEM_Signal),
        .MEM_Zero(MEM_Zero),

        .MEM_PC_Plus_Imm(MEM_PC_Plus_Imm),
        .MEM_ALU_Out(MEM_ALU_Out),
        .MEM_Reg_Read_Data_2(MEM_Reg_Read_Data_2),
        .MEM_Imm(MEM_Imm),
        .MEM_PC_Plus_4(MEM_PC_Plus_4),
        .MEM_Reg_Write_Addr(MEM_Reg_Write_Addr)
    );

    
    // assign PCSrc = MEM_MEM_Signal.Branch ? {MEM_MEM_Signal.B_Type == MEM_Zero, 1'b0} : MEM_MEM_Signal.PCSrc; // reserve for control hazard
    
    assign Addr_Out = MEM_ALU_Out;
    assign Data_Out = MEM_Reg_Read_Data_2;
    assign MemWrite = MEM_MEM_Signal.MemWrite;
    assign MemRead = MEM_MEM_Signal.MemRead;
    logic [31:0]MEM_Mem_Read_Data;
    assign MEM_Mem_Read_Data = Data_In;
    assign MEM_cache_stall = cache_stall;

    WB_Signal MEM_WB_Signal_Cache_Stall;
    always_comb begin
        if(cache_stall) begin
            MEM_WB_Signal_Cache_Stall = '{RegWrite: 1'b0, MemtoReg: MEM_WB_Signal.MemtoReg};
        end
        else begin
            MEM_WB_Signal_Cache_Stall = MEM_WB_Signal;
        end
    end

    // WB
    logic [31:0]WB_Mem_Read_Data;
    logic [31:0]WB_ALU_Out, WB_Imm, WB_PC_Plus_4;
    

    MEM_WB_Reg MEM_WB(
        .clk(clk),
        .rst(rst),
        .unlock(MEM_WB_Write),
        .MEM_WB_Signal(MEM_WB_Signal_Cache_Stall),

        .MEM_Mem_Read_Data(MEM_Mem_Read_Data), // from multiplexer
        .MEM_ALU_Out(MEM_ALU_Out),
        .MEM_Imm(MEM_Imm),
        .MEM_PC_Plus_4(MEM_PC_Plus_4),
        .MEM_Reg_Write_Addr(MEM_Reg_Write_Addr),

        .WB_WB_Signal(WB_WB_Signal),

        .WB_Mem_Read_Data(WB_Mem_Read_Data),
        .WB_ALU_Out(WB_ALU_Out),
        .WB_Imm(WB_Imm),
        .WB_PC_Plus_4(WB_PC_Plus_4),
        .WB_Reg_Write_Addr(WB_Reg_Write_Addr)
    );

    MUX4T1_32 Reg_Data_Mux(
        .I0(WB_ALU_Out),
        .I1(WB_Imm),
        .I2(WB_PC_Plus_4),
        .I3(WB_Mem_Read_Data),
        .s(WB_WB_Signal.MemtoReg),
        .o(WB_Reg_Write_Data)
    );

`ifdef WB_REG_DATA_TEMP_ENABLE
    // add for forwarding in cache stall
    // if there is a forwarding in cache stall, the register data in WB stage
    // only exists for one clock cycle, since I do not stall WB stage. In this
    // situation, when cache stall ends, and the forwarding data is already in
    // the register and the forwarding unit will choose the wrong source of data.
    // That is, it will choose the already write-back data from ID/EX register(from
    // ID stage), while ID/EX register read the data before write back.
    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            WB_Reg_Write_Data_Temp <= 'b0;
        end
        else begin
            WB_Reg_Write_Data_Temp <= WB_Reg_Write_Data;
        end
    end


    logic Temp_Valid;
    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            Temp_Valid <= 1'b0;
        end
        else if(cache_stall && ) begin
            if(Forward_ALUSrc_A == 2'b10 || Forward_ALUSrc_B == 2'b10
            || Reg_Data_Src_1 == 2'b10 || Reg_Data_Src_2 == 2'b10) begin
                Temp_Valid <= 1'b1;    
            end
            else Temp_Valid <= Temp_Valid;
        end
        else begin
            Temp_Valid = 1'b0;
        end
    end
`endif

    assign RegWrite = WB_WB_Signal.RegWrite;
endmodule
