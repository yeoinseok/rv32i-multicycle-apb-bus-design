# RV32I Multicycle CPU with APB Bus

> RISC-V RV32I 멀티사이클 CPU 설계 및 AMBA APB 버스 기반 페리페럴 통합

## 📌 프로젝트 개요

싱글 사이클 RV32I CPU를 5단계 FSM 기반 멀티사이클 구조로 재설계하고, AMBA APB 버스 프로토콜을 적용하여 RAM, GPIO, FND, UART 등 주변장치를 통합한 SoC 프로젝트입니다. MMIO(Memory-Mapped I/O) 방식으로 C 코드에서 하드웨어 레지스터를 직접 제어하며, Basys3 FPGA 보드에서 실제 동작을 검증했습니다.

**개발 기간:** 2026.03.18 ~ 2026.03.24 (1주)  
**팀 구성:** 4인 팀 프로젝트  
**담당 업무:** FND/UART Peripheral 모듈 설계 및 Manager 모듈과의 데이터 송수신 인터페이스 통합

## 🎯 주요 기능

### 멀티사이클 CPU 아키텍처
- **5단계 FSM 구조**: Fetch → Decode → Execute → Memory → WriteBack
- **자원 공유**: 단일 ALU와 메모리를 시분할하여 회로 면적 절감
- **상태별 제어 신호**: 각 단계마다 독립적인 제어 신호 생성

### AMBA APB 버스 통합
- **APB Bridge 설계**: CPU와 페리페럴 간 프로토콜 변환
- **2-Cycle 전송**: PSEL, PENABLE 신호 기반 타이밍 제어
- **주소 디코딩**: RAM, GPIO, FND, UART 각각 고유 메모리 주소 매핑

### MMIO 메모리 맵 I/O
- **하드웨어 레지스터 직접 제어**: C 코드에서 포인터로 레지스터 접근
- **페리페럴 제어**: FND 카운터, UART 송수신 C 함수 구현
- **소프트웨어-하드웨어 통합**: 베어메탈 프로그램 실행

## 🛠 기술 스택

- **HDL**: Verilog, SystemVerilog
- **FPGA 툴**: Xilinx Vivado
- **하드웨어**: Basys3 Artix-7 FPGA
- **ISA**: RISC-V RV32I Base Integer Instruction Set
- **버스 프로토콜**: AMBA APB (Advanced Peripheral Bus)

## 📁 프로젝트 구조

<img width="719" height="406" alt="image" src="https://github.com/user-attachments/assets/a1646143-984e-4ac0-b5cc-6c55f1efe7c6" />


```
RV32I-Multicycle-APB-BUS-Design/
├── rtl/
│   ├── cpu/
│   │   ├── datapath.v
│   │   ├── controller.v
│   │   ├── alu.v
│   │   └── regfile.v
│   ├── memory/
│   │   ├── instruction_mem.v
│   │   └── data_mem.v
│   ├── bus/
│   │   ├── apb_bridge.v
│   │   └── apb_decoder.v
│   └── peripherals/
│       ├── gpio.v
│       ├── fnd_controller.v
│       └── uart.v
├── firmware/
│   ├── fnd_counter.c
│   └── uart_test.c
├── sim/
│   └── testbench.v
└── docs/
    └── memory_map.md
```

## 🏗 시스템 아키텍처

### CPU 멀티사이클 FSM

```
      ┌─────────┐
      │  FETCH  │ ← PC로 명령어 읽기
      └────┬────┘
           │
      ┌────▼────┐
      │ DECODE  │ ← 명령어 해석 & 레지스터 읽기
      └────┬────┘
           │
      ┌────▼────┐
      │ EXECUTE │ ← ALU 연산 / 분기 판정
      └────┬────┘
           │
      ┌────▼────┐
      │ MEMORY  │ ← Load/Store 메모리 접근
      └────┬────┘
           │
      ┌────▼────┐
      │ WRITEBACK│ ← 레지스터 파일 쓰기
      └─────────┘
```

**상태별 클럭 사이클:**
- R-Type: 5 cycles (Fetch, Decode, Execute, -, WriteBack)
- Load: 5 cycles (Fetch, Decode, Execute, Memory, WriteBack)
- Store: 4 cycles (Fetch, Decode, Execute, Memory)
- Branch: 3 cycles (Fetch, Decode, Execute)

### APB 버스 구조

```
┌─────────────┐
│ Multicycle  │
│     CPU     │
└──────┬──────┘
       │
┌──────▼──────┐
│ APB Bridge  │ ← CPU ↔ APB 프로토콜 변환
└──────┬──────┘
       │
┌──────▼──────┐
│ APB Decoder │ ← 주소 기반 페리페럴 선택
└──┬───┬───┬──┘
   │   │   │
   ▼   ▼   ▼
  RAM GPIO FND UART
```

**APB 타이밍:**
<img width="629" height="353" alt="image" src="https://github.com/user-attachments/assets/14e4706e-2c9d-4629-9b97-2b806271fc6a" />


