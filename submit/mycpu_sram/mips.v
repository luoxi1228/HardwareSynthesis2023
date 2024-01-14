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
	input wire [5:0]ext_int,
	output wire[31:0] pcF,
	input wire[31:0] instrF,
	output wire memwriteM,
	output wire[31:0] mem_write_dataM, 
	output wire [3:0] mem_wenM,
	output wire mem_enM,    
	output wire[31:0] aluoutM,writedataM,
	input wire[31:0] readdataM,
    //debug
	output [31:0] debug_wb_pc,
    output [3:0] debug_wb_rf_wen,
    output [4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
    );
	
	wire [5:0] opD,functD;
	wire [1:0]regdstE;
	wire alusrcE,pcsrcD,memtoregE,memtoregM,memtoregW,
			regwriteE,hilo_writeE,regwriteM,regwriteW;
	wire [4:0] alucontrolE;
	wire  flushE,flushM,flushW,equalD,stallE;
    wire jumpD,jalE,branchD,jrD;
    wire cp0_writeM,is_invalidM;

	wire [4:0]rsD,rtD;
	wire [31:0] debug_wb_pc;
    wire [3:0] debug_wb_rf_wen;
    wire [4:0] debug_wb_rf_wnum;
    wire [31:0] debug_wb_rf_wdata;

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
		flushM,
		memtoregM,memwriteM,
		regwriteM,
		cp0_writeM,is_invalidM,
		//write back stage
		flushW,
		memtoregW,regwriteW
		);
	datapath dp(
		clk,rst,ext_int,
		//fetch stage
		pcF,
		instrF,
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
		//mem stage
		memtoregM,
		regwriteM,
		cp0_writeM,
	    is_invalidM,
		mem_write_dataM,
		mem_wenM,
		mem_enM,
		aluoutM,writedataM,
		readdataM,
		flushM,
		//writeback stage
		memtoregW,
		regwriteW,
		flushW,
		debug_wb_pc,
    	debug_wb_rf_wen,
    	debug_wb_rf_wnum,
    	debug_wb_rf_wdata
	    );
	
endmodule
