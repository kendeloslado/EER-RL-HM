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
(2/16)  [0x12 - 0x31]           knownClusterHead        (9-24)
(2/16)  [0x32 - 0x51]           numberOfHops            (25-40)
(2/16)  [0x51 - 0x72]           chQValue                (41-56)
(2/32)  [0x72 - 0xB1]           neighborID              (57-88)
(2/32)  [0xB2 - 0xF1]           clusterID               (89-120)
(2/32)  [0xF2 - 0x131]          energyLeft              (121-152)
(2/32)  [0x132 - 0x171]         neighborQValue          (153-164)
(2/8*32)[0x172 - 0x271]         chIDs                   (165-420)
(2/1)   [0x272 - 0x273]         knownCHcount            (421)
(2/1)   [0x274 - 0x275]         neighborCount           (422)
(2/1)   [0x276 - 0x277]         chosenClusterHead       (423)
(2/32)  [0x278 - 0x2B7]         chIDCount               (424-455)
*/
/*
(2/4)   [0x0 - 0x7]             Internal Flags          (0-3)
(2/1)   [0x8 - 0x9]             nodeID                  (4)
(2/1)   [0xA - 0xB]             nodeEnergy              (5)
(2/1)   [0xC - 0xD]             nodeQValue              (6)
(2/1)   [0xE - 0xF]             deadNodes               (7)
(2/1)   [0x10 - 0x11]           energyThreshold         (8)
(2/16)  [0x12 - 0x31]           knownClusterHead        (9-24)
(2/16)  [0x32 - 0x51]           numberOfHops            (25-40)
(2/16)  [0x51 - 0x72]           chQValue                (41-56)
(2/32)  [0x72 - 0xB1]           neighborID              (57-88)
(2/32)  [0xB2 - 0xF1]           clusterID               (89-120)
(2/32)  [0xF2 - 0x131]          energyLeft              (121-152)
(2/32)  [0x132 - 0x171]         neighborQValue          (153-184)
(2/32)  [0x172 - 0x1B1]         neighborHops            (185-216)
(2/8*32)[0x1B2 - 0x2B1]         chIDs                   (217-472)
(2/1)   [0x2B2 - 0x2B3]         knownCHcount            (473)
(2/1)   [0x2B4 - 0x2B5]         neighborCount           (474)
(2/1)   [0x2B6 - 0x2B7]         chosenClusterHead       (475)
(2/32)  [0x2B8 - 0x2F7]         chIDCount               (476-507)
*/
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
        
