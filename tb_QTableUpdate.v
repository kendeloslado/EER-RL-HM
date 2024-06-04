`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16
`define clk_PD 20

module tb_QTableUpdate();

    reg clk, nrst, en;

    //Memory Module
    
    wire wr_en;
    wire [`WORD_WIDTH-1:0] mem_data_in, mem_data_out;
    wire [10:0] address;

    mem mem1(clk, address, wr_en, mem_data_in, mem_data_out);

    //QTableUpdate Module

    reg[`WORD_WIDTH-1:0] fSourceID, fEnergyLeft, fQValue, fclusterID;
    wire reinit, done;

    QTableUpdate qt1(clk, nrst, en, fSourceID, fEnergyLeft, fQValue, fclusterID, address, data_out, done);

    // Initial Values

    initial begin
    // add new neighbour.
        fSourceID = 11;
        fEnergyLeft = 2;
        fQValue = 0.75;
        fclusterID = 2;
    end

    // clk
    initial begin
        clk = 0
        forever #10 clk = ~clk;
    end

    // Reset

    initial begin
        en = 0;
        nrst = 1;
        #5 nrst = 0;
        #10 nrst = 1;
        #50
        en = 1;
        #20
        en = 0;
        #
    end
    // Write waveform
    initial begin
        $vcdplusfile("tb_learnCosts.vpd"); //$dumpfile("tb_randomGenerator.vcd");
        $vcdpluson;
	    $sdf_annotate("../mapped/learnCosts.sdf", learnCosts);
	    //$dumpvars(0, tb_randomGenerator);
        #1200
        $finish;
    end