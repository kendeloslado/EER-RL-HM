`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.03.2024 14:51:39
// Design Name: 
// Module Name: learnCosts
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

module QTableUpdate(clock, nrst, en, data_in, fSourceID, fEnergyLeft, fQValue, fClusterID, fSourceHops, address, data_out, done);
        input                           clock;
        input                           nrst;
        input                           en;
        //input                           start;
        input   [`WORD_WIDTH-1:0]       data_in;
        input   [`WORD_WIDTH-1:0]       fSourceID;
        input   [`WORD_WIDTH-1:0]       fEnergyLeft;
        input   [`WORD_WIDTH-1:0]       fQValue;
        input   [`WORD_WIDTH-1:0]       fClusterID;
        input   [`WORD_WIDTH-1:0]       fSourceHops;
        output  [10:0]                  address;
        output  [`WORD_WIDTH-1:0]       data_out;
        output                          done;
        
        // Registers
        reg [10:0] address_count;
        reg [`WORD_WIDTH-1:0] data_out_buf, neighborCount, knownCHcount, cur_nID, cur_knownCH, cur_qValue, cur_nHops, chID_address_buf;
        reg done_buf, found, reinit, wr_en_buf;
        reg [`WORD_WIDTH-1:0] n, k;
        reg [4:0] state; 
        
        // Parameters

        
        parameter s_idle = 5'd0;
        parameter s_start= 5'd1;
        parameter s_neighborCount = 5'd2;
        parameter s_knownCHcount = 5'd3;
        parameter s_checknID = 5'd4;
        parameter s_findnID = 5'd5;
        parameter s_foundnID = 5'd6;
        parameter s_checkKCH = 5'd7;
        parameter s_incrementK = 5'd8;
        parameter s_updateEnergy = 5'd9;
        parameter s_updateHop = 5'd10;
        parameter s_setQValueAddr = 5'd11;
        parameter s_updateQValue = 5'd12;
        parameter s_updatedone = 5'd13;
        parameter s_addnH = 5'd14;
        parameter s_addfEL = 5'd15;
        parameter s_addnH = 5'd16;
        parameter s_addnQ = 5'd17;
        parameter s_addcluster = 5'd18;
        parameter s_KCH2 = 5'd19;
        parameter s_checkKCH2 = 5'd20;
        parameter s_incrementK2 = 5'd21;
        parameter s_incrementnC = 5'd22;
        parameter s_wren_zero = 5'd23;
        parameter s_done = 5'd24;

        
        
