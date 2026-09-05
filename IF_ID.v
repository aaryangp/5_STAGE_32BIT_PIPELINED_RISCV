module IF_ID_reg(
    input clk,
    input rst,
    input stall,        // hold current contents (load-use hazard): re-decode the same instruction
    input flush,        // branch misprediction: discard whatever was just fetched, insert a bubble

    input  [31:0] PC_in,
    input  [31:0] Instruction_in,

    output reg [31:0] PC_out,
    output reg [31:0] Instruction_out
);

// Priority: reset first, then a misprediction flush (it must win over a stall --
// there's no point holding an instruction we're about to throw away anyway),
// then a load-use stall, then the normal case.
always @(posedge clk) begin
    if (rst) begin
        PC_out          <= 32'b0;
        Instruction_out <= 32'b0;   // bubble / NOP on reset
    end
    else if (flush) begin
        PC_out          <= 32'b0;
        Instruction_out <= 32'b0;   // bubble / NOP: the fetch this cycle was down the wrong path
    end
    else if (stall) begin
        PC_out          <= PC_out;          // hold
        Instruction_out <= Instruction_out; // hold
    end
    else begin
        PC_out          <= PC_in;
        Instruction_out <= Instruction_in;
    end
end

endmodule