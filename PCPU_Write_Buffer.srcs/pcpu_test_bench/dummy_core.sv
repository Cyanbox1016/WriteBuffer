`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/09/21 18:44:55
// Design Name: 
// Module Name: dummy_core
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


module dummy_core(
    input  logic        clk,
    input  logic        aresetn,
    input  logic        step,
    input  logic        debug_mode,
    input  logic [4:0]  debug_reg_addr, // register address
    input  logic [6:0]  debug_d_cache_index, // d cache index

    output logic [31:0] address,
    output logic [31:0] data_out,
    input  logic [31:0] data_in,
    
    input  logic [31:0] chip_debug_in,
    output logic [31:0] chip_debug_out0,
    output logic [31:0] chip_debug_out1,
    output logic [31:0] chip_debug_out2,
    output logic [31:0] chip_debug_out3
);

    logic rst, MemWrite, MemRead, mem_clk, cpu_clk;
    logic[31:0] Inst, Data_In, Addr_Out, Data_Out, PC_Out, Debug_Reg_Data;
    logic [31:0]clk_div;
    logic d_cache_stall;
    logic i_cache_stall;
    
    assign rst = ~aresetn;

    PCPU cpu(  
        .clk(cpu_clk),
        .rst(rst),
        .Inst_In(Inst),
        .Data_In(Data_In), // Data Memory output
        .Debug_Addr(debug_reg_addr), // add for debug
        .d_cache_stall(d_cache_stall), // d_cache miss stall
        .i_cache_stall(i_cache_stall), // i_cache miss stall
        .Addr_Out(Addr_Out),  // Data Memory address input
        .Data_Out(Data_Out), // Data Memory Data input
        .PC_Out(PC_Out),    // Instruction Memory input
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .Debug_Data(Debug_Reg_Data) // add for debug
    );

// `define I_CACHE_USE
`ifndef I_CACHE_USE
    assign i_cache_stall = 1'b0;
`endif

    always_ff @(posedge clk) begin
        if(rst) clk_div <= 0;
        else clk_div <= clk_div + 1;
    end
    
    assign mem_clk = clk_div[4]; // latency memory clock - 1/32
    assign cpu_clk = debug_mode ? clk_div[0] : step;

    logic d_cache_write_back, d_cache_read_allocate, ram_read, ram_write;
    logic d_cache_write, d_cache_read;
    logic [31:0]ram_data_in, ram_data_out;
    logic [10:0]ram_address;
    // logic [6:0]debug_d_cache_index;
    logic debug_d_cache_dirty;
    logic debug_d_cache_valid;
    logic [3:0]debug_d_cache_tag;
    logic [31:0]debug_d_cache_data;
    assign d_cache_write = MemWrite;
    assign d_cache_read = MemRead;

    Cache d_cache(
        .clk(~cpu_clk),
        .rst(rst),
        .cache_write(d_cache_write),
        .cache_read(d_cache_read),
        .write_back(resp_cache_stall), // interact with memory
        .read_allocate(d_cache_read_allocate), // interact with memory
        .address(Addr_Out[12:2]),
        .data_in(Data_Out),
        .mem_data_out(ram_data_out),
        .debug_cache_index(debug_d_cache_index),

        .data_out(Data_In),
        .mem_address(ram_address),
        .mem_data_in(ram_data_in),
        .mem_read(ram_read),
        .mem_write(ram_write),
        .stall(d_cache_stall),
        .debug_cache_dirty(debug_d_cache_dirty),
        .debug_cache_valid(debug_d_cache_valid),
        .debug_cache_tag(debug_d_cache_tag),
        .debug_cache_data(debug_d_cache_data)
    );

    Mem_Ctrl ram_ctrl(
        .cpu_clk(cpu_clk),
        .mem_clk(mem_clk),
        .rst(rst),
        .mem_read(ram_read),
        .mem_write(ram_write),
        .write_back(d_cache_write_back),
        .read_allocate(d_cache_read_allocate)
    );

    logic [31:0]cache_req_addr, cache_req_data;
    logic cache_req_valid, mem_resp_valid;
    logic resp_cache_valid, resp_cache_stall, read_check, dirty_in_buffer;
    logic [3:0][31:0]req_mem_addr, req_mem_data;
    logic [3:0]req_mem_valid;
    logic req_mem_we;
    assign cache_req_addr = ram_address;
    assign cache_req_data = ram_data_in;
    assign cache_req_valid = ram_write;
    assign read_check = ram_read;

    WriteBuffer #(.BUFFERSIZE(16)) write_buffer (
        .clk(cpu_clk),      // reverse cache clk
        .rst(rst),
        .cache_req_addr(cache_req_addr),
        .cache_req_data(cache_req_data),
        .cache_req_valid(cache_req_valid),
        .resp_cache_valid(resp_cache_valid),        // finish writing to buffer
        .resp_cache_stall(resp_cache_stall),        // buffer is full now, signal cache to stall
        .read_check(read_check),               // check whether there is dirty data in buffer when cache does reading
        .dirty_in_buffer(dirty_in_buffer),
        .req_mem_addr_write(req_mem_addr),
        .req_mem_data_write(req_mem_data),
        .req_mem_valid_write(req_mem_valid),
        .req_mem_we(req_mem_we),
        .mem_resp_valid(mem_resp_valid),
        .req_mem_addr_read(),
        .req_mem_valid_read()
    );

