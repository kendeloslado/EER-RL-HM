module knownClusterHead(
    input   [15:0]          CH_ID,
    input   [15:0]          CH_QValue,
    input   [15:0]          CH_Hops,
    input                   en_KCH,
    output                  chosenCH,
    output                  hopsFromCH
);

// Registers
    reg     [15:0]          CH_ID_reg       [0:15];
    reg     [15:0]          CH_QValue_reg   [0:15];
    reg     [15:0]          CH_Hops_reg     [0:15];
    reg     [15:0]          CH_ID_bitmask;
    reg     [15:0]          CH_Hops_bitmask;
    reg     [15:0]          CH_QValue_bitmask;
    reg     [15:0]          minHops;
    reg     [15:0]          maxQValue;

// Purpose:
/*
CH_ID_bitmask: Assert 1 when this entry is non-empty (CH_ID =/= 0)

CH_Hops_bitmask: Have a 16-bit register represent each entry
0000 0000 0000 0000
At the beginning, all of these start at 0. The only way for this
to be raised to 1 is to meet the minimum hop count, for example:
the minimum hop count for this is 2. For a simple scenario,
let's say there are only 4 cluster heads, and two of them are 2 hops
while the rest are more than 2 hops, say CH1 and CH3
bitmask should look like this:

CH_ID_bitmask: 
1111 0000 0000 0000
CH_Hops_bitmask: 
0101 0000 0000 0000

so CH1 and CH3 are both minimum hops, but comparing the Q-values
(for example, CH1_QValue == 0.75, CH3_QValue == 0.90)

the CH_QValue_bitmask should look like this:
CH_QValue_bitmask:
0001 0000 0000 0000

With this bitmask, the chosenCH should be the CH_ID entry in
slot 3.
*/

endmodule