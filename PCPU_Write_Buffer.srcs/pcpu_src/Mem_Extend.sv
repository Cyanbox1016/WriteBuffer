`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/25 14:54:38
// Design Name: 
// Module Name: Mem_Extend
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


module Mem_Extend(
    input mem_clk,
    input rst,
    input [3:0]we,
    input [3:0]read_address_valid,
    input [3:0][31:0]address,
    input [3:0][31:0]data_in,
    output logic [31:0]data_out
    );
    
    logic [31:0]ram_data_out[0:3];
    Ram ram_unit_0 (
       .clka(mem_clk),
       .wea(we[0]),
       .addra(address[0]),
       .dina(data_in[0]),
       .douta(ram_data_out[0])
    );

    Ram ram_unit_1 (
       .clka(mem_clk),
       .wea(we[1]),
       .addra(address[1]),
       .dina(data_in[1]),
       .douta(ram_data_out[1])
    );

    Ram ram_unit_2 (
       .clka(mem_clk),
       .wea(we[2]),
       .addra(address[2]),
       .dina(data_in[2]),
       .douta(ram_data_out[2])
    );

    Ram ram_unit_3 (
       .clka(mem_clk),
       .wea(we[3]),
       .addra(address[3]),
       .dina(data_in[3]),
       .douta(ram_data_out[3])
    );
    
    always_comb begin
        data_out = 'bx;
        case (read_address_valid)
            4'b0001: data_out = ram_data_out[0];
            4'b0010: data_out = ram_data_out[1];
            4'b0100: data_out = ram_data_out[2];
            4'b1000: data_out = ram_data_out[3];
            default: data_out = 'bx;
        endcase
    end

endmodule
