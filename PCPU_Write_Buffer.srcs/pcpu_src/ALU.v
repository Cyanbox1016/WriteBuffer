`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:01:46 05/10/2020 
// Design Name: 
// Module Name:    ALU 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module ALU( input [31:0]A, B, 
			input[3:0] ALU_operation, 
			output[31:0] res, 
			output zero, overflow
    );
	 
	wire [31:0] res_and,res_or,res_add,res_sub,res_slt,res_xor,res_srl,res_sll,res_sltu,res_sra,shamt;
	reg [31:0] r;
	parameter one = 32'h00000001, zero_0 = 32'h00000000;
	assign shamt = B & 32'h0000001F;
	assign res_and = A & B;
	assign res_or = A | B;
	assign res_add = A + B;
	assign res_sub = A - B;
	assign res_xor = A ^ B;
	// assign res_srl = A >> shamt | A << (32'h00000020 - shamt); // shift right circularly
	assign res_srl = A >> shamt;
	assign res_sra = ($signed(A)) >>> shamt; // arithmeticly
	assign res_sll = A << shamt;
	// assign res_slt = ($signed({A[31], (~A) + 1'b1}) < $signed({B[31], (~B) + 1'b1})) ? one : zero_0; // correct -2020/10/14
	assign res_slt = $signed(A) < $signed(B) ? one : zero_0;
	assign res_sltu = (A < B) ? one : zero_0; // unsigned
	assign res = r;

	always @(*)
		case (ALU_operation)
		4'b0000: r = res_add;
		4'b1000: r = res_sub;
		4'b0001: r = res_sll;
		4'b0010: r = res_slt;
		4'b0011: r = res_sltu;
		4'b0100: r = res_xor;
		4'b0101: r = res_srl;
		4'b1101: r = res_sra;
		4'b0110: r = res_or;	
		4'b0111: r = res_and;
		default: r = 32'hx;
		endcase
	assign zero = (r == 0)? 1'b1: 1'b0;
	 
endmodule
