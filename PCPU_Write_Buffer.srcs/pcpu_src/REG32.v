`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:46:34 05/10/2020 
// Design Name: 
// Module Name:    REG32 
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
module REG32(input clk, rst, CE,
				 input [31:0]D,
				 output[31:0]Q
   );
	reg [31:0]r;
	assign Q = r;
	always @(posedge clk or posedge rst)begin
		if(rst) r <= 0;
		else if(CE) r <= D;
	end
endmodule
