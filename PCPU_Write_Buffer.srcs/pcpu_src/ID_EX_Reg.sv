`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/10/23 21:02:21
// Design Name: 
// Module Name: ID_EX_Reg
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

module ID_EX_Reg(
    input clk,
    input rst,
    input ID_EX_Flush,
    input unlock, // !unlock -> keep reg unchanged

    // signal
    input WB_Signal ID_WB_Signal,
    input MEM_Signal ID_MEM_Signal,
    input EX_Signal ID_EX_Signal,

    // data
    input [31:0]ID_PC,
    input [31:0]ID_Reg_Read_Data_1,
    input [31:0]ID_Reg_Read_Data_2,
    input [31:0]ID_Imm,
    input [31:0]ID_PC_Plus_4,
    input [31:0]ID_PC_Plus_Imm,
    input [4:0]ID_Reg_Write_Addr,
    input [4:0]ID_Reg_Rs_1,
    input [4:0]ID_Reg_Rs_2,

    // signal
    output WB_Signal EX_WB_Signal,
    output MEM_Signal EX_MEM_Signal,
    output EX_Signal EX_EX_Signal,

    // data
    output [31:0]EX_PC,
    output [31:0]EX_Reg_Read_Data_1,
    output [31:0]EX_Reg_Read_Data_2,
    output [31:0]EX_Imm,
    output [31:0]EX_PC_Plus_4,
    output [31:0]EX_PC_Plus_Imm,
    output [4:0]EX_Reg_Write_Addr,
    output [4:0]EX_Reg_Rs_1,
    output [4:0]EX_Reg_Rs_2
    );

    WB_Signal WB_Signal_Current;
    MEM_Signal MEM_Signal_Current;
    EX_Signal EX_Signal_Current;
    reg [31:0]PC_Current, Reg_Read_Data_1_Current, Reg_Read_Data_2_Current, Imm_Current, PC_Plus_4_Current, PC_Plus_Imm_Current;
    reg [4:0]Reg_Write_Addr_Current, Reg_Rs_1_Current, Reg_Rs_2_Current;
    always_ff@ (posedge clk or posedge rst) begin
        if(rst) begin
            WB_Signal_Current <= '{ default:0 };
            MEM_Signal_Current <= '{ default:0 };
            EX_Signal_Current <= '{ default:0 };
            PC_Current <= 32'b0;
            Reg_Read_Data_1_Current <= 32'b0;
            Reg_Read_Data_2_Current <= 32'b0;
            Imm_Current <= 32'b0;
            PC_Plus_4_Current <= 32'b0;
            PC_Plus_Imm_Current <= 32'b0;
            Reg_Write_Addr_Current <= 5'b0;
            Reg_Rs_1_Current <= 5'b0;
            Reg_Rs_2_Current <= 5'b0;
        end
        else begin
            if(ID_EX_Flush) begin
                WB_Signal_Current <= '{ default:0 };
                MEM_Signal_Current <= '{ default:0 };
                EX_Signal_Current <= '{ default:0 };

                PC_Current <= ID_PC;
                Reg_Read_Data_1_Current <= ID_Reg_Read_Data_1;
                Reg_Read_Data_2_Current <= ID_Reg_Read_Data_2;
                Imm_Current <= ID_Imm;
                PC_Plus_4_Current <= ID_PC_Plus_4;
                PC_Plus_Imm_Current <= ID_PC_Plus_Imm;
                Reg_Write_Addr_Current <= ID_Reg_Write_Addr;
                Reg_Rs_1_Current <= ID_Reg_Rs_1;
                Reg_Rs_2_Current <= ID_Reg_Rs_2;
            end
            else begin
                if(unlock) begin
                    WB_Signal_Current <= ID_WB_Signal;
                    MEM_Signal_Current <= ID_MEM_Signal;
                    EX_Signal_Current <= ID_EX_Signal;

                    PC_Current <= ID_PC;
                    Reg_Read_Data_1_Current <= ID_Reg_Read_Data_1;
                    Reg_Read_Data_2_Current <= ID_Reg_Read_Data_2;
                    Imm_Current <= ID_Imm;
                    PC_Plus_4_Current <= ID_PC_Plus_4;
                    PC_Plus_Imm_Current <= ID_PC_Plus_Imm;
                    Reg_Write_Addr_Current <= ID_Reg_Write_Addr;
                    Reg_Rs_1_Current <= ID_Reg_Rs_1;
                    Reg_Rs_2_Current <= ID_Reg_Rs_2;
                end
                else begin
                    WB_Signal_Current <= WB_Signal_Current;
                    MEM_Signal_Current <= MEM_Signal_Current;
                    EX_Signal_Current <= EX_Signal_Current;
                    PC_Current <= PC_Current;
                    Reg_Read_Data_1_Current <= Reg_Read_Data_1_Current;
                    Reg_Read_Data_2_Current <= Reg_Read_Data_2_Current;
                    Imm_Current <= Imm_Current;
                    PC_Plus_4_Current <= PC_Plus_4_Current;
                    PC_Plus_Imm_Current <= PC_Plus_Imm_Current;
                    Reg_Write_Addr_Current <= Reg_Write_Addr_Current;
                    Reg_Rs_1_Current <= Reg_Rs_1_Current;
                    Reg_Rs_2_Current <= Reg_Rs_2_Current;
                end
            end
        end
    end
    
    assign EX_WB_Signal = WB_Signal_Current;
    assign EX_MEM_Signal = MEM_Signal_Current;
    assign EX_EX_Signal = EX_Signal_Current;
    assign EX_PC = PC_Current;
    assign EX_Reg_Read_Data_1 = Reg_Read_Data_1_Current;
    assign EX_Reg_Read_Data_2 = Reg_Read_Data_2_Current;
    assign EX_Imm = Imm_Current;
    assign EX_PC_Plus_4 = PC_Plus_4_Current;
    assign EX_PC_Plus_Imm = PC_Plus_Imm_Current;
    assign EX_Reg_Write_Addr = Reg_Write_Addr_Current;
    assign EX_Reg_Rs_1 = Reg_Rs_1_Current;
    assign EX_Reg_Rs_2 = Reg_Rs_2_Current;
endmodule
