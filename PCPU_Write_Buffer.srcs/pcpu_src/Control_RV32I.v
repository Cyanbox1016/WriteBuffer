`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/09/27 16:29:00
// Design Name: 
// Module Name: Control_RV32I
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


module Control_RV32I(   input [6:0]Opcode,
                        input [2:0]Funct3,
                        input Funct7_5,
                        output reg [1:0]PCSrc,
                        output reg RegWrite,
                        output reg ALUSrc,
                        output reg [3:0]ALUop, // funct3[2:0]+funct7[5]
                        output reg[1:0]MemtoReg,
                        output reg MemWrite, // 0 read; 1 write
                        output reg MemRead, // indicate LOAD instruction
                        output reg Branch, //signal whether the instruction is a branch inst
                        output reg B_Type // BEQ or BNE (prepared for extended instruction like BGE, BLT)
    );
    `include "ALU_Operation.vh"
    always @(*) begin
        PCSrc = 0;
        RegWrite = 0;
        ALUSrc = 0;
        ALUop = {Funct7_5, Funct3}; // Is ALUop = 0 better?
        MemtoReg = 0;
        MemWrite = 0;
        Branch = 0;
        B_Type = 1'bx;
        MemRead = 0;
        case (Opcode)
            7'b0110111: begin PCSrc = 2'b00; RegWrite = 1'b1; MemtoReg = 2'b01; end // LUI
            7'b1101111: begin PCSrc = 2'b10; RegWrite = 1'b1; MemtoReg = 2'b10; end // JAL
            7'b1100111: begin PCSrc = 2'b01; RegWrite = 1'b1; MemtoReg = 2'b10; end // JALR
            7'b1100011: begin // BEQ / BNE
                // PCSrc = 2'b10; // determined later in the datapath
                Branch = 1;
                ALUSrc = 1'b0;
                ALUop = SUB;
                case (Funct3)
                    3'b000: B_Type = 1'b1; // BEQ
                    3'b001: B_Type = 1'b0; // BNE 
                    default: B_Type = 1'bx;
                endcase
            end
            7'b0000011: begin PCSrc = 2'b00; RegWrite = 1'b1; MemtoReg = 2'b11; ALUSrc = 1'b1; ALUop = ADD; MemRead = 1'b1; end // LOAD
            7'b0100011: begin PCSrc = 2'b00; ALUSrc = 1'b1; ALUop = ADD; MemWrite = 1'b1; end //STORE
            7'b0010011: begin // I-Type ALUop has been encode by instruction
                // ALUop = {1'b0, Funct3}/ alter -2020/10/21
                PCSrc = 2'b00;
                RegWrite = 1'b1;
                ALUSrc = 1'b1;
                // judge SRAI or SRLI -2020/11/1
                // correct ALUop[0]->ALUop[3] -2020/11/19
                // ALUop[3] = 1'b0;
                if(Funct3 == 3'b101) ALUop[3] = Funct7_5; // SRAI or SRLI is differetiated by Funt7_5
                else ALUop[3] = 1'b0;
            end 
            7'b0110011: begin PCSrc = 2'b00; RegWrite = 1'b1; ALUSrc = 1'b0; end // R-Type ALUop has been encode by instruction
            default: ALUop = 0;
        endcase
    end
endmodule
