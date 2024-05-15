`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

module betterNeighborsInMyCluster(clock, nrst, en, start, data_in, nodeID, mybest, address, wr_en, data_out, besthop, bestvalue, bestneighborID, nextCHs, done);

    input                                   clock, nrst, en, start;
    input   [`WORD_WIDTH-1:0]               data_in, nodeID, mybest, MY_CLUSTER_ID;
    output  [10:0]                          address;
    output  [`WORD_WIDTH-1:0]               data_out, besthop, bestvalue, bestneighborID, nextCHs;
    output                                  wr_en, done;

    // Registers

    reg     [10:0]                          address_count;
    reg     [`WORD_WIDTH-1:0]               data_out_buf;
    reg     [`WORD_WIDTH-1:0]               besthop_buf, bestneighborID_buf, nextCHs_buf;
    reg     [`WORD_WIDTH-1:0]               knownCHcount, neighborCount, clusterID, neighborID, knownCHs, betterneighbors, betterneighborCount;
    reg     [`WORD_WIDTH-1:0]               ENERGY_THRESHOLD, energyLeft, qValue, bestvalue_buf;
    reg                                     done_buf, wr_en_buf;
    reg     [`WORD_WIDTH-1:0]               neighbors_index, knownSinks_index;
    reg     [3:0]                           state;
    reg     [31:0]                          floating_point_temp;



    // Parameters

    parameter s_idle = 4'd0;
    parameter s_start = 4'd1;

    // Fixed-Point Parameters

    /*
    energyLeft          2./14
    E_o                 2./14
    qValue              8./8
    
    */

    always@(posedge clock) begin
        if(!nrst) begin
            done_buf = 0;
            wr_en_buf = 0;
            address_count = 11'h272;
            data_out_buf = 16'h0;
            betterneighbors = 16'h0;
            betterneighborCount = 16'h0;
            besthop_buf = 16'h0;
            bestvalue_buf = 16'h0100;
            ENERGY_THRESHOLD = 16'h00cd;
            nextCHs_buf = 16'd0;
            bestneighborID_buf = 16'h11;
            state = s_idle;
            neighbors_index = 0;
            betterneighborCount = 0;
            energyLeft = 0;
            clusterID = 0;
            floating_point_temp = 0;
            knownCHcount = 0;
            knownCHs = 0;
            neighborCount = 0;
            neighborID = 0;
            qValue = 0;
        end
        else begin
            case(state)
                s_idle: begin           // 0
                    if (en) begin
                        done_buf = 0;
                        wr_en_buf = 0;
                        address_count = 11'h272;
                        data_out_buf = 16'h0;
                        betterneighbors = 16'h0;
                        betterneighborCount = 16'h0;
                        besthop_buf = 16'h0;
                        bestvalue_buf = 16'h0100;
                        ENERGY_THRESHOLD = 16'h00cd;
                        nextCHs_buf = 16'd0;
                        bestneighborID_buf = 16'h11;
                        state = s_start;
                        neighbors_index = 0;
                        betterneighborCount = 0;
                        energyLeft = 0;
                        clusterID = 0;
                        floating_point_temp = 0;
                        knownCHcount = 0;
                        knownCHs = 0;
                        neighborCount = 0;
                        neighborID = 0;
                        qValue = 0;
                    end
                    else begin
                        state = s_idle;
                    end
                end
                s_start: begin          // 1
                    if (start) begin
                        state = s_knownCHcount;
                        address_count = 11'h272;
                    end
                    else begin
                        state = s_start;
                    end
                end
                s_knownCHcount: begin   // 2
                    knownCHcount = data_in;
                    state = s_neighborCount;
                    address_count = 11'h274;
                end
                s_neighborCount: begin  // 3
                    neighborCount = data_in;
                    state = s_clusterID;
                    address_count = 11'hB2;
                end
                s_clusterID: begin      // 4
                    clusterID = data_in;

                    if (MY_CLUSTER_ID != clusterID) begin
                        $display("Neighbor doesn't belong in my cluster. %d", i);
                        neighbors_index = neighbors_index + 1;
                        address_count = 11'hB2 + 2*neighbors_index;

                        if(i == neighborCount) begin
                            state = s_bestneighborID;
                            address_count = 11'h72 + 2*besthop_buf;     // bestneighborID addr
                        end
                    end
                    else begin
                        state = s_qValue;
                        address_count = 11'h132 + 2*neighbors_index;    // neighborQValue addr
                    end
                end
                s_qValue: begin
                    qValue = data_in;
                    $display("I am now in s_qValue state.");

                    if(qValue <= mybest) begin
                        $display("I finished comparing my qValue to mybest.");
                    end

                end
                default: state = s_idle;
            endcase
        end
    end
endmodule