`timescale 1ns / 10ps

module perm_blk(input reg clk, input reg rst, input reg pushin, output reg stopin, 
    input firstin, input [63:0] din,
    
    output reg [2:0] m1rx, output reg [2:0] m1ry,
    input [63:0] m1rd,
    output reg [2:0] m1wx, output reg [2:0] m1wy,output reg m1wr,
    output reg [63:0] m1wd,
    
    output reg [2:0] m2rx, output reg [2:0] m2ry,
    input [63:0] m2rd,
    output reg [2:0] m2wx, output reg [2:0] m2wy,output reg m2wr,
    output reg [63:0] m2wd,
    
    output reg [2:0] m3rx, output reg [2:0] m3ry,
    input [63:0] m3rd,
    output reg [2:0] m3wx, output reg [2:0] m3wy,output reg m3wr,
    output reg [63:0] m3wd,
    
    output reg [2:0] m4rx, output reg [2:0] m4ry,
    input [63:0] m4rd,
    output reg [2:0] m4wx, output reg [2:0] m4wy,output reg m4wr,
    output reg [63:0] m4wd,
    
    output reg pushout, input stopout, output reg firstout, 
    output reg [63:0] dout
    );



    // Declaration for input SM:    
    //reg m1_spaceready = 1'b1; // output from the perm SM as indication of m55_1 memory is ready for new data.
    reg [2:0] inputx, inputy;
    reg [2:0] inputx_d, inputy_d;
    // Declaration for Permutation SM:
    reg [4:0] perm_round;
    reg [2:0] perm_x, perm_y;
    //reg [5:0] perm_z;
    
    reg [4:0] perm_round_d;
    reg [2:0] perm_x_d, perm_y_d;
    //reg [5:0] perm_z_d;

    // declar variables for Algorithm 2:
    //reg [2:0] algo2_index_x;
    //reg [2:0] algo2_index_y;
    reg [4:0] algo2_t_loop;
    reg [4:0] algo2_t_loop_d;
    reg [5:0] algo2_Zshift_amount;
    reg [127:0] algo2_R128;
    //reg [5:0] algo2_Zshift_amount_sub1;

    //reg [63:0] algo6_RC;

    reg [2:0] outputx, outputy;
    reg [2:0] outputx_d, outputy_d;

    reg ready_to_output;




    // Enum for Input SM:
    enum reg [2:0] { // try optimized to 2 bits????????????????????????????????
        R,
        incx,
        incy
    } cs, ns;
    // Enum for Permutation SM:
    enum reg [3:0] {
        perm_R,
        Algo1_step1,                //Algorithm_1,
        Algo1_step2,
        Algo1_step3,
        Algo2_step1and2,            //Algorithm_2,
        Algo2_step3and4,
        Algo3,                      //Algorithm_3,
        Algo4_step1,                //Algorithm_4 has three sub-steps, see Algo4 section below for more details
        Algo4_step2,
        Algo4_step3,
        Algo5_and_6,                //Algorithm_5: Reset RC to 64'b0;
        Round_decision              //Not until No.24 round
    } perm_cs, perm_ns;

    enum reg [2:0] { 
        O_R,
        O_incx,
        O_incy
    } o_cs, o_ns;


   


    
    //******************************* SM for Input ********************************
    always @(*) begin
        ns=cs;
        inputx_d=inputx;
        inputy_d=inputy;
        case(cs)
            R: begin
                //m1wr=0;
                inputx_d=1;
                inputy_d=0;
                if(stopin == 0 && pushin == 1 && firstin == 1) begin
                    m1wd=din;
                    m1wx=0;
                    m1wy=0;
                    m1wr=1;
                    ns=incx;
                end else begin // not ready for inputs
                    ns=R;
                end
            end

            incx: begin
                if (inputy>4) begin
                    m1wr=0;
                    inputy_d=0;
                    inputx_d=1;
                    ns=R;
                    stopin=1;
                end else begin
                    m1wd=din;
                    m1wx=inputx;
                    m1wy=inputy;
                    inputx_d=inputx+1;
                    if(inputx_d>=4) ns=incy;
                    else ns=incx;
                end
            end

            incy: begin
                m1wd=din;
                m1wx=inputx;
                m1wy=inputy;
                inputx_d=0;
                inputy_d=inputy+1;
                ns=incx;
            end

            default:
                $display("I'm lost with %b, @%t",cs,$time);
        endcase
    end
    // update non_d value posedge clk:
    always @(posedge(clk) or posedge(rst)) begin 
        if(rst) begin
            cs<=R;
            inputx<=0;
            inputy<=0;
            stopin<=0; // default is ready to take input data
            m1wr<=0;
        end else begin
            cs<= #1 ns;
            inputx<= #1 inputx_d;
            inputy<= #1 inputy_d;
        end
    end
    //********************************* Input Stage Ends Here ************************************************
    

    //********************************* SM for Permutation ********************************
    always @(*) begin
        perm_ns = perm_cs;
        perm_round_d = perm_round;
        perm_x_d = perm_x;
        perm_y_d = perm_y;
        //perm_z_d = perm_z;
        algo2_t_loop_d = algo2_t_loop;
        
          // To prevent Latches:
        m1rx=perm_x;//m1
        m1ry=perm_y;
        // if(perm_cs==perm_R) begin
        //     //m1wx=inputx;
        //     //m1wy=inputy;
        //     //m1wr=1;
        //     //m1wd=din;
        // end else begin
        //     // m1wx=perm_x;
        //     // m1wy=perm_y;
        //     // m1wr=0;
        //     // m1wd=m2rd;
        // end
        m2rx=perm_x;//m2
        m2ry=perm_y;
        m2wx=perm_x;
        m2wy=perm_y;
        m3rx=perm_x;//m3
        m3ry=perm_y;
        m3wx=perm_x;
        m3wy=perm_y;

        m4wx=perm_x;
        m4wy=perm_y;
        


        m2wr=0;
        m3wr=0;
        m4wr=0;
        
        
        case(perm_cs)
            perm_R: begin
                    perm_x_d=0;
                    perm_y_d=0;

                    // m1wr=0;
                    // m2wr=0;
                    // m3wr=0;
                    // m4wr=0;

                    //perm_z_d=0;
                    algo2_t_loop_d=0;
                    perm_round_d=0;
                    if(stopin==1) begin // permutation block starting condition
                        perm_ns=Algo1_step1;
                    end else begin
                        perm_ns=perm_R;
                    end
            end
            // Theta:
            Algo1_step1: begin
                m1wr=0;
                // m1rx=perm_x;
                // m1ry=perm_y;
                perm_x_d=perm_x+1; // update x only
                m2wx=(perm_x+1)%5; 
                m2wy=0;
                m3wx=(perm_x+9)%5;  //can not do calculation for negative #, therefore +9
                m3wy=1;
                if(perm_y==0) begin
                    m2wd=m1rd;
                    m3wd=m1rd;
                end else begin
                    m2rx=(perm_x+1)%5;
                    m2ry=0;
                    m2wd=m1rd^m2rd; 
                    m3wd=m1rd^m2rd;
                end
                m2wr=1;
                m3wr=1;
                if(perm_x>=4) begin
                    perm_x_d=0;
                    if(perm_y>3) begin
                        // m2wr=0;
                        // m3wr=0;
                        perm_x_d=0;
                        perm_y_d=0;
                        //perm_z_d=0;
                        //m1_spaceready=1; // for testing only!!!!!!!!!!!!!!!!!!!
                        perm_ns=Algo1_step2;
                    end else begin
                        perm_y_d=perm_y+1; //update y
                        perm_ns=Algo1_step1;
                    end
                end else perm_ns=Algo1_step1;
            end

            Algo1_step2: begin
                perm_x_d=perm_x+1;
                m3wx=perm_x; // (upper level)
                m3wy=4;
                m2rx=perm_x; // read from m2
                m2ry=0;
                m3rx=perm_x; // read from m3_y=1
                m3ry=1;

                m3wd=m2rd^{m3rd[62:0],m3rd[63]}; // XOR with shifted version of m3_y=1

                m3wr=1;
                if(perm_x>=4) begin
                    // m3wr=0;
                    perm_x_d=0;
                    perm_y_d=0;
                    //perm_z_d=0;
                    //m1_spaceready=1; // for testing only!!!!!
                    perm_ns=Algo1_step3;
                end
            end

            Algo1_step3: begin
                m1rx=perm_x;
                m1ry=perm_y;
                perm_x_d=perm_x+1;
                m3wx=perm_x;        
                m3wy=perm_y;        
                m3rx=perm_x;
                m3ry=4;
                m3wd=m1rd^m3rd;
            
                //m2wr=1;
                m3wr=1;
                if(perm_x>=4) begin
                    perm_x_d=0;
                    if(perm_y>3) begin
                        // m3wr=0;
                        perm_x_d=0;
                        perm_y_d=0;
                        //perm_z_d=0;
                        //m1_spaceready=1; // m1 is now ready for the nest 1600 bits data!!!!!!!!!!!
                        perm_ns=Algo2_step1and2;
                    end else begin
                        perm_y_d=perm_y+1;
                        perm_ns=Algo1_step3;
                    end
                end
            end
            // Rho
            Algo2_step1and2: begin
                if (perm_round==23) stopin=0; // m1 is nolonger in use. ready for the next input
                m3rx=0; //read A[0,0,z] from m3 and copy into m2
                m3ry=0;
                m2wx=0;
                m2wy=0;
                
                m2wd=m3rd;
                m2wr=1;
                
                perm_x_d=1;
                perm_y_d=0;
                algo2_t_loop_d=0;
                //m1_spaceready=1; // for testing only!!!!!!!!!!!!!!!!!!!
                //algo2_t_loop_d=0; // initial t for next step
                perm_ns=Algo2_step3and4;
                //algo2_Zshift_amount=1;
            end

            Algo2_step3and4: begin
                // m3rx=perm_x;
                // m3ry=perm_y;
                // m2wx=perm_x;
                // m2wy=perm_y;
                algo2_Zshift_amount=((algo2_t_loop+1)*(algo2_t_loop+2)/2)%64;
                algo2_R128={64'b0, m3rd[63:0]};
                algo2_R128=algo2_R128 << algo2_Zshift_amount;
                m2wd=algo2_R128[127:64] | algo2_R128[63:0];
                //algo2_Zshift_amount_sub1=algo2_Zshift_amount-1;
                //m2wd={m3rd[0:0],m3rd[63:1]}; // Shift amount: algo2_Zshift_amount            
                m2wr=1;

                if(algo2_t_loop>22) begin
                    // m1_spaceready=1; // for testing only!!!!!!!!!!!!!!!!!!!
                    // perm_ns=perm_R;
                    perm_x_d=0;
                    // m2wr=0;
                    perm_y_d=0;
                    perm_ns=Algo3;
                end else begin
                    perm_x_d=perm_y;
                    perm_y_d=((2*perm_x)+(3*perm_y))%5;
                    algo2_t_loop_d=algo2_t_loop+1;
                    perm_ns=Algo2_step3and4;
                end
            end
            // Pi:
            Algo3: begin
                perm_x_d=perm_x+1;
                //perm_x_d=perm_y+1;
                m2rx=(perm_x+3*perm_y)%5;
                m2ry=perm_x;
                // m3wx=perm_x;
                // m3wy=perm_y;
                m3wd=m2rd;
                m3wr=1;

                if(perm_x>=4) begin
                    perm_x_d=0;
                    if(perm_y>3) begin
                        // m3wr=0;
                        perm_x_d=0; // x,y,z归0，为下一个step做准备
                        perm_y_d=0;
                        //m1_spaceready=1; // for testing only!!!!!!!!!!!!
                        perm_ns=Algo4_step1;
                    end else begin
                        perm_y_d=perm_y+1;
                        perm_ns=Algo3;
                    end
                end else perm_ns=Algo3;
            end

            // For Algo4, there are three sub-steps due to limited space of memory blocks.
            // Therefore, I used time in exchange of memory resources.
            // All transactions in this algorithm are from m3 to m2.
            // step 1: read (x+1) sheet from m3 -> write it into m2 at (x)
            // step 2: read (x+2) sheet from m3 and (x) from m2 -> write [(x+2) AND (x)] into m2 at x.
            // step 3: read (x) from m3 and (x) from m2 -> write (x) XOR (x) into m2 at x. ***Then repeat***
            
            // Chi:
            Algo4_step1: begin
                m3rx=(perm_x+1)%5;
                // m3ry=perm_y;
                // m2wx=perm_x;
                // m2wy=perm_y;
                m2wd=m3rd^64'hffffffffffffffff;
                m2wr=1;

                perm_x_d=perm_x+1;
                perm_y_d=perm_y+1;
                if(perm_x>=4) begin
                    perm_x_d=0;
                    if(perm_y>3) begin
                        // m2wr=0;
                        perm_x_d=0; // x,y,z归0，为下一个step做准备
                        perm_y_d=0;
                        //m1_spaceready=1; // for testing only!!!!!!!!!!!!
                        perm_ns=Algo4_step2;
                    end else begin
                        //perm_y_d=perm_y+1;
                        perm_ns=Algo4_step1;
                    end
                end else begin 
                    perm_ns=Algo4_step1;
                    perm_y_d=perm_y;
                end
                //m1_spaceready=1; // for testing only!!!!!!!!!!!!
                //perm_ns=perm_R;
            end

            Algo4_step2: begin
                m3rx=(perm_x+2)%5;
                // m3ry=perm_y;
                // m2rx=perm_x;
                // m2ry=perm_y;
                // m2wx=perm_x;
                // m2wy=perm_y;
                m2wd=m3rd & m2rd;
                m2wr=1;

                perm_x_d=perm_x+1;
                perm_y_d=perm_y+1;
                if(perm_x>=4) begin
                    perm_x_d=0;
                    if(perm_y>3) begin
                        perm_x_d=0; // x,y,z归0，为下一个step做准备
                        perm_y_d=0;
                        // m2wr=0;
                        //m1_spaceready=1; // for testing only!!!!!!!!!!!!
                        perm_ns=Algo4_step3;
                    end else begin
                        //perm_y_d=perm_y+1;
                        perm_ns=Algo4_step2;
                    end
                end else begin 
                    perm_ns=Algo4_step2;
                    perm_y_d=perm_y;
                end
                //m1_spaceready=1; // for testing only!!!!!!!!!!!!
                //perm_ns=perm_R;
            end

            Algo4_step3: begin
                // m3rx=perm_x;
                // m3ry=perm_y;
                // m2rx=perm_x;
                // m2ry=perm_y;
                // m2wx=perm_x;
                // m2wy=perm_y;
                m2wd=m3rd^m2rd;
                m2wr=1;

                perm_x_d=perm_x+1;
                perm_y_d=perm_y+1;
                if(perm_x>=4) begin
                    perm_x_d=0;
                    if(perm_y>3) begin
                        // m2wr=0;
                        perm_x_d=0;
                        perm_y_d=0;
                        //algo6_RC=64'h0000000000000000; // reset RC for Algorithm 5 & 6
                        //m1_spaceready=1; // for testing only!!!!!!!!!!!!
                        perm_ns=Algo5_and_6;
                    end else begin
                        //perm_y_d=perm_y+1;
                        perm_ns=Algo4_step3;
                    end
                end else begin 
                    perm_ns=Algo4_step3;
                    perm_y_d=perm_y;
                end
                //m1_spaceready=1; // for testing only!!!!!!!!!!!!
                //perm_ns=perm_R;
            end

            // For the following code, I have combined algorithm 5 & 6.
            // I have hard coded the RC (round constant) in all cases(24 total) becasuse I thought
            // this is a faster way of doing the chi algorithm.

            // RC function:
            Algo5_and_6: begin
                m2rx=0;
                m2ry=0;
                m2wx=0;
                m2wy=0;
                //m2wd=m2rd;
                //if(perm_x==0 && perm_y==0) begin
                case(perm_round)
                    0: m2wd=m2rd^64'h0000000000000001;
                    1: m2wd=m2rd^64'h0000000000008082;
                    2: m2wd=m2rd^64'h800000000000808A;
                    3: m2wd=m2rd^64'h8000000080008000;
                    4: m2wd=m2rd^64'h000000000000808B;
                    5: m2wd=m2rd^64'h0000000080000001;
                    6: m2wd=m2rd^64'h8000000080008081;
                    7: m2wd=m2rd^64'h8000000000008009;
                    8: m2wd=m2rd^64'h000000000000008A;
                    9: m2wd=m2rd^64'h0000000000000088;
                    10: m2wd=m2rd^64'h0000000080008009;
                    11: m2wd=m2rd^64'h000000008000000A;
                    12: m2wd=m2rd^64'h000000008000808B;
                    13: m2wd=m2rd^64'h800000000000008B;
                    14: m2wd=m2rd^64'h8000000000008089;
                    15: m2wd=m2rd^64'h8000000000008003;
                    16: m2wd=m2rd^64'h8000000000008002;
                    17: m2wd=m2rd^64'h8000000000000080;
                    18: m2wd=m2rd^64'h000000000000800A;
                    19: m2wd=m2rd^64'h800000008000000A;
                    20: m2wd=m2rd^64'h8000000080008081;
                    21: m2wd=m2rd^64'h8000000000008080;
                    22: m2wd=m2rd^64'h0000000080000001;
                    23: m2wd=m2rd^64'h8000000080008008;
                    default: m2wd=m2rd;
                endcase
                //end
                m2wr=1;
                perm_x_d=0;
                perm_y_d=0;
                //m1_spaceready=1; // for testing only!!!!!!!!!!!!
                perm_ns=Round_decision;
                // m2wr=0;
            end

            Round_decision: begin // read from m2, write to m1 or m4 when final round
                // m1wr=0;
                // m4wr=0;
                // m2rx=perm_x; // repeted assignments!!
                // m2ry=perm_y;
                m1wx=perm_x;
                m1wy=perm_y;
                // m4wx=perm_x;
                // m4wy=perm_y;
                m1wd=m2rd;
                m4wd=m2rd;
                //pushout=0; //m4 may get busy, cannot perform output to dout
                if(perm_round>22) m4wr=1;
                else m1wr=1;




                perm_round_d=perm_round; // to prevent forming latch
                perm_x_d=perm_x+1;
                perm_y_d=perm_y+1;
                //pushout=0; // to prevent latch
                if(perm_x>=4) begin
                    perm_x_d=0;
                    if(perm_y>3) begin
                        perm_x_d=0;
                        perm_y_d=0;
                        //m1_spaceready=1; // for testing only!!!!!!!!!!!!
                        perm_round_d=perm_round+1;
                        // m1wr=0;
                        // m4wr=0;
                        if(perm_round>22) begin
                            //m1_spaceready=1; // for testing only!!!!!!!!!!!!
                            // pushout=1; // start output!
                            // firstout=1;
                            ready_to_output=1;
                            perm_round_d=0;
                            perm_ns=perm_R;
                        end else begin
                            perm_ns=Algo1_step1;
                        end
                    end else begin
                        //perm_y_d=perm_y+1;
                        perm_ns=Round_decision;
                    end
                end else begin 
                    perm_ns=Round_decision;
                    perm_y_d=perm_y;
                end
            end
        endcase
    end
    
    
    always @(posedge(clk) or posedge(rst)) begin
        if(rst) begin
            perm_cs<=perm_R;
            perm_x<=0;
            perm_y<=0;
            //perm_z<=0;
            perm_round<=0;
            algo2_t_loop<=0;
            m2wr<=0;
            m3wr<=0;
        end else begin
            perm_cs<= #1 perm_ns;
            perm_x<= #1 perm_x_d;
            perm_y<= #1 perm_y_d;
            //perm_z<= #1 perm_z_d;
            perm_round<= #1 perm_round_d;
            algo2_t_loop<= #1 algo2_t_loop_d;
        end
    end

    //********************************* Permutation Stage Ends Here ************************************************

    //always @(m1rd) $monitor("m1rd output has been changed to: %h @%t", m1rd, $time);








    
    //******************************* SM for Output ********************************
    always @(*) begin
        o_ns=o_cs;
        outputx_d=outputx;
        outputy_d=outputy;
        m4rx=outputx;
        m4ry=outputy;
        dout=m4rd;
        firstout=0;

        case(o_cs)
            O_R: begin
                outputx_d=0;
                outputy_d=0;
                pushout=0;
                if(ready_to_output==1) begin
                    // m4rx=0;
                    // m4ry=0;
                    o_ns=O_incx;
                end else begin
                    o_ns=O_R;
                end
            end

            O_incx: begin
                pushout=1;
                if (outputx==0 && outputy==0) firstout=1;
                if (stopout==1) begin
                    outputx_d=outputx;
                    //firstout=0;
                    o_ns=O_incx;
                end else begin
                    outputx_d=outputx+1;
                    //firstout=0; // 2nd packet of dout starts transfering
                    if(outputx_d>=4) o_ns=O_incy;
                    else o_ns=O_incx;
                end
            end

            O_incy: begin
                if (stopout==1) begin
                    outputx_d=outputx;
                    outputy_d=outputy;
                    o_ns=O_incy;
                end else begin
                    outputx_d=0;
                    outputy_d=outputy+1;
                    //pushout=1;
                    if(outputy>=4) begin // 1600 bits data finished transfer
                        outputy_d=0;
                        outputx_d=0;
                        //pushout=0; // done
                        ready_to_output=0;
                        o_ns=O_R;
                    end else o_ns=O_incx;
                end
            end

            default:
                $display("I'm lost with %b, @%t",cs,$time);
        endcase
    end
   
    always @(posedge(clk) or posedge(rst)) begin 
        if(rst) begin
            o_cs<=O_R;
            outputx<=0;
            outputy<=0;
            pushout<=0;
            firstout<=0;
            ready_to_output<=0;
        end else begin
            o_cs<= #1 o_ns;
            outputx<= #1 outputx_d;
            outputy<= #1 outputy_d;
        end
    end
    //********************************* Output Stage Ends Here ************************************************

endmodule
