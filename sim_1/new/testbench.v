`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/04/01 16:03:01
// Design Name: 
// Module Name: tb_printer
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


module tb_printer( );
   reg [7:0] PD;
   reg TR;
   reg CLK;
   wire  RDY;
   reg RST_N;
   wire [5:0]  print_counter; 
   
   printer_module printer(
   .PD(PD),
   .TR(TR),
   .CLK(CLK),
   .RDY(RDY),
   .RST_N(RST_N),
   .print_counter(print_counter)
   );

   
initial begin
   CLK =0;
   forever #5 CLK = ~CLK;
end


initial begin
    PD = 0;
    RST_N = 0;
    TR = 0;
//    print_counter =0;
    #50
    RST_N = 1;
    #50
    TR = 1;
    #200
    RST_N = 0;
    #200
    RST_N= 1;
    #400
    TR = 0;
    #1000;
    $finish;
end
  
endmodule
