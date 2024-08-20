module NextHopDecision (
    input wire [7:0] nodeID,
    input wire [7:0] nodeHops,
    input wire [15:0] nodeQValue,
    input wire [15:0] nodeEnergy,
    input wire [7:0] chosenCH,
    input wire [7:0] hopsFromCH,
    output wire [7:0] nextHop
);

    // Stage 1: Check if the node is one hop away from the sink
    if (nodeHops == 1) begin
        nextHop = sink; // Set nextHop to the sink
    end
    else begin
        // Stage 2: Check if the hop count to the CH is 1
        if (hopsFromCH == 1) begin
            nextHop = chosenCH; // Set nextHop to the cluster head
        end
        else begin
            // Stage 3: Shortlist nodes with hopsFromCH equal to (myHopsFromCH - 1)
            // and select the node with the highest Q-value
            wire [7:0] bestNextHop;
            wire [15:0] highestQValue = 0;

            // Iterate through neighboring nodes
            for (neighbor = 0; neighbor < numNeighbors; neighbor = neighbor + 1) begin
                if (neighbor.hopsFromCH == (hopsFromCH - 1)) begin
                    if (neighbor.nodeQValue > highestQValue) begin
                        highestQValue = neighbor.nodeQValue;
                        bestNextHop = neighbor.nodeID;
                    end
                end
            end

            nextHop = bestNextHop; // Set nextHop to the node with the highest Q-value
        end
    end

endmodule
