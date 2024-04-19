`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16
`define CLOCK_PD 20

module tb_QTableUpdate();

    reg clock, nrst, en;

    //Memory Module
    
    wire wr_en;
    wire [`WORD_WIDTH-1:0] mem_data_in, mem_data_out;
    wire [10:0] address;

    mem mem1(clock, address, wr_en, mem_data_in, mem_data_out);

    //QTableUpdate Module

    reg[`WORD_WIDTH-1:0] fSourceID, fEnergyLeft, fQValue, fclusterID;
    wire reinit, done;

    QTableUpdate qt1(clock, nrst, en, fSourceID, fEnergyLeft, fQValue, fclusterID, address, data_out, done);

    // Initial Values

    initial begin
        
    end