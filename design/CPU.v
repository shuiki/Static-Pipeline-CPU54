`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/07/01 11:52:17
// Design Name: 
// Module Name: CPU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "D:/vivado_projects/CPU54-Static-Pipeline/CPU54-Static-Pipeline.srcs/sources_1/new/definition.vh"

module CPU(
input clk,
input rst,
output DM_W,
output DM_R,
input [31:0] IM_inst,
input [31:0] DM_rdata,
output [31:0] DM_wdata,
output [31:0] PC_out,
output [31:0] DM_addr,
output [3:0] Byte_ena

//output [31:0] if__inst,
//output [31:0] id_inst,
//output [31:0] ex_inst,
//output [31:0] me_inst,
//output [31:0] wb_inst,
//output[4:0] STALL
    );

//定义
//IF
//wire[31:0] if_pc_out,if_pc_in;
//wire if_pc_ena;
wire[31:0]if_pc_out;
wire[31:0] if_inst;

//IF-ID
reg[31:0] if_id_npc;
reg[31:0] if_id_inst;

//ID
wire[31:0] id_sext16,id_uext16,id_uext5,id_sext18;
wire[4:0] id_rsc,id_rtc;
wire [31:0]id_rs,id_rt;
wire id_pc_ena;
wire[31:0] id_pc_in,id_npc;
wire[31:0] id_alua,id_alub;
wire[4:0] id_cp0_raddr;
wire[31:0] id_cp0_rdata,id_cp0_epcout,id_cp0_status;
wire[31:0] id_pass_data;//直接传递的数据，如MTC0,MFHI等

//ID-EX
reg[31:0] id_ex_alua,id_ex_alub;
reg[31:0] id_ex_pass_data; //store,mtmf系列数据
reg[31:0] id_ex_inst;

//EX
wire[31:0]ex_alua,ex_alub,ex_aluo;
wire[31:0]ex_mula,ex_mulb,ex_multua,ex_multub;
wire[63:0]ex_mulz,ex_multuz;
wire ex_div_start,ex_div_busy,ex_divu_start,ex_divu_busy;
wire[31:0]ex_div_dividend,ex_div_divisor,ex_div_q,ex_div_r;
wire[31:0]ex_divu_dividend,ex_divu_divisor,ex_divu_q,ex_divu_r;

//EX-MEM
reg[31:0] ex_mem_div_q,ex_mem_div_r;//divu同
reg[63:0] ex_mem_mulz;//multu同
reg[31:0] ex_mem_aluo;
reg[31:0] ex_mem_pass_data;//前面传过来的store,mtmf系列数据
reg[31:0] ex_mem_inst;
reg ex_mem_overflowFlag;//ALU OF

//MEM
wire[3:0] mem_byte_ena;//接口
wire mem_dm_r,mem_dm_w;
wire[31:0]mem_dm_rdata,mem_dm_wdata,mem_dm_addr;
wire[31:0]mem_byte_ext,mem_half_ext;

//MEM-WB
reg[31:0] mem_wb_div_q,mem_wb_div_r;//divu同
reg[63:0] mem_wb_mulz;//multu同
reg[31:0] mem_wb_aluo;
reg[31:0] mem_wb_pass_data;//store数据解决了，但也存放mem取来的load数据和原本的mtmf系列数据
reg[31:0] mem_wb_inst;
reg mem_wb_overflowFlag;//ALU OF


//WB
wire wb_rf_wena;
wire[4:0]wb_rdc,wb_cp0_waddr;
wire[31:0]wb_rd,wb_cp0_wdata;
wire wb_hi_wena,wb_lo_wena;
wire[31:0]wb_hi_wdata,wb_lo_wdata;

//others
reg[31:0]HI,LO;
reg[4:0]stall;


//debug
//assign if__inst = if_inst;
//assign id_inst = if_id_inst;
//assign ex_inst = id_ex_inst;
//assign me_inst = ex_mem_inst;
//assign wb_inst = mem_wb_inst;
//assign STALL = stall;


    //IF部分译码
    wire [5:0] ifOp =if_inst[31:26];
    wire [4:0] ifRs = if_inst[25:21];
    wire [4:0] ifRt = if_inst[20:16];
    wire [5:0] ifFunc = if_inst[5:0];
    wire ifOpAddi = (ifOp == `OP_ADDI);
    wire ifOpAddiu = (ifOp == `OP_ADDIU);
    wire ifOpAndi = (ifOp == `OP_ANDI);
    wire ifOpOri = (ifOp == `OP_ORI);
    wire ifOpSltiu = (ifOp == `OP_SLTIU);
    wire ifOpLui = (ifOp == `OP_LUI);
    wire ifOpXori = (ifOp == `OP_XORI);
    wire ifOpSlti = (ifOp == `OP_SLTI);
    wire ifOpAddu = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_ADDU);
    wire ifOpAnd = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_AND);
    wire ifOpBeq = (ifOp == `OP_BEQ);
    wire ifOpBne = (ifOp == `OP_BNE);
    wire ifOpJ = (ifOp == `OP_J);
    wire ifOpJal = (ifOp == `OP_JAL);
    wire ifOpJr = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_JR);
    wire ifOpLw = (ifOp == `OP_LW);
    wire ifOpXor = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_XOR);
    wire ifOpNor = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_NOR);
    wire ifOpOr = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_OR);
    wire ifOpSll = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_SLL && if_inst != 32'b0);
    wire ifOpSllv = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_SLLV);
    wire ifOpSltu = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_SLTU);
    wire ifOpSra = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_SRA);
    wire ifOpSrl = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_SRL);
    wire ifOpSubu = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_SUBU);
    wire ifOpSw = (ifOp == `OP_SW);
    wire ifOpAdd = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_ADD);
    wire ifOpSub = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_SUB);
    wire ifOpSlt = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_SLT);
    wire ifOpSrlv = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_SRLV);
    wire ifOpSrav = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_SRAV);
    wire ifOpClz = (ifOp == `OP_SPECIAL2 && ifFunc == `FUNCT_CLZ);
    wire ifOpDivu = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_DIVU);
    wire ifOpEret = (ifOp == `OP_COP0 && ifFunc == `FUNCT_ERET);
    wire ifOpJalr = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_JALR);
    wire ifOpLb = (ifOp == `OP_LB);
    wire ifOpLbu = (ifOp == `OP_LBU);
    wire ifOpLhu = (ifOp == `OP_LHU);
    wire ifOpSb = (ifOp == `OP_SB);
    wire ifOpSh = (ifOp == `OP_SH);
    wire ifOpLh = (ifOp == `OP_LH);
    wire ifOpMfc0 = (ifOp == `OP_COP0 && ifRs == `RS_MF);
    wire ifOpMfhi = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_MFHI);
    wire ifOpMflo = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_MFLO);
    wire ifOpMtc0 = (ifOp == `OP_COP0 && ifRs == `RS_MT);
    wire ifOpMthi = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_MTHI);
    wire ifOpMtlo = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_MTLO);
    wire ifOpMul = (ifOp == `OP_SPECIAL2 && ifFunc == `FUNCT_MUL);
    wire ifOpMultu = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_MULTU);
    wire ifOpSyscall = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_SYSCALL);
    wire ifOpTeq = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_TEQ);
    wire ifOpBgez = (ifOp == `OP_REGIMM && ifRt == `RT_BGEZ);
    wire ifOpBreak = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_BREAK);
    wire ifOpDiv = (ifOp == `OP_SPECIAL && ifFunc == `FUNCT_DIV);

    //ID部分译码
    wire [5:0] idOp =if_id_inst[31:26];
    wire [4:0] idRs = if_id_inst[25:21];
    wire [4:0] idRt = if_id_inst[20:16];
    wire [5:0] idFunc = if_id_inst[5:0];
    wire idOpAddi = (idOp == `OP_ADDI);
    wire idOpAddiu = (idOp == `OP_ADDIU);
    wire idOpAndi = (idOp == `OP_ANDI);
    wire idOpOri = (idOp == `OP_ORI);
    wire idOpSltiu = (idOp == `OP_SLTIU);
    wire idOpLui = (idOp == `OP_LUI);
    wire idOpXori = (idOp == `OP_XORI);
    wire idOpSlti = (idOp == `OP_SLTI);
    wire idOpAddu = (idOp == `OP_SPECIAL && idFunc == `FUNCT_ADDU);
    wire idOpAnd = (idOp == `OP_SPECIAL && idFunc == `FUNCT_AND);
    wire idOpBeq = (idOp == `OP_BEQ);
    wire idOpBne = (idOp == `OP_BNE);
    wire idOpJ = (idOp == `OP_J);
    wire idOpJal = (idOp == `OP_JAL);
    wire idOpJr = (idOp == `OP_SPECIAL && idFunc == `FUNCT_JR);
    wire idOpLw = (idOp == `OP_LW);
    wire idOpXor = (idOp == `OP_SPECIAL && idFunc == `FUNCT_XOR);
    wire idOpNor = (idOp == `OP_SPECIAL && idFunc == `FUNCT_NOR);
    wire idOpOr = (idOp == `OP_SPECIAL && idFunc == `FUNCT_OR);
    wire idOpSll = (idOp == `OP_SPECIAL && idFunc == `FUNCT_SLL && if_id_inst != 32'b0);
    wire idOpSllv = (idOp == `OP_SPECIAL && idFunc == `FUNCT_SLLV);
    wire idOpSltu = (idOp == `OP_SPECIAL && idFunc == `FUNCT_SLTU);
    wire idOpSra = (idOp == `OP_SPECIAL && idFunc == `FUNCT_SRA);
    wire idOpSrl = (idOp == `OP_SPECIAL && idFunc == `FUNCT_SRL);
    wire idOpSubu = (idOp == `OP_SPECIAL && idFunc == `FUNCT_SUBU);
    wire idOpSw = (idOp == `OP_SW);
    wire idOpAdd = (idOp == `OP_SPECIAL && idFunc == `FUNCT_ADD);
    wire idOpSub = (idOp == `OP_SPECIAL && idFunc == `FUNCT_SUB);
    wire idOpSlt = (idOp == `OP_SPECIAL && idFunc == `FUNCT_SLT);
    wire idOpSrlv = (idOp == `OP_SPECIAL && idFunc == `FUNCT_SRLV);
    wire idOpSrav = (idOp == `OP_SPECIAL && idFunc == `FUNCT_SRAV);
    wire idOpClz = (idOp == `OP_SPECIAL2 && idFunc == `FUNCT_CLZ);
    wire idOpDivu = (idOp == `OP_SPECIAL && idFunc == `FUNCT_DIVU);
    wire idOpEret = (idOp == `OP_COP0 && idFunc == `FUNCT_ERET);
    wire idOpJalr = (idOp == `OP_SPECIAL && idFunc == `FUNCT_JALR);
    wire idOpLb = (idOp == `OP_LB);
    wire idOpLbu = (idOp == `OP_LBU);
    wire idOpLhu = (idOp == `OP_LHU);
    wire idOpSb = (idOp == `OP_SB);
    wire idOpSh = (idOp == `OP_SH);
    wire idOpLh = (idOp == `OP_LH);
    wire idOpMfc0 = (idOp == `OP_COP0 && idRs == `RS_MF);
    wire idOpMfhi = (idOp == `OP_SPECIAL && idFunc == `FUNCT_MFHI);
    wire idOpMflo = (idOp == `OP_SPECIAL && idFunc == `FUNCT_MFLO);
    wire idOpMtc0 = (idOp == `OP_COP0 && idRs == `RS_MT);
    wire idOpMthi = (idOp == `OP_SPECIAL && idFunc == `FUNCT_MTHI);
    wire idOpMtlo = (idOp == `OP_SPECIAL && idFunc == `FUNCT_MTLO);
    wire idOpMul = (idOp == `OP_SPECIAL2 && idFunc == `FUNCT_MUL);
    wire idOpMultu = (idOp == `OP_SPECIAL && idFunc == `FUNCT_MULTU);
    wire idOpSyscall = (idOp == `OP_SPECIAL && idFunc == `FUNCT_SYSCALL);
    wire idOpTeq = (idOp == `OP_SPECIAL && idFunc == `FUNCT_TEQ);
    wire idOpBgez = (idOp == `OP_REGIMM && idRt == `RT_BGEZ);
    wire idOpBreak = (idOp == `OP_SPECIAL && idFunc == `FUNCT_BREAK);
    wire idOpDiv = (idOp == `OP_SPECIAL && idFunc == `FUNCT_DIV);

    // EX部分译码
    wire [5:0] exOp = id_ex_inst[31:26];
    wire [5:0] exFunc = id_ex_inst[5:0];
    wire [5:0] exRs = id_ex_inst[25:21];
    wire [4:0] exRt = id_ex_inst[20:16];
    wire [4:0] exRd = id_ex_inst[15:11];
    wire exOpAddi = (exOp == `OP_ADDI);
    wire exOpAddiu = (exOp == `OP_ADDIU);
    wire exOpAndi = (exOp == `OP_ANDI);
    wire exOpOri = (exOp == `OP_ORI);
    wire exOpSltiu = (exOp == `OP_SLTIU);
    wire exOpLui = (exOp == `OP_LUI);
    wire exOpXori = (exOp == `OP_XORI);
    wire exOpSlti = (exOp == `OP_SLTI);
    wire exOpAddu = (exOp == `OP_SPECIAL && exFunc == `FUNCT_ADDU);
    wire exOpAnd = (exOp == `OP_SPECIAL && exFunc == `FUNCT_AND);
    wire exOpBeq = (exOp == `OP_BEQ);
    wire exOpBne = (exOp == `OP_BNE);
    wire exOpJ = (exOp == `OP_J);
    wire exOpJal = (exOp == `OP_JAL);
    wire exOpJr = (exOp == `OP_SPECIAL && exFunc == `FUNCT_JR);
    wire exOpLw = (exOp == `OP_LW);
    wire exOpXor = (exOp == `OP_SPECIAL && exFunc == `FUNCT_XOR);
    wire exOpNor = (exOp == `OP_SPECIAL && exFunc == `FUNCT_NOR);
    wire exOpOr = (exOp == `OP_SPECIAL && exFunc == `FUNCT_OR);
    wire exOpSll = (exOp == `OP_SPECIAL && exFunc == `FUNCT_SLL && id_ex_inst != 32'b0);
    wire exOpSllv = (exOp == `OP_SPECIAL && exFunc == `FUNCT_SLLV);
    wire exOpSltu = (exOp == `OP_SPECIAL && exFunc == `FUNCT_SLTU);
    wire exOpSra = (exOp == `OP_SPECIAL && exFunc == `FUNCT_SRA);
    wire exOpSrl = (exOp == `OP_SPECIAL && exFunc == `FUNCT_SRL);
    wire exOpSubu = (exOp == `OP_SPECIAL && exFunc == `FUNCT_SUBU);
    wire exOpSw = (exOp == `OP_SW);
    wire exOpAdd = (exOp == `OP_SPECIAL && exFunc == `FUNCT_ADD);
    wire exOpSub = (exOp == `OP_SPECIAL && exFunc == `FUNCT_SUB);
    wire exOpSlt = (exOp == `OP_SPECIAL && exFunc == `FUNCT_SLT);
    wire exOpSrlv = (exOp == `OP_SPECIAL && exFunc == `FUNCT_SRLV);
    wire exOpSrav = (exOp == `OP_SPECIAL && exFunc == `FUNCT_SRAV);
    wire exOpClz = (exOp == `OP_SPECIAL2 && exFunc == `FUNCT_CLZ);
    wire exOpDivu = (exOp == `OP_SPECIAL && exFunc == `FUNCT_DIVU);
    wire exOpEret = (exOp == `OP_COP0 && exFunc == `FUNCT_ERET);
    wire exOpJalr = (exOp == `OP_SPECIAL && exFunc == `FUNCT_JALR);
    wire exOpLb = (exOp == `OP_LB);
    wire exOpLbu = (exOp == `OP_LBU);
    wire exOpLhu = (exOp == `OP_LHU);
    wire exOpSb = (exOp == `OP_SB);
    wire exOpSh = (exOp == `OP_SH);
    wire exOpLh = (exOp == `OP_LH);
    wire exOpMfc0 = (exOp == `OP_COP0 && exRs == `RS_MF);
    wire exOpMfhi = (exOp == `OP_SPECIAL && exFunc == `FUNCT_MFHI);
    wire exOpMflo = (exOp == `OP_SPECIAL && exFunc == `FUNCT_MFLO);
    wire exOpMtc0 = (exOp == `OP_COP0 && exRs == `RS_MT);
    wire exOpMthi = (exOp == `OP_SPECIAL && exFunc == `FUNCT_MTHI);
    wire exOpMtlo = (exOp == `OP_SPECIAL && exFunc == `FUNCT_MTLO);
    wire exOpMul = (exOp == `OP_SPECIAL2 && exFunc == `FUNCT_MUL);
    wire exOpMultu = (exOp == `OP_SPECIAL && exFunc == `FUNCT_MULTU);
    wire exOpSyscall = (exOp == `OP_SPECIAL && exFunc == `FUNCT_SYSCALL);
    wire exOpTeq = (exOp == `OP_SPECIAL && exFunc == `FUNCT_TEQ);
    wire exOpBgez = (exOp == `OP_REGIMM && exRt == `RT_BGEZ);
    wire exOpBreak = (exOp == `OP_SPECIAL && exFunc == `FUNCT_BREAK);
    wire exOpDiv = (exOp == `OP_SPECIAL && exFunc == `FUNCT_DIV);

    // ME部分译码
    wire [5:0] meOp = ex_mem_inst[31:26];
    wire [5:0] meFunc = ex_mem_inst[5:0];
    wire [5:0] meRs = ex_mem_inst[25:21];
    wire [4:0] meRt = ex_mem_inst[20:16];
    wire [4:0] meRd = ex_mem_inst[15:11];
    wire meOpAddi = (meOp == `OP_ADDI);
    wire meOpAddiu = (meOp == `OP_ADDIU);
    wire meOpAndi = (meOp == `OP_ANDI);
    wire meOpOri = (meOp == `OP_ORI);
    wire meOpSltiu = (meOp == `OP_SLTIU);
    wire meOpLui = (meOp == `OP_LUI);
    wire meOpXori = (meOp == `OP_XORI);
    wire meOpSlti = (meOp == `OP_SLTI);
    wire meOpAddu = (meOp == `OP_SPECIAL && meFunc == `FUNCT_ADDU);
    wire meOpAnd = (meOp == `OP_SPECIAL && meFunc == `FUNCT_AND);
    wire meOpBeq = (meOp == `OP_BEQ);
    wire meOpBne = (meOp == `OP_BNE);
    wire meOpJ = (meOp == `OP_J);
    wire meOpJal = (meOp == `OP_JAL);
    wire meOpJr = (meOp == `OP_SPECIAL && meFunc == `FUNCT_JR);
    wire meOpLw = (meOp == `OP_LW);
    wire meOpXor = (meOp == `OP_SPECIAL && meFunc == `FUNCT_XOR);
    wire meOpNor = (meOp == `OP_SPECIAL && meFunc == `FUNCT_NOR);
    wire meOpOr = (meOp == `OP_SPECIAL && meFunc == `FUNCT_OR);
    wire meOpSll = (meOp == `OP_SPECIAL && meFunc == `FUNCT_SLL && ex_mem_inst != 32'b0);
    wire meOpSllv = (meOp == `OP_SPECIAL && meFunc == `FUNCT_SLLV);
    wire meOpSltu = (meOp == `OP_SPECIAL && meFunc == `FUNCT_SLTU);
    wire meOpSra = (meOp == `OP_SPECIAL && meFunc == `FUNCT_SRA);
    wire meOpSrl = (meOp == `OP_SPECIAL && meFunc == `FUNCT_SRL);
    wire meOpSubu = (meOp == `OP_SPECIAL && meFunc == `FUNCT_SUBU);
    wire meOpSw = (meOp == `OP_SW);
    wire meOpAdd = (meOp == `OP_SPECIAL && meFunc == `FUNCT_ADD);
    wire meOpSub = (meOp == `OP_SPECIAL && meFunc == `FUNCT_SUB);
    wire meOpSlt = (meOp == `OP_SPECIAL && meFunc == `FUNCT_SLT);
    wire meOpSrlv = (meOp == `OP_SPECIAL && meFunc == `FUNCT_SRLV);
    wire meOpSrav = (meOp == `OP_SPECIAL && meFunc == `FUNCT_SRAV);
    wire meOpClz = (meOp == `OP_SPECIAL2 && meFunc == `FUNCT_CLZ);
    wire meOpDivu = (meOp == `OP_SPECIAL && meFunc == `FUNCT_DIVU);
    wire meOpEret = (meOp == `OP_COP0 && meFunc == `FUNCT_ERET);
    wire meOpJalr = (meOp == `OP_SPECIAL && meFunc == `FUNCT_JALR);
    wire meOpLb = (meOp == `OP_LB);
    wire meOpLbu = (meOp == `OP_LBU);
    wire meOpLhu = (meOp == `OP_LHU);
    wire meOpSb = (meOp == `OP_SB);
    wire meOpSh = (meOp == `OP_SH);
    wire meOpLh = (meOp == `OP_LH);
    wire meOpMfc0 = (meOp == `OP_COP0 && meRs == `RS_MF);
    wire meOpMfhi = (meOp == `OP_SPECIAL && meFunc == `FUNCT_MFHI);
    wire meOpMflo = (meOp == `OP_SPECIAL && meFunc == `FUNCT_MFLO);
    wire meOpMtc0 = (meOp == `OP_COP0 && meRs == `RS_MT);
    wire meOpMthi = (meOp == `OP_SPECIAL && meFunc == `FUNCT_MTHI);
    wire meOpMtlo = (meOp == `OP_SPECIAL && meFunc == `FUNCT_MTLO);
    wire meOpMul = (meOp == `OP_SPECIAL2 && meFunc == `FUNCT_MUL);
    wire meOpMultu = (meOp == `OP_SPECIAL && meFunc == `FUNCT_MULTU);
    wire meOpSyscall = (meOp == `OP_SPECIAL && meFunc == `FUNCT_SYSCALL);
    wire meOpTeq = (meOp == `OP_SPECIAL && meFunc == `FUNCT_TEQ);
    wire meOpBgez = (meOp == `OP_REGIMM && meRt == `RT_BGEZ);
    wire meOpBreak = (meOp == `OP_SPECIAL && meFunc == `FUNCT_BREAK);
    wire meOpDiv = (meOp == `OP_SPECIAL && meFunc == `FUNCT_DIV);
    
     // WB部分译码
       wire [5:0] wbOp = mem_wb_inst[31:26];
       wire [5:0] wbFunc = mem_wb_inst[5:0];
       wire [5:0] wbRs = mem_wb_inst[25:21];
       wire [4:0] wbRt = mem_wb_inst[20:16];
       wire [4:0] wbRd = mem_wb_inst[15:11];
       wire wbOpAddi = (wbOp == `OP_ADDI);
       wire wbOpAddiu = (wbOp == `OP_ADDIU);
       wire wbOpAndi = (wbOp == `OP_ANDI);
       wire wbOpOri = (wbOp == `OP_ORI);
       wire wbOpSltiu = (wbOp == `OP_SLTIU);
       wire wbOpLui = (wbOp == `OP_LUI);
       wire wbOpXori = (wbOp == `OP_XORI);
       wire wbOpSlti = (wbOp == `OP_SLTI);
       wire wbOpAddu = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_ADDU);
       wire wbOpAnd = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_AND);
       wire wbOpBeq = (wbOp == `OP_BEQ);
       wire wbOpBne = (wbOp == `OP_BNE);
       wire wbOpJ = (wbOp == `OP_J);
       wire wbOpJal = (wbOp == `OP_JAL);
       wire wbOpJr = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_JR);
       wire wbOpLw = (wbOp == `OP_LW);
       wire wbOpXor = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_XOR);
       wire wbOpNor = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_NOR);
       wire wbOpOr = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_OR);
       wire wbOpSll = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_SLL && mem_wb_inst != 32'b0);
       wire wbOpSllv = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_SLLV);
       wire wbOpSltu = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_SLTU);
       wire wbOpSra = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_SRA);
       wire wbOpSrl = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_SRL);
       wire wbOpSubu = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_SUBU);
       wire wbOpSw = (wbOp == `OP_SW);
       wire wbOpAdd = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_ADD);
       wire wbOpSub = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_SUB);
       wire wbOpSlt = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_SLT);
       wire wbOpSrlv = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_SRLV);
       wire wbOpSrav = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_SRAV);
       wire wbOpClz = (wbOp == `OP_SPECIAL2 && wbFunc == `FUNCT_CLZ);
       wire wbOpDivu = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_DIVU);
       wire wbOpEret = (wbOp == `OP_COP0 && wbFunc == `FUNCT_ERET);
       wire wbOpJalr = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_JALR);
       wire wbOpLb = (wbOp == `OP_LB);
       wire wbOpLbu = (wbOp == `OP_LBU);
       wire wbOpLhu = (wbOp == `OP_LHU);
       wire wbOpSb = (wbOp == `OP_SB);
       wire wbOpSh = (wbOp == `OP_SH);
       wire wbOpLh = (wbOp == `OP_LH);
       wire wbOpMfc0 = (wbOp == `OP_COP0 && wbRs == `RS_MF);
       wire wbOpMfhi = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_MFHI);
       wire wbOpMflo = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_MFLO);
       wire wbOpMtc0 = (wbOp == `OP_COP0 && wbRs == `RS_MT);
       wire wbOpMthi = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_MTHI);
       wire wbOpMtlo = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_MTLO);
       wire wbOpMul = (wbOp == `OP_SPECIAL2 && wbFunc == `FUNCT_MUL);
       wire wbOpMultu = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_MULTU);
       wire wbOpSyscall = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_SYSCALL);
       wire wbOpTeq = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_TEQ);
       wire wbOpBgez = (wbOp == `OP_REGIMM && wbRt == `RT_BGEZ);
       wire wbOpBreak = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_BREAK);
       wire wbOpDiv = (wbOp == `OP_SPECIAL && wbFunc == `FUNCT_DIV);

//ALU运算控制信号
parameter ADDU    =    4'b0000;    //r=a+b unsigned
parameter ADD    =    4'b0010;    //r=a+b signed
parameter SUBU    =    4'b0001;    //r=a-b unsigned
parameter SUB    =    4'b0011;    //r=a-b signed
parameter AND    =    4'b0100;    //r=a&b
parameter OR    =    4'b0101;    //r=a|b
parameter XOR    =    4'b0110;    //r=a^b
parameter NOR    =    4'b0111;    //r=~(a|b)
parameter LUI    =    4'b1000;    //r={b[15:0],16'b0}
parameter SLT    =    4'b1011;    //r=(a-b<0)?1:0 signed
parameter SLTU    =    4'b1010;    //r=(a-b<0)?1:0 unsigned
parameter SRA   =    4'b1100;    //r=b>>>a 
parameter SLL    =    4'b1110;    //r=b<<a
parameter SRL    =    4'b1101;    //r=b>>a
parameter CLZ   =   4'b1111;           

//interface
assign DM_W = mem_dm_w;
assign DM_R = mem_dm_r;
assign DM_wdata = mem_dm_wdata;
assign DM_addr = mem_dm_addr;
assign Byte_ena = mem_byte_ena;

//cp0
wire exception;
assign exception = idOpSyscall||idOpBreak||idOpTeq;
wire[4:0] cause;
assign cause=idOpSyscall?5'b01000:idOpBreak?5'b01001:idOpTeq?5'b01101:5'b11111;
wire[4:0] cp0_addr;
assign cp0_addr = wbOpMtc0?wb_cp0_waddr:idOpMfc0?id_cp0_raddr:5'bz;

//pc
wire[31:0] pc_out,pc_in;//pc_reg输入输出
wire pc_ena;
assign pc_ena = id_pc_ena;
assign pc_in = id_pc_ena?id_pc_in:32'bz;
assign PC_out = pc_out;

//alu
wire[31:0]alua,alub,aluo;
wire zeroFlag,negFlag,overflowFlag,carryFlag;
wire[3:0]aluc;
assign alua = ex_alua;
assign alub = ex_alub;
assign aluc = (exOpAddi||exOpJal||exOpLw||exOpSw||exOpAdd||exOpJalr||exOpLb||exOpLbu
                ||exOpLhu||exOpSb||exOpSh||exOpLh)?ADD:
                (exOpAddiu||exOpAddu)?ADDU:(exOpSubu)?SUBU:(exOpSub)?SUB:(exOpAnd||exOpAndi)?AND:
                (exOpOr||exOpOri)?OR:(exOpXor||exOpXori)?XOR:(exOpNor)?NOR:(exOpLui)?LUI:
                (exOpSlt||exOpSlti)?SLT:(exOpSltu||exOpSltiu)?SLTU:(exOpSra||exOpSrav)?SRA:
                (exOpSll||exOpSllv)?SLL:(exOpSrl||exOpSrlv)?SRL:(exOpClz)?CLZ: 4'bz;


//regfile
wire[4:0]rdc,rtc,rsc;
wire[31:0]rd,rt,rs;
wire RF_W;
assign rtc = id_rtc;
assign rsc = id_rsc;
assign rdc = wb_rdc;
assign RF_W = wb_rf_wena;
assign rd = wb_rd;

//mul,multu
    wire[31:0] mula,mulb,multua,multub;
    wire[63:0]mulz,multuz;
    assign mula = ex_mula;
    assign mulb = ex_mulb;
    assign multua = ex_multua;
    assign multub = ex_multub;
    
    
    //div
    wire divBusy,divuBusy;
    wire divStart,divuStart;
    wire[31:0]dividend,udividend,divq,divr,divuq,divur;
    wire [31:0]divisor,udivisor;
    assign divStart = ex_div_start;
    assign divuStart = ex_divu_start;
    assign dividend = ex_div_dividend;
    assign udividend = ex_divu_dividend;
    assign divisor = ex_div_divisor;
    assign udivisor = ex_divu_divisor;
    
///////各段wire信号赋值///////

//IF
assign if_pc_out = pc_out;
//assign if_pc_in = if_id_npc;
assign if_inst = IM_inst;
//这里没有默认编译器的延迟分支处理，所以需要排空跳转指令的下一条指令！
//只有不是跳转指令的，才在if段更新pc。异常陷入例外，因为跳转位置固定。
//跳转指令会在完成if段后零if_id寄存器清零，在id段更新pc。
//assign if_pc_ena = (!ifOpBeq)&&(!ifOpBne)&&(!ifOpJ)&&(!ifOpJal)&&(!ifOpJr)
//                    &&(!ifOpEret)&&(!ifOpJalr)&&(!ifOpBgez);

//ID
wire[15:0] imm16 = if_id_inst[15:0];
assign id_sext16 = imm16[15]==0?{16'b0,imm16}:{16'hffff,imm16};
assign id_uext16={16'b0,imm16};
wire[4:0]imm5 = if_id_inst[10:6];
assign id_uext5={27'b0,imm5};
wire[17:0]imm18 = {if_id_inst[15:0],2'b0};
assign id_sext18=imm18[17]==0?{14'b0,imm18}:{14'b11111111111111,imm18};
assign id_rsc = idRs;
assign id_rtc = idRt;
assign id_rs = rs;
assign id_rt = rt;
assign id_pc_ena =1'b1;
assign id_npc = if_id_npc; 
assign id_pc_in =((!idOpBeq)&&(!idOpBne)&&(!idOpJ)&&(!idOpJal)&&(!idOpJr)
                    &&(!idOpEret)&&(!idOpJalr)&&(!idOpBgez))?id_npc:
                    idOpBeq?id_rs==id_rt?id_npc+id_sext18:id_npc:
                    idOpBne?id_rs==id_rt?id_npc:id_npc+id_sext18:
                    idOpJ?{id_npc[31:28],if_id_inst[25:0],2'b0}:
                    idOpJal?{id_npc[31:28],if_id_inst[25:0],2'b0}:
                    idOpJr?id_rs:idOpEret?id_cp0_epcout:idOpJalr?id_rs:
                    idOpBgez?$signed(id_rs)>=0?id_npc+id_sext18:id_npc:32'bz;
assign id_alua = (idOpClz||idOpLui)?32'bz:(idOpJal||idOpJalr)?id_npc:(idOpSll||idOpSra||idOpSrl)?
                id_uext5:id_rs;   
assign id_alub = idOpClz?id_rs:(idOpAddi||idOpAddiu||idOpSltiu||idOpSlti||idOpLw||idOpSw||idOpLb
                  ||idOpLbu||idOpLhu||idOpSb||idOpSh||idOpLh)?id_sext16:
                  (idOpAndi||idOpOri||idOpXori||idOpLui)?id_uext16:(idOpJal||idOpJalr)?32'd0:id_rt;
assign id_cp0_raddr = if_id_inst[15:11];
assign id_pass_data = idOpMfc0?id_cp0_rdata:idOpMfhi?HI:idOpMflo?LO:(idOpMtc0||idOpSw||idOpSb||idOpSh)?id_rt:
                      (idOpMthi||idOpMtlo)?id_rs:32'bz;
                      
             
//EX
reg div_start_reg,divu_start_reg;

always@(*)begin
div_start_reg = 0;
divu_start_reg = 0;
if(exOpDiv&&!stall[`STAGE_EX]&&!divBusy)begin
div_start_reg = 1;
end
if(exOpDivu&&!stall[`STAGE_EX]&&!divuBusy)begin
divu_start_reg = 1;
end
end

assign ex_alua = id_ex_alua;
assign ex_alub = id_ex_alub;
assign ex_aluo = aluo;
assign ex_mula = id_ex_alua;
assign ex_mulb = id_ex_alub;
assign ex_multua = id_ex_alua;
assign ex_multub = id_ex_alub;
assign ex_mulz = mulz;
assign ex_multuz = multuz;
assign ex_div_busy = divBusy;
assign ex_divu_busy = divuBusy;
assign ex_div_start = div_start_reg;
assign ex_divu_start = divu_start_reg;
assign ex_div_dividend = id_ex_alua;
assign ex_div_divisor = id_ex_alub;
assign ex_div_q = divq;
assign ex_div_r = divr;
assign ex_divu_dividend = id_ex_alua;
assign ex_divu_divisor = id_ex_alub;
assign ex_divu_q = divuq;
assign ex_divu_r = divur;


//MEM
assign mem_byte_ena = meOpSw?4'b1111:meOpSb?4'b0001:meOpSh?4'b0011:4'b0000;
assign mem_dm_r = meOpLw||meOpLb||meOpLbu||meOpLh||meOpLhu;
assign mem_dm_w = meOpSw||meOpSb||meOpSh;
assign mem_dm_rdata = DM_rdata;
assign mem_dm_wdata = ex_mem_pass_data;
assign mem_byte_ext = meOpLb?mem_dm_rdata[7]==0?{24'b0,mem_dm_rdata[7:0]}:{24'hffffff,mem_dm_rdata[7:0]}:meOpLbu?{24'b0,mem_dm_rdata[7:0]}:32'bz;
assign mem_half_ext = meOpLh?mem_dm_rdata[15]==0?{16'b0,mem_dm_rdata[15:0]}:{16'hffff,mem_dm_rdata[15:0]}:meOpLhu?{16'b0,mem_dm_rdata[15:0]}:32'bz;
assign mem_dm_addr = ex_mem_aluo;

//WB
assign wb_rf_wena = (wbOpAddi&&!mem_wb_overflowFlag)||wbOpAddiu||wbOpAndi||wbOpOri||wbOpSltiu||wbOpLui||wbOpXori||wbOpSlti
                    ||wbOpAddu||wbOpJal||wbOpAnd||wbOpLw||wbOpXor||wbOpNor||wbOpOr||wbOpSll||wbOpSllv||wbOpSltu
                    ||wbOpSra||wbOpSrl||wbOpSubu||(wbOpAdd&&!mem_wb_overflowFlag)||wbOpSub||wbOpSlt||wbOpSrlv||wbOpSrav||wbOpClz
                    ||wbOpJalr||wbOpLb||wbOpLbu||wbOpLhu||wbOpLh||wbOpMfc0||wbOpMfhi||wbOpMflo||wbOpMul;                  
assign wb_rdc = (wbOpAddi||wbOpAddiu||wbOpAndi||wbOpOri||wbOpSltiu||wbOpLui||wbOpXori||wbOpSlti||wbOpLw
                ||wbOpLb||wbOpLbu||wbOpLhu||wbOpLh||wbOpMfc0)?wbRt:(wbOpAddu||wbOpAnd||wbOpXor||wbOpNor
                ||wbOpOr||wbOpSll||wbOpSllv||wbOpSltu||wbOpSra||wbOpSrl||wbOpSubu||wbOpAdd||wbOpSub||wbOpSlt
                ||wbOpSrlv||wbOpSrav||wbOpClz||(wbOpJalr&&wbRd!=5'b0)||wbOpMfhi||wbOpMflo||wbOpMul)?wbRd:(wbOpJal||(wbOpJalr&&wbRd==5'b0))?5'd31:32'bz;
assign wb_cp0_waddr = wbOpMtc0?wbRd:5'bz;
assign wb_rd = ((wbOpAddi&&!mem_wb_overflowFlag)||wbOpAddiu||wbOpAndi||wbOpOri||wbOpSltiu||wbOpLui||wbOpXori||wbOpSlti
                    ||wbOpAddu||wbOpJal||wbOpAnd||wbOpXor||wbOpNor||wbOpOr||wbOpSll||wbOpSllv||wbOpSltu
                    ||wbOpSra||wbOpSrl||wbOpSubu||(wbOpAdd&&!mem_wb_overflowFlag)||wbOpSub||wbOpSlt||wbOpSrlv||wbOpSrav||wbOpClz
                    ||wbOpJalr)?mem_wb_aluo:(wbOpLw||wbOpLb||wbOpLbu||wbOpLhu||wbOpLh||wbOpMfc0||wbOpMfhi||wbOpMflo)?mem_wb_pass_data:
                    (wbOpMul)?mem_wb_mulz[31:0]:32'bz;
assign wb_cp0_wdata = wbOpMtc0?mem_wb_pass_data:32'bz;
assign wb_hi_wena = wbOpDivu||wbOpDiv||wbOpMultu||wbOpMthi;
assign wb_lo_wena = wbOpDivu||wbOpDiv||wbOpMultu||wbOpMtlo;
assign wb_hi_wdata =(wbOpDivu||wbOpDiv)?mem_wb_div_r:wbOpMultu?mem_wb_mulz[63:32]:wbOpMthi?mem_wb_pass_data:32'bz;
assign wb_lo_wdata = (wbOpDivu||wbOpDiv)?mem_wb_div_q:wbOpMultu?mem_wb_mulz[31:0]:wbOpMtlo?mem_wb_pass_data:32'bz;

wire wRegId,wRegEx,wRegMe,rRsId,rRtId;
wire[4:0] wAddrId,wAddrEx,wAddrMe;

assign wRegId = idOpAddi||idOpAddiu||idOpAndi||idOpOri||idOpSltiu||idOpLui||idOpXori||idOpSlti
                    ||idOpAddu||idOpJal||idOpAnd||idOpLw||idOpXor||idOpNor||idOpOr||idOpSll||idOpSllv||idOpSltu
                    ||idOpSra||idOpSrl||idOpSubu||idOpAdd||idOpSub||idOpSlt||idOpSrlv||idOpSrav||idOpClz
                    ||idOpJalr||idOpLb||idOpLbu||idOpLhu||idOpLh||idOpMfc0||idOpMfhi||idOpMflo||idOpMul;
assign wRegEx = exOpAddi||exOpAddiu||exOpAndi||exOpOri||exOpSltiu||exOpLui||exOpXori||exOpSlti
                    ||exOpAddu||exOpJal||exOpAnd||exOpLw||exOpXor||exOpNor||exOpOr||exOpSll||exOpSllv||exOpSltu
                    ||exOpSra||exOpSrl||exOpSubu||exOpAdd||exOpSub||exOpSlt||exOpSrlv||exOpSrav||exOpClz
                    ||exOpJalr||exOpLb||exOpLbu||exOpLhu||exOpLh||exOpMfc0||exOpMfhi||exOpMflo||exOpMul;
assign wRegMe = (meOpAddi&&!ex_mem_overflowFlag)||meOpAddiu||meOpAndi||meOpOri||meOpSltiu||meOpLui||meOpXori||meOpSlti
                                        ||meOpAddu||meOpJal||meOpAnd||meOpLw||meOpXor||meOpNor||meOpOr||meOpSll||meOpSllv||meOpSltu
                                        ||meOpSra||meOpSrl||meOpSubu||(meOpAdd&&!ex_mem_overflowFlag)||meOpSub||meOpSlt||meOpSrlv||meOpSrav||meOpClz
                                        ||meOpJalr||meOpLb||meOpLbu||meOpLhu||meOpLh||meOpMfc0||meOpMfhi||meOpMflo||meOpMul;
assign rRsId = idOpAdd||idOpAddi||idOpAddiu||idOpAddu||idOpAnd||idOpAndi||idOpBeq||idOpBgez||idOpBne||idOpClz||idOpDiv||idOpDivu||idOpJalr||idOpJr||idOpLb
                ||idOpLbu||idOpLh||idOpLhu||idOpLw||idOpMthi||idOpMtlo||idOpMul||idOpMultu||idOpNor||idOpOr||idOpOri||idOpSb||idOpSh||idOpSllv
                ||idOpSlt||idOpSlti||idOpSltiu||idOpSltu||idOpSrav||idOpSrlv||idOpSub||idOpSubu||idOpSw||idOpXor||idOpXori;
assign rRtId = idOpAdd||idOpAddu||idOpAnd||idOpBeq||idOpBne||idOpDiv||idOpDivu||idOpMul||idOpMultu||idOpNor||idOpOr||idOpSb||idOpSh||idOpSllv
               ||idOpSlt||idOpSltu||idOpSrav||idOpSrlv||idOpSub||idOpSubu||idOpSw||idOpXor
               ||idOpMtc0||idOpSll||idOpSra||idOpSrl;

assign wAddrId = (idOpAddi||idOpAddiu||idOpAndi||idOpOri||idOpSltiu||idOpLui||idOpXori||idOpSlti||idOpLw
                ||idOpLb||idOpLbu||idOpLhu||idOpLh||idOpMfc0)?idRt:(idOpAddu||idOpAnd||idOpXor||idOpNor
                ||idOpOr||idOpSll||idOpSllv||idOpSltu||idOpSra||idOpSrl||idOpSubu||idOpAdd||idOpSub||idOpSlt
                ||idOpSrlv||idOpSrav||idOpClz||(idOpJalr&&if_id_inst[15:11]!=5'b0)||idOpMfhi||idOpMflo||idOpMul)?if_id_inst[15:11]:(idOpJal||(idOpJalr&&if_id_inst[15:11]==5'b0))?5'd31:32'bz;


assign wAddrEx = (exOpAddi||exOpAddiu||exOpAndi||exOpOri||exOpSltiu||exOpLui||exOpXori||exOpSlti||exOpLw
                ||exOpLb||exOpLbu||exOpLhu||exOpLh||exOpMfc0)?exRt:(exOpAddu||exOpAnd||exOpXor||exOpNor
                ||exOpOr||exOpSll||exOpSllv||exOpSltu||exOpSra||exOpSrl||exOpSubu||exOpAdd||exOpSub||exOpSlt
                ||exOpSrlv||exOpSrav||exOpClz||(exOpJalr&&exRd!=5'b0)||exOpMfhi||exOpMflo||exOpMul)?exRd:(exOpJal||(exOpJalr&&exRd==5'b0))?5'd31:32'bz;

assign wAddrMe = (meOpAddi||meOpAddiu||meOpAndi||meOpOri||meOpSltiu||meOpLui||meOpXori||meOpSlti||meOpLw
                                ||meOpLb||meOpLbu||meOpLhu||meOpLh||meOpMfc0)?meRt:(meOpAddu||meOpAnd||meOpXor||meOpNor
                                ||meOpOr||meOpSll||meOpSllv||meOpSltu||meOpSra||meOpSrl||meOpSubu||meOpAdd||meOpSub||meOpSlt
                                ||meOpSrlv||meOpSrav||meOpClz||(meOpJalr&&meRd!=5'b0)||meOpMfhi||meOpMflo||meOpMul)?meRd:(meOpJal||(meOpJalr&&meRd==5'b0))?5'd31:32'bz;

//wire anti_clk = ~clk;

//更新等待信号stall
always @ (*) begin
        stall = `CTRL_STALLW'b0;
        //跳转指令会在id阶段的时钟下降沿读reg写pc，所以在if段就要判断冲突！
        if(ifOpJr||ifOpJalr||ifOpBne||ifOpBeq||ifOpBgez)begin
            if(wRegId && (wAddrId == ifRs||((ifOpBne||ifOpBeq)&&wAddrId==ifRt)))begin
            stall = `CTRL_STALL_IF;
            end
            if(wRegEx && (wAddrEx == ifRs||((ifOpBne||ifOpBeq)&&wAddrEx==ifRt)))begin
            stall = `CTRL_STALL_IF;
            end
            if(wRegMe && (wAddrMe == ifRs||((ifOpBne||ifOpBeq)&&wAddrMe==ifRt)))begin
            stall = `CTRL_STALL_IF;
            end
        end
        if (wRegEx) begin                           //相邻指令的regfile先写后读
            if (
                (rRsId && wAddrEx == idRs) ||
                (rRtId && wAddrEx == idRt)
            ) begin
                stall = `CTRL_STALL_ID;    
            end
        end
        if ((exOpMthi||exOpMultu||exOpDiv||exOpDivu) && idOpMfhi) begin      //相邻指令的HI先写后读
            stall = `CTRL_STALL_ID;
        end
        if ((exOpMtlo||exOpMultu||exOpDiv||exOpDivu) && idOpMflo) begin      //相邻指令的LO先写后读
            stall = `CTRL_STALL_ID;    
        end
        if (exOpMtc0 && idOpMfc0) begin    //相邻指令的cp0先写后读
            stall = `CTRL_STALL_ID;    
        end
        if (wRegMe) begin                  //间隔一条指令的regfile先写后读
            if (
                (rRsId && wAddrMe == idRs) ||
                (rRtId && wAddrMe == idRt)
            ) begin
                stall = `CTRL_STALL_ID;
            end
        end
        if ((meOpMthi||meOpMultu||meOpDiv||meOpDivu) && idOpMfhi) begin    //间隔一条指令的HI先写后读
            stall = `CTRL_STALL_ID;    
        end
        if ((meOpMtlo||meOpMultu||meOpDiv||meOpDivu) && idOpMflo) begin    //间隔一条指令的LO先写后读
            stall = `CTRL_STALL_ID;    
        end
        if (meOpMtc0 && idOpMfc0) begin    //间隔一条指令的cp0先写后读
            stall = `CTRL_STALL_ID;    
        end
        if ((exOpDiv&&divBusy)||(exOpDivu&&divuBusy)) begin
            stall = `CTRL_STALL_EX;
        end
    end




//各段reg时序赋值
 // IF/ID段
 always @(posedge clk or posedge rst) begin
          if(rst) begin
            if_id_npc <= 32'b0;
            if_id_inst <= 32'b0;
        end
        else if(stall[`STAGE_IF] && (!stall[`STAGE_ID]))begin
            if_id_inst<=32'b0;
        end
        else if (!stall[`STAGE_IF]) begin
            if_id_inst <= if_inst;
            if(ifOpSyscall||ifOpTeq||ifOpBreak)begin
            if_id_npc<=32'h00400004;
            end
            else    begin   
            if_id_npc <= if_pc_out + 32'h4;
            end   
        end
    end



//ID_EX
always @ (posedge clk or posedge rst) begin
        if (rst) begin
        id_ex_alua<=32'b0;
        id_ex_alub<=32'b0;
        id_ex_pass_data<=32'b0;
        id_ex_inst<=32'b0;
        end
        else if(stall[`STAGE_ID] && !stall[`STAGE_EX])begin
        id_ex_alua<=32'b0;
        id_ex_alub<=32'b0;
        id_ex_pass_data<=32'b0;
        id_ex_inst<=32'b0;
        end
        else if (!stall[`STAGE_ID]) begin
        id_ex_alua<=id_alua;
        id_ex_alub<=id_alub;
        id_ex_pass_data<=id_pass_data;
        id_ex_inst<=if_id_inst;
        end
end

//EX_MEM
always @ (posedge clk or posedge rst) begin
        if (rst) begin
            ex_mem_div_q<=32'b0;
            ex_mem_div_r<=32'b0;
            ex_mem_mulz<=64'b0;
            ex_mem_aluo<=32'b0;
            ex_mem_pass_data<=32'b0;
            ex_mem_inst<=32'b0;
            ex_mem_overflowFlag<=1'b0;
        end
        else if (stall[`STAGE_EX] && !stall[`STAGE_ME])begin
                    ex_mem_div_q<=32'b0;
                    ex_mem_div_r<=32'b0;
                    ex_mem_mulz<=64'b0;
                    ex_mem_aluo<=32'b0;
                    ex_mem_pass_data<=32'b0;
                    ex_mem_inst<=32'b0;
                    ex_mem_overflowFlag<=1'b0;
        end
        else if (!stall[`STAGE_EX]) begin
            ex_mem_div_q<=exOpDiv?ex_div_q:exOpDivu?ex_divu_q:32'b0;
            ex_mem_div_r<=exOpDiv?ex_div_r:exOpDivu?ex_divu_r:32'b0;
            ex_mem_mulz<=exOpMul?ex_mulz:exOpMultu?ex_multuz:64'b0;
            ex_mem_aluo<=ex_aluo;
            ex_mem_pass_data<=id_ex_pass_data;
            ex_mem_inst<=id_ex_inst;
            ex_mem_overflowFlag<=overflowFlag;
        end
    end


//MEM_WB
always @ (posedge clk or posedge rst) begin
        if (rst) begin
        mem_wb_div_q<=32'b0;
        mem_wb_div_r<=32'b0;
        mem_wb_aluo<=32'b0;
        mem_wb_mulz<=64'b0;
        mem_wb_pass_data<=32'b0;
        mem_wb_inst<=32'b0;
        mem_wb_overflowFlag<=32'b0;
        end
        else if(stall[`STAGE_ME] && !stall[`STAGE_WB])begin
        mem_wb_div_q<=32'b0;
        mem_wb_div_r<=32'b0;
        mem_wb_aluo<=32'b0;
        mem_wb_mulz<=64'b0;
        mem_wb_pass_data<=32'b0;
        mem_wb_inst<=32'b0;
        mem_wb_overflowFlag<=32'b0;
        end
        else if (!stall[`STAGE_ME]) begin
            mem_wb_mulz<=ex_mem_mulz;
            mem_wb_div_q<=ex_mem_div_q;
            mem_wb_div_r<=ex_mem_div_r;
            mem_wb_aluo<=ex_mem_aluo;
            if(meOpLw)begin
                mem_wb_pass_data<=mem_dm_rdata;
            end
            else if(meOpLb||meOpLbu) begin
                mem_wb_pass_data<=mem_byte_ext;
            end
            else if(meOpLh||meOpLhu)begin
                mem_wb_pass_data<=mem_half_ext;
            end
            else begin
                mem_wb_pass_data<=ex_mem_pass_data;
            end
            mem_wb_inst<=ex_mem_inst;
            mem_wb_overflowFlag<=ex_mem_overflowFlag;
        end
    end

//更新HI,LO
always @ (negedge clk or posedge rst) begin
    if(rst)begin
    HI<=32'b0;
    end
    else if(wb_hi_wena)begin
    HI<=wb_hi_wdata;
    end
end

always @ (negedge clk or posedge rst) begin
    if(rst)begin
    LO<=32'b0;
    end
    else if(wb_lo_wena)begin
    LO<=wb_lo_wdata;
    end
end



 CP0 cp0(
    .clk(clk),				//时钟信号
    .rst(rst),				//reset信号
    .mfc0(idOpMfc0),				//指令为mfc0
    .mtc0(wbOpMtc0),				//指令为mtc0
    .eret(idOpEret),				//指令为eret
    .exception(exception),		//异常发生信号
    .cause(cause),		//异常原因
    .addr(cp0_addr),		//cp0寄存器地址
    .wdata(wb_cp0_wdata),		//写入的数据
    .pc(id_npc),			//npc->cp0.epc
    .rdata(id_cp0_rdata),		//Cp0寄存器读出数据
    .status(id_cp0_status),	//状态
    .exc_addr(id_cp0_epcout)	//异常发生地址
);
  
  PcReg pcreg(
   .clk(clk),
   .rst(rst),
   .ena(pc_ena),
   .PR_in(pc_in),
   .PR_out(pc_out)
   );
           
 ALU cpu_alu(
    .a(alua),
    .b(alub),
    .aluc(aluc),
    .r(aluo),
    .zero(zeroFlag),
    .carry(carryFlag),
    .negative(negFlag),
    .overflow(overflowFlag)
    );
           
RegFile cpu_ref(
    .RF_ena(1'b1), 
    .RF_rst(rst),
    .RF_clk(clk),
    .Rdc(rdc),
    .Rsc(rsc),
    .Rtc(rtc),
    .Rd(rd),
    .Rs(rs),
    .Rt(rt),
    .RF_W(RF_W)
    );
    


DIV cpu_div(
    .dividend(dividend),
    .divisor(divisor),
    .start(divStart),
    .clock(clk),
    .reset(rst),
    .q(divq),
    .r(divr),
    .busy(divBusy)
    );
 
DIVU cpu_divu(
            .dividend(udividend),
            .divisor(udivisor),
            .start(divuStart),
            .clock(clk),
            .reset(rst),
            .q(divuq),
            .r(divur),
            .busy(divuBusy)
            );
            
MULT cpu_mult(
                .clk(clk),
                .reset(rst),
                .a(mula),
                .b(mulb),
                .z(mulz)
            );
            
MULTU cpu_multu(
                .clk(clk),
                .reset(rst),
                .a(multua),
                .b(multub),
                .z(multuz)
            );



endmodule





