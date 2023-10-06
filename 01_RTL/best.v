module geofence ( clk,reset,X,Y,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
output reg valid;
output reg is_inside;
//reg valid;
//reg is_inside;

// --------------------------------------------------------------
// parameter
// --------------------------------------------------------------
parameter S_IDLE   = 3'b010;
// parameter S_INPUT  = 3'b010;
parameter S_SORT   = 3'b110;
parameter S_CAL    = 3'b111;
parameter S_OUTPUT = 3'b011;


// --------------------------------------------------------------
// regs & genvar
// --------------------------------------------------------------
genvar i;
wire signed [21:0] product;
wire signed [10:0] A_s[1:0], B_s[1:0], C_s[1:0];
reg  [9:0] A[1:0], B[1:0], C[1:0];
reg  [9:0] A_nxt[1:0], B_nxt[1:0], C_nxt[1:0];
reg  [9:0] pos_x[6:0], pos_y[6:0];
reg [4:0] flag;
wire [2:0] flag_sum;
reg [2:0] pointer, cnt_sort, cnt;
reg [2:0] cs, ns;


// --------------------------------------------------------------
// design
// --------------------------------------------------------------

// sort :
// keep choose two point and get the upper point and lower point to find all
// clockwise position
// plan : keep choose pos 0 
// and first choose 1
// worst case
// choose 1 and get all lower than pos 1=> [1] [2] [3] [4] [5]
// choose 2 and get 3 upper 4 5 lower => [1] [3] [2] [4] [5]
// choose 3
// choose 4
// use one pointer to find the index of choose number => see through oll
// number add pointer when found number upper than choose number



// product : 20bit => warning for 30ns
// plan a : do direct => cons : 2*(10x10)multiplier
// plan b : do twice  => cons : 20 bit register
// assign product = (A[0] - C[0])*(B[1] - C[1]) - (A[1] - C[1])*(B[0] - C[0]);
assign product = (A_s[0] - C_s[0])*(B_s[1] - C_s[1]) - (A_s[1] - C_s[1])*(B_s[0] - C_s[0]);
generate 
for (i = 0; i < 2; i = i + 1) begin
    assign A_s[i] = {1'b0, A[i]};
    assign B_s[i] = {1'b0, B[i]};
    assign C_s[i] = {1'b0, C[i]};
end
endgenerate 
always @(*) begin
    case (cs)
        S_SORT : begin
            C[0] = pos_x[1];
            C[1] = pos_y[1];
            A[0] = (cnt == 3'd7) ? pos_x[0] : pos_x[cnt];
            A[1] = (cnt == 3'd7) ? pos_y[0] : pos_y[cnt];
            B[0] = (cnt_sort == 3'd7) ? pos_x[0] : pos_x[cnt_sort];
            B[1] = (cnt_sort == 3'd7) ? pos_y[0] : pos_y[cnt_sort];
        end
        S_CAL : begin
            A[0] = pos_x[0]; 
            A[1] = pos_y[0];
            case (cnt) 
                3'd1 : begin
                    C[0] = pos_x[2];
                    C[1] = pos_y[2];
                    B[0] = pos_x[3];
                    B[1] = pos_y[3];
                end
                3'd2 : begin 
                    C[0] = pos_x[3];
                    C[1] = pos_y[3];
                    B[0] = pos_x[4];
                    B[1] = pos_y[4];
                end
                3'd3 : begin
                    C[0] = pos_x[4];
                    C[1] = pos_y[4];
                    B[0] = pos_x[5];
                    B[1] = pos_y[5];
                end
                3'd4 : begin
                    C[0] = pos_x[5];
                    C[1] = pos_y[5];
                    B[0] = pos_x[6];
                    B[1] = pos_y[6];
                end
                3'd5 : begin
                    C[0] = pos_x[6];
                    C[1] = pos_y[6];
                    B[0] = pos_x[1];
                    B[1] = pos_y[1];
                end
                default : begin
                    C[0] = pos_x[1];
                    C[1] = pos_y[1];
                    B[0] = pos_x[2];
                    B[1] = pos_y[2];
                end
            endcase 
        end
        default : begin
            A[0] = pos_x[2];
            A[1] = pos_y[2];
            B[0] = pos_x[3];
            B[1] = pos_y[3];
            C[0] = pos_x[1];
            C[1] = pos_y[1];
        end
    endcase 

end
// always @(*) begin
//     // mux for ax ay bx by
//     case (cs) 
//         S_IDLE : begin
//             A_nxt[0] = pos_x[2];
//             A_nxt[1] = pos_y[2];
//             B_nxt[0] = pos_x[3];
//             B_nxt[1] = pos_y[3];
//             C_nxt[0] = pos_x[1];
//             C_nxt[1] = pos_y[1];
//         end
//         S_SORT : begin
//             C_nxt[0] = pos_x[1];
//             C_nxt[1] = pos_y[1];
//             if (flag_sum == 3'd4) begin
//                 // initialize for a[] b[] for s_cal
//                 // as vector ac is opposite => hence all test product should
//                 // be all positive with clockwise test
//                 A_nxt[0] = pos_x[0];
//                 A_nxt[1] = pos_y[0];
//                 B_nxt[0] = pos_x[2];
//                 B_nxt[1] = pos_y[2];
//             end
//             else begin
//                 if (cnt_sort == 3'd0) begin
//                     case (cnt) // do not need to reset A
//                         3'd2 : begin
//                             A_nxt[0] = (flag[0] == 1'b1) ? pos_x[3] : pos_x[2];
//                             A_nxt[1] = (flag[0] == 1'b1) ? pos_y[3] : pos_y[2];
//                         end                                                   
//                         3'd3 : begin                                          
//                             A_nxt[0] = (flag[1] == 1'b1) ? pos_x[4] : pos_x[3];
//                             A_nxt[1] = (flag[1] == 1'b1) ? pos_y[4] : pos_y[3];
//                         end                                                   
//                         3'd4 : begin                                          
//                             A_nxt[0] = (flag[2] == 1'b1) ? pos_x[5] : pos_x[4];
//                             A_nxt[1] = (flag[2] == 1'b1) ? pos_y[5] : pos_y[4];
//                         end                                                   
//                         3'd5 : begin                                          
//                             A_nxt[0] = (flag[3] == 1'b1) ? pos_x[6] : pos_x[5];
//                             A_nxt[1] = (flag[3] == 1'b1) ? pos_y[6] : pos_y[5];
//                         end
//                         default : begin
//                             A_nxt[0] = pos_x[0];
//                             A_nxt[1] = pos_y[0];
//                         end
//                     endcase  
//                 end
//                 else begin
//                     A_nxt[0] = A[0];
//                     A_nxt[1] = A[1];
//                 end 
//                 case (cnt_sort) 
//                     3'd2 : begin
//                         B_nxt[0] = (cnt - 3'd1 == cnt_sort) ? pos_x[4] : pos_x[3];
//                         B_nxt[1] = (cnt - 3'd1 == cnt_sort) ? pos_y[4] : pos_y[3];
//                     end                                            
//                     3'd3 : begin                                   
//                         B_nxt[0] = (cnt - 3'd1 == cnt_sort) ? pos_x[5] : pos_x[4];
//                         B_nxt[1] = (cnt - 3'd1 == cnt_sort) ? pos_y[5] : pos_y[4];
//                                                                    
//                     end                                            
//                     3'd4 : begin                                   
//                         B_nxt[0] = (cnt - 3'd1 == cnt_sort) ? pos_x[6] : pos_x[5];
//                         B_nxt[1] = (cnt - 3'd1 == cnt_sort) ? pos_y[6] : pos_y[5];
//                     end                                            
//                     3'd5 : begin                                   
//                         B_nxt[0] = pos_x[6];
//                         B_nxt[1] = pos_y[6];
//                     end
//                     default : begin
//                         B_nxt[0] = (cnt == 3'd2) ? pos_x[3] : pos_x[2];
//                         B_nxt[1] = (cnt == 3'd2) ? pos_y[3] : pos_y[2];
//                     end
//                 endcase  
//             end
//         end
//         S_CAL : begin
//             A_nxt[0] = pos_x[0]; 
//             A_nxt[1] = pos_y[0];
//             case (cnt) 
//                 3'd1 : begin
//                     C_nxt[0] = pos_x[2];
//                     C_nxt[1] = pos_y[2];
//                     B_nxt[0] = pos_x[3];
//                     B_nxt[1] = pos_y[3];
//                 end
//                 3'd2 : begin 
//                     C_nxt[0] = pos_x[3];
//                     C_nxt[1] = pos_y[3];
//                     B_nxt[0] = pos_x[4];
//                     B_nxt[1] = pos_y[4];
//                 end
//                 3'd3 : begin
//                     C_nxt[0] = pos_x[4];
//                     C_nxt[1] = pos_y[4];
//                     B_nxt[0] = pos_x[5];
//                     B_nxt[1] = pos_y[5];
//                 end
//                 3'd4 : begin
//                     C_nxt[0] = pos_x[5];
//                     C_nxt[1] = pos_y[5];
//                     B_nxt[0] = pos_x[6];
//                     B_nxt[1] = pos_y[6];
//                 end
//                 3'd5 : begin
//                     C_nxt[0] = pos_x[6];
//                     C_nxt[1] = pos_y[6];
//                     B_nxt[0] = pos_x[1];
//                     B_nxt[1] = pos_y[1];
//                 end
//                 default : begin
//                     C_nxt[0] = pos_x[1];
//                     C_nxt[1] = pos_y[1];
//                     B_nxt[0] = pos_x[2];
//                     B_nxt[1] = pos_y[2];
//                 end
//             endcase
//         end
//         default : begin
//             A_nxt[0] = pos_x[2];
//             A_nxt[1] = pos_y[2];
//             B_nxt[0] = pos_x[3];
//             B_nxt[1] = pos_y[3];
//             C_nxt[0] = pos_x[1];
//             C_nxt[1] = pos_y[1];
//         end
//     endcase
// end
// generate
// for (i = 0; i < 2; i = i + 1) begin
//     always @(posedge clk or posedge reset) begin
//         if (reset) begin
//             A[i] <= 11'd0;
//             B[i] <= 11'd0;
//             C[i] <= 11'd0;
//         end
//         else begin
//             A[i] <= {1'b0, A_nxt[i]};
//             B[i] <= {1'b0, B_nxt[i]};
//             C[i] <= {1'b0, C_nxt[i]};
//         end
//     end
// end
// endgenerate

// pos register : 0 for the target
generate
for (i = 0; i < 7; i = i + 1) begin
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pos_x[i] <= 10'd0;
            pos_y[i] <= 10'd0;
        end
        else if (cs == S_IDLE) begin
            if (cnt == i) begin
                pos_x[i] <= X;
                pos_y[i] <= Y;
            end 
            else begin
                pos_x[i] <= pos_x[i];
                pos_y[i] <= pos_y[i];
            end 
        end
        else if (cs == S_SORT) begin
            if (i == 0 || i == 1) begin
                pos_x[i] <= pos_x[i];
                pos_y[i] <= pos_y[i];
            end
            else begin
                if (cnt_sort == 3'd7 && i == pointer) begin
                    // two 10 bits 7 to 1 mux
                    pos_x[i] <= pos_x[cnt];    
                    pos_y[i] <= pos_y[cnt];
                end
                else if (cnt_sort == 3'd7 && i == cnt) begin
                    pos_x[i] <= pos_x[pointer];
                    pos_y[i] <= pos_y[pointer];
                end
                else begin
                    pos_x[i] <= pos_x[i];
                    pos_y[i] <= pos_y[i];
                end
            end
        end
        else begin
            pos_x[i] <= pos_x[i];
            pos_y[i] <= pos_y[i];
        end
    end
end
endgenerate

generate 
for (i = 0; i < 5; i = i + 1) begin
    always @(posedge clk or posedge reset) begin
        if (reset) flag[i] <= 1'b0;
        else if (cs == S_SORT) begin
            if (cnt_sort == 3'd7 && i + 2 == pointer) flag[i] <= 1'b1;      // use only flag_sum 
            else                                      flag[i] <= flag[i];
        end
        else flag[i] <= 1'b0;
    end
end
endgenerate

// counter
always @(posedge clk or posedge reset) begin
    if (reset) pointer <= 3'd2;
    else if (cs == S_SORT) begin
        if (cnt_sort == 3'd7) pointer <= 3'd2;
        else if (cnt_sort == 3'd0) pointer <= pointer;
        else if (product[21] == 1'b0) pointer <= pointer + 3'd1; // product delay one cycle
        else pointer <= pointer;
    end
    else pointer <= 3'd2;
end

always @(posedge clk or posedge reset) begin
    if (reset) cnt_sort <= 3'd3;
    else begin
        case (cs)
            S_IDLE : cnt_sort <= 3'd3;
            S_SORT : begin
                if (cnt_sort == 3'd7) cnt_sort <= 3'd0; // cnt_sort == 7 -> pointer cannot be record for the flag register
                else if (cnt_sort == 3'd0 || flag_sum == 3'd4) cnt_sort <= (cnt == 3'd2) ? 3'd3 : 3'd2; // cnt_sort == 7 -> pointer cannot be record for the flag register
                else if (cnt_sort == (cnt - 3'd1)) cnt_sort <= cnt_sort + 3'd2;
                else cnt_sort <= cnt_sort + 3'd1;
            end
            S_CAL : begin
                // cnt_sort initialize be 3'b010
                cnt_sort[2] <= cnt_sort[2];
                cnt_sort[1] <= (product[21] == 1'b1) ? 1'b0 : cnt_sort[1]; // all must be positive
                cnt_sort[0] <= cnt_sort[0];
            end
            default : cnt_sort <= cnt_sort;
        endcase
    end
end

assign flag_sum = flag[0] + flag[1] + flag[2] + flag[3] + flag[4];
always @(posedge clk or posedge reset) begin
    if (reset) cnt <= 3'd0;
    else begin
        case (cs) 
            S_IDLE : cnt <= (cnt == 3'b110) ? 3'd2 : cnt + 3'd1; // pos[1] must be the head of sort hence only choose for the rest number 
            S_SORT : begin
                if (flag_sum == 3'd4) cnt <= 3'd1;
                else begin
                    cnt <= (pointer == cnt && cnt_sort == 3'd7) ? cnt + 3'd1 : cnt;
                    // case (cnt) 
                    //     3'd2 : cnt <= (flag[0] == 1'b1) ? 3'd3 : 3'd2;
                    //     3'd3 : cnt <= (flag[1] == 1'b1) ? 3'd4 : 3'd3;
                    //     3'd4 : cnt <= (flag[2] == 1'b1) ? 3'd5 : 3'd4;
                    //     3'd5 : cnt <= (flag[3] == 1'b1) ? 3'd6 : 3'd5;
                    //     3'd6 : cnt <= (flag[4] == 1'b1) ? 3'd7 : 3'd6; // ?
                    //     default : cnt <= 3'd1;
                    // endcase
                end
            end
            S_CAL : cnt <= (cnt == 3'b111) ? cnt : cnt + 3'd1;
            default : cnt <= 3'd7;
        endcase
    end 
end


// state machine
always @(*) begin
    case (cs) 
        // S_IDLE : ns = (!reset) ? S_INPUT : cs;
        S_IDLE : ns = (cnt == 3'b110) ? S_SORT : cs;
        S_SORT : ns = (flag_sum == 3'd4) ? S_CAL : cs; // 4 place right => last must be right => only check for first 4 number
        S_CAL : ns = (cnt == 3'd6) ? S_OUTPUT : cs;
        S_OUTPUT : ns = S_IDLE;
        default : ns = S_IDLE;
    endcase
end
always @(posedge clk or posedge reset) begin
    if (reset) cs <= S_IDLE;
    else       cs <= ns;        
end


// output
always @(posedge clk or posedge reset) begin
    if (reset)               valid <= 1'b0;
    else if (cs == S_OUTPUT) valid <= 1'b1;
    else                     valid <= 1'b0; 
end

always @(posedge clk or posedge reset) begin
    if (reset)               is_inside <= 1'b0;
    else if (cs == S_OUTPUT) is_inside <= cnt_sort[1];
    else                     is_inside <= 1'b0; 
end

endmodule

