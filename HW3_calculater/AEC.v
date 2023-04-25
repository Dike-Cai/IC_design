module AEC(clk, rst, ascii_in, ready, valid, result);

// Input signal
input clk;
input rst;
input ready;
input [7:0] ascii_in;

// Output signal
output valid;
output [6:0] result;

//varibles//
reg valid;
reg [6:0] result;
reg [6:0] f[3:0];
reg [4:0] infix[14:0],postfix[12:0],stk[3:0];

reg [3:0] infix_idx=0,infix_size=0;
reg [3:0] postfix_idx=0,postfix_size=0;
reg [2:0] f_size=0,stk_idx=0;
wire tostg0,tostg1;
reg [1:0] State=2'b0,NextState;
reg pend,taking,donesort;
parameter S0 =3'b000,S1=3'b001,S2=3'b010;

assign tostg0=ready;
assign tostg1=(pend);

//-----Your design-----//
//FSM begin
always@(posedge rst or posedge ready or posedge clk)begin
    if(rst)begin
        State <=S2;
    end
    else if(ready)begin
        State <= S0;
    end
    else begin
       State <= NextState;
    end
end

always@(*)begin
    case (State)
        S0: begin
            if (tostg1)NextState <= S1;
            else NextState=S0;
        end
        S1: begin
            if (tostg1)NextState <= S2;
            else NextState=S1;
        end
        S2: begin
            if (tostg0)NextState <= S0;
            else NextState=S2;
        end
        default: NextState=S2;
    endcase
