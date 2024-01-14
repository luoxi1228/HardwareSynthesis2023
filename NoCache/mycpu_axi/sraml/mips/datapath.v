`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 15:12:22
// Design Name: 
// Module Name: datapath
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


module datapath(
	input wire clk,rst,
	input wire [5:0] ext_int,//硬件中断标识
	//fetch stage
	output wire[31:0] pcF,
	input wire[31:0] instrF,
	output wire	 instr_enF,//指令存储器使�?
	input wire  i_stall,
	//decode stage
	input wire pcsrcD,branchD,
	input wire jumpD,jrD,jalD,
	output wire equalD,
	output wire[5:0] opD,functD,
	output wire[4:0] rscontrol,//提供给controller模块
    output wire[4:0] rtcontrol,
	//execute stage
	input wire memtoregE,
	input wire alusrcE,
	input wire [1:0]regdstE,
	input wire regwriteE,
	input wire[4:0] alucontrolE,
	input wire hilo_writeE,jalE,
	output wire flushE,stallE,
	input wire d_stall,
	//mem stage
	input wire memtoregM,
	input wire regwriteM,
	input wire cp0_writeM,
	input wire is_invalidM,
	output wire[31:0] mem_write_dataM, 
	output wire [3:0] mem_wenM,
	output wire mem_enM,   //存储器使�? 
	output wire[31:0] aluoutM,//writedataM,
	input wire[31:0] readdataM,
	output wire flushM,stallM,
	//writeback stage
	input wire memtoregW,
	input wire regwriteW, 
	output wire flushW,stallW,
	output wire longest_stall,
	//debug
	output [31:0] debug_wb_pc     ,
    output [3:0] debug_wb_rf_wen  ,
    output [4:0] debug_wb_rf_wnum ,
    output [31:0] debug_wb_rf_wdata

    );


	//fetch stage
	wire stallF,flushF;
	wire is_AdEL_pcF;    //地址错误例外
	wire is_in_delayslotF; //当前指令是否在延迟槽
	//FD
	wire [31:0] pcnextFD,pcnextbrFD,pcplus4F,pcbranchD,pcnextF,pcnextjrD;
	//decode stage
	wire [31:0] pcplus4D,instrD;
	wire forwardaD,forwardbD;
	wire [4:0] rsD,rtD,rdD,saD;
	wire flushD,stallD; 
	wire [31:0] signimmD,signimmshD;
	wire [31:0] srcaD,srca2D,srcbD,srcb2D;
	wire [31:0]pcD;
	wire is_AdEL_pcD,is_syscallD,is_breakD,is_eretD;
	wire is_in_delayslotD; 
	wire [4:0] cp0_waddrD; //cp0写地�?，指令MTC0
	wire [4:0] cp0_raddrD; //cp0读地�?，指令MFC0
	//execute stage
	wire [1:0] forwardaE,forwardbE;
	wire [4:0] rsE,rtE,rdE,saE;
	wire [5:0] opE;
	wire [4:0] writeregE,writeregE1;
	wire [31:0] signimmE;
	wire [31:0] srcaE,srca2E,srcbE,srcb2E,srcb3E,srca3E,srcb4E;
	wire [31:0] aluoutE;
	wire [63:0] read_hiloE;
	wire [63:0] write_hiloE;
	wire hilo_write2E; //考虑了除法后的hilo寄存器写信号
	wire is_overflowE;
	wire div_readyE; //除法运算是否完成
	wire div_stallE; //除法导致的流水线暂停控制
	wire stallE,flushE; //Ex阶段暂停、刷新控制信�?
	wire [31:0]pcE;
	wire is_AdEL_pcE,is_syscallE,is_breakE,is_eretE,is_overflowE; //例外标记
	wire is_in_delayslotE;
	wire [4:0] cp0_waddrE;
	wire [4:0] cp0_raddrE;
	wire [31:0] cp0_rdataE,cp0_rdata2E;
	//mem stage
	wire [5:0] opM;
	wire [4:0] writeregM;
	wire [31:0] final_read_dataM,writedataM;
	wire is_AdEL_pcM,is_syscallM,is_breakM,is_eretM,is_AdELM,is_AdESM,is_overflowM; //例外标记
	wire is_in_delayslotM;
	wire [31:0] pcM;
	wire [4:0] cp0_waddrM;
	wire is_exceptM;
	wire [31:0] except_typeM;
	wire [31:0] except_pcM;
	wire [31:0] cp0_countM,cp0_compareM,cp0_statusM,cp0_causeM,
				cp0_epcM,cp0_configM,cp0_pridM,cp0_badvaddrM;
	wire cp0_timer_intM;
	wire [31:0] bad_addrM;
	wire stallM,flushM;
	//writeback stage
	wire [4:0] writeregW;
	wire [31:0] aluoutW,readdataW,resultW;
	wire stallW,flushW;

    //debug
	wire [31:0] pcW;
    wire [31:0] instrE,instrM,instrW;
    flopenrc #(32) rinstrE(clk,rst,~stallE,flushE,instrD,instrE);
    flopenrc #(32) rinstrM(clk,rst,~stallM,flushM,instrE,instrM);
    flopenrc #(32) rinstrW(clk,rst,~stallW,flushW,instrM,instrW);
    
	wire regwrite_for_debugW = stallW ?0 : regwriteW;
    flopenrc #(32) rpcW(clk,rst,~stallW,flushW,pcM,pcW);
    assign debug_wb_pc          = pcW;
    assign debug_wb_rf_wen      = {4{regwrite_for_debugW}};
    assign debug_wb_rf_wnum     = writeregW;
    assign debug_wb_rf_wdata    = resultW;
	//hazard detection
	hazard h(
		//fetch stage
		stallF,
		i_stall,
		//decode stage
		rsD,rtD,
		branchD,jrD,
		forwardaD,forwardbD,
		stallD,
		//execute stage
		rsE,rtE,
		writeregE,
		regwriteE,
		memtoregE,
		div_stallE,
		forwardaE,forwardbE,
		flushF,
		flushD,
		flushE,
		flushM,
		flushW,
		stallE,
		//mem stage
		writeregM,
		regwriteM,
		memtoregM,
		is_exceptM,
		d_stall,
		stallM,
		//write back stage
		writeregW,
		regwriteW,
        stallW,
		longest_stall
		);

	//next PC logic (operates in fetch an decode)
	mux2 #(32) pcbrmux(pcplus4F,pcbranchD,pcsrcD,pcnextbrFD);
	mux2 #(32) pcmux(pcnextbrFD,
		{pcplus4D[31:28],instrD[25:0],2'b00},
		jumpD,pcnextFD);
    //jrD=1:地址为srca2D, 0:地址为pcnextFD
	mux2 #(32) pc_jr_mux(pcnextFD,srca2D,jrD,pcnextjrD);
	mux2 #(32) pc_except_mux(pcnextjrD,except_pcM,is_exceptM,pcnextF);
	//regfile (operates in decode and writeback)
	regfile rf(clk,regwriteW,rsD,rtD,writeregW,resultW,srcaD,srcbD);

	//fetch stage logic
	pc #(32) pcreg(clk,rst,~stallF,pcnextF,pcF);
	adder pcadd1(pcF,32'b100,pcplus4F);

	assign is_AdEL_pcF = ~(pcF[1:0] == 2'b00);
	assign is_in_delayslotF = jumpD | branchD | jalD | jrD; //这几类指令会存在延迟�?
	assign instr_enF= ~is_exceptM;

	//decode stage
	flopenrc #(32) r1D(clk,rst,~stallD,flushD,pcplus4F,pcplus4D);
	flopenrc #(32) r2D(clk,rst,~stallD,flushD,instrF,instrD);
	flopenrc #(1) r3D(clk,rst,~stallD,flushD,is_AdEL_pcF,is_AdEL_pcD);
	flopenrc #(1) r4D(clk,rst,~stallD,flushD,is_in_delayslotF,is_in_delayslotD);
    flopenrc #(32) r5D(clk,rst,~stallD,flushD,pcF,pcD);

	signext se(instrD[15:0],opD[3:2],signimmD);
	sl2 immsh(signimmD,signimmshD);
	adder pcadd2(pcplus4D,signimmshD,pcbranchD);
	mux2 #(32) forwardamux(srcaD,aluoutM,forwardaD,srca2D);
	mux2 #(32) forwardbmux(srcbD,aluoutM,forwardbD,srcb2D);
	eqcmp comp(srca2D,srcb2D,opD,rtD,equalD);

	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	assign saD = instrD[10:6];
	assign rtcontrol=rtD;
    assign rscontrol=rsD;

	assign is_breakD = (opD == 6'b000000) & (functD == `BREAK);
	assign is_syscallD = (opD == 6'b000000) & (functD == `SYSCALL);
	assign is_eretD = (instrD == 32'b01000010000000000000000000011000);
	assign cp0_waddrD = rdD;
	assign cp0_raddrD = rdD;

	//execute stage
	flopenrc #(32) r1E(clk,rst,~stallE,flushE,srcaD,srcaE);
	flopenrc #(32) r2E(clk,rst,~stallE,flushE,srcbD,srcbE);
	flopenrc #(32) r3E(clk,rst,~stallE,flushE,signimmD,signimmE);
	flopenrc #(5) r4E(clk,rst,~stallE,flushE,rsD,rsE);
	flopenrc #(5) r5E(clk,rst,~stallE,flushE,rtD,rtE);
	flopenrc #(5) r6E(clk,rst,~stallE,flushE,rdD,rdE);
	flopenrc #(5) r7E(clk,rst,~stallE,flushE,saD,saE);
	flopenrc #(6) r8E(clk,rst,~stallE,flushE,opD,opE);
	flopenrc #(4) r9E(clk,rst,~stallE,flushE,
		{is_AdEL_pcD,is_syscallD,is_breakD,is_eretD},
		{is_AdEL_pcE,is_syscallE,is_breakE,is_eretE});
	flopenrc #(1) r10E(clk,rst,~stallE,flushE,is_in_delayslotD,is_in_delayslotE);
	flopenrc #(32) r11E(clk,rst,~stallE,flushE,pcD,pcE);
	flopenrc #(5) r12E(clk,rst,~stallE,flushE,cp0_waddrD,cp0_waddrE);
	flopenrc #(5) r13E(clk,rst,~stallE,flushE,cp0_raddrD,cp0_raddrE);

	mux3 #(32) forwardaemux(srcaE,resultW,aluoutM,forwardaE,srca2E);
	mux3 #(32) forwardbemux(srcbE,resultW,aluoutM,forwardbE,srcb2E);
	mux2 #(32) srcbmux(srcb2E,signimmE,alusrcE,srcb3E);

	//跳转指令,ALU源操作数选择分别为pcE and 8
	mux2 #(32) alusrcamux(srca2E,pcE,jalE,srca3E);
	mux2 #(32) alusrcbmux(srcb3E,32'h00000008,jalE,srcb4E);
	//CP0写后读数据前�?
	mux2 #(32) forwardcp0mux(cp0_rdataE,aluoutM,(cp0_raddrE == cp0_waddrM),cp0_rdata2E); 

    alu alu(clk,rst,srca3E,srcb4E,alucontrolE,saE,read_hiloE,cp0_rdata2E,is_exceptM,write_hiloE,aluoutE,div_readyE,div_stallE,is_overflowE);
	assign hilo_write2E = (alucontrolE == `DIV_CONTROL | alucontrolE == `DIVU_CONTROL) ? 
							(div_readyE & hilo_writeE) : (hilo_writeE);
	hilo_reg hilo_reg(clk,rst,(hilo_write2E & ~is_exceptM),write_hiloE,read_hiloE);
	mux3 #(5) wrmux(rtE,rdE,5'b11111,regdstE,writeregE);

	//mem stage
	flopenrc #(32) r1M(clk,rst,~stallM,flushM,srcb2E,writedataM);
	flopenrc #(32) r2M(clk,rst,~stallM,flushM,aluoutE,aluoutM);
	flopenrc #(5) r3M(clk,rst,~stallM,flushM,writeregE,writeregM);
	flopenrc #(6) r4M(clk,rst,~stallM,flushM,opE,opM);
	flopenrc #(32) r5M(clk,rst,~stallM,flushM,pcE,pcM);
	flopenrc #(5) r6M(clk,rst,~stallM,flushM,
		{is_AdEL_pcE,is_syscallE,is_breakE,is_eretE,is_overflowE},
		{is_AdEL_pcM,is_syscallM,is_breakM,is_eretM,is_overflowM});
	flopenrc #(1) r7M(clk,rst,~stallM,flushM,is_in_delayslotE,is_in_delayslotM);
	flopenrc #(5) r8M(clk,rst,~stallM,flushM,cp0_waddrE,cp0_waddrM);

	assign mem_enM =(~is_AdELM & ~is_AdESM); //存储器使能，防止异常地址写入或读�?;
    mem_ctrl mem_ctrl(opM,aluoutM,readdataM,final_read_dataM,writedataM,mem_write_dataM,mem_wenM,is_AdELM,is_AdESM);
	exception exception(
		//input
		.clk(clk),              
		.rst(rst),              
		.ext_int(ext_int),   
		.cp0_status(cp0_statusM),  
		.cp0_cause(cp0_causeM),  
		.cp0_epc(cp0_epcM),    
		.is_syscallM(is_syscallM),      
		.is_breakM(is_breakM),        
		.is_eretM(is_eretM),         
		.is_AdEL_pcM(is_AdEL_pcM),      
		.is_AdELM(is_AdELM),    
		.is_AdESM(is_AdESM),         
		.is_overflowM(is_overflowM),     
		.is_invalidM(is_invalidM),   
		//output   
		.is_except(is_exceptM),       
		.except_type(except_typeM),
		.except_pc(except_pcM)   
	);
	assign bad_addrM = is_AdEL_pcM ? pcM : aluoutM;
	wire [31:0] current_inst_addr;
	flopr #(32) except_inst_addr(clk,rst,pcE,current_inst_addr); //写入cp0_epc, �? pcE 传�?�来，无flush
	cp0_reg cp0_reg(
		//input
		.clk(clk),                          
		.rst(rst),
		.we_i(cp0_writeM),    
		.waddr_i(cp0_waddrM),
		.raddr_i(cp0_raddrE),
		.data_i(aluoutM),
		.int_i(ext_int),
		.excepttype_i(except_typeM),
		.current_inst_addr_i(current_inst_addr),
		.is_in_delayslot_i(is_in_delayslotM),
		.bad_addr_i(bad_addrM),
		//output
		//不需要的输出
		.count_o(cp0_countM),
		.compare_o(cp0_compareM),
		.config_o(cp0_configM),
		.prid_o(cp0_pridM),
		.badvaddr(cp0_badvaddrM),
		.timer_int_o(cp0_timer_intM),
		//�?要的输出
		.data_o(cp0_rdataE),
		.status_o(cp0_statusM), //用于判断中断
		.cause_o(cp0_causeM), //用于判断中断
		.epc_o(cp0_epcM) //用于ERET
	);
	//writeback stage
	flopenrc #(32) r1W(clk,rst,~stallW,flushW,aluoutM,aluoutW);
	flopenrc #(32) r2W(clk,rst,~stallW,flushW,final_read_dataM,readdataW);
	flopenrc #(5) r3W(clk,rst,~stallW,flushW,writeregM,writeregW);
	mux2 #(32) resmux(aluoutW,readdataW,memtoregW,resultW);

	

endmodule
