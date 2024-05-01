`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

module findMyBest(clock, nrst, en, start, data_in, MY_BATTERY_STAT, address, wr_en, data_out, mybest, done);

input clock, nrst, en, start;
input [`WORD_WIDTH-1:0] data_in;
input [`WORD_WIDTH-1:0] MY_BATTERY_STAT;
