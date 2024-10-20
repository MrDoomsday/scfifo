module axis_fifo #(
    parameter T_DATA_WIDTH = 32,
    parameter SIZE = 10
)(
    input bit clk,
    input bit reset_n,

    //input stream
    input   bit   [T_DATA_WIDTH-1:0]        s_data_i,
    input   bit                             s_valid_i,
    output  bit                             s_ready_o,

    //output stream
    output  bit   [T_DATA_WIDTH-1:0]        m_data_o,
    output  bit                             m_valid_o,
    input   bit                             m_ready_i,

    output  bit                             fifo_empty_o,
    output  bit                             fifo_full_o
);

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            DECLARATION      ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
    localparam WIDTH_POINTER = $clog2(SIZE);
    logic [T_DATA_WIDTH-1:0] ram [SIZE-1:0];
    logic [WIDTH_POINTER-1:0] wr_ptr, wr_ptr_next, rd_ptr, rd_ptr_next;
    logic s_ready_next;
    logic m_valid_next;
    logic fifo_empty_next;
    logic fifo_full_next;


/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            LOGIC            ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
    always_ff @ (posedge clk) begin
        if(s_valid_i & s_ready_o) ram[wr_ptr] <= s_data_i;
    end

    assign m_data_o = ram[rd_ptr];

    always_ff @ (posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            wr_ptr      <= {WIDTH_POINTER{1'b0}};
            rd_ptr      <= {WIDTH_POINTER{1'b0}};
            s_ready_o   <= 1'b1;
            m_valid_o   <= 1'b0;
            fifo_empty_o<= 1'b1;
            fifo_full_o <= 1'b0;
        end
        else begin
            wr_ptr      <= wr_ptr_next;
            rd_ptr      <= rd_ptr_next;
            s_ready_o   <= s_ready_next;
            m_valid_o   <= m_valid_next;
            fifo_empty_o<= fifo_empty_next;
            fifo_full_o <= fifo_full_next;
        end
    end


    always_comb begin
        wr_ptr_next     = wr_ptr;
        rd_ptr_next     = rd_ptr;
        s_ready_next    = s_ready_o;
        m_valid_next    = m_valid_o;
        fifo_empty_next = fifo_empty_o;
        fifo_full_next  = fifo_full_o;

        case({m_valid_o & m_ready_i, s_valid_i & s_ready_o})
            2'b00: begin
                wr_ptr_next     = wr_ptr;
                rd_ptr_next     = rd_ptr;
            end

            2'b01: begin
                if(wr_ptr == WIDTH_POINTER'(SIZE-1)) 
                    wr_ptr_next = WIDTH_POINTER'(1'b0);
                else 
                    wr_ptr_next = wr_ptr + WIDTH_POINTER'(1'b1);

                if(wr_ptr_next == rd_ptr) begin
                    s_ready_next = 1'b0;
                    fifo_full_next = 1'b1;
                end
                else begin
                    s_ready_next = 1'b1;
                    fifo_full_next = 1'b0;
                end

                m_valid_next = 1'b1;
            end

            2'b10: begin
                if(rd_ptr == WIDTH_POINTER'(SIZE-1)) 
                    rd_ptr_next = WIDTH_POINTER'(1'b0);
                else 
                    rd_ptr_next = rd_ptr + WIDTH_POINTER'(1'b1);

                s_ready_next = 1'b1;

                if(rd_ptr_next == wr_ptr) begin
                    m_valid_next = 1'b0;
                    fifo_empty_next = 1'b1;
                end
                else begin
                    m_valid_next = 1'b1;
                    fifo_empty_next = 1'b0;
                end
            end

            2'b11: begin
                if(wr_ptr == WIDTH_POINTER'(SIZE-1)) 
                    wr_ptr_next = WIDTH_POINTER'(1'b0);
                else 
                    wr_ptr_next = wr_ptr + WIDTH_POINTER'(1'b1);

                if(rd_ptr == WIDTH_POINTER'(SIZE-1)) 
                    rd_ptr_next = WIDTH_POINTER'(1'b0);
                else 
                    rd_ptr_next = rd_ptr + WIDTH_POINTER'(1'b1);
            end
        endcase
    end

endmodule
