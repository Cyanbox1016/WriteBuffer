`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/10/24 09:51:03
// Design Name: 
// Module Name: MEM_WB_Reg
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


module MEM_WB_Reg(
    input clk,
    input rst,
    input unlock,

    // signal
    input WB_Signal MEM_WB_Signal,
    
    // data
    input [31:0]MEM_Mem_Read_Data,
    input [31:0]MEM_ALU_Out,
    input [31:0]MEM_Imm,
    input [31:0]MEM_PC_Plus_4,
    input [4:0]MEM_Reg_Write_Addr,

    // signal
    output WB_Signal WB_WB_Signal,

    // data
    output [31:0]WB_Mem_Read_Data,
    output [31:0]WB_ALU_Out,
    output [31:0]WB_Imm,
    output [31:0]WB_PC_Plus_4,
    output [4:0]WB_Reg_Write_Addr
    );

    WB_Signal WB_Signal_Current;
    logic [31:0]Mem_Read_Data_Current, ALU_Out_Current, Imm_Current, PC_Plus_4_Current;
    logic [4:0]Reg_Write_Addr_Current;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            WB_Signal_Current <= '{default:0};
            Mem_Read_Data_Current <= 32'b0;
            ALU_Out_Current <= 32'b0;
            Imm_Current <= 32'b0;
            PC_Plus_4_Current <= 32'b0;
            Reg_Write_Addr_Current <= 5'b0;
        end
        else begin
            if(unlock) begin
                WB_Signal_Current <= MEM_WB_Signal;
                Mem_Read_Data_Current <= MEM_Mem_Read_Data;
                ALU_Out_Current <= MEM_ALU_Out;
                Imm_Current <= MEM_Imm;
                PC_Plus_4_Current <= MEM_PC_Plus_4;
                Reg_Write_Addr_Current <= MEM_Reg_Write_Addr;
            end
            else begin
                WB_Signal_Current <= WB_Signal_Current;
                Mem_Read_Data_Current <= Mem_Read_Data_Current;
                ALU_Out_Current <= ALU_Out_Current;
                Imm_Current <= Imm_Current;
                PC_Plus_4_Current <= PC_Plus_4_Current;
                Reg_Write_Addr_Current <= Reg_Write_Addr_Current;
            end
        end
    end

    assign WB_WB_Signal = WB_Signal_Current;
    assign WB_Mem_Read_Data = Mem_Read_Data_Current;
    assign WB_ALU_Out = ALU_Out_Current;
    assign WB_Imm = Imm_Current;
    assign WB_PC_Plus_4 = PC_Plus_4_Current;
    assign WB_Reg_Write_Addr = Reg_Write_Addr_Current;

endmodule
