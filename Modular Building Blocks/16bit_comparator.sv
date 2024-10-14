module 16bitEQComparator#(
    parameter WORD_WIDTH = 16
)(
    input logic             [WORD_WIDTH-1:0]    inA,
    input logic             [WORD_WIDTH-1:0]    inB,
    output logic            [WORD_WIDTH-1:0]    out
);
    assign out = (inA == inB) ? 1 : 0;
endmodule