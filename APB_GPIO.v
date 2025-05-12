module APB_GPIO #(

  //ADDR Parameters
  parameter    ADDR_GPIO   = 32'h0000_0000,       // 定义GPIO模块的基地址
  parameter    OFFSET_GPIO_DATA_RO = 4'h0,          // 定义只读数据寄存器的偏移地址
  parameter    OFFSET_GPIO_DATA    = 4'h4,          // 定义数据寄存器的偏移地址
  parameter    OFFSET_GPIO_DIRM    = 4'h8,          // 定义方向模式寄存器的偏移地址
  parameter    OFFSET_GPIO_OEN     = 4'hC           // 定义输出使能寄存器的偏移地址

) (
    // APB Signal
    input         iPCLK   ,      //时钟，APB总线信号
    input         iPRESETn,      //异步复位，APB总线信号
    input         iPSEL   ,      //选择信号，（当前模块被选中时拉高）APB总线信号
    input         iPWRITE ,      //写使能，APB总线信号
    input         iPENABLE,      //传输使能，APB总线信号
    input  [31:0] iPADDR  ,      //地址，APB总线信号
    input  [31:0] iPWDATA ,      //写数据，APB总线信号
    output [31:0] oPRDATA ,      //读数据，APB总线信号

    // I/O Signal//
    input  [31:0] iGPIOin,        //连接开发板按键，外设信号
    output [31:0] oGPIOout        //连接开发板LED，外设信号

);

    /*————————————————————————————————————————————————————————————————————————*\
    /                            APB Signal Register                           \
    \*————————————————————————————————————————————————————————————————————————*/
    reg         iPSELx_r  ;//APB从设备选择信号寄存
    reg         iPWRITE_r ;//写使能寄存
    reg  [31:0] iPADDR_r  ;// 地址寄存
    reg  [31:0] iPWDATA_r ;// 写数据寄存

    always@( posedge iPCLK)  begin   //时钟上升沿时触发，寄存控制信号
        if(!iPRESETn) begin          //如果主机复位信号不为有效，触发
            iPWRITE_r  <= 1'b0;       //写使能寄存器复位为0
            iPADDR_r   <= 16'b0;     //地址寄存器复位为0
        end
        else begin                     //复位信号无效
            iPWRITE_r  <= iPWRITE;    //寄存写使能信号
            iPWDATA_r  <= iPWDATA;    //寄存写数据总线
            iPADDR_r   <= iPADDR;     //寄存地址总线
        end
    end

    /*————————————————————————————————————————————————————————————————————————*\
    /                           GPIO Register Declaration                      \
    \*————————————————————————————————————————————————————————————————————————*/
    // Read Only Data
    reg [31:0] reg_DATA_RO;     //用来观测GPIO引脚状态，若引脚被配置成输出模式，则该寄存器会反映驱动该引脚的电平的状态。DATA_RO是一个只读寄存器，对该寄存器的写操作是无效的
    // GPIO Data 
    reg [31:0] reg_DATA;         //当GPIO某一引脚被配置为输出模式时，用来控制该引脚的输出状态
    // Direction (in or out)    
    reg [31:0] reg_DIRM;     //用来配置GPIO各个引脚的方向（做输入or做输出），当DIRMP[x]==0，第x位引脚为输入引脚，其输出功能被disable
    // Output Enable 
    reg [31:0] reg_OEN;   //输出使能寄存器

    /*————————————————————————————————————————————————————————————————————————*\
    /                              Register Configuration                      \
    \*————————————————————————————————————————————————————————————————————————*/
    integer i;                           //循环变量
    reg [31:0] oGPIOout_r ;              //GPIO输出值寄存器
    //reg [31:0] GPIOin_r;

    always @(posedge iPCLK ) begin       //时钟上升沿触发
        if( !iPRESETn ) begin             //如果复位信号有效//复位阶段，初始化所有寄存器
            reg_DATA_RO   <= 32'b0;        // 只读寄存器清零
            reg_DATA      <= 32'b0;          // 输出数据寄存器清零
            reg_DIRM      <= 32'b0;         // 方向寄存器清零（默认输入模式）
            reg_OEN       <= 32'b0;          // 输出使能寄存器清0
        end
        else begin         //复位信号无效
     
            // reg_DATA, reg_DIRM, reg_OEN
            if( iPENABLE && iPWRITE) begin            //如果使能信号和写信号都有效
                case ( iPADDR[3:0] )                  // 根据地址偏移选择目标寄存器
                    OFFSET_GPIO_DATA_RO: begin end    //DATA_RO is read only register             
                    OFFSET_GPIO_DATA:    begin        
                        reg_DATA       <= iPWDATA;     // 将写数据写入数据寄存器
                    end
                    OFFSET_GPIO_DIRM:    begin
                        reg_DIRM <= iPWDATA;            // 将写数据写入方向模式寄存器
                    end
                    OFFSET_GPIO_OEN:     begin
                        reg_OEN <= iPWDATA;             // 将写数据写入输出使能寄存器
                    end
                    default:             begin
                        reg_DATA    <= reg_DATA   ;     //保持数据寄存器不变
                        reg_DIRM    <= reg_DIRM   ;     // 保持方向模式寄存器不变
                        reg_OEN     <= reg_OEN    ;      // 保持输出使能寄存器不变
                    end
                endcase 
            end

            // DATA_RO
            for ( i=0 ; i<32 ; i=i+1 ) begin                 // 遍历32个GPIO引脚
                if ( reg_DIRM[i] ) begin
                    reg_DATA_RO[i] <= oGPIOout_r[i] ;// output mode  如果引脚为输出模式，将输出数据寄存到只读数据寄存器
                end else begin
                    reg_DATA_RO[i] <= iGPIOin[i] ;// input mode     如果引脚为输入模式，将输入数据寄存到只读数据寄存器
                end  
            end     
       end
    end

    /*————————————————————————————————————————————————————————————————————————*\
    /                                     I/O                                  \
    \*————————————————————————————————————————————————————————————————————————*/
    // iGPIOin -> GPIOin_r -> DATA_RO -> PRADATA
    assign oPRDATA = reg_DATA_RO;                     // 将只读数据寄存器的值作为读数据输出

    // reg_DATA -> GPIOout 
    
    assign oGPIOout = oGPIOout_r ;                 //将寄存的输出数据作为最终的GPIO输出
    always @(*) begin                             //当任何输入信号变化时触发
        for ( i=0 ; i<32 ; i=i+1 ) begin            // 遍历32个GPIO引脚
            if( reg_DIRM[i] & reg_OEN[i] ) begin //output mode  如果引脚为输出模式且输出使能有效
                oGPIOout_r[i] = reg_DATA[i] ;      // 将数据寄存器的值输出到该引脚
            end else begin
                oGPIOout_r[i] = 1'bz;             // 否则，将该引脚设置为高阻态
            end
        end
    end

endmodule
