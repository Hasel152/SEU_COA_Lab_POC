`timescale 1ns/1ps

module printer_module(
    input             CLK,          // 时钟
    input wire [7:0]  PD,           // 从POC来的数据
    input wire        TR,           // POC的打印请求
    input wire        RST_N,        // 复位信号（低电平有效）
    output reg        RDY = 1'b1 ,// 就绪信号：1=准备好，0=忙
    output reg [5:0] print_counter 
);
   //reg [5:0] print_counter ;
    // 打印处理计数器

    localparam PRINT_TIME = 6'd10;  // 打印耗时10个时钟周期
    
    always @(posedge CLK or negedge RST_N) begin
        if(!RST_N) begin
            RDY <= 1'b1;
            print_counter <= 6'd0;
        end
        else begin
            if(TR == 1'b1 && RDY == 1'b1) begin
                // 检测到有效的打印请求
                RDY <= 1'b0;              // 设置为忙
                print_counter <= 6'd0;   // 重置计数器
            end
            else if(RDY == 1'b0) begin
                // 打印过程中
                print_counter <= print_counter + 1'b1;
                if(print_counter == PRINT_TIME - 1) begin
                    RDY <= 1'b1;          // 打印完成，恢复就绪
                end
            end
        end
    end

endmodule