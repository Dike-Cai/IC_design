module demosaic(clk, reset, in_en, data_in, wr_r, addr_r, wdata_r, rdata_r, wr_g, addr_g, wdata_g, rdata_g, wr_b, addr_b, wdata_b, rdata_b, done);
input clk;
input reset;
input in_en;
input [7:0] data_in;
output reg wr_r;
output reg [13:0] addr_r;
output reg [7:0] wdata_r;
input [7:0] rdata_r;
output reg wr_g;
output reg [13:0] addr_g;
output reg [7:0] wdata_g;
input [7:0] rdata_g;
output reg wr_b;
output reg [13:0] addr_b;
output reg [7:0] wdata_b;
input [7:0] rdata_b;
output reg done;


//==================================
reg [3:0] state,nextState;
parameter S0=0, S1=1,S6=14,S7=15;
parameter S2_0=2, S2_1=3, S2_2=4;
parameter S3_0=5, S3_1=6, S3_2=7;
parameter S4_0=8, S4_1=9, S4_2=10;
parameter S5_0=11, S5_1=12, S5_2=13;
reg [6:0] col,row;
reg [13:0] r_queue[3:0],g_queue[3:0],b_queue[3:0];
reg [2:0] count;


//==================================
wire [13:0] position;
assign position={row[6:0],col[6:0]};


