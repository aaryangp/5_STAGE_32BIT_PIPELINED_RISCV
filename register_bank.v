
module register_bank(rs1,rs2,rd,clk,rst,read1,read2,write_data,write_enable) ;

input clk,rst,write_enable ;
input [4:0] rs1,rs2,rd ;
input [31:0] write_data ;
output [31:0] read1 , read2 ;
integer i;
reg [31:0] RB [0:31] ;

// Initialize registers with non-zero values for testing
initial begin
    RB[0]  = 0;
    RB[1]  = 4;
    RB[2]  = 2;
    RB[3]  = 1;
    RB[4]  = 4;
    RB[5]  = 9;
    RB[6]  = 44;
    RB[7]  = 4;
    RB[8]  = 2;
    RB[9]  = 1;
    RB[10] = 23;
    RB[11] = 4;
    RB[12] = 90;
    RB[13] = 10;
    RB[14] = 20;
    RB[15] = 30;
    RB[16] = 40;
    RB[17] = 50;
    RB[18] = 60;
    RB[19] = 70;
    RB[20] = 80;
    RB[21] = 80;
    RB[22] = 90;
    RB[23] = 70;
    RB[24] = 60;
    RB[25] = 65;
    RB[26] = 4;
    RB[27] = 32;
    RB[28] = 12;
    RB[29] = 34;
    RB[30] = 5;
    RB[31] = 10;
end

always@(posedge clk) begin
   /* if(rst) begin
        // Reset all 32 entries
      for(i = 0 ; i < 32 ; i = i + 1)begin
           RB[i] <= 32'b0 ;
        end
      end */
    // Write only if enabled AND CRITICALLY, if destination rd is NOT x0 (5'b0)
    if(write_enable && rd != 5'b0) 
        RB[rd] <= write_data ;
end 

// Combinational Read with CRITICAL x0 check: always output 0 if address is 5'b0
// Also bypasses a same-cycle write: if this same edge is writing `rd` and we're
// reading that same register, hand back the value being written instead of the
// stale RB[] contents. Without this, an instruction whose ID-stage read lands on
// the exact same cycle as its producer's WB-stage write (a "3 instructions apart"
// RAW hazard in a 5-stage pipeline) would read one cycle late -- this case is NOT
// covered by the EX-stage forwarding unit, since neither instruction is in EX/MEM
// or MEM/WB at that point; it has to be handled here, in the register file itself.

assign read1 = (rs1 == 5'b0) ? 32'b0 :
               (write_enable && rd == rs1 && rd != 5'b0) ? write_data : RB[rs1];
assign read2 = (rs2 == 5'b0) ? 32'b0 :
               (write_enable && rd == rs2 && rd != 5'b0) ? write_data : RB[rs2];

endmodule