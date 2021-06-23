module top 
#(
        parameter integer USB_SEND_WIDTH      = 512,
        parameter integer USB_REVE_WIDTH      = 512,
        parameter integer USB_PORT_WIDTH      = 8
)(        
    //USB硬件接口
    input  wire                         usb_reset,          //(ALL RST):USB复位
    input  wire                         usb_clock,          //(CLKOUT):USB时钟端口（USB模块提供：60MHZ）
    inout  wire [USB_PORT_WIDTH -1 :0]  usb_ports,          //(D0-D7):USB数据端口
    //output reg [USB_PORT_WIDTH -1 :0]   usb_ports,          //(D0-D7):USB数据端口
    output reg                          usb_read_n,         //(RD#):USB读取使能端口
    output reg                          usb_write_n,        //(WR#):USB写入使能端口
    input  wire                         usb_rx_empty,       //(RXF#):USB接收空端口
    input  wire                         usb_tx_full,        //(TXE#):USB发送满端口
    output reg                          usb_sendimm_n,      //(SIWV#):USB立即发送端口
    output reg                          usb_outen_n        //(OE#):USB输出使能端口
    //USB模块接口
//    input  wire [USB_SEND_WIDTH -1 :0]  usb_send,          //USB数据发送口
//    input  wire                         usb_en,            //USB使能端口
//    output reg                          usb_vaild,         //USB数据有效
//    output reg  [USB_REVE_WIDTH -1 :0]  usb_reve           //USB数据接收口
);
//参数定义
localparam  USB_STATE_SEND    =   1'b1;                 //USB发送状态
localparam  USB_STATE_REVE    =   1'b0;                 //USB接收状态
localparam  USB_SEND_MAX      =   USB_SEND_WIDTH/8;    //发送数据最大计数
localparam  USB_REVE_MAX      =   USB_REVE_WIDTH/8 +3; //接收数据最大计数

//数据定义
reg [  7:0] usb_cache;                           //USB发送寄存器
reg         usb_state;                          //USB状态寄存器
reg [ 15:0] usb_reve_count;                     //接收计数
reg [ 15:0] usb_send_count;                     //发送计数

//USB模块接口
reg  [USB_SEND_WIDTH -1 :0]  usb_send;          //USB数据发送口
reg                          usb_en;            //USB使能端口
reg                          usb_vaild;         //USB数据有效
reg  [USB_REVE_WIDTH -1 :0]  usb_reve;          //USB数据接收口


//USB硬件端口（发送状态=发送缓存；接收状态=高阻态）
assign usb_ports = (usb_state == USB_STATE_SEND) ? usb_cache : 8'hZZ;


//USB状态切换
//always @(posedge usb_clock, negedge usb_reset) 
//begin
//    if(!usb_reset)
//       usb_state <=  USB_STATE_SEND;
////    else if(usb_en == 1'b1)
////       usb_state <=  USB_STATE_SEND; 
////    else if(usb_send_count == USB_SEND_MAX)
////       usb_state <=  USB_STATE_REVE;
//end

//USB状态切换
always @(posedge usb_clock, negedge usb_reset) 
begin
    if(!usb_reset)
       usb_state <=  USB_STATE_REVE;
    else if(usb_vaild == 1'b1)
    begin
       usb_state <=  USB_STATE_SEND; 
       usb_send <= usb_reve;
    end
    else if(usb_send_count == USB_SEND_MAX)
       usb_state <=  USB_STATE_REVE;
end


//USB发送计数
always @(posedge usb_clock, negedge usb_reset) 
begin
    if(!usb_reset)
       usb_send_count <= 16'b0; 
    else if(usb_state ==  USB_STATE_SEND && !usb_tx_full && usb_send_count < USB_SEND_MAX)
       usb_send_count <= usb_send_count + 16'd1;
    else if(usb_send_count == USB_SEND_MAX)
       usb_send_count <= 16'b0;
end
//发送写入启动
always @(posedge usb_clock, negedge usb_reset) 
begin
    if(!usb_reset)
    begin
        usb_write_n <= 1'b1;
        usb_cache[7:0] <= 8'b0;
    end
    else if(usb_state ==  USB_STATE_SEND && !usb_tx_full && usb_send_count > 16'd0)
    begin
        usb_write_n <= 1'b0;
        usb_cache[7:0] <= usb_send[((usb_send_count-1)*8+7) -: 8]; 
    end
    else  
    begin
        usb_write_n <= 1'b1;
        usb_cache[7:0] <= 8'b0; 
    end  
end



//USB接收计数
always @(posedge usb_clock, negedge usb_reset) 
begin
    if(!usb_reset)
       usb_reve_count <= 16'b0; 
    else if(usb_state ==  USB_STATE_REVE && !usb_rx_empty && usb_reve_count < USB_REVE_MAX)
       usb_reve_count <= usb_reve_count + 16'b1;
    else if(usb_reve_count == USB_REVE_MAX) 
       usb_reve_count <= 16'b0;
end
//接收赋值
always @(posedge usb_clock, negedge usb_reset) 
begin
    if(!usb_reset)
        usb_reve[511:0] <= 512'b0; 
    else if(usb_state ==  USB_STATE_REVE && !usb_rx_empty && usb_reve_count > 16'd2)
        usb_reve[((usb_reve_count-3)*8+7) -: 8] <= usb_ports[7:0]; 
end
//接收完成通知
always @(posedge usb_clock, negedge usb_reset) 
begin
    if(!usb_reset)
        usb_vaild <= 1'b0;
    else if(usb_reve_count == USB_REVE_MAX) 
        usb_vaild <= 1'b1;
    else usb_vaild <= 1'b0;   
end
//接收读取启动
always @(posedge usb_clock, negedge usb_reset) 
begin
    if(!usb_reset)
        usb_read_n <= 1'b1;
    else if(usb_state ==  USB_STATE_REVE && !usb_rx_empty && usb_reve_count > 16'd1)
        usb_read_n <= 1'b0;
    else usb_read_n <= 1'b1;
end
//接收输出使能开启
always @(posedge usb_clock, negedge usb_reset) 
begin
    if(!usb_reset)
        usb_outen_n <= 1'b1;
    else if(usb_state ==  USB_STATE_REVE && usb_reve_count == 16'd1)
        usb_outen_n <= 1'b0;
    else if(usb_reve_count == USB_REVE_MAX)
        usb_outen_n <= 1'b1;   
end

endmodule