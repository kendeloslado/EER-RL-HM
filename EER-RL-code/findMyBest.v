`timescale 1ns / 1ps
`define MEM_DEPTH 2048
`define MEM_WIDTH 8
`define WORD_WIDTH 16

module findMyBest(clk, nrst, en, start, data_in, MY_BATTERY_STAT, address, wr_en, mybest, done);

    input                               clk, nrst, en, start;
    input   [`WORD_WIDTH-1:0]           data_in;
    input   [`WORD_WIDTH-1:0]           nodeEnergy;
    output  [10:0]                      address;
    output                              wr_en;
    output  [`WORD_WIDTH-1:0]           mybestQ, mybestH;
    output                              done;


    // Registers

    reg     [10:0]                      address_count;
    reg     [`WORD_WIDTH-1:0]           mybestQ_buf, mybestH_buf;
    reg                                 wr_en_buf, done_buf;
    reg     [3:0]                       state;
    reg     [`WORD_WIDTH-1:0]           neighborCount, nC_index;
    reg     [`WORD_WIDTH-1:0]           neighborQValue, neighborHops;

    // Parameters

    parameter s_wait = 4'd0;
    parameter s_start = 4'd1;
    parameter s_fetchnC = 4'd2;
    parameter s_fetchnH = 4'd3;
    parameter s_fetchQ = 4'd4;
    parameter s_compareQ = 4'd5;
    parameter s_compareH = 4'd6;
    parameter s_check_nCindex = 4'd7;
    parameter s_done = 4'd8;

    // Program Flow described

/*
    "The policy is used such that the sender selects the neighbour with the highest Q-value, denoted as maxQ(S',a),
    to maximize the reward, and end up in state S'."

    Algorithm 3: Data Transmission (Pseudo-code)

    1)  For i -> 1 to n, do
    2)      If S(i).E > 0, then
    3)          maxQ = max(Q(i,:))
    4)          If S(i).d <= Tx_range
    5)              If S(i) is next-hop, then
    6)                  Aggregate data
    7)                  Send data to sink
    8)              Else
    9)                  Send data to sink
    10)             End if
    11)         Else if S(i).role == 0, then
    12)             If CH w/in TX_range, then
    13)                 Send data to CH
    14)             Else
    15)                 Find closest neighbour in the cluster
    16)                 Send data to closest neighbour
    17)             End if
    18)         End if
    19)         Compute reward
    20)         Update Q-value
    21)     End if
    22) End for

    FindMyBest Hardware Flow

    states:
    s_wait -> Wait for the module to be enabled (this is different from start)
    s_start -> wait for a preceding module's go signal then start fetching
    s_fetchnC -> fetch neighbor count, start indexing
    s_fetchnH -> fetch neighbor node's hopcount
    s_fetchQ -> fetch neighbor node's Q-Value
    s_compare -> get highest Q-value
        some priorities to note:
            * Finding the highest Q-value takes precedence. When you find a node possessing
            the highest Q-value, you should add that to another table, called betterNeighbors
            for this case.
            * In that table, the betterNeighbors table should have the following:
                a. node ID
                b. Q-value
                c. HopsFromCH
                d. HopsFromSink
            * In this table, the tiebreaking rules will be done with this hierarchy:
            Q-value > nHops > nodeID
    s_done -> send done signal for next module to start
    
    Remember: you have hierarchies for finding best hop

    best Q-value > shortest distance (lowest number of hops) > node ID

    tiebreakers:
    Same Q-value -> pick shortest hops between the best Q-values
    same Q-value and number of hops -> X (unknown, either pick lower nID or actually pick at random)

*/

    // Program Proper
/*
    always@(posedge clk) begin
        if(!nrst) begin
            address_count = 11'h2B4;
            data_out_buf = 0;
            mybest_buf = 16'h0;
            wr_en_buf = 0;
            done_buf = 0;
            neighborCount = 0;
            nC_index = 0;
            state = s_wait;
        end
        else begin
            case(state)
                s_wait: begin
                    if(en) begin
                        address_count = 11'h2B4;
                        data_out_buf = 0;
                        mybest_buf = 16'h0; // tentative fixed-point value
                        wr_en_buf = 0;
                        done_buf = 0;
                        neighborCount = 0;
                        nC_index = 0;
                        state = s_start;
                    end
                    else begin
                        state = s_wait;
                    end
                end
                s_start: begin
                    if(start) begin
                        state = s_fetch;
                    end
                    else begin
                        state = s_start;
                        address_count = 11'h2B4;
                    end
                end
                s_fetch: begin
                    neighborCount = data_in;
                    state = s_fetchQ;
                    address_count = 11'h172;
                end
                s_fetchQ: begin
                    neighborQValue = data_in;
                    nC_index = nC_index + 1;

                    if(neighborQValue > mybest_buf) begin
                        mybest_buf = neighborQValue;
                    end

                    if (nC_index == neighborCount) begin
                        state = s_done;
                    end
                end
                s_done: begin
                    done_buf = 1;
                    state = s_wait;
                end
                default: state = s_wait;
            endcase
        end
    end
*/

    always@(posedge clk) begin
        if(!nrst) begin
            address_count <= 11'h2B4;
            //data_out_buf = 0;
            mybestQ_buf = 16'h0;
            mybestH_buf = 16'h0;
            wr_en_buf = 0;
            done_buf = 0;
            neighborCount = 0;
            nC_index = 0;
            state = s_wait;
        end
        else begin
            case(state)
                s_wait: begin               // 0
                    if(en) begin    // enable module
                        address_count = 11'h2C4;    // neighborCount addr
                        //data_out_buf = 0;
                        mybestQ_buf = 16'h0;
                        mybestH_buf = 16'h7;    // worst case scenario hop
                        wr_en_buf = 0;
                        done_buf = 0; 
                        state <= s_start;
                    end
                    else begin
                        state <= s_wait;
                    end
                end
                s_start: begin              // 1
                    if(start) begin
                        state <= s_fetchnC;
                        address_count = 11'h2C4;
                        nC_index = 0;
                    end
                    else begin
                        state <= s_start;
                    end
                end
                s_fetchnC: begin            // 2
                    state = s_fetchnH;
                    neighborCount = data_in;
                    address_count = 11'h132 + nC_index*2;
                end
                s_fetchnH: begin            // 3
                    state = s_fetchQ;
                    neighborHops = data_in;
                    address_count = 11'h172 + nC_index*2;
                end
                s_fetchQ: begin             // 4
                    state = s_compareQ;
                    neighborQValue = data_in;
                end
                s_compareQ: begin           // 5
                    if(neighborQValue > mybestQ_buf) begin
                        mybestQ_buf = neighborQValue;
                        state = s_compareH;
                    end
                    else begin
                        state = s_compareH;
                    end
                end
                s_compareH: begin           // 6
                    if(neighborHops < mybestH_buf) begin
                        mybestH_buf = neighborHops;
                        state = s_check_nCindex;
                    end
                    else begin
                        state = s_check_nCindex;
                    end
                end
                s_check_nCindex: begin      // 7
                    if (nC_index >= neighborCount) begin
                        state = s_done;
                    end
                    else begin
                        state = s_fetchnH;
                        nC_index = nC_index + 1;
                        address_count = 11'h132 + 2*nC_index;
                    end
                end
                s_done: begin               // 8
                    done_buf = 1;
                    state = s_wait;
                end
                default: state <= s_idle;
            endcase
        end
    end
    //assign data_out = data_out_buf;
    assign mybestQ = mybestQ_buf;
    assign mybestH = mybestH_buf;
    assign wr_en = wr_en_buf;
    assign done = done_buf;
endmodule
