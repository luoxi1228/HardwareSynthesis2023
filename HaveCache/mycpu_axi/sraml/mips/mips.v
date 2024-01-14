`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/07 10:58:03
// Design Name: 
// Module Name: mips
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


module mips(
	input wire clk,rst,
	input wire [5:0] ext_int,//硬件中断标识

	//instr
	output wire[31:0] pcF,
	output wire instr_enF, //指令存储器使�?
	input wire[31:0] instrF,
	input wire i_stall, //指令存储器读指令时暂停流水线信号

	//data
	// output wire memwriteM,
	output wire[31:0] aluoutM, //数据存储器读写地�?
	output wire[31:0] mem_write_dataM, //写数�?
	input wire[31:0] readdataM,        //读数�?
	output wire mem_enM,    //数据存储器使�?
	output wire [3:0] mem_wenM, //数据存储器字节写使能
	input wire d_stall, //数据存储器读写数据时暂停流水线信�?

	output wire longest_stall,

	//for debug
    output [31:0] debug_wb_pc     ,
    output [3:0] debug_wb_rf_wen  ,
    output [4:0] debug_wb_rf_wnum ,
    output [31:0] debug_wb_rf_wdata
    );
	
	wire [5:0] opD,functD;
	wire [1:0]regdstE;
	wire alusrcE,pcsrcD,memtoregE,memtoregM,memtoregW,
			regwriteE,hilo_writeE,regwriteM,regwriteW;
	wire [4:0] alucontrolE;
	wire  flushE,flushM,flushW,equalD,stallE,stallM,stallW;
    wire jumpD,jalE,branchD,jrD;
    wire cp0_writeM,is_invalidM;

	wire [4:0]rsD,rtD;


	controller c(
		clk,rst,
		//decode stage
		opD,functD,rsD,rtD,
		equalD,
		pcsrcD,branchD,jumpD,jrD,jalD,
		
		//execute stage
		flushE,stallE,
		memtoregE,alusrcE,
		regdstE,
		regwriteE,	
		hilo_writeE,
		alucontrolE,
        jalE,
		//mem stage
		flushM,stallM,
		memtoregM,//memwriteM,
		regwriteM,
		cp0_writeM,is_invalidM,
		//write back stage
		flushW,stallW,
		memtoregW,regwriteW
		);
	datapath dp(
		clk,rst,ext_int,
		//fetch stage
		pcF,
		instrF,
	    instr_enF,//指令存储器使�?
		i_stall,
		//decode stage
		pcsrcD,branchD,
		jumpD,jrD,jalD,
		equalD,
		opD,functD,
		rsD,rtD,
		//execute stage
		memtoregE,
		alusrcE,
		regdstE,
		regwriteE,
		alucontrolE,
		hilo_writeE,jalE,
		flushE,stallE,
		d_stall,
		//mem stage
		memtoregM,
		regwriteM,
		cp0_writeM,
	    is_invalidM,
		mem_write_dataM,
		mem_wenM,
		mem_enM,
		aluoutM,//writedataM,
		readdataM,
		flushM,stallM,
		//writeback stage
		memtoregW,
		regwriteW,
		flushW,stallW,
		longest_stall,

		debug_wb_pc,
    	debug_wb_rf_wen,
    	debug_wb_rf_wnum,
    	debug_wb_rf_wdata
	    );
	
endmodule
