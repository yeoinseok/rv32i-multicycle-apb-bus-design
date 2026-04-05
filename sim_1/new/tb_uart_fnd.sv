`timescale 1ns / 1ps

module tb_uart_fnd ();

    logic clk, rst;
    logic [7:0] GPI;
    wire  [7:0] GPO;
    wire  [15:0] GPIO;
    wire  [ 3:0] fnd_digit;
    wire  [ 7:0] fnd_data;

    logic uart_rx;
    wire  uart_tx;

    logic [7:0] sw_in;
    assign GPIO[7:0]  = sw_in;
    assign GPIO[15:8] = 8'bz;

    // -------------------------------------------------------
    // [보드레이트 설정 셀렉터] 테스트할 보드레이트 하나만 주석을 푸세요.
    // -------------------------------------------------------
    localparam BIT_PERIOD = 104167; // 9600   bps (현재 활성)
    //localparam BIT_PERIOD = 52083;  // 19200  bps
     //localparam BIT_PERIOD = 8681;   // 115200 bps

    // MCU Instance
    rv32I_mcu dut (
        .clk      (clk),
        .rst      (rst),
        .GPI      (GPI),
        .GPO      (GPO),
        .GPIO     (GPIO),
        .fnd_digit(fnd_digit),
        .fnd_data (fnd_data),
        .uart_rx  (uart_rx),
        .uart_tx  (uart_tx)
    );

    // -------------------------------------------------------
    // 실제 UART 신호 주입 Task (에코 대기 시간 포함)
    // -------------------------------------------------------
    task uart_send_byte(input [7:0] data);
        integer i;
        begin
            // 1. Start Bit (Low)
            uart_rx = 1'b0;
            #(BIT_PERIOD);

            // 2. Data Bits (8-bit, LSB First)
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = data[i];
                #(BIT_PERIOD);
            end

            // 3. Stop Bit (High)
            uart_rx = 1'b1;
            #(BIT_PERIOD);

            // [에코 확인을 위한 대기] 
            // CPU가 수신 후 다시 TX로 내보낼 때까지 충분한 시간을 줍니다.
            // 보통 10~15비트 정도 대기하면 에코 신호가 완전히 끝납니다.
            #(BIT_PERIOD * 15); 
        end
    endtask

    // 클럭 생성 (10ns 주기로 100MHz 가정)
    always #5 clk = ~clk;

    initial begin
        // 초기 상태 설정
        clk     = 0;
        rst     = 1;
        GPI     = 8'h00;
        sw_in   = 8'h00;
        uart_rx = 1'b1; // Idle 상태는 항상 High

        // 리셋 동작
        repeat(10) @(posedge clk);
        rst = 0;
        repeat(2000) @(posedge clk); // CPU 부팅 대기

        // =====================================================
        // [SCENARIO 1] UP: '0' ~ '9' -> 'a' ~ 'f'
        // =====================================================
        $display("=== [UP] SCENARIO START (BIT_PERIOD: %d) ===", BIT_PERIOD);
        
        for (int i = 0; i <= 9; i++) begin
            uart_send_byte(8'h30 + i); // '0'~'9' 전송
            $display("  [TX] Sent: '%c' | [FND] Data: %d", 8'h30+i, dut.U_APB_FND.FND_DATA_REG);
        end
        for (int i = 0; i <= 5; i++) begin
            uart_send_byte(8'h61 + i); // 'a'~'f' 전송
            $display("  [TX] Sent: '%c' | [FND] Data: %d", 8'h61+i, dut.U_APB_FND.FND_DATA_REG);
        end

        // 잠시 휴식
        #(BIT_PERIOD * 20);

        // =====================================================
        // [SCENARIO 2] DOWN: 기존과 동일한 순서로 다시 테스트
        // =====================================================
        $display("=== [DOWN] SCENARIO START ===");
        
        for (int i = 0; i <= 9; i++) begin
            uart_send_byte(8'h30 + i);
            $display("  [TX] Sent: '%c' | [FND] Data: %d", 8'h30+i, dut.U_APB_FND.FND_DATA_REG);
        end
        for (int i = 0; i <= 5; i++) begin
            uart_send_byte(8'h61 + i);
            $display("  [TX] Sent: '%c' | [FND] Data: %d", 8'h61+i, dut.U_APB_FND.FND_DATA_REG);
        end

        // 최종 대기 및 종료
        #(BIT_PERIOD * 50);
        $display("=== [SUCCESS] Final FND Value: %d ===", dut.U_APB_FND.FND_DATA_REG);
        $stop;
    end

endmodule