## 🗺 메모리 맵

| 주소 범위 | 크기 | 디바이스 | 설명 |
|-----------|------|----------|------|
| 0x0000_0000 - 0x0000_0FFF | 4KB | Instruction Memory | 프로그램 코드 |
| 0x0000_1000 - 0x0000_1FFF | 4KB | Data Memory | 데이터 RAM |
| 0x8000_0000 - 0x8000_000F | 16B | GPIO | 입출력 포트 |
| 0x8000_0010 - 0x8000_001F | 16B | FND Controller | 7-Segment Display |
| 0x8000_0020 - 0x8000_002F | 16B | UART | 시리얼 통신 |

### 페리페럴 레지스터

#### GPIO (0x8000_0000)
| 오프셋 | 레지스터 | 설명 |
|--------|----------|------|
| 0x00 | DATA_IN | 입력 포트 (스위치) |
| 0x04 | DATA_OUT | 출력 포트 (LED) |
| 0x08 | DIR | 방향 설정 (0: IN, 1: OUT) |

#### FND Controller (0x8000_0010)
| 오프셋 | 레지스터 | 설명 |
|--------|----------|------|
| 0x00 | VALUE | 표시할 값 (0~9999) |
| 0x04 | CTRL | Enable/Disable |

#### UART (0x8000_0020)
| 오프셋 | 레지스터 | 설명 |
|--------|----------|------|
| 0x00 | TX_DATA | 송신 데이터 |
| 0x04 | RX_DATA | 수신 데이터 |
| 0x08 | STATUS | [0] BUSY, [1] RX_VALID |

## 🚀 빌드 및 실행

### 1. Vivado 프로젝트 생성

```tcl
# Vivado GUI에서
File → New Project
Add Sources → rtl/ 폴더 전체 추가
Add Constraints → basys3.xdc
Run Synthesis
Run Implementation
Generate Bitstream
```

### 2. 펌웨어 컴파일

```bash
# RISC-V GCC 툴체인 사용
riscv32-unknown-elf-gcc -march=rv32i -mabi=ilp32 \
    -nostdlib -T linker.ld -o firmware.elf firmware/fnd_counter.c

# ELF → HEX 변환
riscv32-unknown-elf-objcopy -O verilog firmware.elf firmware.hex

# instruction_mem.v에 로드
```

### 3. FPGA 다운로드

```
Vivado: Flow → Program and Debug → Program Device
```

## 📊 검증 결과

### FND 카운터 동작

```c
// firmware/fnd_counter.c
#define FND_BASE 0x80000010

volatile unsigned int* fnd_value = (volatile unsigned int*)(FND_BASE + 0x00);
volatile unsigned int* fnd_ctrl  = (volatile unsigned int*)(FND_BASE + 0x04);

void main() {
    *fnd_ctrl = 1;  // FND 활성화
    
    for (int i = 0; i < 10000; i++) {
        *fnd_value = i;
        delay(1000);
    }
}
```

**결과:**
- ✅ Basys3 7-Segment에 0~9999 카운터 표시
- ✅ 멀티사이클 FSM 정상 동작 확인
- ✅ APB 버스 타이밍 검증 완료

### UART 통신 테스트

```c
// firmware/uart_test.c
#define UART_BASE 0x80000020

void uart_send(char c) {
    volatile unsigned int* tx = (volatile unsigned int*)(UART_BASE + 0x00);
    volatile unsigned int* status = (volatile unsigned int*)(UART_BASE + 0x08);
    
    while (*status & 0x01);  // Wait BUSY
    *tx = c;
}

void main() {
    uart_send('H');
    uart_send('e');
    uart_send('l');
    uart_send('l');
    uart_send('o');
}
```

**결과:**
- ✅ 터미널에 "Hello" 출력 확인
- ✅ MMIO 방식 정상 동작
- ✅ C 코드 → 하드웨어 제어 검증 완료

## 🔧 Troubleshooting

### 1. FND 나눗셈 연산 타이밍 문제

**문제:**  
FND에 0~9999 숫자를 표시하기 위해 Verilog 나눗셈(`/`)과 나머지(`%`) 연산자로 자릿수를 분리했는데, 조합 논리 경로가 너무 길어져 타이밍 슬랙이 네거티브(WNS: -0.162ns)로 나타났습니다.

**1차 시도 - Double Dabble 알고리즘:**
```verilog
// Before (나눗셈 연산자)
digit_0 = value % 10;
digit_1 = (value / 10) % 10;
digit_2 = (value / 100) % 10;
digit_3 = (value / 1000) % 10;

// After (Double Dabble - Shift and Add-3)
for (i = 0; i < 14; i++) begin
    if (bcd[3:0] >= 5)   bcd[3:0]   = bcd[3:0] + 3;
    if (bcd[7:4] >= 5)   bcd[7:4]   = bcd[7:4] + 3;
    if (bcd[11:8] >= 5)  bcd[11:8]  = bcd[11:8] + 3;
    if (bcd[15:12] >= 5) bcd[15:12] = bcd[15:12] + 3;
    bcd = {bcd[14:0], value[13-i]};
end
```

