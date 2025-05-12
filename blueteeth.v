module blueteeth(
input wire sys_clk,
input wire rst_n,
input wire ble_rxd,
output reg [7:0] rdata,
output reg rx_sig
);

  //----Code starts here: integrated by Robei-----
  	// 波特率分频计数值定义，根据系统时钟频率计算得到不同波特率对应的计数值
  parameter               CNT_BAUD9600     = 1735,  // 9600波特率对应的分频计数值
                          CNT_BAUD19200    = 867,   // 19200波特率对应的分频计数值
                          CNT_BAUD38400    = 433,   // 38400波特率对应的分频计数值
                          CNT_BAUD57600    = 288,   // 57600波特率对应的分频计数值
                          CNT_BAUD115200   = 216;   // 115200波特率对应的分频计数值
  
  parameter   CNT_END_SEL = CNT_BAUD115200;         // 选择当前使用的波特率分频值（此处选择115200）
  
  reg baud_clk;               // 生成的波特率时钟信号（实际为波特率使能信号，频率 = 系统时钟/(2*(CNT_END_SEL+1))）
  reg [11:0] baud_cnt;        // 波特率分频计数器（根据CNT_END_SEL进行计数）
  
  // 波特率时钟生成模块（本质是分频器，生成指定波特率的使能信号）
  always@(posedge sys_clk or negedge rst_n) begin
      if(!rst_n) begin            // 复位时清零
          baud_clk <= 1'b0;
          baud_cnt <= 12'd0;
      end
      else if (baud_cnt == CNT_END_SEL) begin  // 达到设定计数值时
          baud_clk <= ~baud_clk;               // 翻转时钟信号（生成50%占空比的使能脉冲）
          baud_cnt <= 12'd0;                   // 计数器归零
      end
      else begin
          baud_cnt <= baud_cnt + 1'b1;         // 计数器递增
      end
  end
  
  // 状态机状态定义
  parameter   IDLE        = 2'd0,  // 空闲状态：初始化寄存器
              READY       = 2'd1,  // 准备状态：等待起始位（检测到BLE_RXD低电平）
              RX_DATA     = 2'd2,  // 数据接收状态：依次接收8位数据
              RX_FINISH   = 2'd3;  // 接收完成状态：处理停止位并输出数据
  
  reg [1:0]   state;      // 状态机当前状态
  reg [2:0]   rx_cnt;     // 数据位接收计数器（0-7共8位）
  reg [7:0]   rx_reg;     // 接收数据暂存寄存器
  
  // UART接收状态机（每个波特率时钟上升沿触发）
  always@(posedge baud_clk or negedge rst_n) begin
      if(!rst_n) begin            // 复位初始化
          rdata <= 8'd0;          // 接收完成数据输出寄存器
          rx_reg <= 8'd0;         // 接收数据暂存器清零
          rx_cnt <= 3'd0;         // 数据位计数器清零
          rx_sig <= 1'b0;         // 接收完成标志清零
          state <= IDLE;          // 状态机回到空闲状态
      end
      else begin
          case(state)
              IDLE: begin         // 初始化状态
                  rx_reg <= 8'd0;
                  rx_sig <= 1'b0;
                  rx_cnt <= 3'd0;
                  state <= READY;  // 无条件跳转到准备状态
              end
              
              READY: begin         // 等待起始位
                  rx_reg <= 8'd0;
                  rx_sig <= 1'b0;
                  rx_cnt <= 3'd0;
                  if(!ble_rxd)     // 检测到起始位（低电平）
                      state <= RX_DATA;
                  else
                      state <= READY;  // 保持等待
              end
              
              RX_DATA: begin      // 接收数据位
                  if(rx_cnt == 7) begin          // 已接收第7位（共8位）
                      rx_reg[rx_cnt] <= ble_rxd; // 存入最高位
                      rx_sig <= 1'b1;            // 接收完成标志置位
                      state <= RX_FINISH;        // 跳转到完成状态
                  end
                  else begin
                      rx_reg[rx_cnt] <= ble_rxd; // 按顺序存入当前数据位
                      rx_cnt <= rx_cnt + 1'b1;   // 接收计数器递增
                      state <= RX_DATA;           // 保持接收状态
                  end
              end
              
              RX_FINISH: begin     // 处理停止位
                  rdata <= rx_reg;     // 输出完整接收数据
                  rx_sig <= 1'b1;      // 保持接收完成标志
                  if(ble_rxd)          // 检测停止位（高电平）
                      state <= READY;  // 回到准备状态等待下一帧
                  else
                      state <= RX_FINISH; // 未检测到停止位，保持当前状态
              end
              
              default: begin       // 异常处理，回到空闲
                  rdata <= 8'd0;
                  rx_reg <= 8'd0;
                  rx_sig <= 1'b0;
                  rx_cnt <= 3'd0;
                  state <= IDLE;
              end
          endcase
      end
  end
  
  
endmodule    //blueteeth
