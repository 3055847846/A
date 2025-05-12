///////////////////////////////////////////////////////////////////////
//! Company             : Inspiration
//!  
//! Engineer            : Green Plum
//!  
//! Creat Data          : 
//!  
//! Design Name         : 
//!  
//! Project Name        : 
//!  
//! Module Name         : 
//!  
//! Target Devices      : 
//!  
//! Tool Versions       : 
//!  
//! Description         : 
//!  
//!  CN:
//!  
//! ----
//!  
//! EN:
//!  
//! ----
//!  
//! Dependencies        : 
//!  
//! ----
//!  
//! Revision            : v0.0
//!  
//! Additional Comments : 
//!  
//! ----
//!  
//! In the event of publication, the following notice is applicable: Copyright(C) 2023-20xx "Inspiration" Corporation.
///////////////////////////////////////////////////////////////////////
    
module SoC_top(
    //===========================BEGIN===========================//
    // 
    input            HCLK    ,
    input            HRESETn ,
    input  [ 3 : 0 ] FPGA_Key,
    output [ 3 : 0 ] FPGA_LED
    //============================END============================//
);

    wire  [  1 : 0 ] HTRANS;
    wire  [  3 : 0 ] HSIZE ;
    wire  [  2 : 0 ] HBURST;
    wire             HWRITE;
    wire  [ 31 : 0 ] HWDATA;
    wire  [ 31 : 0 ] HADDR ;

    wire             HREADY;
    wire  [  1 : 0 ] HRESP ;
    wire  [ 31 : 0 ] HRDATA;

    wire  [ 31 : 0 ] PRDATA;

    wire             PSEL0  ;
    wire             PSEL1  ;
    wire             PWRITE ;
    wire             PENABLE;
    wire  [ 31 : 0 ] PADDR  ;
    wire  [ 31 : 0 ] PWDATA ;
    
    wire   [ 31 : 0 ] GPIO0in ;
    wire   [ 31 : 0 ] GPIO0out;

    assign GPIO0in  = {28'b0,FPGA_Key};
    assign FPGA_LED = GPIO0out[7:4];

    //===========================BEGIN===========================//
    // 
    AHB_control_unit u_AHB_control_unit(
        .iHCLK    (HCLK    ),
        .iHRESETn (HRESETn ),

        .oHWRITE  (HWRITE  ),

        .oHADDR   (HADDR   ),
        
        .oHTRANS  (HTRANS  ),
        .oHSIZE   (HSIZE   ),
        .oHBURST  (HBURST  ),
    
        .oHWDATA  (HWDATA  ),
        .iHRDATA  (HRDATA  ),

        .iHRESP   (HRESP   ),
        .iHREADY  (HREADY  )
    );
    
    AHB2APB_bridge u_AHB2APB_bridge(
        .iHCLK    (HCLK    ),
        .iHRESETn (HRESETn ),

        .iHWRITE  (HWRITE  ),

        .iHADDR   (HADDR   ),
        .iHSEL    (1'b1    ),

        .iHTRANS  (HTRANS  ),
        .iHSIZE   (HSIZE   ),
        .iHBURST  (HBURST  ),
        
        .iHWDATA  (HWDATA  ),
        .oHRDATA  (HRDATA  ),

        .oHRESP   (HRESP   ),
        .oHREADY  (HREADY  ),
        
        .iPRDATA  (PRDATA  ),
        .oPSEL0   (PSEL0   ),
        .oPSEL1   (PSEL1   ),
        .oPWRITE  (PWRITE  ),
        .oPENABLE (PENABLE ),
        .oPADDR   (PADDR   ),
        .oPWDATA  (PWDATA  )
    );

    APB_GPIO u_APB_GPIO0(
        .iPCLK    (HCLK     ),
        .iPRESETn (HRESETn  ),

        .iPSEL    (PSEL0    ),
        .iPWRITE  (PWRITE   ),
        .iPENABLE (PENABLE  ),
        .iPADDR   (PADDR    ),
        .iPWDATA  (PWDATA   ),
        .oPRDATA  (PRDATA   ),
        .iGPIOin  (GPIO0in  ),
        .oGPIOout (GPIO0out )
    );

    //
    //============================END============================//
    
endmodule