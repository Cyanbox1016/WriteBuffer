`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/25 16:29:28
// Design Name: 
// Module Name: WriteBuffer
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


module WriteBuffer # (parameter BUFFERSIZE = 16) (
    input clk,      // reverse cache clk
    input rst,

    /* contact with cache */
    input [31:0] cache_req_addr,
    input [31:0] cache_req_data,
    input cache_req_valid,
    output resp_cache_valid,        // finish writing to buffer
    output resp_cache_stall,        // buffer is full now, signal cache to stall

    input read_check,               // check whether there is dirty data in buffer when cache does reading
    output dirty_in_buffer,
    
    /* newly added: tell cache  */

    /* contact with memory */
    output [3:0][31:0] req_mem_addr,
    output [3:0][31:0] req_mem_data,
    output [3:0] req_mem_valid,
    input mem_resp_valid
);

logic [3:0][BUFFERSIZE - 1:0][31:0] buffer;
logic [3:0][BUFFERSIZE - 1:0][31:0] addr;
logic [3:0][BUFFERSIZE - 1:0] valid;    // whether content in buffer is valid

wire [1:0] col_index;
assign col_index[1:0] = cache_req_addr[1:0];

logic [31:0] select_position;

int queue_head;
int queue_tail;

/* 每行都有数据占着，但新数据还可能可以加进�? */
wire buffer_is_fully_occupied;  
assign buffer_is_fully_occupied = (queue_head == queue_tail + 1 || (queue_head == 0 && queue_tail == BUFFERSIZE - 1)) ? 1 : 0;

wire buffer_is_empty;
assign buffer_is_empty = (queue_head == queue_tail) ? 1 : 0;

int i;
/* 给新数据找一个合适的放置位置 */
always @ * begin
    if (rst == 1) select_position <= 32'b0;
    else begin
        for (i = queue_head; i != queue_tail; i = (i + 1) % BUFFERSIZE) begin
            if (col_index != 0 && addr[0][i][31:2] == cache_req_addr[31:2] && valid[0][i]) begin
                select_position <= i;
                break;
            end
            else if (col_index != 1 && addr[1][i][31:2] == cache_req_addr[31:2] && valid[1][i]) begin
                select_position <= i;
                break;
            end
            else if (col_index != 2 && addr[2][i][31:2] == cache_req_addr[31:2] && valid[2][i]) begin
                select_position <= i;
                break;
            end
            else if (col_index != 3 && addr[3][i][31:2] == cache_req_addr[31:2] && valid[3][i]) begin
                select_position <= i;
                break;
            end
            else if (i == queue_tail - 1 || (queue_tail == 0 && i == BUFFERSIZE - 1)) begin
                select_position <= queue_tail;
                break;
            end
        end
    end
end

/* read into buffer */
always @ (posedge clk or posedge rst) begin
    if (rst == 1) begin
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < BUFFERSIZE; j++) begin
                buffer[i][j][31:0] <= 32'b0;
                addr[i][j][31:0] <= 32'b0;
                valid[i][j] <= 1'b0;
            end
        end
        queue_head <= 32'b0;
        queue_tail <= 32'b0;
    end
    else if (cache_req_valid) begin
        if (!buffer_is_fully_occupied || (buffer_is_fully_occupied && select_position != queue_tail)) begin
            valid[col_index][select_position] <= 1'b1;
            buffer[col_index][select_position] <= cache_req_data;
            if (!buffer_is_fully_occupied && select_position == queue_tail) queue_tail++;
        end
    end
end

assign resp_cache_stall = (buffer_is_fully_occupied && select_position == queue_tail) ? 1 : 0;

assign req_mem_addr[3:0][31:0] = addr[3:0][queue_head][31:0];
assign req_mem_data[3:0][31:0] = buffer[3:0][queue_head][31:0];
assign req_mem_valid[3:0] = valid[3:0][queue_head];

/* write into memory */
always @ (posedge mem_resp_valid) begin
    if (!buffer_is_empty) begin
        valid[0][queue_read] = 1'b0;
        valid[1][queue_read] = 1'b0;
        valid[2][queue_read] = 1'b0;
        valid[3][queue_read] = 1'b0;
        queue_head = queue_head + 1;
    end
end

logic dirty_in_buffer_state;
assign dirty_in_buffer = dirty_in_buffer_state;

always @ * begin
    if (rst == 1) dirty_in_buffer_state <= 1'b0;
    else if (read_check) begin
        for (int k = queue_head; k != queue_tail; k = (k + 1) % BUFFERSIZE) begin
            if (addr[col_index][k][31:0] == cache_req_addr[31:0] && valid[col_index][k] == 1) begin
                dirty_in_buffer_state <= 1'b1;
                break;
            end 
            else if (k == queue_tail - 1 || (queue_tail == 0 && k == BUFFERSIZE - 1)) begin
                dirty_in_buffer_state <= 1'b0;
            end
        end
    end
end

endmodule