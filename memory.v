`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

/*
Address List 

(2/4)   [0x0 - 0x7]             Internal Flags          (0-3)
(2/1)   [0x8 - 0x9]             nodeID                  (4)
(2/1)   [0xA - 0xB]             nodeEnergy              (5)
(2/1)   [0xC - 0xD]             nodeQValue              (6)
(2/1)   [0xE - 0xF]             deadNodes               (7)
(2/1)   [0x10 - 0x11]           energyThreshold         (8)
(2/16)  [0x12 - 0x21]           knownClusterHead        (9-24)
(2/16)  [0x22 - 0x31]           numberOfHops            (25-40)
(2/16)  [0x31 - 0x42]           chQValue                (41-56)
(2/32)  [0x42 - 0x61]           neighborID              (57-88)
(2/32)  [0x62 - 0x81]           clusterID               (89-120)
(2/32)  [0x82 - 0xA1]           energyLeft              (121-152)
(2/32)  [0xA2 - 0xC1]           neighborQValue          (153-164)
(2/8*32)[0xC2 - 0x191]          chIDs                   (165-420)
(2/1)   [0x192 - 0x193]         knownCHcount            (421)
(2/1)   [0x194 - 0x195]         neighborCount           (422)
(2/1)   [0x196 - 0x197]         chosenClusterHead       (423)
(2/32)  [0x198 - 0x1B7]         chIDCount               (424-455)

Internal Flags

        [0x0]                   hopsFromSink
        [0x1[7]]                role
        [0x1[6]]                forAggregation
        [0x1[5]]                forSOS
        [0x1[4]]                forMR
        [0x1[3]]                forHB
        [0x1[2]]                forCHM
        [0x1[1]]                communicationMode
        [0x2]                   prev
        [0x3 - 0x4]             dest
        [0x5]                   timeslotTDMA
        [0x6 - 0x7]             sinkID
*/


module memory(clock, address, wr_en, data_in, data_out);

        input clock, wr_en;
        input [10:0] address;
        input [`WORD_WIDTH-1:0] data_in;
        input [`WORD_WIDTH-1:0] data_out;

// initialize memory array
        reg [`MEM_WIDTH-1:0] memory [0: `MEM_DEPTH-1];
        
//  initialize with zeros
        integer i;
        initial begin
                for(i = 0; i < `MEM_DEPTH; i = i + 1) begin
                        memory[i] = 0;
                end
        
        
/*
        this part is for preloading memory with existing data 
        //FLAGS
        memory['h0] = 2;
        memory['h1] = 4'b0000;  // not a cluster head, not for aggregation, SOS not needed, sinkID 0
        
        memory['h2] = 0;
        
        memory['h3] = 8'h63;    // cluster head choose node #99
        memory['h4] = 0;    
        
        memory['h5] = 1;        // TDMA timeslot
        
        memory['h6] = 0;        // sinkID
        memory['h7] = 0;
        
        memory['h8] = 11;       // nodeID
        memory['h9] = 0;
        
        memory['hA] = 8'h40;    // energy = 1.00;
        memory['hB] = 8'h0;    
        
        memory['hC] = 8'h02;
        memory['hD] = 8'hAB;    // Q-value = 0.1667
        
        memory['hE] = 0;
        memory['hF] = 0;        // deadNodes = 0
        
*/
        end

        // reading port
        reg [`WORD_WIDTH-1:0] data_out_buffer;
        
        always@(*)
                data_out_buffer <= {memory[address], memory[address+1]};
        
        
        assign data_out = data_out_buffer;
        
        
        always@(posedge clock) begin
                if(wr_en) begin
                        memory[address] = data_in[15:8];
                        memory[address+1] = data_in[7:0];
                end        
        end
endmodule
