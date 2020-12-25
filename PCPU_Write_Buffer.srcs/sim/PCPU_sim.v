`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/03 20:30:38
// Design Name: 
// Module Name: PCPU_sim
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


module PCPU_sim
    #(parameter T = 40)
    ();
    // input 
    reg clk, mem_clk;
    reg rst;
    wire [31:0]Inst;
    wire [31:0]Data_In;
    
    // output
    wire [31:0]Addr_Out, Data_Out, PC_Out, Debug_Data;
    wire MemWrite;
    reg [4:0]Debug_Addr;
    
    PCPU uut(  
        .clk(clk),
        .rst(rst),
        .Inst_In(Inst),    // Instruction Memory output
        .Data_In(Data_In),    // Data Memory output
        .Debug_Addr(Debug_Addr),  // register number(address) for debug
        .Addr_Out(Addr_Out),  // Data Memory address input
        .Data_Out(Data_Out), // Data Memory Data input
        .PC_Out(PC_Out),   // Instruction Memory input
        .Debug_Data(Debug_Data), // register value to display for debug
        .MemWrite(MemWrite) // Data Memory write
    );
    
    Rom rom_unit (
        .clka(mem_clk),
        .a(PC_Out[11:2]),
        .spo(Inst)
    );

    Ram ram_unit (
       .clka(mem_clk),
       .wea(MemWrite),
       .addra(Addr_Out[11:2]),
       .dina(Data_Out),
       .douta(Data_In)
    );
    integer i;
    initial begin
        rst = 1;
        clk = 1;
        mem_clk = 1;
        Debug_Addr = 0; // start with register 1
        #100;
        
        fork
            forever #(T/2) clk <= ~clk;
            forever #(T/4) mem_clk <= ~mem_clk;
            #(2*T) rst = 0;
            forever #(T/2) begin
                for(i = 1; i <= 20; i = i + 1) begin
                    Debug_Addr = i;
                    #(T/40);
                end
            end
        join
    end
endmodule