/*
        Some notes on reading and writing from memory
        
        You will use data_in to write into various registers in the program flow proper
        
        address_count will be used to navigate through memory, address_count will help 
        output the correct data_in to respective registers
        
        Registers will be the following:
        address_count -> assigned to output address
        data_out_buf -> output data for stoof
        neighborCount -> index for neighborID list
        knownCHcount -> index for knownCHs list
        cur_nID -> current node ID
        cur_knownCH -> current known cluster head
        cur_qValue -> current Q-value
        done_buf -> buffer for the done signal
        found ->  binary flag to indicate an entry is found in the table
        reinit -> used for comparing some qValues and initial epsilon
        (this is from CLIQUE, could be removed)
        wr_en_buf ->  signal to enable writing to memory
        n -> this is essentially a counter to navigate indexes for neighbor nodes
        k -> counter to navigate knownCH indexes
*/
        
        // Program Flow Proper
 /*       
        always@(posedge clock) begin
                if(!nrst) begin
                        done_buf <= 0;
                        address_count <= 0;
                        state <= 22;
                        wr_en_buf <= 0;
                        data_out_buf <= 0;
                        neighborCount <= 0;
                        knownCHcount <= 0;
                        cur_nID <= 0;
                        cur_knownCH <= 0;
                        cur_qValue <= 0;
                        cur_nHops <= 0;
                        found <= 0;
                        reinit <= 0;
                        wr_en_buf <= 0;
                end
                else begin
                        case (state) 
                                0: begin        // neighborCount index
                                        state <= 1;
                                        address_count <= 11'h274; //neighborCount address
                                end
                                1: begin        // write to memory neighborCount, change index to knownCHcount
                                        neighborCount <= data_in;
                                        state <= 2;
                                        address_count <= 11'h272; //knownCHcount address
                                end
                                2: begin        // write to memory knownCHcount
                                        knownCHcount <= data_in;
                                        state <= 3;
                                end
                                3: begin
                                        // if not found, add a new neighbor in the entry
                                        if (n == neighborCount)
                                                state <= 12; // add a new neighbor state
                                        else   begin
                                                address_count <= 11'h72 + 2*n; //neighborID address
                                                state <= 4;
                                        end
                                end
                                4: begin
                                        cur_nID = data_in;      // current neighborID

                                        // if found == 1, update Q-table values
                                        if (curnID == fSourceID) begin
                                                found <= 1;
                                                state <= 5;

                                                chID_address_buf =  16'h172 + 16*n;
                                        end
                                        else begin      // check next entry
                                                n = n + 1;
                                                state <= 3;
                                        end
                                end
                                5: begin
                                        if (k == knownCHcount) begin
                                                data_out_buf = k;
                                                address_count <= 11'h278 + 2*k; //chIDcount address
                                                wr_en_buf <= 1;
                                                state <= 8;
                                        end
                                        else begin
                                                address_count <= 11'h12 + 2*k
                                                state <= 6;
                                        end
                                end
                                6: begin
                                         cur_knownCH = data_in; // current knownCH
                                         data_out_buf = cur_knownCH;
                                         address_count <= chID_address_buf + k*2;
                                         wr_en_buf <= 1;
                                         state <= 7;
                                end
                                7: begin        // increment knownCH counter
                                        wr_en_buf <= 0;
                                        k = k + 1;
                                        state <= 5;
                                end
                                8: begin        // write energyLeft
                                        data_out_buf <= fEnergyLeft;
                                        address_count <= 11'hF2 + n*2; // fEnergyLeft address
                                        wr_en_buf <= 1;                
                                        state <= 9;
                                end
                                9: begin        // write qValue
                                        wr_en_buf <= 0;
                                        address_count <= 11'h52 + n*2; // chQValue address
                                        state <= 10;
                                end
                                10: begin
                                        cur_qValue = data_in;
                                        data_out_buf = cur_qValue;
                                        wr_en_buf <= 1;

                                        if (cur_qValue < fQValue)
                                                reinit <= 1;
                                        else
                                                reinit <= 0;

                                        state <= 11;
                                end
                                11: begin
                                        if(found) begin
                                                if(reinit) begin
                                                        state <= 20 
                                                end
                                                else
                                                        state <= 21;

                                        end
                                        else
                                                state <= 21;
                                end
                                12: begin
                                        address_count <= 11'h72 + neighborCount*2; // neighborID address
                                        data_out_buf <= fSourceID;
                                        wr_en_buf <= 1;
                                        state <= 13;
                                end
                                13: begin
                                        address_count <= 11'hF2 + neighborCount*2; // energyLeft address
                                        data_out_buf <= fEnergyLeft;
                                        wr_en_buf <= 1;
                                        state <= 14;
                                end
                                14: begin
                                        address_count <= 11'h132 + neighborCount*2; // neighborQValue address
                                        data_out_buf <= fQValue;
                                        wr_en_buf <= 1;
                                        state <= 15;
                                end
                                15: begin
                                        address_count <= 11'hB2 + neighborCount*2; // clusterID address
                                        data_out_buf <= fClusterID;
                                        wr_en_buf <= 1;
                                        k = 0;

                                        chID_address_buf =  16'h172 + 16*neighborCount;

                                        state <= 16;
                                end
                                16: begin
                                        if(k == knownCHcount) begin
                                                state <= 19;
                                                address_count <= 11'h278 + 2*neighborCount; // chIDCount address
                                                data_out_buf = k;
                                                wr_en_buf <= 1;
                                        end
                                        else begin
                                                address_count <= 11'h12 + 2*k; //knownCH address
                                                state <= 17;
                                        end
                                end
                                17: begin
                                        cur_knownCH = data_in;
                                        data_out_buf = cur_knownCH;
                                        address_count <= chID_address_buf + k*2; // knownCHcount address
                                        wr_en_buf <= 1;
                                        state <= 18;
                                end
                                18: begin
                                        wr_en_buf <= 0;
                                        k = k + 1;
                                        state <= 16;
                                end
                                19: begin
                                        data_out_buf = neighborCount + 1;
                                        address_count <= 11'h274;
                                        wr_en_buf <= 1;
                                        state <= 20;
                                end
                                20: begin
                                        wr_en_buf <= 0;
                                        state <= 21;
                                end
                                21: begin
                                        done_buf <= 1;
                                        state <= 22;
                                end
                                22: begin       //idle 
                                        if(en) begin
                                                done_buf <= 0;
                                                address_count <= 0;
                                                state <= 0;
                                                wr_en_buf <= 0;
                                                data_out_buf = 0;
                                                neighborCount <= 0;
                                                knownCHcount <= 0;
                                                cur_nID <= 0;
                                                cur_knownCH <= 0;
                                                cur_qValue <= 0;
                                                found <= 0;
                                                reinit <= 0;
                                                wr_en_buf <= 0;
                                                cur_nID = 16'h2b8;
                                                cur_knownCH = 16'h2b8;
                                                cur_qValue = 16'd0;
                                                chID_address_buf = 0;
                                                data_out_buf = 0;
                                                n = 0;
                                                k = 0;
                                        end
                                        else begin
                                                state <= s_idle;
                                        end
                                end

                                default: state <= 22;
                        endcase
                end
        end
*/
        always@(posedge clock) begin
                if(!nrst) begin
                        done_buf <= 0;
                        address_count <= 0;
                        state <= s_idle;
                        wr_en_buf <= 0;
                        data_out_buf <= 0;
                        neighborCount <= 0;
                        knownCHcount <= 0;
                        cur_nID <= 0;
                        cur_knownCH <= 0;
                        cur_qValue <= 0;
                        cur_nHops <= 0;
                        found <= 0;
                        reinit <= 0;
                        wr_en_buf <= 0;
                end
                else begin
                        case(state)
                                s_idle: begin   // 0
                                        if(en) begin
                                                done_buf <= 0;
                                                address_count <= 0;
                                                state <= s_neighborCount;
                                                wr_en_buf <= 0;
                                                data_out_buf = 0;
                                                neighborCount <= 0;
                                                knownCHcount <= 0;
                                                cur_nID <= 0;
                                                cur_knownCH <= 0;
                                                cur_qValue <= 0;
                                                found <= 0;
                                                reinit <= 0;
                                                wr_en_buf <= 0;
                                                cur_nID = 16'h2b8;
                                                cur_knownCH = 16'h2b8;
                                                cur_qValue = 16'd0;
                                                chID_address_buf = 0;
                                                data_out_buf = 0;
                                                n = 0;
                                                k = 0;
                                        end
                                        else begin
                                                state = s_idle;
                                        end
                                end
                                s_start: begin  // 1
                                        state <= s_neighborCount;
                                        address_count <= 11'h2C4; // neighborCount's address
                                end
                                s_neighborCount: begin // 2
                                        neighborCount <= data_in;
                                        state <= s_knownCHcount;     // 3
                                        address_count <= 11'h2C2;       // knownCHcount address
                                end
                                s_knownCHcount: begin   // 3
                                        knownCHcount <= data_in;
                                        state <= s_checknID;
                                end
                                s_checknID: begin       // 4
                                        if(n == neighborCount) begin    // when you get to here, this is the time to add a new neighbor
                                                state <= s_addnID;
                                        end
                                        else begin
                                                state <= s_findnID;
                                                address_count <= 11'h72 + 2*n;
                                        end
                                end
                                s_findnID: begin      // 5
                                        cur_nID = data_in;

                                        if(cur_nID == fSourceID) begin  // start updating entries
                                                found <= 1;
                                                state <= s_foundnID;

                                                chID_address_buf = 16'h1B2 + 16*n;
                                        end
                                        else begin      // check next existing neighborID
                                                n = n + 1;
                                                state <= s_checknID;
                                        end
                                end
                                s_foundnID: begin       // 6
                                        if (k == knownCHCount) begin    // new knownCH
                                                data_out_buf = k;
                                                address_count = 11'h2CA + 2*k;  // chIDcount addr
                                                wr_en_buf <= 1;
                                                state <= s_updateEnergy;
                                        end
                                        else begin
                                                address_count = 11'h12 + 2*k;
                                                state <= s_checkKCH;
                                        end
                                end
                                s_checkKCH: begin       // 7             // add CH
                                        cur_knownCH = data_in;
                                        data_out_buf = cur_knownCH;
                                        address_count = chID_address_buf + k*2;
                                        wr_en_buf = 1;
                                        state <= s_incrementK;
                                end
                                s_incrementK: begin     // 8            
                                        wr_en_buf = 0;
                                        k = k + 1;
                                        state = s_foundnID;
                                end
                                s_updateEnergy: begin   // 9
                                        data_out_buf <= fEnergyLeft;
                                        address_count <= 11'hF2 + n*2;
                                        wr_en_buf <= 1;
                                        state <= s_updateHop;
                                end
                                s_updateHop: begin      // 10
                                        data_out_buf <= fSourceHops;
                                        address_count <= 11'h132 + n*2;
                                        wr_en_buf <= 1;
                                        state = s_setQValueAddr;
                                end
                                s_setQValueAddr: begin  // 11
                                        wr_en_buf <= 0;
                                        address_count <= 11'h52 + n*2;
                                        state <= s_updateQValue;
                                end
                                s_updateQValue: begin   // 12
                                        cur_qValue = data_in;
                                        data_out_buf = cur_qValue;
                                        wr_en_buf = 1;

                                        if (cur_qValue < fQValue)
                                                reinit <= 1;
                                        else    reinit <= 0;

                                        state <= s_updatedone;
                                end
                                s_updatedone: begin     // 13
                                        if(found) begin
                                                if(reinit) begin
                                                        state <= s_wren_zero;
                                                end
                                                else    state <= s_done;
                                        end
                                        else begin
                                                state <= s_done;
                                        end
                                end
                                s_addnID: begin         // 14           addneighborID
                                        address_count <= 11'h72 + neighborCount*2;
                                        data_out_buf <= fSourceID;
                                        wr_en_buf <= 1;
                                        state <= s_addfEL;
                                end
                                s_addfEL: begin         // 15           addenergyLeft
                                        address_count <= 11'hF2 + neighborCount*2;
                                        data_out_buf <= fEnergyLeft;
                                        wr_en_buf <= 1;
                                        state <= s_addnH;
                                end
                                s_addnH: begin          // 16           // addneighborHops
                                        address_count = 11'h132 + neighborCount*2;
                                        data_out_buf <= fSourceHops;
                                        wr_en_buf <= 1;
                                        state <= s_addnQ;
                                end
                                s_addnQ: begin          // 17           // add neighborQValue
                                        address_count <= 11'h172 + neighborCount*2;
                                        data_out_buf <= fQValue;
                                        wr_en_buf <= 1;
                                        state <= s_addcluster;      
                                end
                                s_addcluster: begin     // 18           // add neighborclusterID
                                        address_count <= 11'hB2 + neighborCount*2;
                                        data_out_buf <= fClusterID;
                                        wr_en_buf <= 1;
                                        k <= 0;

                                        chID_address_buf = 16'h1B2 + 16*neighborCount;

                                        state <= s_KCH2;
                                end
                                s_KCH2: begin           // 19           
                                        if(k == knownCHcount) begin
                                                address_count <= 11'h2B8 + 2*neighborCount;
                                                data_out_buf = k;
                                                wr_en_buf <= 1;
                                                state <= s_incrementnC;
                                        end
                                        else begin
                                                address_count <= 11'h12 + 2*k;
                                                state <= s_checkKCH2;
                                        end
                                end
                                s_checkKCH2: begin      // 20
                                        cur_knownCH = data_in;
                                        data_out_buf = cur_knownCH;
                                        address_count <= chID_address_buf + k*2;
                                        wr_en_buf <= 1;
                                        state <= s_incrementK2;
                                end
                                s_incrementK2: begin    // 21
                                        wr_en_buf <= 0;
                                        k = k + 1;
                                        state <= s_KCH2;
                                end
                                s_incrementnC: begin    // 22
                                        data_out_buf = neighborCount + 1;
                                        address_count <= 11'h2B4;
                                        wr_en_buf <= 1;
                                        state <= s_wren_zero;
                                end
                                s_wren_zero: begin      // 23
                                        wr_en_buf = 0;
                                        state <= s_done;
                                end
                                s_done: begin           // 24
                                        done_buf = 1;
                                        state <= s_idle;
                                end
                                default: state <= s_idle;
                        endcase
                end
        end
        assign done = done_buf;
        assign address = address_count;
        assign data_out = data_out_buf;  
        assign wr_en = wr_en_buf;
endmodule
