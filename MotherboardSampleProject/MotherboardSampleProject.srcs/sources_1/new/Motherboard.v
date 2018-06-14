`timescale 1ns / 1ps
`default_nettype none

//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 11/25/2017 05:38:31 PM
// Design Name:
// Module Name: Motherboard
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

module CLOCK_GENERATOR #(parameter DIVIDE = 2)
(
    input  wire rst,
    input  wire fast_clk,
    output reg  slow_clk
);

reg [31:0] counter = 0;

always @(posedge fast_clk or posedge rst)
begin
    if(rst)
    begin
        slow_clk <= 0;
        counter <= 0;
    end
    else
    begin
        if(counter == DIVIDE/2)
        begin
            slow_clk <= ~slow_clk;
            counter <= 0;
        end
        else
        begin
            slow_clk <= slow_clk;
            counter <= counter + 1;
        end
    end
end

endmodule

module Motherboard #(parameter CLOCK_DIVIDER = 100)
(
    //// input 100 MHz clock
    input  wire        clk100Mhz,
    input  wire        rst,
    input  wire [15:0] switches,
    output wire [15:0] led
);

// ==================================
//// Internal Parameter Field
// ==================================
parameter ROM_SIZE      = 32'h400/4;
`define ROM_PC_RANGE    ($clog2(ROM_SIZE)+2):2
// ==================================
//// Wires
// ==================================
//// Clock Signals
wire cpu_clk;
//// CPU Signals
wire [31:0] AddressBus, DataBus;
wire [31:0] ProgramCounter, ALUResult, RegOut1, RegOut2, RegWriteData, RegWriteAddress;
wire [31:0] Instruction;
wire [3:0]  MemWrite;
wire MemRead, BusCycle;
//// Address Decoding Signals
wire cs_ram;
wire cs_io;

wire cs_input0;
wire cs_input1;
wire cs_output0;
wire cs_output1;

// ==================================
//// Wire Assignments
// ==================================
// ==================================
//// Modules
// ==================================
CLOCK_GENERATOR #(
    .DIVIDE                     (CLOCK_DIVIDER)
) clock (
    .rst                        (rst),
    .fast_clk                   (clk100Mhz),
    .slow_clk                   (cpu_clk)
);

ROM #(
    .LENGTH                     (ROM_SIZE),
    .WIDTH                      (32),
    .FILE_NAME                  ("rom.mem")
) rom (         
    .a                          (ProgramCounter[`ROM_PC_RANGE]),
    .out                        (Instruction)
);

MIPS mips(
    .clk                        (cpu_clk),
    .rst                        (rst),
    .BusCycle                   (BusCycle),
    .MemWrite                   (MemWrite),
    .MemRead                    (MemRead),
    .AddressBus                 (AddressBus),
    .DataBus                    (DataBus),
    .ProgramCounter             (ProgramCounter),
    .ALUResult                  (ALUResult),
    .RegOut1                    (RegOut1),
    .RegOut2                    (RegOut2),
    .RegWriteData               (RegWriteData),
    .RegWriteAddress            (RegWriteAddress),
    .Instruction                (Instruction)
);

RAM #(
    .LENGTH                     (32'h1000/4),
    .USE_FILE                   (1),
    .WIDTH                      (32),
    .MINIMUM_SECTIONAL_WIDTH    (8),
    .FILE_NAME                  ("ram.mem")
) ram (
    .clk                        (cpu_clk),
    .we                         (MemWrite),
    .cs                         (cs_ram),
    .oe                         (MemRead),
    .address                    (AddressBus[11:2]),
    .data                       (DataBus)
);

wire MemWriteEnable;
AND #(
    .WIDTH                      (4)
) we_and (
    .in                         (MemWrite),
    .out                        (MemWriteEnable)
);

// Address Decoding
wire full_addr_dec_out;

NAND #(
    .WIDTH                      (19)
) full_addr_dec_and (
    .in                         (AddressBus[31:13]),
    .out                        (full_addr_dec_out)
);

AND #(
    .WIDTH                      (2)
) cs_ram_and (
    .in                         ({full_addr_dec_out, ~AddressBus[12]}),
    .out                        (cs_ram)
);

AND #(
    .WIDTH                      (2)
) cs_io_and (
    .in                         ({full_addr_dec_out, AddressBus[12]}),
    .out                        (cs_io)
);

wire [3:0] io_addr_dec_out;

DECODER #(
    .INPUT_WIDTH                (2)
) io_address_decoder
(
    .enable                     (cs_io),
    .in                         (AddressBus[3:2]),
    .out                        (io_addr_dec_out)
);

AND #(
    .WIDTH                      (2)
) cs_input0_and (
    .in                         ({MemRead, io_addr_dec_out[0]}),
    .out                        (cs_input0)
);

AND #(
    .WIDTH                      (2)
) cs_input1_and (
    .in                         ({MemRead, io_addr_dec_out[1]}),
    .out                        (cs_input1)
);

AND #(
    .WIDTH                      (2)
) cs_output0_and (
    .in                         ({MemWriteEnable, io_addr_dec_out[2]}),
    .out                        (cs_output0)
);

AND #(
    .WIDTH                      (2)
) cs_output1_and (
    .in                         ({MemWriteEnable, io_addr_dec_out[3]}),
    .out                        (cs_output1)
);

TRIBUFFER #(
    .WIDTH(32)
) input0 (
    .oe                         (cs_input0),
    .in                         ({16'b0, switches}),
    .out                        (DataBus)
);

TRIBUFFER #(
    .WIDTH(32)
) input1 (
    .oe                         (cs_input1),
    .in                         (32'b0),
    .out                        (DataBus)
);

REGISTER #(
    .WIDTH                      (32)
) output0 (
    .rst                        (rst),
    .clk                        (cpu_clk),
    .load                       (cs_output0),
    .D                          (DataBus),
    .Q                          (led[15:0])
);

REGISTER #(
    .WIDTH                      (32)
) output1 (
    .rst                        (rst),
    .clk                        (cpu_clk),
    .load                       (cs_output1),
    .D                          (DataBus),
    .Q                          ()
);

endmodule