`define MEM_EXTEND_USE


    logic [31:0]ram_extend_read_address;
    logic [3:0]read_address_valid;
    logic [3:0]ram_extend_we;
    // read and write address translation
    assign ram_extend_read_address = {23'b0, ram_address[10:2]};
    always_comb begin
        if(ram_read) begin
            case (ram_address[1:0])
                2'b00: begin
                    read_address_valid = 4'b0001;
                end
                2'b01: begin
                    read_address_valid = 4'b0010;
                end
                2'b10: begin
                    read_address_valid = 4'b0100;
                end
                2'b11: begin
                    read_address_valid = 4'b1000;
                end
                default:;
            endcase
        end
        if(req_mem_we) begin
            ram_extend_we = req_mem_valid;
        end
        else begin
            ram_extend_we = 4'b0000;
        end
    end

    Mem_Extend ram_extend (
        .mem_clk(mem_clk),
        .rst(rst),
        .we(ram_extend_we),
        .read_address_valid(read_address_valid),
        .read_address(ram_extend_read_address),
        .write_address(req_mem_addr),
        .data_in(req_mem_data),
        .data_out(ram_data_out)
    );


`ifdef I_CACHE_USE
    logic i_cache_read_allocate, rom_read;
    logic [31:0]rom_data_out;
    logic [10:0]rom_address;
    Cache i_cache(
        .clk(~cpu_clk),
        .rst(rst),
        .cache_write(),
        .cache_read(1'b1),
        .write_back(),
        .read_allocate(i_cache_read_allocate), // interact with memory
        .address(PC_Out[12:2]),
        .data_in(),
        .mem_data_out(rom_data_out),
        .debug_cache_index(),

        .data_out(Inst),
        .mem_address(rom_address),
        .mem_data_in(),
        .mem_read(rom_read),
        .mem_write(),
        .stall(i_cache_stall),
        .debug_cache_dirty(),
        .debug_cache_valid(),
        .debug_cache_tag(),
        .debug_cache_data()
    );
    
    Mem_Ctrl rom_ctrl(
        .cpu_clk(cpu_clk),
        .mem_clk(mem_clk),
        .rst(rst),
        .mem_read(rom_read),
        .mem_write(),
        .write_back(),
        .read_allocate(i_cache_read_allocate)
    );
`endif


`ifndef I_CACHE_USE
    Rom rom_unit (
        .clka(~cpu_clk),
        .addra(PC_Out[12:2]),
        .douta(Inst)
    );
`endif

`ifdef I_CACHE_USE
    Rom rom_unit (
        .clka(mem_clk),
        .addra(rom_address),
        .douta(rom_data_out)
    );
`endif

`ifndef MEM_EXTEND_USE
    Ram ram_unit (
       .clka(mem_clk),
       .wea(ram_write),
       .addra(ram_address),
       .dina(ram_data_in),
       .douta(ram_data_out)
    );
`endif

    assign chip_debug_out0 = PC_Out;
    assign chip_debug_out1 = Debug_Reg_Data;
    assign chip_debug_out2 = Addr_Out;
    // assign chip_debug_out2 = debug_d_cache_data;
    assign chip_debug_out3 = Inst;
    // assign chip_debug_out3 = {17'b0, debug_d_cache_index, debug_d_cache_tag, 2'b0, debug_d_cache_valid, debug_d_cache_dirty};

endmodule
