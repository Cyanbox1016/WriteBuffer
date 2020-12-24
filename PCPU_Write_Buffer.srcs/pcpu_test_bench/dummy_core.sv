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
        .write_back(d_cache_write_back), // interact with memory
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



    // logic mem_state, mem_ready;
    
    // localparam MEM_IDLE = 1'b0, MEM_WORK = 1'b1;
    // always_ff @(negedge cpu_clk) begin
    //     if(rst) mem_state <= MEM_IDLE;
    //     if(mem_write || mem_read) begin
    //         if(!mem_ready) mem_state <= MEM_WORK;
    //         else mem_state <= MEM_IDLE;
    //     end
    // end

    // logic cnt;
    // always_ff @(posedge mem_clk or posedge rst) begin
    //     if(rst) begin
    //         cnt <= 1'b0;
    //     end
    //     else begin
    //         if(mem_write || mem_read) begin
    //             if(cnt == 1'b1) begin
    //                 mem_ready <= 1'b1;
    //             end
    //             else begin
    //                 mem_ready <= 1'b0;
    //             end
    //             cnt <= cnt + 1;
    //         end
    //         else begin
    //             // mem_ready = 1'b1;
    //             mem_ready = 1'b0;
    //             cnt <= 1'b0;
    //         end
    //     end
    // end

    // assign write_back = !(mem_ready && mem_state == MEM_WORK);
    // assign read_allocate = !(mem_ready && mem_state == MEM_WORK);

    // Rom rom_unit (
    //     .clka(~cpu_clk),
    //     .addra(PC_Out[12:2]),
    //     .douta(Inst)
    // );

    Rom rom_unit (
        .clka(mem_clk),
        .addra(rom_address),
        .douta(rom_data_out)
    );
    
    Ram ram_unit (
       .clka(mem_clk),
       .wea(ram_write),
       .addra(ram_address),
       .dina(ram_data_in),
       .douta(ram_data_out)
    );


    assign chip_debug_out0 = PC_Out;
    assign chip_debug_out1 = Debug_Reg_Data;
    assign chip_debug_out2 = Addr_Out;
    // assign chip_debug_out2 = debug_d_cache_data;
    assign chip_debug_out3 = Inst;
    // assign chip_debug_out3 = {17'b0, debug_d_cache_index, debug_d_cache_tag, 2'b0, debug_d_cache_valid, debug_d_cache_dirty};

endmodule