//===================================================
always @(*) begin
    case(state)
        S0:begin
			if(&col & &row)nextState<=S1;
            else nextState <= S0;
        end
        S1:begin
            nextState = S7;
        end

        S2_0:begin
            nextState<=S2_1;
        end
        S2_1:begin
            if (count==2) nextState<=S2_2;
            else nextState<=S2_1;            
        end
        S2_2:begin
            nextState<=S6;
        end

        S3_0:begin
            nextState<=S3_1;
        end
        S3_1:begin
            if (count==4) nextState<=S3_2;
            else nextState<=S3_1;            
        end
        S3_2:begin
            nextState<=S6;
        end

        S4_0:begin
            nextState<=S4_1;
        end
        S4_1:begin
            if (count==4) nextState<=S4_2;
            else nextState<=S4_1;            
        end
        S4_2:begin
            nextState<=S6;
        end

        S5_0:begin
            nextState<=S5_1;
        end
        S5_1:begin
            if (count==2) nextState<=S5_2;
            else nextState<=S5_1;            
        end
        S5_2:begin
            nextState<=S6;
        end

        S6:begin
            nextState<=S7;
        end			
  
		S7:begin
			if (row[0]) begin
                if (col[0]) begin
                    //G with ud R lr B
                    nextState<=S2_0;
                end
                else begin
                    //B with udlr G else R
                    nextState<=S3_0;
                end
            end
            else begin
                if (col[0]) begin
                    //R with udlr G else B
                    nextState<=S4_0;
                end
                else begin
                    //G with ud B lr R
                    nextState<=S5_0;
                end
            end
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
//=================================================
always @(posedge clk) begin
    case (state)
        S0:begin
            if (reset) begin
                wr_r<=0;//addr_r<=0;wdata_r<=0;
                wr_g<=0;//addr_g<=0;wdata_g<=0;
                wr_b<=0;//addr_b<=0;wdata_b<=0;
                row<=0;col<=0;
            end
            else if (in_en) begin
                wr_r<=0;
                wr_g<=0;
                wr_b<=0;
                if (row[0]) begin
                    if (col[0]) begin
                        //G
                        wr_g<=1;
                    end
                    else begin
                        //B
                        wr_b<=1;
                    end
                end
                else begin
                    if (col[0]) begin
                        //R
                        wr_r<=1;
                    end
                    else begin
                        //G
                        wr_g<=1;
                    end
                end

                addr_r<=position;
                wdata_r<=data_in;
                addr_g<=position;
                wdata_g<=data_in;
                addr_b<=position;
                wdata_b<=data_in;

                col<=col+1;
                if(&col) begin
                    row<=row+1;
                end
            end
        end
        S1:begin
            row<=1;col<=1;
            wr_r<=0;wr_g<=0;wr_b<=0;   
            count<=0;         
        end

        S2_0:begin
            r_queue[0]<=position-128;
            r_queue[1]<=position+128;
            b_queue[0]<=position-1;
            b_queue[1]<=position+1;
        end
        S2_1:begin
            if (count<2) begin
                addr_r<=r_queue[count];
                addr_b<=b_queue[count];
            end
            if (count) begin
                r_queue[count-1]<=rdata_r;
                b_queue[count-1]<=rdata_b;
            end
            count<=count+1;
        end
        S2_2:begin
            wr_r<=1;wr_b<=1;
            addr_r<=position;
            addr_b<=position;
            wdata_r<=(r_queue[0]+r_queue[1])>>1;
            wdata_b<=(b_queue[0]+b_queue[1])>>1;
        end

        S3_0:begin
            g_queue[0]<=position-128;
            g_queue[1]<=position+128;
            g_queue[2]<=position+1;
            g_queue[3]<=position-1;

            r_queue[0]<=position-129;
            r_queue[1]<=position-127;
            r_queue[2]<=position+127;
            r_queue[3]<=position+129;
        end
        S3_1:begin
            if (count<4) begin
                addr_g<=g_queue[count];
                addr_r<=r_queue[count];
            end
            if (count) begin
                g_queue[count-1]<=rdata_g;
                r_queue[count-1]<=rdata_r;
            end
            count<=count+1;
        end
        S3_2:begin
            wr_g<=1;wr_r<=1;
            addr_g<=position;
            addr_r<=position;
            wdata_g<=((g_queue[0]+g_queue[1])+(g_queue[2]+g_queue[3]))>>2;
            wdata_r<=((r_queue[0]+r_queue[1])+(r_queue[2]+r_queue[3]))>>2;            
        end

        S4_0:begin
            g_queue[0]<=position-128;
            g_queue[1]<=position+128;
            g_queue[2]<=position+1;
            g_queue[3]<=position-1;

            b_queue[0]<=position-129;
            b_queue[1]<=position-127;
            b_queue[2]<=position+127;
            b_queue[3]<=position+129;
        end
        S4_1:begin
            if (count<4) begin
                addr_g<=g_queue[count];
                addr_b<=b_queue[count];
            end
            if (count) begin
                g_queue[count-1]<=rdata_g;
                b_queue[count-1]<=rdata_b;
            end
            count<=count+1;
        end
        S4_2:begin
            wr_g<=1;wr_b<=1;
            addr_g<=position;
            addr_b<=position;
            wdata_g<=((g_queue[0]+g_queue[1])+(g_queue[2]+g_queue[3]))>>2;
            wdata_b<=((b_queue[0]+b_queue[1])+(b_queue[2]+b_queue[3]))>>2;
        end

        S5_0:begin
            b_queue[0]<=position-128;
            b_queue[1]<=position+128;
            r_queue[0]<=position-1;
            r_queue[1]<=position+1;
        end
        S5_1:begin
            if (count<2) begin
                addr_r<=r_queue[count];
                addr_b<=b_queue[count];
            end
            if (count) begin
                r_queue[count-1]<=rdata_r;
                b_queue[count-1]<=rdata_b;
            end
            count<=count+1;
        end
        S5_2:begin
            wr_r<=1;wr_b<=1;
            addr_r<=position;
            addr_b<=position;
            wdata_r<=(r_queue[0]+r_queue[1])>>1;
            wdata_b<=(b_queue[0]+b_queue[1])>>1;
        end

        S6:begin
            wr_r<=0;wr_g<=0;wr_b<=0;    
            count<=0;            
            if(col==127) begin
                row<=row+1;
                col<=0;
            end
            else col<=col+1;
        end

        S7:begin
            if (&row) begin
                done<=1;
            end
        end

            
    endcase
end
endmodule