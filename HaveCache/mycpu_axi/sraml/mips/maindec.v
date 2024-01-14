`include "defines2.vh"
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: maindec
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


module maindec(
	input wire[5:0] op,
    input wire[5:0] funct,
	input wire[4:0] rs,
	input wire[4:0] rt,
	output wire memtoreg,
	output wire memwrite,
	output wire branch,
	output wire alusrc,
	output wire[1:0] regdst,
	output wire regwrite,
	output wire jump,
	output wire hilo_write,
	output wire jr,
	output wire jal,
	output wire cp0_write,
	output reg is_invalid         //保留指令例外信号
	
    );
	reg[11:0] controls;
	assign {memtoreg,memwrite,branch,alusrc, regdst ,regwrite,jump,hilo_write,jr,jal,cp0_write} = controls;
	always @(*) begin
		is_invalid <= 1'b0;
		case (op)
		    `R_TYPE:
		          case(funct)
				        //逻辑指令
					   `AND,`NOR,`OR,`XOR:               controls<= 12'b0000_01_100000;
					    //移位指令
					   `SLLV,`SLL,`SRAV,`SRA,`SRLV,`SRL: controls<= 12'b0000_01_100000;
					    //算术指令 
					   `ADD,`ADDU,`SUB,`SUBU,`SLT,`SLTU: controls<= 12'b0000_01_100000;
                       `DIV,`DIVU,`MULT,`MULTU:          controls<= 12'b0000_00_001000;
                        //数据移动指令
		               `MFHI,`MFLO:                      controls<= 12'b0000_01_100000;
		               `MTHI,`MTLO:						 controls<= 12'b0000_00_001000;
					    //跳转
                       `JR:     						 controls<= 12'b0000_00_000100;
					   `JALR:   						 controls<= 12'b0000_01_100110; 
					    //自陷指令
					   `BREAK,`SYSCALL:                  controls<= 12'b0000_00_000000;
					    default:  begin
						controls <= 12'b0000_00_000000;
						is_invalid <= 1'b1;
					end
		          endcase

            //I-type
			  //逻辑指令
			`ANDI,`LUI,`ORI,`XORI:      controls <= 12'b0001_00_100000;
			  //算术指令
			`ADDI,`ADDIU,`SLTI,`SLTIU:	controls <= 12'b0001_00_100000;
			  //访存指令
			`LB,`LBU,`LH,`LHU,`LW:		controls <= 12'b1001_00_100000;
			`SB,`SH,`SW:				controls <= 12'b0101_00_000000;
		      //分支跳转
			`J:                         controls <= 12'b0000_00_010000;
			`JAL:                       controls <= 12'b0000_10_110010;
			`BEQ,`BNE,`BGTZ,`BLEZ:		controls <= 12'b0010_00_000000;
			`REGIMM_INST:
				case (rt)
					`BGEZ,`BLTZ:		controls <= 12'b0010_00_000000;
					`BGEZAL,`BLTZAL:	controls <= 12'b0010_10_100010;
					default:  begin
						controls <= 12'b0000_00_000000;
						is_invalid <= 1'b1;
					end
				endcase

			//特权指令
			`SPECIAL3_INST:
				case(rs)
					`MTC0:  controls <= 12'b0000_00_000001;
        			`MFC0:  controls <= 12'b0000_00_100000;
        			`ERET:  controls <= 12'b0000_00_000000;
					default: begin
						controls <= 12'b0000_00_000000;
						is_invalid <= 1'b1;
					end
				endcase 
			default: begin
					controls <= 12'b0000_00_000000;
					is_invalid <= 1'b1;
			end
		endcase
	end
endmodule
