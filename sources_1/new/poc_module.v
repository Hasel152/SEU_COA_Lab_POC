`timescale 1ns/1ps

module poc_module(
   input wire       CLK,
   input wire       RST_N,
   //CPU接口
   input wire [7:0]  Din,
   output reg  [7:0] Dout,
   input wire        RW,
   input wire [2:0]  ADDR,
   output wire       IRQ,
   //printer接口
   input  wire       RDY,
   output reg        TR,
   output reg [7:0]  PD
);

   // 内部寄存器
   reg [7:0] BR; // 数据缓冲寄存器（存要打印的数据）
   reg [7:0] SR; // 状态寄存器：SR7=就绪，SR0=中断使能
   reg [1:0] state;
   
   // 地址宏定义
   localparam ADDR_SR = 3'b000; // 状态寄存器地址
   localparam ADDR_BR = 3'b001; // 数据缓冲寄存器地址
   
   always @(posedge CLK or negedge RST_N) begin
       if(!RST_N) begin
           BR <= 8'h00;
           SR <= 8'h80;  // 初始化为就绪状态
           state <= 0;
           TR <= 0;
           PD <= 8'h00;
       end
       else begin
           // 处理CPU写操作
           if(RW == 1) begin
               if(ADDR == ADDR_SR) begin
                   SR <= Din; 
               end 
               else if(ADDR == ADDR_BR) begin
                   BR <= Din;
                   SR[7] <= 0;  // 写入数据后，清除就绪标志
               end 
           end
           
           // 打印状态机
           case(state)
               2'd0: begin  // 空闲状态
                   TR <= 0;
                   if(SR[7] == 0) begin  // 有待发送数据
                       state <= 2'd1;
                   end
               end
               
               2'd1: begin  // 等待打印机就绪
                   if(RDY == 1) begin
                       TR <= 1;
                       PD <= BR;
                       state <= 2'd2;
                   end
               end
               
               2'd2: begin  // 等待打印机完成
                   if(RDY == 0) begin
                       TR <= 0;
                       SR[7] <= 1;  // 设置就绪标志
                       state <= 2'd0;
                   end
               end 
               
               default: state <= 2'd0;
           endcase
       end
   end
   
   // CPU读操作
   always @(*) begin
       if(RW == 0) begin
           if(ADDR == ADDR_SR) begin
               Dout = SR;
           end 
           else if(ADDR == ADDR_BR) begin
               Dout = BR;
           end 
           else begin
               Dout = 8'h00;
           end
       end 
       else begin
           Dout = 8'h00;
       end
   end
   
   // 中断信号（低电平有效）
   assign IRQ = (SR[7] == 1'b1 && SR[0] == 1'b1) ? 1'b0 : 1'b1;

endmodule