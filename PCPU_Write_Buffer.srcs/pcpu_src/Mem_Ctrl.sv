`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/21 14:02:02
// Design Name: 
// Module Name: Mem_Ctrl
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


module Mem_Ctrl(
    input cpu_clk,
    input mem_clk,
    input rst,
    input mem_read,
    input mem_write,
    output write_back,
    output read_allocate
    );
    logic mem_state, mem_ready, cnt;
    localparam MEM_IDLE = 1'b0, MEM_WORK = 1'b1;

    always_ff @(negedge cpu_clk) begin
        if(rst) mem_state <= MEM_IDLE;
        if(mem_write || mem_read) begin
            if(!mem_ready) mem_state <= MEM_WORK;
            else mem_state <= MEM_IDLE;
        end
        else begin
            mem_state <= MEM_IDLE;
        end
    end

    // always_ff @(posedge mem_clk or posedge rst) begin
    //     if(rst) begin
    //         mem_ready = 1'b0;
    //     end
    //     else begin
    //         if(mem_state == MEM_IDLE) begin
    //             mem_ready = 1'b0;
    //         end
    //         else if(mem_write || mem_read) begin
    //             mem_ready = 1'b1;
    //         end
    //         else begin
    //             mem_ready = 1'b0;
    //         end
    //     end
    // end

    always_ff @(posedge mem_clk or posedge rst) begin
        if(rst) begin
            cnt <= 1'b0;
            mem_ready <= 1'b0;
        end
        else begin
            if(mem_write || mem_read) begin
                if(cnt == 1'b1) begin
                    mem_ready <= 1'b1;
                end
                else begin
                    mem_ready <= 1'b0;
                end
                cnt <= cnt + 1;
            end
            else begin
                mem_ready = 1'b0;
                cnt <= 1'b0;
            end
        end
    end

    assign write_back = !(mem_ready && mem_state == MEM_WORK);
    assign read_allocate = !(mem_ready && mem_state == MEM_WORK);

    // logic [3:0]mem_ready;
    // always_ff @(posedge cpu_clk or posedge rst) begin
    //     if(rst) begin
    //         mem_ready <= 3'b0;
    //     end
    //     else begin
    //         mem_ready <= {mem_ready[1:0], mem_clk};
    //     end
    // end
    
    // logic posedge_mem_ready;
    // assign posedge_mem_ready = mem_ready[2] & ~mem_ready[1];
    // assign write_back = ~posedge_mem_ready;
    // assign read_allocate = ~posedge_mem_ready;
endmodule