// update: 2:49PM 19/03/2024
/*
neighborID, clusterID, energyLeft, neighborQValue, chIDs, neighborCount, 
chIDcount not added yet
*/        
        // this part is for preloading memory with existing data 
        /*FLAGS
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
        
        memory['hC] = 8'h0A;
        memory['hD] = 8'hAB;    // Q-value = 0.1667
        
        memory['hE] = 0;
        memory['hF] = 0;        // deadNodes = 0
        
        memory['h10] = 8'h33;
        memory['h11] = 8'h33;   // energyThreshold = 0.8
        */
        /*
        
        knownClusterHeads
        
        memory['h12 + 0] = 8'h10;
        memory['h12 + 1] = 8'h00;       //chID = 16;
        
        memory['h12 + 2] = 8'h63;
        memory['h12 + 3] = 8'h00;       //chID = 99;
        
        memory['h12 + 4] = 8'h03;
        memory['h12 + 5] = 8'h00;       //chID = 3;
        
        memory['h12 + 6] = 8'h6;
        memory['h12 + 7] = 8'h00;       //chID = 6
        
        memory['h12 + 8] = 8'h09;
        memory['h12 + 9] = 8'h00;      //chID = 9;
        
        memory['h12 + 10] = 8'h0D;       
        memory['h12 + 11] = 8'h00;       //chID = 13;
        
        memory['h12 + 12] = 8'h13;
        memory['h12 + 13] = 8'h00;      //chID = 19;
        
        memory['h12 + 14] = 8'h15;
        memory['h12 + 15] = 8'h00;      //chID = 21;
        
        memory['h12 + 16] = 8'h1C;
        memory['h12 + 17] = 8'h00;      //chID = 28;
        
        memory['h12 + 18] = 8'h1E;
        memory['h12 + 19] = 8'h00;      //chID = 30;
        
        */
        /*
        numberOfHops
        
        memory['h32 + 0] = 1;
        memory['h32 + 1] = 0;
        
        memory['h32 + 2] = 2;
        memory['h32 + 3] = 0;
        
        memory['h32 + 4] = 2;
        memory['h32 + 5] = 0;
        
        memory['h32 + 6] = 2;
        memory['h32 + 7] = 0;
        
        memory['h32 + 8] = 2;
        memory['h32 + 9] = 0;
        
        memory['h32 + 10] = 2;
        memory['h32 + 11] = 0;
        
        memory['h32 + 12] = 2;
        memory['h32 + 13] = 0;
        
        memory['h32 + 14] = 2;
        memory['h32 + 15] = 0;
        
        memory['h32 + 16] = 2;
        memory['h32 + 17] = 0;
        
        memory['h32 + 18] = 2;
        memory['h32 + 19] = 0;
        
        */
        
        /*
        chQValue
       
        memory['h52 + 0] = 8'h10;
        memory['h52 + 1] = 8'h00;               // Q = 1.0
        
        memory['h52 + 2] = 8'h0C;
        memory['h52 + 3] = 8'h00;               // Q = 0.75
        
        memory['h52 + 4] = 8'h0C;
        memory['h52 + 5] = 8'h00;               // Q = 0.75
        
        memory['h52 + 6] = 8'h0C;
        memory['h52 + 7] = 8'h00;               // Q = 0.75
        
        memory['h52 + 8] = 8'h0C;
        memory['h52 + 9] = 8'h00;               // Q = 0.75
        
        memory['h52 + 10] = 8'h0C;
        memory['h52 + 11] = 8'h00;               // Q = 0.75
        
        memory['h52 + 12] = 8'h0C;
        memory['h52 + 13] = 8'h00;               // Q = 0.75
        
        memory['h52 + 14] = 8'h0C;
        memory['h52 + 15] = 8'h00;               // Q = 0.75
        
        memory['h52 + 16] = 8'h0C;
        memory['h52 + 17] = 8'h00;               // Q = 0.75
        
        memory['h52 + 18] = 8'h0C;
        memory['h52 + 19] = 8'h00;               // Q = 0.75
        
        */
        
        /*
        //neighborID
        
        memory['h72 + 0] = ;
        memory['h72 + 1] = ;
        
        memory['h72 + 2] = ;
        memory['h72 + 3] = ;
        
        memory['h72 + 4] = ;
        memory['h72 + 5] = ;
        
        memory['h72 + 6] = ;
        memory['h72 + 7] = ;
        
        memory['h72 + 8] = ;
        memory['h72 + 9] = ;
        
        memory['h72 + 10] = ;
        memory['h72 + 11] = ;
        
        memory['h72 + 12] = ;
        memory['h72 + 13] = ;
        
        memory['h72 + 14] = ;
        memory['h72 + 15] = ;
        
        memory['h72 + 16] = ;
        memory['h72 + 17] = ;
        
        memory['h72 + 18] = ;
        memory['h72 + 19] = ;
        
        memory['h72 + 20] = ;
        memory['h72 + 21] = ;
        
        memory['h72 + 22] = ;
        memory['h72 + 23] = ;
        
        memory['h72 + 24] = ;
        memory['h72 + 25] = ;
        
        memory['h72 + 26] = ;
        memory['h72 + 27] = ;
        
        memory['h72 + 28] = ;
        memory['h72 + 29] = ;
        
        memory['h72 + 30] = ;
        memory['h72 + 31] = ;
        
        memory['h72 + 32] = ;
        memory['h72 + 33] = ;
        
        memory['h72 + 34] = ;
        memory['h72 + 35] = ;
        
        memory['h72 + 36] = ;
        memory['h72 + 37] = ;
        
        memory['h72 + 38] = ;
        memory['h72 + 39] = ;
        
        memory['h72 + 40] = ;
        memory['h72 + 41] = ;
        
        memory['h72 + 42] = ;
        memory['h72 + 43] = ;
        
        memory['h72 + 44] = ;
        memory['h72 + 45] = ;
        
        memory['h72 + 46] = ;
        memory['h72 + 47] = ;
        
        memory['h72 + 48] = ;
        memory['h72 + 49] = ;
        
        memory['h72 + 50] = ;
        memory['h72 + 51] = ;
        
        memory['h72 + 52] = ;
        memory['h72 + 53] = ;
        
        memory['h72 + 54] = ;
        memory['h72 + 55] = ;
        
        memory['h72 + 56] = ;
        memory['h72 + 57] = ;
        
        memory['h72 + 58] = ;
        memory['h72 + 59] = ;
        
        memory['h72 + 60] = ;
        memory['h72 + 61] = ;
        
        memory['h72 + 62] = ;
        memory['h72 + 63] = ;
        
        */
        
        /*
        //clusterID
        
        memory['hB2 + 0] = ;
        memory['hB2 + 1] = ;
        
        memory['hB2 + 2] = ;
        memory['hB2 + 3] = ;
        
        memory['hB2 + 4] = ;
        memory['hB2 + 5] = ;
        
        memory['hB2 + 6] = ;
        memory['hB2 + 7] = ;
        
        memory['hB2 + 8] = ;
        memory['hB2 + 9] = ;
        
        memory['hB2 + 10] = ;
        memory['hB2 + 11] = ;
        
        memory['hB2 + 12] = ;
        memory['hB2 + 13] = ;
        
        memory['hB2 + 14] = ;
        memory['hB2 + 15] = ;
        
        memory['hB2 + 16] = ;
        memory['hB2 + 17] = ;
        
        memory['hB2 + 18] = ;
        memory['hB2 + 19] = ;
        
        memory['hB2 + 20] = ;
        memory['hB2 + 21] = ;
        
        memory['hB2 + 22] = ;
        memory['hB2 + 23] = ;
        
        memory['hB2 + 24] = ;
        memory['hB2 + 25] = ;
        
        memory['hB2 + 26] = ;
        memory['hB2 + 27] = ;
        
        memory['hB2 + 28] = ;
        memory['hB2 + 29] = ;
        
        memory['hB2 + 30] = ;
        memory['hB2 + 31] = ;
        
        memory['hB2 + 32] = ;
        memory['hB2 + 33] = ;
        
        memory['hB2 + 34] = ;
        memory['hB2 + 35] = ;
        
        memory['hB2 + 36] = ;
        memory['hB2 + 37] = ;
        
        memory['hB2 + 38] = ;
        memory['hB2 + 39] = ;
        
        memory['hB2 + 40] = ;
        memory['hB2 + 41] = ;
        
        memory['hB2 + 42] = ;
        memory['hB2 + 43] = ;
        
        memory['hB2 + 44] = ;
        memory['hB2 + 45] = ;
        
        memory['hB2 + 46] = ;
        memory['hB2 + 47] = ;
        
        memory['hB2 + 48] = ;
        memory['hB2 + 49] = ;
        
        memory['hB2 + 50] = ;
        memory['hB2 + 51] = ;
        
        memory['hB2 + 52] = ;
        memory['hB2 + 53] = ;
        
        memory['hB2 + 54] = ;
        memory['hB2 + 55] = ;
        
        memory['hB2 + 56] = ;
        memory['hB2 + 57] = ;
        
        memory['hB2 + 58] = ;
        memory['hB2 + 59] = ;
        
        memory['hB2 + 60] = ;
        memory['hB2 + 61] = ;
        
        memory['hB2 + 62] = ;
        memory['hB2 + 63] = ;
        
        */
        
        /*
        //energyLeft 
        
        memory['hF2 + 0] = ;
        memory['hF2 + 1] = ;
        
        memory['hF2 + 2] = ;
        memory['hF2 + 3] = ;
        
        memory['hF2 + 4] = ;
        memory['hF2 + 5] = ;
        
        memory['hF2 + 6] = ;
        memory['hF2 + 7] = ;
        
        memory['hF2 + 8] = ;
        memory['hF2 + 9] = ;
        
        memory['hF2 + 10] = ;
        memory['hF2 + 11] = ;
        
        memory['hF2 + 12] = ;
        memory['hF2 + 13] = ;
        
        memory['hF2 + 14] = ;
        memory['hF2 + 15] = ;
        
        memory['hF2 + 16] = ;
        memory['hF2 + 17] = ;
        
        memory['hF2 + 18] = ;
        memory['hF2 + 19] = ;
        
        memory['hF2 + 20] = ;
        memory['hF2 + 21] = ;
        
        memory['hF2 + 22] = ;
        memory['hF2 + 23] = ;
        
        memory['hF2 + 24] = ;
        memory['hF2 + 25] = ;
        
        memory['hF2 + 26] = ;
        memory['hF2 + 27] = ;
        
        memory['hF2 + 28] = ;
        memory['hF2 + 29] = ;
        
        memory['hF2 + 30] = ;
        memory['hF2 + 31] = ;
        
        memory['hF2 + 32] = ;
        memory['hF2 + 33] = ;
        
        memory['hF2 + 34] = ;
        memory['hF2 + 35] = ;
        
        memory['hF2 + 36] = ;
        memory['hF2 + 37] = ;
        
        memory['hF2 + 38] = ;
        memory['hF2 + 39] = ;
        
        memory['hF2 + 40] = ;
        memory['hF2 + 41] = ;
        
        memory['hF2 + 42] = ;
        memory['hF2 + 43] = ;
        
        memory['hF2 + 44] = ;
        memory['hF2 + 45] = ;
        
        memory['hF2 + 46] = ;
        memory['hF2 + 47] = ;
        
        memory['hF2 + 48] = ;
        memory['hF2 + 49] = ;
        
        memory['hF2 + 50] = ;
        memory['hF2 + 51] = ;
        
        memory['hF2 + 52] = ;
        memory['hF2 + 53] = ;
        
        memory['hF2 + 54] = ;
        memory['hF2 + 55] = ;
        
        memory['hF2 + 56] = ;
        memory['hF2 + 57] = ;
        
        memory['hF2 + 58] = ;
        memory['hF2 + 59] = ;
        
        memory['hF2 + 60] = ;
        memory['hF2 + 61] = ;
        
        memory['hF2 + 62] = ;
        memory['hF2 + 63] = ;
        
        
        */
        
        /*
        //neighborQValue
        
        memory['h132 + 0] = ;
        memory['h132 + 1] = ;
        
        memory['h132 + 2] = ;
        memory['h132 + 3] = ;
        
        memory['h132 + 4] = ;
        memory['h132 + 5] = ;
        
        memory['h132 + 6] = ;
        memory['h132 + 7] = ;
        
        memory['h132 + 8] = ;
        memory['h132 + 9] = ;
        
        memory['h132 + 10] = ;
        memory['h132 + 11] = ;
        
        memory['h132 + 12] = ;
        memory['h132 + 13] = ;
        
        memory['h132 + 14] = ;
        memory['h132 + 15] = ;
        
        memory['h132 + 16] = ;
        memory['h132 + 17] = ;
        
        memory['h132 + 18] = ;
        memory['h132 + 19] = ;
        
        memory['h132 + 20] = ;
        memory['h132 + 21] = ;
        
        memory['h132 + 22] = ;
        memory['h132 + 23] = ;
        
        memory['h132 + 24] = ;
        memory['h132 + 25] = ;
        
        memory['h132 + 26] = ;
        memory['h132 + 27] = ;
        
        memory['h132 + 28] = ;
        memory['h132 + 29] = ;
        
        memory['h132 + 30] = ;
        memory['h132 + 31] = ;
        
        memory['h132 + 32] = ;
        memory['h132 + 33] = ;
        
        memory['h132 + 34] = ;
        memory['h132 + 35] = ;
        
        memory['h132 + 36] = ;
        memory['h132 + 37] = ;
        
        memory['h132 + 38] = ;
        memory['h132 + 39] = ;
        
        memory['h132 + 40] = ;
        memory['h132 + 41] = ;
        
        memory['h132 + 42] = ;
        memory['h132 + 43] = ;
        
        memory['h132 + 44] = ;
        memory['h132 + 45] = ;
        
        memory['h132 + 46] = ;
        memory['h132 + 47] = ;
        
        memory['h132 + 48] = ;
        memory['h132 + 49] = ;
        
        memory['h132 + 50] = ;
        memory['h132 + 51] = ;
        
        memory['h132 + 52] = ;
        memory['h132 + 53] = ;
        
        memory['h132 + 54] = ;
        memory['h132 + 55] = ;
        
        memory['h132 + 56] = ;
        memory['h132 + 57] = ;
        
        memory['h132 + 58] = ;
        memory['h132 + 59] = ;
        
        memory['h132 + 60] = ;
        memory['h132 + 61] = ;
        
        memory['h132 + 62] = ;
        memory['h132 + 63] = ;
        
        */
        /*
        //knownCHCount
        
        memory['h272 + 0] = 8'h0A;
        memory['h272 + 1] = 8'h00;              //10 CHs
        
        //neighborCount
        
        memory['h274 + 0] = ;
        memory['h274 + 1] = ;
        
        //chosenClusterHead
        
        memory['h276 + 0] = 8'h63;
        memory['h276 + 1] = 8'h00;              // CHID = 99;
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
