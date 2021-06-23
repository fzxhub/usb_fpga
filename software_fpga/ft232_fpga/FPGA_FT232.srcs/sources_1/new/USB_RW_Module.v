module USB_RW_Module
(
	Clk,
	Rst_n,
	
	USB_Flag_A,
	USB_FD,
	USB_SLRD_n,
	USB_SLOE_n,
	USB_SLWR_n,
	USB_PACKEND,
	USB_FIFO_Adr,
	
	EN_Write,
	DATA_in,
	EN_DATA_out,
	DATA_out
	
);

	input Clk;
	input Rst_n;
	
	input USB_Flag_A;
	inout [15:0]USB_FD;
	output reg USB_SLRD_n;
	output reg USB_SLOE_n;
	output reg USB_SLWR_n;
	output reg USB_PACKEND;
	output reg [1:0]USB_FIFO_Adr;
	
	input EN_Write;
	input [255:0]DATA_in;
	output reg EN_DATA_out;
	output reg [255:0]DATA_out;


parameter
	IDLE 					=	4'd0//空闲状态
	,SET_READ_ADR 		=	4'd1//设置读取地址
	,ENABLE_SLOE		=	4'd2//使能OE信号
	,ENABLE_SLRD		=	4'd3//使能RD信号
	,DISABLE_SLRD		=	4'd4//不使能RD信号
	,COMPENSATION		=	4'd5//补齐32字节
	
	,SET_WRITE_ADR 	=	4'd6//设置写入地址
	,ENABLE_SLWR	 	=	4'd7//使能WR信号
	,DISABLE_SLWR	 	=	4'd8//不使能WR信号
	,ENABLE_PACKEND 	=	4'd9//使能PACKEND信号
	,DISABLE_PACKEND 	=	4'd10//不使能PACKEND信号
	,HOLD_WRITE_ADR	=	4'd11//保持读取地址信号
	


;

parameter
	TIME_CNT_MAX		=	3'd3
	,READ_CNT			=	6'd16
	,WRITE_CNT			=	6'd16



;
	
	reg [3:0]State;
	reg [5:0]Data_cnt;
	reg [5:0]WR_Data_cnt;
	reg [2:0]time_cnt;
	reg [255:0]Data_Out_temp;
	reg [255:0]DATA_in_temp;
	reg EN_Write_flag;
	
	
	assign USB_FD = ((State == ENABLE_SLWR)||(State == DISABLE_SLWR))?{DATA_in_temp[247:240],DATA_in_temp[255:248]}:16'hzzzz;
	
	
	
	
	always@(posedge Clk,negedge Rst_n)//时钟分频块
	if(!Rst_n)
		time_cnt <= 3'd0;
	else if(time_cnt == TIME_CNT_MAX)
		time_cnt <= 3'd0;
	else
		time_cnt <= time_cnt + 1'b1;
		
		
	always@(posedge Clk,negedge Rst_n)
	if(!Rst_n)
		State <= IDLE;
	else if(time_cnt == TIME_CNT_MAX)//达到计数值上限
	begin
		case (State)
			IDLE://空闲状态
			begin
				if(USB_Flag_A)//若有数据
					State <= SET_READ_ADR;
				else if(EN_Write_flag)
					State <= SET_WRITE_ADR;
				else//其他情况
					State <= State;
			end
			
			SET_READ_ADR://设置地址状态
				State <= ENABLE_SLOE;
			
			ENABLE_SLOE://设置OE有效
				State <= ENABLE_SLRD;
			
			ENABLE_SLRD://设置RD下降沿
			begin
				if(USB_Flag_A)//仍有数据
					State <= DISABLE_SLRD;
				
				else
					State <= COMPENSATION;
			end				
			
			DISABLE_SLRD://设置RD上升沿
				State <= ENABLE_SLRD;
				
			COMPENSATION://补齐32字节
				State <= IDLE;
				
			SET_WRITE_ADR://设置写入地址
				State <= ENABLE_SLWR;
				
			ENABLE_SLWR://使能WR信号
				State <= DISABLE_SLWR;
				
			DISABLE_SLWR://不使能WR信号
			begin
				if(WR_Data_cnt == WRITE_CNT)
					State <= ENABLE_PACKEND;
				else
					State <= ENABLE_SLWR;
			end
				
			ENABLE_PACKEND://使能PACKEND信号
				State <= DISABLE_PACKEND;
				
			DISABLE_PACKEND://不使能PACKEND信号
				State <= HOLD_WRITE_ADR;
				
			HOLD_WRITE_ADR://保持读取地址状态
				State <= IDLE;
				
			default:;
		endcase
	end
	
	
