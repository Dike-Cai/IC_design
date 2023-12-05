`timescale 1ns/10ps
module  ATCONV(
	input		clk,
	input		reset,
	output	reg	busy,	
	input		ready,	
			
	output reg	[11:0]	iaddr,
	input signed [12:0]	idata,
	
	output	reg 	cwr,
	output  reg	[11:0]	caddr_wr,
	output reg 	[12:0] 	cdata_wr,
	
	output	reg 	crd,
	output reg	[11:0] 	caddr_rd,
	input 	[12:0] 	cdata_rd,
	
	output reg 	csel
	);

//=================================================
//            write your design below
//=================================================
reg [2:0] state,nextState;
parameter S0=0, S1=1, S2=2 ,S3=3,S4=4;
reg [12:0]  block[4623:0];
reg [12:0]  L0pixel[4095:0];
reg	[12:0]	c1,r1,r0;
reg [4:0] 	c0;

initial busy <=0;
reg [11:0]   L0;
reg [9:0] 	 L1;

parameter a=1;
wire [12:0] w1;
assign w1=(	((~(block[c1+(r1<<6)+(r1<<2)]>>4))+13'b1)+
			((~(block[c1+(r1<<6)+(r1<<2)+2]>>3))+13'b1)+
			((~(block[c1+(r1<<6)+(r1<<2)+4]>>4))+13'b1)+

			((~(block[c1+(r1<<6)+(r1<<2)+136]>>2))+13'b1)+
			(block[c1+(r1<<6)+(r1<<2)+138])+
			((~(block[c1+(r1<<6)+(r1<<2)+140]>>2))+13'b1)+

			((~(block[c1+(r1<<6)+(r1<<2)+272]>>4))+13'b1)+
			((~(block[c1+(r1<<6)+(r1<<2)+274]>>3))+13'b1)+
			((~(block[c1+(r1<<6)+(r1<<2)+276]>>4))+13'b1)+
				13'b1111111110100						);

wire [12:0] w2,w3,w4;
assign w2=L0pixel[r0]>L0pixel[r0+1]?L0pixel[r0]:L0pixel[r0+1];
assign w3=L0pixel[r0+64]>L0pixel[r0+65]?L0pixel[r0+64]:L0pixel[r0+65];
// assign w2=L0pixel[0]>L0pixel[1]?L0pixel[0]:L0pixel[1];
// assign w3=L0pixel[64]>L0pixel[65]?L0pixel[64]:L0pixel[65];
assign w4=w2>w3?w2:w3;



always @(*) begin
    case(state)
        S0:begin
			if(~reset & ready)nextState<=S1;
            else nextState <= S0;
        end
        S1:begin
            if(&iaddr) nextState = S2;
            else nextState = S1;
        end
        S2:begin
			if(&L0) nextState = S3;
            else nextState = S2;
        end
		S3:begin
			if(&L1) nextState = S4;
            else nextState = S3;
        end
		S4:begin
			if(~busy) nextState = S0;
            else nextState = S4;
        end
        default:begin
            nextState = S0;
        end
    endcase
end

always @(posedge clk or posedge reset) begin
    if(reset) state <= S0;
    else state <= nextState;
end
//==FSM=================================

always @(posedge clk) begin
	case (state)
		S0:begin//RstEverything
			busy<=0;
			iaddr<=0;
			c0<=0;
			r0<=0;
			c1<=0;
			r1<=0;
			L0<=0;
			L1<=0;
			crd<=0;caddr_rd<=0;
			if(~reset & ready)busy<=1 ;								
		end 
		S1:begin
			// savedfromphoto[iaddr]<=idata;
			case (iaddr) 
				0:begin
					block[0]<=idata;
					block[1]<=idata;
					block[2]<=idata;
					block[68]<=idata;
					block[69]<=idata;
					block[70]<=idata;
					block[136]<=idata;
					block[137]<=idata;
					block[138]<=idata;
				end 
				63:begin
					block[65]<=idata;
					block[66]<=idata;
					block[67]<=idata;
					block[133]<=idata;
					block[134]<=idata;
					block[135]<=idata;
					block[201]<=idata;
					block[202]<=idata;
					block[203]<=idata;
				end
				4032:begin
					block[4420]<=idata;
					block[4421]<=idata;
					block[4422]<=idata;
					block[4488]<=idata;
					block[4489]<=idata;
					block[4490]<=idata;
					block[4556]<=idata;
					block[4557]<=idata;
					block[4558]<=idata;
				end
				4095:begin
					block[4485]<=idata;
					block[4486]<=idata;
					block[4487]<=idata;
					block[4553]<=idata;
					block[4554]<=idata;
					block[4555]<=idata;
					block[4621]<=idata;
					block[4622]<=idata;
					block[4623]<=idata;
				end
				default:begin
					if (iaddr>0 && iaddr <63) begin
						block[iaddr+2]<=idata;
						block[iaddr+70]<=idata;
						block[iaddr+138]<=idata;
					end
					if (iaddr>4031 && iaddr<4095) begin
						block[iaddr+390]<=idata;
						block[iaddr+458]<=idata;
						block[iaddr+526]<=idata;
					end
					if(iaddr>63 && iaddr<4032) begin
						if(c1==0 || c1 == 63)begin
							if (c1) begin
								block[(c1+138)+(r1<<6)+(r1<<2)]<=idata;
								block[(c1+139)+(r1<<6)+(r1<<2)]<=idata;
								block[(c1+140)+(r1<<6)+(r1<<2)]<=idata;
							end
							else begin
								block[(c1+138)+(r1<<6)+(r1<<2)]<=idata;
								block[(c1+137)+(r1<<6)+(r1<<2)]<=idata;
								block[(c1+136)+(r1<<6)+(r1<<2)]<=idata;
							end
						end						
						else begin
							block[(c1+138)+(r1<<6)+(r1<<2)]<=idata;
						end						
					end
				end
			endcase
			if (c1==63) begin
				c1<=0;
				r1<=r1+12'b1;
			end
			else begin
				c1<=c1+13'b1;
			end
			if (~iaddr) begin
				iaddr <= iaddr+12'b1;
			end  
			else begin
				c1<=0;
				r1<=0;
			end
		end
		S2:begin
			cwr<=1;
			csel<=0;
			caddr_wr<=L0;
			L0<=L0+12'b1;
						
			if (w1[12]) begin
				cdata_wr<=0;
				L0pixel[L0]<=0;
			end
			else begin
				cdata_wr<=w1;
				L0pixel[L0]<=w1;
			end 				
			// cdata_wr<=(	((~(block[c1+(r1<<6)+(r1<<2)]>>4))+13'b1)+
			// 			((~(block[c1+(r1<<6)+(r1<<2)+2]>>3))+13'b1)+
			// 			((~(block[c1+(r1<<6)+(r1<<2)+4]>>4))+13'b1)+

			// 			((~(block[c1+(r1<<6)+(r1<<2)+136]>>2))+13'b1)+
			// 			(((block[c1+(r1<<6)+(r1<<2)+138])))+
			// 			((~(block[c1+(r1<<6)+(r1<<2)+140]>>2))+13'b1)+

			// 			((~(block[c1+(r1<<6)+(r1<<2)+272]>>4))+13'b1)+
			// 			((~(block[c1+(r1<<6)+(r1<<2)+274]>>3))+13'b1)+
			// 			((~(block[c1+(r1<<6)+(r1<<2)+276]>>4))+13'b1)+
			// 				13'b1111111110100						);
			// end
			if (c1==63)begin
				c1<=0;
				r1<=r1+13'b1;
			end 
			else begin
				c1<=c1+13'b1;
			end					
		end
		S3:begin
			cwr<=1;
			csel<=1;
			caddr_wr<=L1;			
			L1<=L1+11'b1;
			
			if(c0==31)begin
				c0<=13'b0;
				r0<=r0+13'd66;
			end 
			else begin
				c0<=c0+13'b1;
				r0<=r0+13'd2;
			end					

			if (w4[3:0]) begin
				cdata_wr<= (w4&13'h1ff0)+13'b10000;
			end
			else cdata_wr<=w4&13'h1ff0;
		end
		S4:begin			
			busy<=0;
		end
		 
	endcase
end
endmodule