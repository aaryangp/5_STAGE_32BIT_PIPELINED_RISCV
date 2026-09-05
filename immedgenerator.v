module ImmGen (instruction, ImmExt);
  
  input [31:0] instruction;
  output reg [31:0] ImmExt;

  always @(*) begin
    // Set a safe default before the case statement
    ImmExt = 32'b0; 
    
    case (instruction[6:0]) 
      
      // I-TYPE (LOAD, ALU IMM, and now JALR)
      7'b0000011, // Load
      7'b0010011, // ALU Immediate (e.g., ADDI, ORI, SLTI)
      7'b1100111: // JALR -- same 12-bit I-type immediate encoding
        // I-type immediate is Instruction[31:20] (12 bits)
        ImmExt = {{20{instruction[31]}}, instruction[31:20]};

      // J-TYPE (JAL)
      7'b1101111 :
        // J-type immediate: imm[20|10:1|11|19:12], imm[0] is always 0
        ImmExt = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};

      // S-TYPE (STORE)
      7'b0100011 : 
        // S-type immediate is Instruction[31:25] and Instruction[11:7] (12 bits)
        ImmExt = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};

      // B-TYPE (BRANCH)
      7'b1100011 : 
        // B-type immediate (12 bits + 1 implied zero)
        ImmExt = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
  
    endcase
  end
endmodule
