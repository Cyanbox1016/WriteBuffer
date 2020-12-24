`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/10/21 16:58:46
// Design Name: 
// Module Name: IF_ID_Reg
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


module IF_ID_Reg(
    input clk,
    input rst,
    input IF_ID_Flush,
    input we, // write enable
    input [31:0]IF_PC,
    input [31:0]IF_Inst,
    input [31:0]IF_PC_Plus_4,
    output [31:0]ID_PC,
    output [31:0]ID_Inst,
    output [31:0]ID_PC_Plus_4
    );
    logic [31:0] PC_Current, Inst_Current, PC_Plus_4_Current; // current reg value
    always@ (posedge clk or posedge rst) begin
        if(rst || IF_ID_Flush) begin
            PC_Current <= 32'b0;
            Inst_Current <= 32'b0;
            PC_Plus_4_Current <= 32'b0;
        end
        else if(we) begin
            PC_Current <= IF_PC;
            Inst_Current <= IF_Inst;
            PC_Plus_4_Current <= IF_PC_Plus_4;
        end
        else begin
            PC_Current <= PC_Current;
            Inst_Current <= Inst_Current;
            PC_Plus_4_Current <= PC_Plus_4_Current;
        end
    end
    assign ID_PC = PC_Current;
    assign ID_Inst = Inst_Current;
    assign ID_PC_Plus_4 = PC_Plus_4_Current;
endmodule
