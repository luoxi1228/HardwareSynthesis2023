`timescale 1ns / 1ps
`include "defines2.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 14:52:16
// Design Name: 
// Module Name: alu
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




module alu(
	input wire clk,rst,
	input wire[31:0] a,b,            //操作数a，b
	input wire [4:0] alucontrolE,    //运算控制信号
	input wire [4:0] sa,             //立即数sa
	input wire [63:0] hilo_in,       //hilo寄存器输入
	input wire [31:0] cp0_rdata,     //读取cp0寄存器的值
	input wire is_except,            //触发异常，除法刷新
	output reg[63:0] hilo_out,       //hilo寄存器输出
	output reg[31:0] result,         //计算结果
	output wire div_ready,           //除法是否完成
	output reg div_stall,            //除法的流水线暂停控制
	output wire overflow             //溢出信号
    );

	reg double_sign; //凑运算结果的双符号位，处理整型溢出
	assign overflow = (alucontrolE==`ADD_CONTROL || alucontrolE==`SUB_CONTROL) & (double_sign ^ result[31]); 
	//div
	reg div_start;
	reg div_signed;
	reg [31:0] a_save; 
	reg [31:0] b_save;
	wire [63:0] div_result;
	always @(*) begin
		double_sign = 0;
		hilo_out = 64'b0;
		if(rst|is_except) 
		begin
			div_stall = 1'b0;
			div_start = 1'b0;
		end
		else begin
        	case(alucontrolE)
				//逻辑指令
				`AND_CONTROL   :  result = a & b;          //and,andi
				`OR_CONTROL    :  result = a | b;          //or,ori
				`XOR_CONTROL   :  result = a ^ b;          //xor
				`NOR_CONTROL   :  result = ~(a | b);       //nor,xori
				`LUI_CONTROL   :  result = {b[15:0],16'b0};//lui
				//移位指令
				`SLL_CONTROL   :  result = b << sa;               //sll
				`SRL_CONTROL   :  result = b >> sa;               //srl
				`SRA_CONTROL   :  result = $signed(b) >>> sa;     //sra
				`SLLV_CONTROL  :  result = b << a[4:0];           //sllv
				`SRLV_CONTROL  :  result = b >> a[4:0];           //srlv
				`SRAV_CONTROL  :  result = $signed(b) >>> a[4:0]; //srav
				//数据移动指令
				`MFHI_CONTROL  :  result = hilo_in[63:32];         //MFHI
				`MFLO_CONTROL  :  result = hilo_in[31:0];          //MFLO
				`MTHI_CONTROL  :  hilo_out = {a,hilo_in[31:0]};    //MTHI
				`MTLO_CONTROL  :  hilo_out = {hilo_in[63:32],a};   //ָMTLO
				//算术指令
				`ADD_CONTROL   :  {double_sign,result} = {a[31],a} + {b[31],b}; //ADD、ADDI
				`ADDU_CONTROL  :  result = a + b;                               //ADDU、ADDIU
				`SUB_CONTROL   :  {double_sign,result} = {a[31],a} - {b[31],b}; //SUB
				`SUBU_CONTROL  :  result = a - b;                               //SUBU
				`SLT_CONTROL: result = $signed(a) < $signed(b) ? 32'b1 : 32'b0; //SLT
				`SLTU_CONTROL:result = a < b ? 32'b1 : 32'b0;                   //SLTU
				`MULT_CONTROL: hilo_out = $signed(a) * $signed(b);              //MULT
				`MULTU_CONTROL:hilo_out = {32'b0, a} * {32'b0, b};              //MULTU

                // 5'b10110: begin
				// 	if(a[31]==1 & b[31]==1)begin
				// 		result=(a>b)?b:a;
				// 	end
				// 	else if(a[31]==0 & b[31]==0)begin
				// 		result=(a>b)?a:b;
				// 	end
				// 	else begin
				// 		result=(a[31]==0)?a:b;
				// 	end
				// end

				`DIV_CONTROL   :  begin //指令DIV, 除法器控制状态机逻辑
					if(~div_ready & ~div_start) begin //~div_start : 为了保证除法进行过程中，除法源操作数不因ALU输入改变而重新被赋值
						//必须非阻塞赋值，否则时序不对
						div_start <= 1'b1;
						div_signed <= 1'b1;
						div_stall <= 1'b1;
						a_save <= a; //除法时保存两个操作数
						b_save <= b;
					end
					else if(div_ready) begin
						div_start <= 1'b0;
						div_signed <= 1'b1;
						div_stall <= 1'b0;
						hilo_out <= div_result;
					end
				end
				`DIVU_CONTROL  :  begin //指令DIVU, 除法器控制状态机逻辑
					if(~div_ready & ~div_start) begin 
						//必须非阻塞赋值，否则时序不对
						div_start <= 1'b1;
						div_signed <= 1'b0;
						div_stall <= 1'b1;
						a_save <= a; //除法时保存两个操作数
						b_save <= b;
					end
					else if(div_ready) begin
						div_start <= 1'b0;
						div_signed <= 1'b0;
						div_stall <= 1'b0;
						hilo_out <= div_result;
					end
				end			

				//读写CP0
				`MFC0_CONTROL  :  result = cp0_rdata; //指令MFC0
				`MTC0_CONTROL  :  result = b;         //指令MTC0
				default        :  result = `ZeroWord;

			endcase
		end
    end
	wire annul; //终止除法信号
	assign annul = ((alucontrolE == `DIV_CONTROL)|(alucontrolE == `DIVU_CONTROL)) & is_except;
	div div(
		.clk(clk),
		.rst(rst),
		.signed_div_i(div_signed),
		.opdata1_i(a_save),
		.opdata2_i(b_save),
		.start_i(div_start),
		.annul_i(annul),
		.result_o(div_result),
		.ready_o(div_ready)
	);
endmodule