**결과:** WNS가 -0.065ns로 개선되었지만 여전히 네거티브, Failing Endpoint 3개 남음

**2차 해결 - 크리티컬 패스 파이프라이닝:**

**문제 분석:**  
Instruction Memory 출력 → Decoder → Register File 경로가 한 클럭 안에 완료되어야 하는데 경로가 너무 길었습니다.

**해결:**
```verilog
// Instruction Memory 출력에 레지스터 추가
always @(posedge clk) begin
    if (ir_en)
        instruction_reg <= instruction_mem[pc];
end

// Decode 단계부터 레지스터 값 사용
assign opcode = instruction_reg[6:0];
assign rd     = instruction_reg[11:7];
assign rs1    = instruction_reg[19:15];
```

**최종 결과:**
- ✅ WNS: +0.357ns (양수 달성)
- ✅ Failing Endpoints: 0개
- ✅ 타이밍 제약 만족

### 2. APB Bridge PENABLE 타이밍 이슈

**문제:**  
PENABLE 신호를 PSEL과 동시에 올려서 데이터 전송이 누락되는 문제 발생

**해결:**
```verilog
// 2-cycle APB 프로토콜 구현
always @(posedge clk) begin
    case (state)
        IDLE: begin
            PSEL <= 1'b0;
            PENABLE <= 1'b0;
        end
        SETUP: begin  // Cycle 1
            PSEL <= 1'b1;
            PENABLE <= 1'b0;
        end
        ACCESS: begin  // Cycle 2
            PSEL <= 1'b1;
            PENABLE <= 1'b1;
        end
    endcase
end
```

## 📚 배운 점

### 1. 멀티사이클 아키텍처의 트레이드오프
싱글 사이클에서는 ALU와 메모리를 명령어마다 따로 두어야 했지만, 멀티사이클로 전환하면서 FSM으로 하나의 자원을 단계별로 공유하는 구조를 직접 설계했습니다. 회로 면적은 줄었지만 명령어당 클럭 수가 증가하는 것을 확인하며, **빠른 구조가 항상 좋은 게 아니라 목적에 맞는 아키텍처를 선택하는 게 중요하다**는 것을 배웠습니다.

### 2. 버스 프로토콜의 중요성
APB Bridge를 직접 구현하면서 PSEL/PENABLE 타이밍을 잘못 잡으면 데이터가 손실되는 것을 경험했습니다. 이 과정에서 **버스 프로토콜이 왜 엄격한 규격을 두는지** 체감했고, 타이밍 다이어그램을 꼼꼼히 따라야 한다는 교훈을 얻었습니다.

### 3. MMIO와 소프트웨어-하드웨어 인터페이스
하드웨어 주소를 할당해서 C 코드로 직접 제어하는 MMIO 구조를 구현하면서, **소프트웨어가 하드웨어에 접근하는 실제 원리**를 이해하게 되었습니다. 코드를 짜는 것과 그 코드가 내가 만든 하드웨어 위에서 실제로 구동되는 걸 확인하는 건 완전히 다른 경험이었습니다.

### 4. 타이밍 분석과 최적화
나눗셈 연산자가 긴 조합 논리를 만들어 타이밍 위반을 일으킨 경험을 통해, **알고리즘 선택이 하드웨어 성능에 직접적인 영향을 미친다**는 것을 배웠습니다. Double Dabble로 개선한 뒤에도 크리티컬 패스 파이프라이닝이 필요했던 경험은 하드웨어 설계의 복잡성을 깨닫게 했습니다.

## 🎓 향후 개선 방향

- [ ] **파이프라인 CPU**: 멀티사이클 → 5단 파이프라인으로 전환하여 IPC 향상
- [ ] **캐시 메모리**: Instruction/Data 캐시 추가로 메모리 접근 지연 감소
- [ ] **인터럽트 컨트롤러**: 외부 이벤트 처리 메커니즘 추가
- [ ] **AHB 버스**: APB → AHB로 업그레이드하여 버스트 전송 지원
- [ ] **OS 포팅**: FreeRTOS 포팅하여 멀티태스킹 구현

## 🔗 관련 레포지토리

- **싱글사이클 CPU**: [RV32I Single-Cycle](#) (이전 버전)
- **UVM 검증 환경**: [RV32I UVM Testbench](#) (검증 자동화)

## 📄 참고 자료

- [RISC-V ISA Specification](https://riscv.org/technical/specifications/)
- [AMBA APB Protocol Specification](https://developer.arm.com/documentation/ihi0024/latest/)
- [Basys3 Reference Manual](https://digilent.com/reference/programmable-logic/basys-3/reference-manual)
- [Double Dabble Algorithm](https://en.wikipedia.org/wiki/Double_dabble)

## 📄 라이선스

이 프로젝트는 개인 학습 목적으로 작성되었습니다.

---

**Contact**: [GitHub](https://github.com/yeoinseok)
