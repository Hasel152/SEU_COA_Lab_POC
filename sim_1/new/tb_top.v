`timescale 1ns / 1ps

module tb_top();

    // --- 1. 定义驱动信号 (reg) ---
    reg         clk;
    reg         rst_n;
    reg         switch;    // 0:查询, 1:中断
    reg         print;     // 脉冲信号
    reg  [7:0]  data;      // 待打印数据

    // --- 2. 定义观测信号 (wire) ---


    // --- 3. 实例化顶层模块 (DUT) ---
    top_module uut (
        .CLK(clk),
        .RST_N(rst_n),
        .switch(switch),
        .print(print),
        .data(data)

    );

    // --- 4. 产生时钟 (周期 2ns, 500MHz) ---
    initial begin
        clk = 0;
        forever #1 clk = ~clk;
    end

    // --- 5. 测试剧本：模拟真实操作流 ---
    initial begin
        // 初始化
        rst_n = 0; switch = 0; print = 0; data = 0;
        
        // --- 步骤 1: 系统复位 ---
        #10 rst_n = 1;
        #10;

        // --- 步骤 2: 测试查询模式 (Polling Mode) ---
        // 目标：打印数据 8'h11

        @(posedge clk);
        switch = 0;          // 设置为查询模式
        data = 8'h11;        // 准备数据 11
        #2 print = 1;        // 按下打印键

        @(posedge clk);
        #10 rst_n = 0;
        #20 
        @(posedge clk);
        rst_n = 1;
        // 等待第一个数据打印完（观察波形中 CPU 不停读 SR 的动作）
        #100;

        // --- 步骤 3: 动态切换模式 (Switch 0 -> 1) ---
        // 目标：验证 CPU 是否会自动去纠正 POC 内部的 SR0

        @(posedge clk);
        switch = 1;          // 此时拨动开关
        // 注意看波形：CPU 应该会检测到 switch 变化，闪一下 RW 去改 SR0
        #20;
        
        // --- 步骤 4: 测试中断模式 (Interrupt Mode) ---
        // 目标：打印数据 8'h33
;
        @(posedge clk);
        data = 8'h33;        // 准备新数据 33

        // 等待中断触发和传输过程
        #100;

        // --- 步骤 5: 再次切换回查询模式 (Switch 1 -> 0) ---
 
        @(posedge clk);
        switch = 0;
        #20;

        // 打印最后一个数据验证稳定性
        data = 8'hFF;


        #200;

        $finish;
    end

endmodule