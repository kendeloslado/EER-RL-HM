

module registerFile #(
    parameter ADDR_WIDTH = 5,
    parameter DATA_WIDTH = 16,
    parameter REG_COUNT = 32
)(
    input logic                         clk,
    input logic                         nrst,
    input logic                         wr_en,
    input logic     [ADDR_WIDTH-1:0]    wr_addr,
    input logic     [DATA_WIDTH-1:0]    wr_data,
    input logic     [ADDR_WIDTH-1:0]    rd_addrA,
    input logic     [ADDR_WIDTH-1:0]    rd_addrB,
    output logic    [DATA_WIDTH-1:0]    rd_dataA,
    output logic    [DATA_WIDTH-1:0]    rd_dataB
);

logic [REG_COUNT-1:0][DATA_WIDTH-1:0]   register_file;

always_ff@(negedge clock) begin
    if(!nrst) begin
        register_file[0] <= 0;
        register_file[1] <= 0;
        register_file[2] <= 0;
        register_file[3] <= 0;
        register_file[4] <= 0;
        register_file[5] <= 0;
        register_file[6] <= 0;
        register_file[7] <= 0;
        register_file[8] <= 0;
        register_file[9] <= 0;
        register_file[10] <= 0;
        register_file[11] <= 0;
        register_file[12] <= 0;
        register_file[13] <= 0;
        register_file[14] <= 0;
        register_file[15] <= 0;
        register_file[16] <= 0;
        register_file[17] <= 0;
        register_file[18] <= 0;
        register_file[19] <= 0;
        register_file[20] <= 0;
        register_file[21] <= 0;
        register_file[22] <= 0;
        register_file[23] <= 0;
        register_file[24] <= 0;
        register_file[25] <= 0;
        register_file[26] <= 0;
        register_file[27] <= 0;
        register_file[28] <= 0;
        register_file[29] <= 0;
        register_file[30] <= 0;
        register_file[31] <= 0;
    end
    else begin
        if(wr_en) begin
            register_file[wr_addr] <= wr_data;
        end
        else begin
            register_file[wr_addr] <= register_file[wr_addr];
        end
    end
end

assign rd_dataA = register_file[rd_addrA];
assign rd_dataB = register_file[rd_addrB];

endmodule