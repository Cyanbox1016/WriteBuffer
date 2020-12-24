`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/08 14:50:50
// Design Name: 
// Module Name: Cache
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


module Cache(
    input clk,
    input rst,
    input cache_write,
    input cache_read,
    input write_back, // interact with memory
    input read_allocate, // interact with memory
    input [10:0]address,
    input [31:0]data_in,
    input [31:0]mem_data_out,
    input [6:0]debug_cache_index,
    output logic [31:0]data_out,
    output logic [10:0]mem_address,
    output logic [31:0]mem_data_in,
    output logic mem_read,
    output logic mem_write,
    output logic stall,
    output logic debug_cache_dirty,
    output logic debug_cache_valid,
    output logic [3:0]debug_cache_tag,
    output logic [31:0]debug_cache_data
    );
    parameter CACHE_SIZE = 128;
    logic [CACHE_SIZE - 1 : 0]valid, dirty;
    logic [3:0]tag[0 : CACHE_SIZE - 1];
    logic [31:0]data[0 : CACHE_SIZE - 1];
    logic [6:0]index;
    logic miss, is_dirty;
    logic [3:0]state;
    localparam  S_IDLE = 3'd0, S_BACK = 3'd1, S_BACK_WAIT = 3'd2,
                S_FILL = 3'd4, S_FILL_WAIT = 3'd5, S_ERROR = 3'd6;
    assign index = address[6:0];
    integer i;
    assign debug_cache_dirty = dirty[debug_cache_index];
    assign debug_cache_valid = valid[debug_cache_index];
    assign debug_cache_tag = tag[debug_cache_index];
    assign debug_cache_data = data[debug_cache_index];

    // control unit
    always_ff @(posedge clk) begin
        if(rst) begin
            state <= S_IDLE;
        end
        else begin
            case (state)
                S_IDLE: begin
                    if(!cache_read && !cache_write) begin
                        state <= state; // do nothing
                    end
                    else begin
                        if(miss) begin
                            if(is_dirty) state <= S_BACK;
                            else state <= S_FILL;
                        end
                        else state <= state; //hit
                    end 
                    
                end
                S_BACK: begin
                    if(!write_back) state <= S_BACK_WAIT;
                    else state <= state;
                end
                S_BACK_WAIT: begin 
                    state <= S_FILL;
                end
                S_FILL: begin
                    if(!read_allocate) state <= S_FILL_WAIT;
                    else state <= state;
                end
                S_FILL_WAIT: begin 
                    state <= S_IDLE;
                end
                S_ERROR: state <= S_ERROR;
                default: state <= S_ERROR;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            valid <= 'b0;
            dirty <= 'b0;
            for(i = 0; i < CACHE_SIZE; i = i + 1) begin
                tag[i] <= 'b0;
                data[i] <= 'b0;
            end
        end
        else begin
            case (state)
                S_IDLE: begin
                    if(!miss) begin
                        if(cache_write) begin
                            dirty[index] <= 1'b1;
                            data[index] <= data_in;
                        end
                    end
                end
                S_BACK,
                S_BACK_WAIT,
                S_FILL:;
                S_FILL_WAIT: begin
                    if(cache_write) begin
                        data[index] <= data_in; // write data in cache
                        dirty[index] <= 1'b1;
                    end
                    else if(cache_read) begin
                        data[index] <= mem_data_out; // replace data in cache
                        dirty[index] <= 1'b0;
                    end
                    valid[index] <= 1'b1;
                    tag[index] <= address[10:7]; // update corresponding tag
                end
                S_ERROR:;
                default:;
            endcase
        end
    end

    // cache signal generator
    always_comb begin
        miss = 1'b0;
        is_dirty = 1'b0;
        if(!valid[index]) miss = 1'b1;
        else if(tag[index] != address[10:7]) miss = 1'b1;
        if(dirty[index]) is_dirty = 1'b1;
    end

    always_comb begin
        mem_data_in = 'x;
        mem_address = 'x;
        stall = 1'b1;
        mem_write = 1'b0;
        mem_read = 1'b0;
        case (state)
            S_IDLE: begin data_out = data[index]; stall = 1'b0; end
            S_BACK: begin 
                mem_write = 1'b1;
                mem_address = {tag[index], index};
                mem_data_in = data[index];
            end
            S_FILL: begin
                mem_read = 1'b1;
                mem_address = address;
            end
            S_BACK_WAIT:;
            S_FILL_WAIT: mem_address = address;
            S_ERROR:;
            default:;
        endcase
    end

    
    
endmodule
