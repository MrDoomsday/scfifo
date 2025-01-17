/*
sc_fifo #(
	.data_width(32),
	.fifo_depth(10)
) sc_fifo_inst (
	.clk	(),
	.reset_n(),
		
	.wr		(),
	.data_in(),
	
	.rd			(),
	.data_out	(),
	
	.full		(),
	.empty		(),
	.use_words	(),
	.clear		()//active is HIGH
	
);

*/
module sc_fifo #(
	parameter data_width = 256,
	parameter fifo_depth = 12
)(
	input 	logic clk,
	input 	logic reset_n,
	
	input 	logic 						wr,
	input 	logic 	[data_width-1:0] 	data_in,
	
	input 	logic 						rd,
	output 	logic 	[data_width-1:0] 	data_out,
	
	output 	logic 						full,
	output 	logic 						empty,
	output 	logic 	[fifo_depth:0] 		use_words,
	input 	logic						clear 
	
);


	reg [data_width-1:0] ram [2**fifo_depth-1:0];
	reg [fifo_depth:0] wr_ptr, rd_ptr;
	reg [fifo_depth:0] cnt_word;




//current point--------------------------------------------------------------
	always_ff @ (posedge clk or negedge reset_n) begin
		if(!reset_n) wr_ptr <= {(fifo_depth+1){1'b0}};
		else if(wr && ~full) wr_ptr <= wr_ptr + 1'b1;
		else if(clear) wr_ptr <= {(fifo_depth+1){1'b0}};
	end
		
	always_ff @ (posedge clk or negedge reset_n) begin
		if(!reset_n) rd_ptr <= {(fifo_depth+1){1'b0}};
		else if(rd && ~empty) rd_ptr <= rd_ptr + 1'b1;
		else if(clear) rd_ptr <= {(fifo_depth+1){1'b0}};
	end

	always_ff @ (posedge clk or negedge reset_n) begin
		if(!reset_n) cnt_word <= {(fifo_depth+1){1'b0}};
		else if(clear) cnt_word <= {(fifo_depth+1){1'b0}};
		else begin
			case({rd && ~empty, wr && ~full})
				2'b01:	cnt_word <= cnt_word + 1'b1;
				2'b10: 	cnt_word <= cnt_word - 1'b1;
				default: cnt_word <= cnt_word;
			endcase 
		end
	end

//RAM R/W--------------------------------------------------------------
	always_ff @ (posedge clk) begin
		if(wr && ~full)	ram[wr_ptr[fifo_depth-1:0]] <= data_in;
	end

	always_ff @ (posedge clk) begin
		if(rd && ~empty) data_out <= ram[rd_ptr[fifo_depth-1:0]];	
	end
//----------------------------------------------------------------------------
//status signal
	assign full = (wr_ptr[fifo_depth] ^ rd_ptr[fifo_depth]) & (wr_ptr[fifo_depth-1:0] == rd_ptr[fifo_depth-1:0]);//interval = full counter, fifo full
	assign empty = (wr_ptr[fifo_depth:0] == rd_ptr[fifo_depth:0]);
	assign use_words = cnt_word;

endmodule 
