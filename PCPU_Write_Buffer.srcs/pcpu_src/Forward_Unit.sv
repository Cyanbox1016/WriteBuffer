`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/03 21:50:01
// Design Name: 
// Module Name: Forward_Unit
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


module Forward_Unit(
    input [4:0]EX_Rs_1,
    input [4:0]EX_Rs_2,
    input [4:0]ID_Rs_1, // forwarding for branch
    input [4:0]ID_Rs_2, // forwarding for branch
    input [4:0]MEM_Rd,
    input MEM_RegWrite,
    input [4:0]WB_Rd,
    input WB_RegWrite,
    input WB_Temp_Valid, // temp reg valid when forwarding in cache stall
    output logic [1:0]ALUSrc_A, // 00 -> EX; 01 -> MEM; 10 -> WB; 11 -> WB temp
    output logic [1:0]ALUSrc_B,  // 00 -> EX; 01 -> MEM; 10 -> WB; 11 -> WB temp
    output logic [1:0]Reg_Data_Src_1, // 00 -> ID; 01 -> MEM; 10 -> WB; 11 -> WB temp
    output logic [1:0]Reg_Data_Src_2 // 00 -> ID; 01 -> MEM; 10 -> WB; 11 -> WB temp
    );
    always_comb begin
        ALUSrc_A = 2'b00;
        ALUSrc_B = 2'b00;
        Reg_Data_Src_1 = 2'b00;
        Reg_Data_Src_2 = 2'b00;

        // for EX forwarding
        if(MEM_RegWrite && MEM_Rd != 5'b0 && EX_Rs_1 == MEM_Rd) begin // EX data hazard
            ALUSrc_A = 2'b01;
        end
        else if(WB_RegWrite && WB_Rd != 5'b0 && EX_Rs_1 == WB_Rd) begin // MEM data hazard
            ALUSrc_A = 2'b10;
        end
        // else if(WB_Temp_Valid) begin
        //     ALUSrc_A = 2'b11;
        // end

        if(MEM_RegWrite && MEM_Rd != 5'b0 && EX_Rs_2 == MEM_Rd) begin // EX data hazard
            ALUSrc_B = 2'b01;
        end
        else if(WB_RegWrite && WB_Rd != 5'b0 && EX_Rs_2 == WB_Rd) begin // MEM data hazard
            ALUSrc_B = 2'b10;
        end
        // else if(WB_Temp_Valid) begin
        //     ALUSrc_B = 2'b11;
        // end

        // for branch forwarding
        if(MEM_RegWrite && MEM_Rd != 5'b0 && ID_Rs_1 == MEM_Rd) begin
            Reg_Data_Src_1 = 2'b01;
        end
        else if(WB_RegWrite && WB_Rd != 5'b0 && ID_Rs_1 == WB_Rd) begin
            Reg_Data_Src_1 = 2'b10;
        end
        // else if(WB_Temp_Valid) begin
        //     Reg_Data_Src_1 = 2'b11;
        // end

        if(MEM_RegWrite && MEM_Rd != 5'b0 && ID_Rs_2 == MEM_Rd) begin
            Reg_Data_Src_2 = 2'b01;
        end
        else if(WB_RegWrite && WB_Rd != 5'b0 && ID_Rs_2 == WB_Rd) begin
            Reg_Data_Src_2 = 2'b10;
        end
        // else if(WB_Temp_Valid) begin
        //     Reg_Data_Src_2 = 2'b11;
        // end
    end
endmodule
