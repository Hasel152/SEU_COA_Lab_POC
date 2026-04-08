`timescale 1ns / 1ps

module tb_poc_printer();

    // --- 1. 定义信号线 ---
    // 发给 POC 的信号（由上帝/CPU驱动，用 reg）
    reg         clk;
    reg         rst_n;
    reg  [7:0]  din;
    reg         rw;
    reg  [2:0]  addr;
    
    // 从模块出来的信号（观察用，用 wire）
    wire [7:0]  dout;
    wire        irq;
    
    // POC 和 Printer 之间的内部连线（就像电缆，用 wire）
    wire        tr_line;
    wire        rdy_line;
    wire [7:0]  pd_line;

    // --- 2. 实例化 POC 模块 ---
    poc_module uut_poc (
        .CLK(clk),
        .RST_N(rst_n),
        .Din(din),
        .Dout(dout),
        .RW(rw),
        .ADDR(addr),
        .IRQ(irq),
        .RDY(rdy_line), // 接到中间线上
        .TR(tr_line),   // 接到中间线上
        .PD(pd_line)    // 接到中间线上
    );

    // --- 3. 实例化 Printer 模块 ---
    printer_module uut_printer (
        .CLK(clk),
        .RST_N(rst_n),
        .TR(tr_line),   // 接收 POC 的信号
        .RDY(rdy_line),  // 反馈给 POC 的信号
        .PD(pd_line)    // 接收数据
    );

    // --- 4. 产生时钟信号 (周期 2ns) ---
    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    // --- 5. 模拟 CPU 的测试剧本 (Stimulus) ---
    initial begin
        // 初始化信号
        rst_n = 0; rw = 0; addr = 0; din = 0;
        
        // 1. 复位系统
        #10 rst_n = 1;
        #10;

        // 2. 模拟 CPU 写入待打印数据到 BR (地址 3'b001)
        @(posedge clk);
        rw = 1; addr = 3'b001; din = 8'hA5; // 准备发送数据 0xA5
        @(posedge clk);
        rw = 0; // 停止写入

        // 3. 模拟 CPU 修改 SR 开启中断模式并启动打印 (地址 3'b000)
        // 我们写 SR，令 SR7=0(忙碌/启动), SR0=1(开中断) -> 8'h01
        @(posedge clk);
        rw = 1; addr = 3'b000; din = 8'h01; 
        @(posedge clk);
        rw = 0;

        // 4. 此时，上帝只需围观波形！
        // 你应该观察到：
        // (1) stat 变 1，TR 变高
        // (2) RDY 随之变低 (打印机开始数数)
        // (3) RDY 10个周期后变高
        // (4) SR7 自动变回 1，IRQ 随之拉低
        
        #200; // 等待整个过程跑完

        // 5. 再次发送一个数据验证连贯性
        @(posedge clk);
        rw = 1; addr = 3'b001; din = 8'h5A; // 写入新数据 0x5A
        // 注意：由于你的逻辑是写 BR 自动清除 SR7，所以这一步可能就直接触发第二次打印了
        @(posedge clk);
        rw = 0;

        #300;
        $finish;
    end

endmodule