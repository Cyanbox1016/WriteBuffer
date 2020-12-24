`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/04 00:43:48
// Design Name: 
// Module Name: Hazard_Detect_Unit
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


module Hazard_Detect_Unit(
    input [4:0]ID_Rs_1,
    input [4:0]ID_Rs_2,
    input [4:0]EX_Rd,
    input [4:0]MEM_Rd,
    input EX_MemRead,
    input MEM_MemRead,
    input EX_RegWrite, 
    input ID_Branch, // detect branch after register write
    input ID_MemWrite, // store after load which can be forwarding
    input MEM_cache_stall, // highest priority stall, (brute force)
    output logic PCWrite,
    output logic IF_ID_Write,
    output logic Inst_Nop, // make the current stage excute nop
    output logic ID_EX_Write,
    output logic EX_MEM_Write,
    output logic MEM_WB_Write
    );
    always_comb begin
        PCWrite = 1'b1;
        IF_ID_Write = 1'b1;
        Inst_Nop = 1'b0;
        ID_EX_Write = 1'b1;
        EX_MEM_Write = 1'b1;
        MEM_WB_Write = 1'b1;
        if(MEM_cache_stall) begin
            PCWrite = 1'b0;
            IF_ID_Write = 1'b0;
            ID_EX_Write = 1'b0;
            EX_MEM_Write = 1'b0;
            MEM_WB_Write = 1'b0;
        end
        else begin
            if(EX_MemRead && EX_Rd != 0 && (EX_Rd == ID_Rs_1 || EX_Rd == ID_Rs_2)) begin // read after load, stall
            PCWrite = 1'b0;
            IF_ID_Write = 1'b0;
            Inst_Nop = 1'b1;
            end
            else if(ID_Branch && EX_RegWrite && EX_Rd != 0 && (EX_Rd == ID_Rs_1 || EX_Rd == ID_Rs_2)) begin
                PCWrite = 1'b0;
                IF_ID_Write = 1'b0;
                Inst_Nop = 1'b1;
            end
            if((ID_Branch || ID_MemWrite) && MEM_MemRead && MEM_Rd != 0 && (MEM_Rd == ID_Rs_1 || MEM_Rd == ID_Rs_2)) begin // second stall for branch/store after load
                PCWrite = 1'b0;
                IF_ID_Write = 1'b0;
                Inst_Nop = 1'b1;
            end
        end
        
    end
endmodule
