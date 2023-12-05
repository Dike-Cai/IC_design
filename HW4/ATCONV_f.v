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
	output  reg [12:0] 	cdata_wr,
	
	output	reg 	crd,
	output reg	[11:0] 	caddr_rd,
	input 	[12:0] 	cdata_rd,
	
	output reg 	csel
	);

//=================================================
//            write your design below
//=================================================
reg [5:0] row,col;
reg [12:0] mutiqueue[8:0];
reg [12:0] compqueue[3:0];
reg [1:0]  L1;
reg [9:0]  L0=0;
reg [3:0]  count=0;

reg [2:0] state,nextState;
parameter S0=0, S1=1, S2=2 ,S3=3,S4=4,S5=5,S6=6;

//========================================================
wire [12:0] w0=col-2;
wire [12:0] w1=row-2<<6;
wire [12:0] w2=w0+w1;
wire [12:0] w3=col+2;
wire [12:0] w4=row<<6;
wire [12:0] w5=13'd63;
wire [12:0] w6=13'd63<<6;
wire [12:0] w7=row+2<<6;
//========================================================
wire [12:0] calculate;
assign calculate=~(((mutiqueue[0][12:4])+(mutiqueue[2][12:4])+
					   (mutiqueue[6][12:4])+(mutiqueue[8][12:4]))+
					  ((mutiqueue[1][12:3])+(mutiqueue[7][12:3]))+
					  ((mutiqueue[3][12:2])+(mutiqueue[5][12:2]))+13'b1100)+
					    mutiqueue[4]+13'b1;


wire [12:0] w13,w14,w15;

assign w13=compqueue[0]>compqueue[1]?compqueue[0]:compqueue[1];
assign w14=compqueue[2]>compqueue[3]?compqueue[2]:compqueue[3];
assign w15=w13>w14?w13:w14;


always @(*) begin
    case(state)
        S0:begin
			if(~reset & ready)nextState<=S1;
            else nextState <= S0;
        end
        S1:begin
            nextState = S2;
        end
        S2:begin
			if( count==9) nextState = S3;
            else nextState = S2;
        end
		S3:begin
			if (col[0]&row[0]) nextState = S4;
			else nextState = S5;
        end
		S4:begin
			if(&L0) nextState = S6;
			else nextState = S5;
        end
		S5:begin
			nextState = S1;
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
			crd<=0;caddr_rd<=0;
			cwr<=0;caddr_wr<=0;cdata_wr<=0;
			crd<=0;caddr_rd<=0;
			csel<=0;
			row<=0;col<=0;
			if(~reset & ready)busy<=1 ;								
		end
		S1:begin
			if (col==0|col==1) begin
				//0,1,3,4,6,7
				//[0]===============================================
				if (row<2) begin
					if (col==0|col==1) begin
						mutiqueue[0]<=0;
					end
					else begin
						mutiqueue[0]<=w0;
					end
				end 
				else if (col==0|col==1) begin
					mutiqueue[0]=w1;
				end
				else begin
					mutiqueue[0]<=w2;
				end
				//[1]==============================================	
				if (row<2) begin
					mutiqueue[1]<=col;	
				end
				else begin
					mutiqueue[1]<=w1+col;
				end
				//[3]==============================================	
				if (col==0|col==1) begin
					mutiqueue[3]<=w4;
				end 
				else begin
					mutiqueue[3]<=w4+w0;
				end
				//[4]==============================================	
				mutiqueue[4]<=w4+col;
				//[6]==============================================	
				if (row==62|row==63) begin
					if (col==0|col==1) begin
						mutiqueue[6]<=w6;
					end
					else begin
						mutiqueue[6]<=w6+w0;
					end
				end 
				else if (col==0|col==1) begin
					mutiqueue[6]<=w7;
				end
				else begin
					mutiqueue[6]<=w7+w0;
				end
				//[7]==============================================	
				if (row==62|row==63) begin
					mutiqueue[7]<=w6+col;
				end
				else begin
					mutiqueue[7]<=w7+col;
				end
				//=================================================
			end
			else begin
				mutiqueue[0]<=mutiqueue[1];
				mutiqueue[1]<=mutiqueue[2];
				mutiqueue[3]<=mutiqueue[4];
				mutiqueue[4]<=mutiqueue[5];
				mutiqueue[6]<=mutiqueue[7];
				mutiqueue[7]<=mutiqueue[8];
			end
			//2,5,8			
			//[2]==============================================	
			if (row<2) begin
				if (col==62|col==63) begin
					mutiqueue[2]<=w5;
				end
				else begin
					mutiqueue[2]<=w3;
				end
			end 
			else if (col==62|col==63) begin
				mutiqueue[2]<=w1+w5;
			end
			else begin
				mutiqueue[2]<=w1+w3;
			end			
			//[5]==============================================	
			if (col==62|col==63) begin
				mutiqueue[5]<=w4+w5;
			end
			else begin
				mutiqueue[5]<=w4+w3;
			end			
			//[8]==============================================	
			if (row==62|row==63) begin
				if (col==62|col==63) begin
					mutiqueue[8]<=4095;
				end
				else begin
					mutiqueue[8]<=w6+w3;
				end
			end 
			else if (col==62|col==63) begin
				mutiqueue[8]<=w7+w5;
			end
			else begin
				mutiqueue[8]<=w7+w3;
			end
			//================================================
		end
		S2:begin
			if (col==0|col==1) begin
				if (count<9) begin
					iaddr<=mutiqueue[count];
				end	
				if (count) begin
					mutiqueue[count-1]<=idata;
				end	
				count<=count+5'b1;
			end
			else begin
				if (count<9) begin
					iaddr<=mutiqueue[count+2];
				end
				if (count) begin
					mutiqueue[count-1]<=idata;
				end	
				count<=count+5'b11;
			end		
			if (col[0]&row[0]) begin
				crd<=1;csel<=0;
				case (L1)
					0:begin
						caddr_rd<=((row-1)<<6)+col-1;
					end 
					1:begin
						caddr_rd<=((row-1)<<6)+col;
						compqueue[0]<=cdata_rd;
					end
					2:begin
						caddr_rd<=(row<<6)+col-1;
						compqueue[1]<=cdata_rd;
					end
					3:begin
						compqueue[2]<=cdata_rd;
					end 
				endcase	
				L1<=L1+1;			
			end							
		end
		S3:begin
			crd<=0;cwr<=1;csel<=0;caddr_wr<=w4+col;
			if (calculate[12]) begin
				cdata_wr<=0;
				compqueue[3]<=0;
			end
			else begin
				cdata_wr<=calculate;
				compqueue[3]<=calculate;
			end
		end
		S4:begin
			csel<=1;
			if (w15[3:0]) begin
				cdata_wr<= (w15&13'h1ff0)+13'b10000;
			end
			else cdata_wr<=w15&13'h1ff0;	
			caddr_wr<=L0;
			L0<=L0+1;							
		end
		S5:begin
			L1<=0;
			cwr<=0;
			count<=0;
			if (col==63)begin
				col<=0;
				row<=row+13'b1;
			end 
			else if (col==62) begin
				col<=1;
			end
			else begin
				col<=col+13'd2;
			end			
		end
		S6:begin
			busy<=0;
		end
	endcase
end
endmodule