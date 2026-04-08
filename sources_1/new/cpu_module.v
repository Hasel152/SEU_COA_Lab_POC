module cpu_module(
    input  wire        CLK,
    input  wire        RST_N,
    input  wire        switch,     //0：Polling，1：Interrupt
    input  wire        print,     // 启动打印
    input  wire [7:0]  data,      // 待打印数据
    input  wire        IRQ,       // POC中断请求
    input  wire [7:0]  Dout,      // 来自总线的数据
    output reg         RW,        // 读写信号
    output reg  [7:0]  Din,       // 输出到总线的数据
    output reg  [2:0]  ADDR       // 3位地址
);

    // 1. 定义状态 (localparam)
    localparam ST_IDLE   = 3'd0,
               ST_INIT   = 3'd1,
               ST_POLL   = 3'd2,
               ST_CHECK  = 3'd3,
               ST_WRITE  = 3'd4;

    reg [2:0] state;

 localparam ADDR_SR = 3'b000;
 localparam ADDR_BR = 3'b001;
 
    // 2. 编写逻辑块 (always posedge)
    always @(posedge CLK or negedge RST_N) begin
        if(!RST_N) begin
            state <= ST_IDLE;
            RW <= 0; Din <= 0; ADDR <= 0;
        end
        else begin
            case(state)
                // --- 1. 空闲态：根据模式决定去向 ---
                ST_IDLE: begin
                    RW <= 0;
                    if(switch == 1'b1) begin
                        // 中断模式下，先去初始化 SR0 = 1
                        state <= ST_INIT; 
                    end
                    else if(print == 1'b1) begin
                        // 轮询模式下，按了打印就开始轮询
                        state <= ST_POLL;
                    end
                end

                // --- 2. 初始化态：把中断开关打开 ---
                ST_INIT: begin
                    ADDR <= ADDR_SR;
                    Din  <= 8'h01; // 令 SR[0] = 1, SR[7] 保持默认
                    RW   <= 1'b1;
                    // 初始化完，等待 IRQ 信号
                    if(IRQ == 1'b0) begin
                        state <= ST_WRITE; // 发现中断，直接去写数据
                    end
                    else begin
                        state <= ST_INIT; // 没中断就在这里"睡着"等
                    end
                end

                // --- 3. 轮询态：发起读请求 ---
                ST_POLL: begin
                    ADDR <= ADDR_SR;
                    RW   <= 1'b0; // 读
                    state <= ST_CHECK;
                end

                // --- 4. 判断态：检查结果 ---
                ST_CHECK: begin
                    if(Dout[0] == 1'b1&&Dout[7]==1'b1&&switch == 0)begin
                        ADDR <= ADDR_SR;
                        Din <= 8'h80;
                        RW <= 1'b1;
                        state <= ST_IDLE;
                    end
                    
                    else if(Dout[7] == 1'b1) begin
                        state <= ST_WRITE; // 好了，去写数据
                    end
                    else begin
                        state <= ST_POLL;  // 没好，跳回去继续轮询
                    end
                end

                // --- 5. 写入态：发货 ---
                ST_WRITE: begin
                    ADDR <= ADDR_BR;
                    Din  <= data;
                    RW   <= 1'b1;
                    state <= ST_IDLE; // 发完收工，回 IDLE
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

endmodule