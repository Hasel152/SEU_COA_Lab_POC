`timescale 1ns/1ps

module top_module(
  input CLK,
  input switch,
  input print,
  input [7:0] data,
  input RST_N
  );
  
 //CPU”ÎPOC
wire [2:0] ADDR;
wire [7:0] Din;
wire [7:0] Dout;
wire RW;
wire IRQ;

//POC”ÎPrinter
wire RDY;
wire [7:0] PD;
wire TR;

    cpu_module cpu(
           .CLK(CLK),
           .RST_N(RST_N),
           .switch(switch),
           .print(print),
           .data(data),
           .RW(RW),
           .Din(Din),
           .ADDR(ADDR),
           .IRQ(IRQ),
           .Dout(Dout)
    );
    
    
    poc_module  poc(
            .CLK(CLK),
            .RST_N(RST_N),
            .RW(RW),
            .ADDR(ADDR),
            .Din(Din),
            .Dout(Dout),
            .IRQ(IRQ),
            .RDY(RDY),
            .TR(TR),
            .PD(PD)
    );
    
    
    printer_module  printer(
            .CLK(CLK),
            .TR(TR),
            .PD(PD),
            .RDY(RDY)
    );

endmodule