end
//FSM end
always @(posedge clk) begin
    case (State)
        S0:begin
            if(taking)begin
                if (ascii_in < 46) begin
                    case (ascii_in)
                        43:begin infix[infix_size]<=5'b10010; end //+
                        45:begin infix[infix_size]<=5'b10001; end //-
                        42:begin infix[infix_size]<=5'b10111; end //*
                        40:begin infix[infix_size]<=5'b11001; end //(
                        41:begin infix[infix_size]<=5'b11000; end //)
                    endcase
                    infix_size <=infix_size+4'b1;
                end
                else if (ascii_in < 58) begin
                    infix[infix_size] <=(ascii_in-8'd48);
                    infix_size <=infix_size+4'b1;
                end
                else if (ascii_in != 61)begin  
                    infix[infix_size] <= (ascii_in-8'd87);
                    infix_size <= infix_size+4'b001;       
                end
                else begin
                    taking<=0;
                end  
            end
            //1 
            if (infix_size) begin
                if (infix_idx==infix_size) begin
                    if(stk_idx==0) begin
                        stk_idx <= stk_idx;
                        postfix_size <= postfix_size;
                        donesort<=1;
                    end
                    else begin
                        postfix[postfix_size] <= stk[stk_idx-1];
                        stk_idx <= stk_idx-3'b1;
                        postfix_size <= postfix_size+4'b001;
                    end    
                end
                else begin
                    casez (infix[infix_idx]) 
                        5'b11zz0:
                        begin
                            if(stk[stk_idx-1][3])begin
                                infix_idx <= infix_idx+4'b1;
                            end
                            else begin
                                postfix[postfix_size] <= stk[stk_idx-1];
                                postfix_size <= postfix_size+4'b1;
                            end
                            stk_idx <= stk_idx-3'b001;
                        end 
                        5'b11zz1: 
                        begin
                            stk[stk_idx] <= infix[infix_idx];
                            stk_idx <= stk_idx+3'b1;
                            infix_idx <= infix_idx+4'b1;
                        end
                        5'b101zz:begin
                            if (stk_idx==0 || stk[stk_idx-1][2]==0) begin
                                stk[stk_idx] <= infix[infix_idx];
                                stk_idx <= stk_idx+3'b001;
                            end
                            else begin
                                postfix[postfix_size] <= infix[infix_idx];
                                postfix_size <= postfix_size+4'b1;
                            end
                            infix_idx <= infix_idx+4'b1;                        
                        end
                        5'b100zz:
                        begin
                            if (stk_idx==0 || stk[stk_idx-1][3]) begin
                                stk[stk_idx] <= infix[infix_idx];
                                stk_idx <= stk_idx+3'b001;
                                infix_idx <= infix_idx+4'b1;
                            end
                            else begin
                                postfix[postfix_size] <=stk[stk_idx-1];
                                postfix_size <= postfix_size+4'b1;
                                stk_idx <= stk_idx-3'b001;
                            end
                        end
                        5'b0zzzz:begin
                            postfix[postfix_size] <= infix[infix_idx]; 
                            postfix_size <= postfix_size+4'b1;
                            infix_idx <= infix_idx+4'b1;
                        end                       
                    endcase
                end
            
                     
                // if (infix[infix_idx][4]) begin
                //     if (infix[infix_idx][3]) begin
                //         if (infix[infix_idx][0]==0) begin
                //             if(stk[stk_idx-1][3])begin
                //                 infix_idx <= infix_idx+4'b1;
                //             end
                //             else begin
                //                 postfix[postfix_size] <= stk[stk_idx-1];
                //                 postfix_size <= postfix_size+4'b1;
                //             end
                //             stk_idx <= stk_idx-3'b001;
                //         end
                //         else begin
                //             stk[stk_idx] <= infix[infix_idx];
                //             stk_idx <= stk_idx+3'b1;
                //             infix_idx <= infix_idx+4'b1;
                //         end
                //     end
                //     else if (infix[infix_idx][2]) begin
                //         if (stk_idx==0 || stk[stk_idx-1][2]==0) begin
                //             stk[stk_idx] <= infix[infix_idx];
                //             stk_idx <= stk_idx+3'b001;
                //         end
                //         else begin
                //             postfix[postfix_size] <= infix[infix_idx];
                //             postfix_size <= postfix_size+4'b1;
                //         end
                //         infix_idx <= infix_idx+4'b1;                        
                //     end
                //     else begin
                //         if (stk_idx==0 || stk[stk_idx-1][3]) begin
                //             stk[stk_idx] <= infix[infix_idx];
                //             stk_idx <= stk_idx+3'b001;
                //             infix_idx <= infix_idx+4'b1;
                //         end
                //         else begin
                //             postfix[postfix_size] <=stk[stk_idx-1];
                //             postfix_size <= postfix_size+4'b1;
                //             stk_idx <= stk_idx-3'b001;
                //         end
                //     end
                // end
                // else begin
                //     postfix[postfix_size] <= infix[infix_idx]; 
                //     postfix_size <= postfix_size+4'b1;
                //     infix_idx <= infix_idx+4'b1;
                // end
            end
            //2
            if (postfix_size>postfix_idx || donesort) begin
                if (postfix[postfix_idx][4]==0) begin
                    f[f_size] <= postfix[postfix_idx];
                    f_size <= f_size+3'b001;
                end
                else begin
                    if (postfix[postfix_idx][0]==0)begin
                        f[f_size-2] <= f[f_size-2]+f[f_size-1];
                    end 
                    else if (postfix[postfix_idx][1]==0)begin
                        f[f_size-2] <= f[f_size-2]-f[f_size-1];
                    end 
                    else begin
                        f[f_size-2] <= f[f_size-2]*f[f_size-1];
                    end
                    f_size <= f_size-3'b001;
                end
                postfix_idx <= postfix_idx+4'b001;
                if(postfix_idx==postfix_size) begin
                    result=f[0];
                    pend<=1;
                end
            end
        end

        S1:begin
            valid<=1;
        end

        S2:begin
            pend=0;
            valid<=0;
            infix_idx<=0;
            infix_size<=0;
            postfix_idx<=0;
            postfix_size<=0;
            f_size <=0;
            taking=1;
            donesort<=0;
        end
    endcase
end
endmodule