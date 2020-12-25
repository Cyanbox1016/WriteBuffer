`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/10/23 22:39:18
// Design Name: 
// Module Name: EX_MEM_Reg
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

module EX_MEM_Reg(
    input clk,
    input rst,
    input unlock,

    // signal
    input WB_Signal EX_WB_Signal,
    input MEM_Signal EX_MEM_Signal,
    input EX_Zero,

    // data
    input [31:0]EX_PC_Plus_Imm,
    input [31:0]EX_ALU_Out,
    input [31:0]EX_Reg_Read_Data_2,
    input [31:0]EX_Imm,
    input [31:0]EX_PC_Plus_4,
    input [4:0]EX_Reg_Write_Addr,

    // signal
    output WB_Signal MEM_WB_Signal,
    output MEM_Signal MEM_MEM_Signal,
    output MEM_Zero,

    // data
    output [31:0]MEM_PC_Plus_Imm,
    output [31:0]MEM_ALU_Out,
    output [31:0]MEM_Reg_Read_Data_2,
    output [31:0]MEM_Imm,
    output [31:0]MEM_PC_Plus_4,
    output [4:0]MEM_Reg_Write_Addr
    );

    WB_Signal WB_Signal_Current;
    MEM_Signal MEM_Signal_Current;
    logic Zero_Current;
    logic [31:0]PC_Plus_Imm_Current, ALU_Out_Current, Reg_Read_Data_2_Current, Imm_Current, PC_Plus_4_Current;
    logic [4:0]Reg_Write_Addr_Current;

    always @(posedge clk) begin
        if(rst) begin
            WB_Signal_Current <= '{default:0};
            MEM_Signal_Current <= '{default:0};
            Zero_Current <= 1'b0;
            PC_Plus_Imm_Current <= 32'b0;
            ALU_Out_Current <= 32'b0;
            Reg_Read_Data_2_Current <= 32'b0;
            Imm_Current <= 32'b0;
            PC_Plus_4_Current <= 32'b0;
            Reg_Write_Addr_Current <= 32'b0;
        end
        else begin
            if(unlock) begin
                WB_Signal_Current <= EX_WB_Signal;
                MEM_Signal_Current <= EX_MEM_Signal;
                Zero_Current <= EX_Zero;
                PC_Plus_Imm_Current <= EX_PC_Plus_Imm;
                ALU_Out_Current <= EX_ALU_Out;
                Imm_Current <= EX_Imm;
                PC_Plus_4_Current <= EX_PC_Plus_4;
                Reg_Read_Data_2_Current <= EX_Reg_Read_Data_2;
                Reg_Write_Addr_Current <= EX_Reg_Write_Addr;
            end
            else begin
                WB_Signal_Current <= WB_Signal_Current;
                MEM_Signal_Current <= MEM_Signal_Current;
                Zero_Current <= Zero_Current;
                PC_Plus_Imm_Current <= PC_Plus_Imm_Current;
                ALU_Out_Current <= ALU_Out_Current;
                Imm_Current <= Imm_Current;
                PC_Plus_4_Current <= PC_Plus_4_Current;
                Reg_Read_Data_2_Current <= Reg_Read_Data_2_Current;
                Reg_Write_Addr_Current <= Reg_Write_Addr_Current;
            end
        end
    end
    
    assign MEM_WB_Signal = WB_Signal_Current;
    assign MEM_MEM_Signal = MEM_Signal_Current;
    assign MEM_Zero = Zero_Current;
    assign MEM_PC_Plus_Imm = PC_Plus_Imm_Current;
    assign MEM_ALU_Out = ALU_Out_Current;
    assign MEM_Reg_Read_Data_2 = Reg_Read_Data_2_Current;
    assign MEM_Imm = Imm_Current;
    assign MEM_PC_Plus_4 = PC_Plus_4_Current;
    assign MEM_Reg_Write_Addr = Reg_Write_Addr_Current;
    
endmodule
