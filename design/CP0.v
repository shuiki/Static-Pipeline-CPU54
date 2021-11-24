`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/06/28 12:48:44
// Design Name: 
// Module Name: CP0
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


`timescale 1ns / 1ps
module CP0(
input clk,				//ʱ���ź�
input rst,				//reset�ź�
input mfc0,				//ָ��Ϊmfc0
input mtc0,				//ָ��Ϊmtc0
input eret,				//ָ��Ϊeret
input exception,		//�쳣�����ź�
input [4:0] cause,		//�쳣ԭ��
input [4:0] addr,		//cp0�Ĵ�����ַ
input [31:0]wdata,		//д�������
input [31:0]pc,			//pc
output [31:0]rdata,		//Cp0�Ĵ�����������
output [31:0]status,	//״̬
output [31:0]exc_addr	//�쳣������ַ
);

parameter
STATUSADDR	=5'd12,
EPCADDR		=5'd14,
CAUSEADDR	=5'd13;

reg [31:0]cp0Reg[31:0];
assign exc_addr	=eret?cp0Reg[EPCADDR]:32'h00400004;
assign status	=cp0Reg[STATUSADDR];
assign rdata	=mfc0?cp0Reg[addr]:32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;


always @(negedge clk or posedge rst)begin
	if(rst)begin
		cp0Reg[STATUSADDR]<={27'd0,5'b11111};
		cp0Reg[0]<=32'b0;
		cp0Reg[1]<=32'b0;
		cp0Reg[2]<=32'b0;
		cp0Reg[3]<=32'b0;
		cp0Reg[4]<=32'b0;
		cp0Reg[5]<=32'b0;
		cp0Reg[6]<=32'b0;
		cp0Reg[7]<=32'b0;
		cp0Reg[8]<=32'b0;
		cp0Reg[9]<=32'b0;
		cp0Reg[10]<=32'b0;
		cp0Reg[11]<=32'b0;
		cp0Reg[13]<=32'b0;
		cp0Reg[14]<=32'h00400004;
		cp0Reg[15]<=32'b0;
		cp0Reg[16]<=32'b0;
		cp0Reg[17]<=32'b0;
		cp0Reg[18]<=32'b0;
		cp0Reg[19]<=32'b0;
		cp0Reg[20]<=32'b0;
		cp0Reg[21]<=32'b0;
		cp0Reg[22]<=32'b0;
		cp0Reg[23]<=32'b0;
		cp0Reg[24]<=32'b0;
		cp0Reg[25]<=32'b0;
		cp0Reg[26]<=32'b0;
		cp0Reg[27]<=32'b0;
		cp0Reg[28]<=32'b0;
		cp0Reg[29]<=32'b0;
		cp0Reg[30]<=32'b0;
		cp0Reg[31]<=32'b0;
	end
	else begin
		if(mtc0)
			cp0Reg[addr]<=wdata;
		if(exception)begin
			cp0Reg[STATUSADDR]<={cp0Reg[STATUSADDR][26:0],5'd0};
			cp0Reg[CAUSEADDR]<={24'd0,cause,2'd0};
			cp0Reg[EPCADDR]<=pc;
		end
		if(eret)begin
			cp0Reg[STATUSADDR]<={5'd0,cp0Reg[STATUSADDR][31:5]};
		end
	end
end

endmodule