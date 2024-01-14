`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: controller
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


module controller(
	input wire clk,rst,
	//decode stage
	input wire[5:0] opD,functD,rsD,rtD,
	input wire equalD,
	output wire pcsrcD,branchD,jumpD,jrD,jalD,
	
	//execute stage
	input wire flushE,stallE,
	output wire memtoregE,alusrcE,
	output wire [1:0]regdstE,
	output wire regwriteE,	
	output wire hilo_writeE,
	output wire[4:0] alucontrolE,
	output wire jalE,

	//mem stage
	input wire flushM,stallM,
	output wire memtoregM,//memwriteM,
				regwriteM,
	output wire cp0_writeM,is_invalidM,
	//write back stage
	input wire flushW,stallW,
	output wire memtoregW,regwriteW
    );
	
	//decode stage
	
	wire memtoregD,memwriteD,alusrcD,regwriteD,jalD,cp0_writeD,is_invalidD;
	wire [1:0]	regdstD;
	wire hilo_writeD;
	wire[4:0] alucontrolD;
	//execute stage
	wire memwriteE,cp0_writeE,is_invalidE;

	maindec md(
		//input
		.op(opD),
		.funct(functD),
		.rs(rsD),
		.rt(rtD),
		//output
		.memtoreg(memtoregD),
		.memwrite(memwriteD),
		.branch(branchD),
		.alusrc(alusrcD),
		.regdst(regdstD),
		.regwrite(regwriteD),
		.jump(jumpD),
		.hilo_write(hilo_writeD),
		.jr(jrD),
		.jal(jalD),
		.cp0_write(cp0_writeD),
		.is_invalid(is_invalidD)
		);
	aludec ad(functD,opD,rsD,rtD,alucontrolD);
    
	assign pcsrcD = branchD & equalD;

	//pipeline registers
	flopenrc #(15) regE(
		clk,
		rst,
		~stallE,
		flushE,
		{memtoregD,memwriteD,alusrcD,regdstD,regwriteD,alucontrolD,hilo_writeD,jalD,cp0_writeD,is_invalidD},
		{memtoregE,memwriteE,alusrcE,regdstE,regwriteE,alucontrolE,hilo_writeE,jalE,cp0_writeE,is_invalidE}
		);
	flopenrc #(5) regM(
		clk,rst,~stallM,flushM,
		{memtoregE,memwriteE,regwriteE,cp0_writeE,is_invalidE},
		{memtoregM,memwriteM,regwriteM,cp0_writeM,is_invalidM}
		);
	flopenrc #(2) regW(
		clk,rst,~stallW,flushW,
		{memtoregM,regwriteM},
		{memtoregW,regwriteW}
		);
endmodule
