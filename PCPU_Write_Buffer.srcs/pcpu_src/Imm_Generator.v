`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/09/23 20:18:43
// Design Name: 
// Module Name: Imm_Generator
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


module Imm_Generator(   input [31:0]Inst,
                        output reg[31:0]Imm
    );
    localparam  I_Type = 3'b000,
                S_Type = 3'b001,
                B_Type = 3'b010,
                U_Type = 3'b011,
                J_Type = 3'b100;
    function [31:0]getImm;  // maybe five seperate functions can save more hardware resources
    input [2:0]type;
    input [31:0]Inst;
        begin
            case(type)
                I_Type: getImm = {{20{Inst[31]}},Inst[31:20]};
                S_Type: getImm = {{20{Inst[31]}},Inst[31:25],Inst[11:7]};
                B_Type: getImm = {{20{Inst[31]}},Inst[7],Inst[30:25],Inst[11:8],1'b0}; // << 1
                U_Type: getImm = {Inst[31:12],12'h0};
                J_Type: getImm = {{12{Inst[31]}},Inst[19:12],Inst[20],Inst[30:21],1'b0}; // << 1
            endcase
        end
    endfunction
    always @(*) begin
        case(Inst[6:0])
            7'b0110111: Imm = getImm(U_Type, Inst); // LUI
            7'b1101111: Imm = getImm(J_Type, Inst); // JAL
            7'b1100111: Imm = getImm(I_Type, Inst) & 32'hfffffffe; // JALR / make the lsb = 0   -2020/11/5
            7'b1100011: Imm = getImm(B_Type, Inst); // BEQ / BNE / BLT / BGE / BLTU / BGTU
            7'b0000011: Imm = getImm(I_Type, Inst); // LW
            7'b0100011: Imm = getImm(S_Type, Inst); // SW
            7'b0010011: 
                case(Inst[14:12])
                    3'b001, // SLLI SRLI SRAL
                    3'b101: Imm = getImm(I_Type, Inst) & 32'h0000001F; // shamt = lowest 5 bits
                    default:Imm = getImm(I_Type, Inst); // ADDI / SLTI / SLTIU / XORI / ORI / ANDI
                endcase
            default:    Imm = 32'hx;
        endcase
    end
endmodule