/************			以下为读取USB操作		****************/	

	always@(posedge Clk,negedge Rst_n)//输出地址描述块
	if(!Rst_n)
		USB_FIFO_Adr <= 2'b00;
	else if(State >= SET_WRITE_ADR)
		USB_FIFO_Adr <= 2'b10;
	else
		USB_FIFO_Adr <= 2'b00;
		
	
	always@(posedge Clk,negedge Rst_n)//SLOE描述块
	if(!Rst_n)
		USB_SLOE_n <= 1'b1;
	else if((State == ENABLE_SLOE)||(State == ENABLE_SLRD)||(State == DISABLE_SLRD))
		USB_SLOE_n <= 1'b0;
	else
		USB_SLOE_n <= 1'b1;
		
	
	always@(posedge Clk,negedge Rst_n)//SLRD描述块
	if(!Rst_n)
		USB_SLRD_n <= 1'b1;
	else if((State == ENABLE_SLRD))
		USB_SLRD_n <= 1'b0;
	else
		USB_SLRD_n <= 1'b1;
		
		
	always@(posedge Clk,negedge Rst_n)//Data_Out_temp描述块
	if(!Rst_n)
		Data_Out_temp <= 256'd0;
	else if((USB_SLRD_n == 1'b0)&&(time_cnt == 3'd0))
		Data_Out_temp <= {Data_Out_temp[239:0],USB_FD[7:0],USB_FD[15:8]};
	else
		Data_Out_temp <= Data_Out_temp;	


	always@(posedge Clk,negedge Rst_n)//Data_cnt描述块
	if(!Rst_n)
		Data_cnt <= 6'd0;
	else if((State == IDLE))
		Data_cnt <= 6'd0;
	else if((USB_SLRD_n == 1'b0)&&(time_cnt == 3'd0))
		begin
			if(Data_cnt == READ_CNT)
				Data_cnt <= 6'd1;
			else
				Data_cnt <= Data_cnt + 1'b1;
		end
	else
		Data_cnt <= Data_cnt;


	always@(posedge Clk,negedge Rst_n)//Data_Out描述块
	if(!Rst_n)
		DATA_out <= 256'd0;
	else if((Data_cnt == READ_CNT)&&(time_cnt == TIME_CNT_MAX)&&(USB_SLRD_n == 1'b1))
		DATA_out <= Data_Out_temp;
	else
		DATA_out <= DATA_out;
	
	
	always@(posedge Clk,negedge Rst_n)//EN_DATA_out描述块
	if(!Rst_n)
		EN_DATA_out <= 1'b0;
	else if((Data_cnt == READ_CNT)&&(time_cnt == TIME_CNT_MAX)&&(USB_SLRD_n == 1'b1))
		EN_DATA_out <= 1'b1;
	else if(time_cnt == 3'd1)
		EN_DATA_out <= 1'b0;		
		
		
/************			以下为写入USB操作		****************/

	always@(posedge Clk,negedge Rst_n)//EN_Write_flag描述块
	if(!Rst_n)
		EN_Write_flag <= 1'b0;
	else if(State >= SET_WRITE_ADR)
		EN_Write_flag <= 1'b0;
	else if(EN_Write)
		EN_Write_flag <= 1'b1;
	else
		EN_Write_flag <= EN_Write_flag;
		
		
	always@(posedge Clk,negedge Rst_n)//DATA_in_temp描述块
	if(!Rst_n)
		DATA_in_temp <= 256'd0;
	else if((EN_Write == 1'b1)&&(EN_Write_flag == 1'b0))
		DATA_in_temp <= DATA_in;
	else if((State == ENABLE_SLWR)&&(time_cnt == 3'd0)&&(WR_Data_cnt > 6'd0))
		DATA_in_temp <= DATA_in_temp << 16;
	else
		DATA_in_temp <= DATA_in_temp;		
		

	always@(posedge Clk,negedge Rst_n)//WR_Data_cnt描述块
	if(!Rst_n)
		WR_Data_cnt <= 6'd0;
	else if(State == IDLE)
		WR_Data_cnt <= 6'd0;
	else if((State == DISABLE_SLWR)&&(time_cnt == 3'd0))
		WR_Data_cnt <= WR_Data_cnt + 1'b1;
	else
		WR_Data_cnt <= WR_Data_cnt;	
		
		
		
	always@(posedge Clk,negedge Rst_n)//USB_SLWR_n描述块
	if(!Rst_n)
		USB_SLWR_n <= 1'b1;
	else if((State == ENABLE_SLWR))
		USB_SLWR_n <= 1'b0;
	else
		USB_SLWR_n <= 1'b1;	
		
	always@(posedge Clk,negedge Rst_n)//USB_PACKEND描述块
	if(!Rst_n)
		USB_PACKEND <= 1'b1;
	else if((State == ENABLE_PACKEND))
		USB_PACKEND <= 1'b0;	
	else
		USB_PACKEND <= 1'b1;	
		
endmodule
