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
reg [12:0] L0pixel[4095:0];
reg [12:0] block [4623:0];
reg [5:0] row,col;
reg [1:0] i;
integer j=0,k=0;
reg [12:0] mutiqueue[8:0];
reg [14:0] plus3,plus2,plus4;
reg [11:0]  L0=0;
reg [4:0] 	count=0;
reg [13:0] f;




reg [3:0] state,nextState;
parameter S0=0, S1=1, S2=2 ,S3=3,S4=4,S5=5,S6=6,S7=7,S8=8;

//========================================================
// reg [5:0]	c1=0,r1=0;

wire [12:0] w1=L0+(row<<2);
// wire [12:0] w2=(~((plus4>>4)+(plus3>>3)+(plus2>>2)))+
// 					 	(mutiqueue[4]+13'b1111111110101);
// assign w1=((~((block[c1+(r1<<6)+(r1<<2)]>>4)+
// 			(block[c1+(r1<<6)+(r1<<2)+2]>>3)+
// 			(block[c1+(r1<<6)+(r1<<2)+4]>>4)+
// 			(block[c1+(r1<<6)+(r1<<2)+136]>>2)+
// 			(block[c1+(r1<<6)+(r1<<2)+140]>>2)+
// 			(block[c1+(r1<<6)+(r1<<2)+272]>>4)+
// 			(block[c1+(r1<<6)+(r1<<2)+274]>>3)+
// 			block[c1+(r1<<6)+(r1<<2)+276]>>4))+13'b1+
// 			(block[c1+(r1<<6)+(r1<<2)+138])+
// 			13'b1111111110100						);
// L0pixel[L0]<=( ~((block[w1]>>4)+
			// 				(block[w1+2]>>3)+
			// 				(block[w1+4]>>4)+
			// 				(block[w1+136]>>2)+
			// 				(block[w1+140]>>2)+
			// 				(block[w1+272]>>4)+
			// 				(block[w1+274]>>3)+
			// 				(block[w1+276]>>4))+
			// 				block[w1+138]+
			// 				13'b1111111110101);	
//========================================================
// wire [12:0] w2,w3,w4;
// assign w2=L0pixel[r0]>L0pixel[r0+1]?L0pixel[r0]:L0pixel[r0+1];
// assign w3=L0pixel[r0+64]>L0pixel[r0+65]?L0pixel[r0+64]:L0pixel[r0+65];
// assign w4=w2>w3?w2:w3;
//========================================================



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
			if(&i) nextState = S3;
            else nextState = S2;
        end
		S3:begin
			if(count==2) nextState = S4;
            else nextState = S3;
        end
		S4:begin
			nextState = S5;
        end
		S5:begin
			nextState = S6;
		end
		S6:begin
			if(&L0) nextState = S8;
		 	else	nextState = S7;
        end
		S7:begin
            nextState = S3;
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
			i<=0;
			if(~reset & ready)busy<=1 ;								
		end
		S1:begin
			block[col+(row<<6)+(row<<2)+138]<=idata;
			iaddr<=iaddr+12'd1;
			if (&col) begin
				row<=row+6'b1;
			end
			col<=col+6'b1;
		end
		S2:begin
			for (j = 0;j<68;j=j+1 ) begin
				block[j]<=block[j+68];
				block[j+68]<=block[j+136];
				block[j+4556]<=block[j+4488];
				block[j+4488]<=block[j+4420];
			end
			for (k=0;k<64;k=k+1 ) begin
				block[(k<<6)+(k<<2)+136] <= block[(k<<6)+(k<<2)+137];
				block[(k<<6)+(k<<2)+137] <= block[(k<<6)+(k<<2)+138];
				block[(k<<6)+(k<<2)+202] <= block[(k<<6)+(k<<2)+201];
				block[(k<<6)+(k<<2)+203] <= block[(k<<6)+(k<<2)+202];
			end
			i<=i+1;
			// col<=0;row<=0;
		end
		S3:begin
			case (count)
				0:begin
					mutiqueue[0] <= block[w1];
					mutiqueue[1] <= block[w1+2];
					mutiqueue[2] <= block[w1+4];
				end 		
				1:begin
					mutiqueue[0] <= block[w1+136];
					mutiqueue[1] <= block[w1+138];
					mutiqueue[2] <= block[w1+140];
				end 
				2:begin
					mutiqueue[0] <= block[w1+272];
					mutiqueue[1] <= block[w1+274];	
				 	mutiqueue[2] <= block[w1+276];
				end 	
				default:;			 
			endcase
			if (count==2) count<=0;	
			else		  count<=count+1;

			mutiqueue[3] <= mutiqueue[0];
			mutiqueue[4] <= mutiqueue[1];
			mutiqueue[5] <= mutiqueue[2];

			mutiqueue[6] <= mutiqueue[3];
			mutiqueue[7] <= mutiqueue[4];
			mutiqueue[8] <= mutiqueue[5];
		end
		S4:begin
			plus4<=(mutiqueue[0]+mutiqueue[2]+mutiqueue[6]+mutiqueue[8]);
			plus3<=(mutiqueue[1]+mutiqueue[7]);
			plus2<=(mutiqueue[3]+mutiqueue[5]);							
		end
		S5:begin			
			f<=(~((plus4>>4)+(plus3>>3)+(plus2>>2)))+
					 	(mutiqueue[4]+13'b1111111110101);
		end
		S6:begin
			cwr<=1;csel<=0;caddr_wr<=L0;
			cdata_wr<=f;
		end		
		S7:begin			
			cwr<=0;
			L0 <= L0+1;							
			if (col==63)begin
				col<=0;
				row<=row+13'b1;
			end 
			else begin
				col<=col+13'b1;
			end			
		end
		S8:begin
			busy<=0;
		end
	endcase
end
endmodule