module mux3(in0, in1, in2, sel, out);

input  [31:0] in0, in1, in2;   // in0 = no forwarding, in1 = MEM/WB, in2 = EX/MEM
input  [1:0]  sel;
output reg [31:0] out;

always @(*) begin
    case (sel)
        2'b00: out = in0;
        2'b01: out = in1;
        2'b10: out = in2;
        default: out = in0;
    endcase
end

endmodule