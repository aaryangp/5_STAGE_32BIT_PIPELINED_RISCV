module data_memory(
    input clk,
    input rst,
    input MemWrite,
    input MemRead,
    input [31:0] data_write,
    input [31:0] address,
    output [31:0] data_out
);

reg [31:0] DM [0:63];
integer i;

wire [5:0] word_address;
assign word_address = address[7:2];

always @(posedge clk) begin
    if (rst) begin
        for(i=0; i<64; i=i+1)
            DM[i] <= 32'b0;
    end
    else if (MemWrite) begin
        DM[word_address] <= data_write;
    end
end

assign data_out = MemRead ? DM[word_address] : 32'b0;

endmodule
