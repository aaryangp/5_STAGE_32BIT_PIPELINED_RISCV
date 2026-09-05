`include "PC.v"
`include "PC_adder.v"
`include "instruction_memory.v"
`include "immedgenerator.v"
`include "register_bank.v"
`include "mux.v"
`include "data_memory.v"
`include "and.v"
`include "controlunit.v"
`include "branch_adder.v"
`include "ALU_unit.v"
`include "ALU_control.v"
`include "IF_ID.v"
`include "ID_EX.v"
`include "EX_MEM.v"
`include "MEM_WB.v"
`include "forwarding_unit.v"
`include "mux3.v"
`include "hazard_detection_unit.v"
`include "branch_predictor.v"

module top(clk,rst);

  input clk,rst ;

  //==================================================================
  // IF stage
  //==================================================================
  wire [31:0] PC_TOP, pc_plus4_top, PC_IN, INSTRUCTION;

  //==================================================================
  // IF/ID register outputs
  //==================================================================
  wire [31:0] IFID_PC, IFID_Instruction;

  //==================================================================
  // ID stage
  //==================================================================
  wire [31:0] regdata1, regdata2, ImmExt_top;
  wire RegWrite_top, Branch_top, Jump_top, Jalr_top, ALUSrc_top, MemWrite_TOP, MemRead_TOP;
  wire [1:0] MemtoReg_TOP;
  wire [1:0] ALUOp_top;

  //==================================================================
  // ID/EX register outputs
  //==================================================================
  wire IDEX_RegWrite;
  wire [1:0] IDEX_MemtoReg;
  wire IDEX_Branch, IDEX_Jump, IDEX_Jalr, IDEX_MemRead, IDEX_MemWrite;
  wire [1:0] IDEX_ALUOp;
  wire IDEX_ALUSrc;
  wire [31:0] IDEX_PC, IDEX_ReadData1, IDEX_ReadData2, IDEX_ImmExt, IDEX_Instruction;
  wire [4:0] IDEX_rs1, IDEX_rs2, IDEX_rd;
  wire IDEX_funct7;
  wire [2:0] IDEX_funct3;
  wire IDEX_predicted_taken;

  // branch prediction (computed in ID, for the instruction currently there)
  wire predicted_taken_ID;

  //==================================================================
  // EX stage
  //==================================================================
  wire [31:0] ALU_MUX_OUT, ALU_Result_TOP, BranchTarget_top, jump_target_top, link_pc4_top;
  wire zero_top;
  wire [3:0] Control_out_top;
  reg  branch_taken;
  wire actual_taken;   // real outcome: branch_taken for a conditional branch, forced 1 for any jump

  // forwarding
  wire [1:0] ForwardA, ForwardB;
  wire [31:0] Forwarded_A, Forwarded_B;

  //==================================================================
  // EX/MEM register outputs
  //==================================================================
  wire EXMEM_RegWrite;
  wire [1:0] EXMEM_MemtoReg;
  wire EXMEM_MemRead, EXMEM_MemWrite, EXMEM_Branch, EXMEM_Jump, EXMEM_branch_taken;
  wire EXMEM_predicted_taken;
  wire [31:0] EXMEM_ALU_Result, EXMEM_BranchTarget, EXMEM_WriteData, EXMEM_LinkPC, EXMEM_Instruction;
  wire [4:0] EXMEM_rd;

  //==================================================================
  // MEM stage
  //==================================================================
  wire [31:0] data_out_top;
  wire pc_src;          // redirect PC to the branch target (actual outcome, unconditional)
  wire misprediction;   // actual outcome disagreed with what was predicted back in ID

  //==================================================================
  // MEM/WB register outputs
  //==================================================================
  wire MEMWB_RegWrite;
  wire [1:0] MEMWB_MemtoReg;
  wire [31:0] MEMWB_ReadData, MEMWB_ALU_Result, MEMWB_LinkPC, MEMWB_Instruction;
  wire [4:0] MEMWB_rd;

  //==================================================================
  // WB stage
  //==================================================================
  wire [31:0] write_data_TOP;

  //==================================================================
  // Hazard detection (load-use stall)
  //==================================================================
  wire stall_load_use;


  //==================================================================
  // ========================  IF STAGE  =============================
  //==================================================================
  mux PC_MUX(
        .A(pc_plus4_top),
        .B(EXMEM_BranchTarget),
        .sel(pc_src),
        .out(PC_IN)
      );

  program_counter PC(.clk(clk) ,.rst(rst) , .stall(stall_load_use), .pc_in(PC_IN) , .pc_out(PC_TOP)) ;

  PC_adder PC_ADDER(.pc_output(PC_TOP),.pc_plus4(pc_plus4_top)) ;

  instruction_memory IM(.read_add(PC_TOP),.instruction(INSTRUCTION)) ;


  //==================================================================
  // ========================  IF/ID  ================================
  //==================================================================
  IF_ID_reg IF_ID (
      .clk(clk), .rst(rst), .stall(stall_load_use), .flush(misprediction),
      .PC_in(PC_TOP),
      .Instruction_in(INSTRUCTION),
      .PC_out(IFID_PC),
      .Instruction_out(IFID_Instruction)
  );


  //==================================================================
  // ========================  HAZARD DETECTION  =====================
  //==================================================================
  // Looks at the instruction now in EX (ID/EX) and the instruction now
  // in ID (IF/ID). If EX is a load and ID needs that load's destination
  // register, freeze PC + IF/ID for one cycle and push a bubble into
  // ID/EX instead of letting the hazard flow through uncorrected.
  hazard_detection_unit HDU(
        .IDEX_MemRead(IDEX_MemRead),
        .IDEX_rd(IDEX_rd),
        .IFID_rs1(IFID_Instruction[19:15]),
        .IFID_rs2(IFID_Instruction[24:20]),
        .stall(stall_load_use)
      );


  //==================================================================
  // ========================  ID STAGE  =============================
  //==================================================================
  // NOTE: rs1/rs2 come from the instruction currently in ID (IF/ID),
  // but rd / write_data / write_enable come from the instruction
  // currently in WB (MEM/WB) -- these are two different instructions.
  register_bank RB(
        .rs1(IFID_Instruction[19:15]),
        .rs2(IFID_Instruction[24:20]),
        .rd(MEMWB_rd),
        .clk(clk),
        .rst(rst),
        .read1(regdata1),
        .read2(regdata2),
        .write_data(write_data_TOP),
        .write_enable(MEMWB_RegWrite)
      ) ;

  ImmGen IMMGEN (.instruction(IFID_Instruction), .ImmExt(ImmExt_top ));

  controlunit CU(
        .instruction(IFID_Instruction[6:0]) ,
        .Branch(Branch_top) ,
        .Jump(Jump_top) ,
        .Jalr(Jalr_top) ,
        .MemRead(MemRead_TOP) ,
        .MemtoReg(MemtoReg_TOP),
        .ALUOp(ALUOp_top) ,
        .MemWrite(MemWrite_TOP),
        .ALUSrc(ALUSrc_top) ,
        .RegWrite(RegWrite_top)
      ) ;

  // Static branch predictor: guesses this instruction's outcome (currently
  // always "not taken") right here in ID. The guess rides along in ID/EX and
  // EX/MEM alongside the instruction itself, to be checked against the real
  // outcome once EX/MEM has it.
  branch_predictor BRANCH_PREDICTOR(
        .opcode(IFID_Instruction[6:0]),
        .predicted_taken(predicted_taken_ID)
      );


  //==================================================================
  // ========================  ID/EX  ================================
  //==================================================================
  // ID/EX must bubble on EITHER a load-use stall OR a branch misprediction:
  // whatever the reason, the instruction that was about to move into EX
  // this edge must not be allowed through.
  wire flush_IDEX = stall_load_use || misprediction;

  ID_EX_reg ID_EX (
      .clk(clk), .rst(rst), .flush(flush_IDEX),

      .RegWrite_in(RegWrite_top), .MemtoReg_in(MemtoReg_TOP),
      .Branch_in(Branch_top), .Jump_in(Jump_top), .Jalr_in(Jalr_top),
      .MemRead_in(MemRead_TOP), .MemWrite_in(MemWrite_TOP),
      .ALUOp_in(ALUOp_top), .ALUSrc_in(ALUSrc_top),

      .PC_in(IFID_PC),
      .ReadData1_in(regdata1),
      .ReadData2_in(regdata2),
      .ImmExt_in(ImmExt_top),
      .Instruction_in(IFID_Instruction),
      .rs1_in(IFID_Instruction[19:15]),
      .rs2_in(IFID_Instruction[24:20]),
      .rd_in(IFID_Instruction[11:7]),
      .funct7_in(IFID_Instruction[30]),
      .funct3_in(IFID_Instruction[14:12]),
      .predicted_taken_in(predicted_taken_ID),

      .RegWrite_out(IDEX_RegWrite), .MemtoReg_out(IDEX_MemtoReg),
      .Branch_out(IDEX_Branch), .Jump_out(IDEX_Jump), .Jalr_out(IDEX_Jalr),
      .MemRead_out(IDEX_MemRead), .MemWrite_out(IDEX_MemWrite),
      .ALUOp_out(IDEX_ALUOp), .ALUSrc_out(IDEX_ALUSrc),

      .PC_out(IDEX_PC),
      .ReadData1_out(IDEX_ReadData1),
      .ReadData2_out(IDEX_ReadData2),
      .ImmExt_out(IDEX_ImmExt),
      .Instruction_out(IDEX_Instruction),
      .rs1_out(IDEX_rs1),
      .rs2_out(IDEX_rs2),
      .rd_out(IDEX_rd),
      .funct7_out(IDEX_funct7),
      .funct3_out(IDEX_funct3),
      .predicted_taken_out(IDEX_predicted_taken)
  );


  //==================================================================
  // ========================  EX STAGE  =============================
  //==================================================================

  // Forwarding unit: compares ID/EX's source registers against the
  // destinations sitting in EX/MEM and MEM/WB, and picks which value
  // the ALU should actually see instead of the (possibly stale)
  // ID/EX.ReadData1/2 that came out of the register file back in ID.
  forwarding_unit FWD_UNIT(
        .IDEX_rs1(IDEX_rs1), .IDEX_rs2(IDEX_rs2),
        .EXMEM_rd(EXMEM_rd), .EXMEM_RegWrite(EXMEM_RegWrite),
        .MEMWB_rd(MEMWB_rd), .MEMWB_RegWrite(MEMWB_RegWrite),
        .ForwardA(ForwardA), .ForwardB(ForwardB)
      );

  // in0 = no hazard (ID/EX value), in1 = MEM/WB writeback value, in2 = EX/MEM ALU result
  mux3 FWD_MUX_A(.in0(IDEX_ReadData1), .in1(write_data_TOP), .in2(EXMEM_ALU_Result), .sel(ForwardA), .out(Forwarded_A));
  mux3 FWD_MUX_B(.in0(IDEX_ReadData2), .in1(write_data_TOP), .in2(EXMEM_ALU_Result), .sel(ForwardB), .out(Forwarded_B));

  mux ALU_MUX(.A(Forwarded_B),.B(IDEX_ImmExt),.sel(IDEX_ALUSrc),.out(ALU_MUX_OUT));

  ALU_Control ALU_CONTROL(.ALUOp(IDEX_ALUOp), .fun7(IDEX_funct7), .fun3(IDEX_funct3), .Control_out(Control_out_top));

  ALU_unit ALU_UNIT(.A(Forwarded_A), .B(ALU_MUX_OUT), .Control_in(Control_out_top), .ALU_Result(ALU_Result_TOP), .zero(zero_top));

  branch_adder BRANCH_ADDER(.pc_input(IDEX_PC) , .shift_input(IDEX_ImmExt) , .branch_out(BranchTarget_top) );

  // Branch condition evaluation (BEQ/BNE/BLT/BGE).
  // This used to live combinationally at the top level in the single-cycle
  // design; it now belongs in EX, right next to the ALU result it depends on.
  always @(*)
  begin
    case (IDEX_funct3) // funct3
      3'b000:
        branch_taken =  zero_top;          // BEQ
      3'b001:
        branch_taken = ~zero_top;          // BNE
      3'b100:
        branch_taken =  ALU_Result_TOP[0]; // BLT
      3'b101:
        branch_taken = ~ALU_Result_TOP[0]; // BGE
      default:
        branch_taken = 1'b0;
    endcase
  end

  // JAL/JALR are unconditionally taken -- override the branch condition for them.
  assign actual_taken = IDEX_Jump ? 1'b1 : branch_taken;

  // Redirect target: PC+imm (branch_adder, reused as-is) for a conditional branch
  // or JAL; rs1+imm for JALR specifically -- which is exactly ALU_Result_TOP,
  // since ALUSrc routed the immediate into the ALU's B input for this case.
  // Per spec, JALR's target also has its LSB cleared.
  assign jump_target_top = IDEX_Jalr ? (ALU_Result_TOP & ~32'h1) : BranchTarget_top;

  // Link value (PC+4 of this instruction) for JAL/JALR's writeback -- reuses
  // the same adder module the IF stage uses for its own sequential PC+4.
  PC_adder LINK_ADDER(.pc_output(IDEX_PC), .pc_plus4(link_pc4_top));


  //==================================================================
  // ========================  EX/MEM  ===============================
  //==================================================================
  // EX/MEM only ever needs to bubble for a branch misprediction (a load-use
  // stall never touches this register -- it holds while younger stages wait).
  EX_MEM_reg EX_MEM (
      .clk(clk), .rst(rst), .flush(misprediction),

      .RegWrite_in(IDEX_RegWrite), .MemtoReg_in(IDEX_MemtoReg),
      .MemRead_in(IDEX_MemRead), .MemWrite_in(IDEX_MemWrite),
      .Branch_in(IDEX_Branch), .Jump_in(IDEX_Jump),
      .branch_taken_in(actual_taken),
      .predicted_taken_in(IDEX_predicted_taken),

      .ALU_Result_in(ALU_Result_TOP),
      .BranchTarget_in(jump_target_top),
      .WriteData_in(Forwarded_B),        // forwarded, so SW right after the value's producer stores the right data
      .LinkPC_in(link_pc4_top),
      .Instruction_in(IDEX_Instruction),
      .rd_in(IDEX_rd),

      .RegWrite_out(EXMEM_RegWrite), .MemtoReg_out(EXMEM_MemtoReg),
      .MemRead_out(EXMEM_MemRead), .MemWrite_out(EXMEM_MemWrite),
      .Branch_out(EXMEM_Branch), .Jump_out(EXMEM_Jump),
      .branch_taken_out(EXMEM_branch_taken),
      .predicted_taken_out(EXMEM_predicted_taken),

      .ALU_Result_out(EXMEM_ALU_Result),
      .BranchTarget_out(EXMEM_BranchTarget),
      .WriteData_out(EXMEM_WriteData),
      .LinkPC_out(EXMEM_LinkPC),
      .Instruction_out(EXMEM_Instruction),
      .rd_out(EXMEM_rd)
  );


  //==================================================================
  // ========================  MEM STAGE  ============================
  //==================================================================
  // PC redirect fires for EITHER a taken conditional branch OR any jump
  // (JAL/JALR) -- EXMEM_branch_taken is already forced to 1 for jumps back
  // in EX, so this AND gate doesn't need to know the difference.
  AND PC_SRC_AND(.branch(EXMEM_Branch | EXMEM_Jump), .zero(EXMEM_branch_taken), .out(pc_src));

  // Misprediction: only meaningful for something that can redirect the PC at
  // all (a branch or a jump), and only when the real outcome disagrees with
  // what was guessed for it back in ID. Jumps are always "mispredicted" under
  // today's static not-taken policy (predicted_taken is always 0, but a jump's
  // actual outcome is always 1) -- that's correct: every jump costs the same
  // 3-cycle flush a mispredicted branch does, until a smarter predictor (or
  // early jump resolution) is added.
  assign misprediction = (EXMEM_Branch | EXMEM_Jump) && (EXMEM_branch_taken != EXMEM_predicted_taken);

  data_memory DM(
        .address(EXMEM_ALU_Result),
        .MemRead(EXMEM_MemRead),
        .MemWrite(EXMEM_MemWrite),
        .clk(clk),
        .rst(rst),
        .data_out(data_out_top),
        .data_write(EXMEM_WriteData)
      );


  //==================================================================
  // ========================  MEM/WB  ===============================
  //==================================================================
  MEM_WB_reg MEM_WB (
      .clk(clk), .rst(rst),

      .RegWrite_in(EXMEM_RegWrite), .MemtoReg_in(EXMEM_MemtoReg),
      .ReadData_in(data_out_top),
      .ALU_Result_in(EXMEM_ALU_Result),
      .LinkPC_in(EXMEM_LinkPC),
      .Instruction_in(EXMEM_Instruction),
      .rd_in(EXMEM_rd),

      .RegWrite_out(MEMWB_RegWrite), .MemtoReg_out(MEMWB_MemtoReg),
      .ReadData_out(MEMWB_ReadData),
      .ALU_Result_out(MEMWB_ALU_Result),
      .LinkPC_out(MEMWB_LinkPC),
      .Instruction_out(MEMWB_Instruction),
      .rd_out(MEMWB_rd)
  );


  //==================================================================
  // ========================  WB STAGE  =============================
  //==================================================================
  // 00 = ALU result, 01 = memory read data, 10 = link (PC+4, for JAL/JALR)
  mux3 WB_MUX(.in0(MEMWB_ALU_Result), .in1(MEMWB_ReadData), .in2(MEMWB_LinkPC), .sel(MEMWB_MemtoReg), .out(write_data_TOP));

endmodule
