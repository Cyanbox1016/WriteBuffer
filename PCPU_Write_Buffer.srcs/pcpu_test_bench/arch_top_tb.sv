`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/09/17 16:23:50
// Design Name: 
// Module Name: arch_top_tb
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


module arch_top_tb(
);

logic        clk;
logic        resetn;
logic [15:0] switch;
logic [15:0] led;
logic [ 7:0] num_csn;
logic [ 7:0] num_an;

initial begin
    clk <= 1'b1;
    resetn <= 1'b0;
    
    #100;
    
    resetn <= 1'b1;
end

always begin
    clk <= 1'b1;
    #0.5;
    clk <= 1'b0;
    #0.5;
end

arch_top arch_top_inst(
    .clk(clk),
    .resetn(resetn),
    .switch(switch),
    .button(),
    
    .led(led),
    .rgb1(),
    .rgb2(),
    .num_csn(num_csn),
    .num_an(num_an)
);

endmodule
