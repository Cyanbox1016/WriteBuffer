`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/15 00:38:33
// Design Name: 
// Module Name: dummy_core_sim
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


module dummy_core_sim 
    #(parameter T = 80)();
    // input
    logic        clk;
    logic        aresetn;
    logic        step;
    logic        debug_mode;
    logic [4:0]  debug_reg_addr; // register address
    logic [6:0]  debug_d_cache_index;
//    logic [31:0] data_in;
//    logic [31:0] chip_debug_in;
    // output
//    logic [31:0] address;
//    logic [31:0] data_out;
//    logic [31:0] chip_debug_out0;
//    logic [31:0] chip_debug_out1;
//    logic [31:0] chip_debug_out2;
//    logic [31:0] chip_debug_out3;

    logic [31:0]PC_Out, Debug_Reg_Data, Addr_Out, Inst;

    dummy_core uut(
        .clk(clk),
        .aresetn(aresetn),
        .step(step),
        .debug_mode(debug_mode),
        .debug_reg_addr(debug_reg_addr), // register address
        .debug_d_cache_index(debug_d_cache_index), // d cache index
        .address(),
        .data_out(),
        .data_in(),
        .chip_debug_in(),
        .chip_debug_out0(PC_Out),
        .chip_debug_out1(Debug_Reg_Data),
        .chip_debug_out2(Addr_Out),
        .chip_debug_out3(Inst)
    );

    integer i;
    initial begin
        aresetn = 0;
        clk = 1;
        debug_reg_addr = 0; // start with register 1
        step = 0;
        debug_mode = 1;
        debug_d_cache_index = 0;
        #100;
        
        fork
            forever #(T/2) clk <= ~clk;
            #(3*T) aresetn = 1;
            forever #(T/2) begin
                for(i = 1; i <= 40; i = i + 1) begin
                    if(i <= 31) begin
                        debug_reg_addr = i;
                        #(T/80);
                    end
                    else #(T/80);
                end
            end
        join
    end
    
    
endmodule
