`include "defines2.vh"

module mem_ctrl(
    input wire[5:0] op_code,  
    input wire[31:0] addr, 
    //Load
	input wire[31:0] mem_read_data,  
    output reg[31:0] final_read_data, 
    //Store
    input wire[31:0] pre_write_data,
	output reg[31:0] mem_write_data,  
	output reg [3:0] mem_wen ,
    //except
    output reg is_AdELM, //地址错例外（读数据或读取指令）
    output reg is_AdESM  //地址错例外（写数据）
    );
	
	always @(*) begin
        mem_wen = 4'b0000;
        is_AdELM = 1'b0;
        is_AdESM = 1'b0;
        case(op_code)
            //Load
            `LB  :  begin //有符号扩展
                case(addr[1:0])
                    2'b00 : final_read_data = {{24{mem_read_data[7]}},  mem_read_data[7:0]};
                    2'b01 : final_read_data = {{24{mem_read_data[15]}}, mem_read_data[15:8]};
                    2'b10 : final_read_data = {{24{mem_read_data[23]}}, mem_read_data[23:16]};
                    2'b11 : final_read_data = {{24{mem_read_data[31]}}, mem_read_data[31:24]};
                endcase
            end
            `LBU :  begin //无符号扩展
                case(addr[1:0])
                    2'b00 : final_read_data = {      24'b0    ,       mem_read_data[7:0]};
                    2'b01 : final_read_data = {      24'b0    ,       mem_read_data[15:8]};
                    2'b10 : final_read_data = {      24'b0    ,       mem_read_data[23:16]};
                    2'b11 : final_read_data = {      24'b0    ,       mem_read_data[31:24]};
                endcase
            end
            `LH  :  begin //有符号扩展
                case(addr[1:0])
                    2'b00 : final_read_data = {{16{mem_read_data[15]}}, mem_read_data[15:0]};
                    2'b10 : final_read_data = {{16{mem_read_data[31]}}, mem_read_data[31:16]};
                    default : is_AdELM = 1'b1; //标记异常
                endcase
            end
            `LHU :  begin //无符号扩展
                case(addr[1:0])
                    2'b00 : final_read_data = {      16'b0    ,       mem_read_data[15:0]};
                    2'b10 : final_read_data = {      16'b0    ,       mem_read_data[31:16]};
                    default : is_AdELM = 1'b1; //标记异常
                endcase
            end
            `LW  :  begin
                final_read_data = mem_read_data;
                if(~(addr[1:0] == 2'b00)) begin
                    is_AdELM = 1'b1; //标记异常
                end
            end
            //Store
            `SB  :  begin
                case(addr[1:0]) //控制信号-字节写使能
                    2'b00 : mem_wen = 4'b0001;
                    2'b01 : mem_wen = 4'b0010;
                    2'b10 : mem_wen = 4'b0100;
                    2'b11 : mem_wen = 4'b1000;
                endcase
                mem_write_data = {4{pre_write_data[7:0]}};
            end
            `SH  :  begin
                case(addr[1:0]) //控制信号-字节写使能
                    2'b00 : mem_wen = 4'b0011;
                    2'b10 : mem_wen = 4'b1100;
                    default : is_AdESM = 1'b1; //标记异常
                endcase
                mem_write_data = {2{pre_write_data[15:0]}};
            end
            `SW  :  begin
                //控制信号-字节写使能
                mem_wen = 4'b1111;
                mem_write_data = pre_write_data;
                if(~(addr[1:0] == 2'b00)) begin
                    is_AdESM = 1'b1; //标记异常
                end
            end  
		endcase
    end
endmodule