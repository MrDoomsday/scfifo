/*
    fr - полностью регисторые выходы
*/
module axis_fifo_fr #(
    parameter T_DATA_WIDTH = 32,
    parameter SIZE = 1024
)(
    input   logic clk,
    input   logic reset_n,

    //input stream
    input   logic   [T_DATA_WIDTH-1:0]        s_data_i,
    input   logic                             s_valid_i,
    output  logic                             s_ready_o,

    //output stream
    output  logic   [T_DATA_WIDTH-1:0]        m_data_o,
    output  logic                             m_valid_o,
    input   logic                             m_ready_i,

    output  logic   [$clog2(SIZE):0]          fifo_usedw_o,// указывает сколько слов на текущий момент находится в FIFO
    output  logic   [$clog2(SIZE):0]          fifo_avalwd_o,// указывает сколько слов на текущий момент доступно для записи в FIFO
    output  logic                             fifo_empty_o,
    output  logic                             fifo_full_o
);

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            DECLARATION      ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
    localparam WIDTH_POINTER = $clog2(SIZE);
    logic [T_DATA_WIDTH-1:0] ram [SIZE-1:0];
    logic [WIDTH_POINTER-1:0] wr_ptr, wr_ptr_next, rd_ptr, rd_ptr_next;
    logic wr_en, rd_en; //write enable, read enable
    logic [WIDTH_POINTER:0] use_word, use_word_next;
    logic [WIDTH_POINTER:0] available_word, available_word_next;
    logic fifo_empty_next;
    logic fifo_full_next;
    logic s_ready_next;
    logic ready_out;

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            LOGIC            ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/
    assign wr_en = s_valid_i & s_ready_o;
    /*
        читаем из буферов если выходной регистр не занят или ready установлен в единицу
        Для справки: |use_word === (use_word > 0)
    */
    assign ready_out = !m_valid_o | m_ready_i;
    assign rd_en = |use_word & ready_out;
    


    always_ff @(posedge clk) begin
        if(wr_en) ram[wr_ptr] <= s_data_i;
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            wr_ptr          <= {WIDTH_POINTER{1'b0}};
            rd_ptr          <= {WIDTH_POINTER{1'b0}};
            fifo_empty_o    <= 1'b1;
            fifo_full_o     <= 1'b0;
            use_word        <= {(WIDTH_POINTER+1){1'b0}};
            available_word  <= (WIDTH_POINTER+1)'(SIZE);
            s_ready_o       <= 1'b1;
        end else begin
            wr_ptr          <= wr_ptr_next;
            rd_ptr          <= rd_ptr_next;
            fifo_empty_o    <= fifo_empty_next;
            fifo_full_o     <= fifo_full_next;
            use_word        <= use_word_next;
            available_word  <= available_word_next;
            s_ready_o       <= s_ready_next;
        end
    end

    always_comb begin
        wr_ptr_next         = wr_ptr;
        rd_ptr_next         = rd_ptr;
        fifo_empty_next     = fifo_empty_o;
        fifo_full_next      = fifo_full_o;
        use_word_next       = use_word;
        available_word_next = available_word;
        s_ready_next        = s_ready_o;

        case({rd_en, wr_en})
            2'b01: begin
                use_word_next = use_word + (WIDTH_POINTER+1)'(1'b1);
                available_word_next = available_word - (WIDTH_POINTER+1)'(1'b1);
                
                if(wr_ptr == WIDTH_POINTER'(SIZE-1)) wr_ptr_next = WIDTH_POINTER'(1'b0);
                else wr_ptr_next = wr_ptr + WIDTH_POINTER'(1'b1);
                
                fifo_empty_next = 1'b0;
                if(use_word == SIZE-1) begin//осталось записать только одно слово
                    fifo_full_next = 1'b1;
                    s_ready_next = 1'b0;
                end else begin
                    fifo_full_next = 1'b0;
                    s_ready_next = 1'b1;         
                end
            end
            2'b10: begin
                use_word_next = use_word - (WIDTH_POINTER+1)'(1'b1);
                available_word_next = available_word + (WIDTH_POINTER+1)'(1'b1);

                if(rd_ptr == WIDTH_POINTER'(SIZE-1)) rd_ptr_next = WIDTH_POINTER'(1'b0);
                else rd_ptr_next = rd_ptr + WIDTH_POINTER'(1'b1);

                s_ready_next = 1'b1;
                fifo_full_next = 1'b0;
                if(use_word == (WIDTH_POINTER+1)'(1'b1)) begin//осталось прочитать только одно слово
                    fifo_empty_next = 1'b1;
                end else begin
                    fifo_empty_next = 1'b0;
                end
            end
            2'b11: begin
                if(wr_ptr == WIDTH_POINTER'(SIZE-1)) wr_ptr_next = WIDTH_POINTER'(1'b0);
                else wr_ptr_next = wr_ptr + WIDTH_POINTER'(1'b1);

                if(rd_ptr == WIDTH_POINTER'(SIZE-1)) rd_ptr_next = WIDTH_POINTER'(1'b0);
                else rd_ptr_next = rd_ptr + WIDTH_POINTER'(1'b1);
            end
            default: begin
                wr_ptr_next         = wr_ptr;
                rd_ptr_next         = rd_ptr;
                fifo_empty_next     = fifo_empty_o;
                fifo_full_next      = fifo_full_o;
                use_word_next       = use_word;
                available_word_next = available_word;
                s_ready_next        = s_ready_o;
            end
        endcase
    end

//данные должны выставляться независимо от сигнала ready на выходе, а у тебя сейчас противоположная история, надо менять всё
    always_ff @(posedge clk) begin
        if(rd_en) m_data_o <= ram[rd_ptr];
    end

    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) m_valid_o <= 1'b0;
        else if(ready_out) m_valid_o <= |use_word;
    end


    assign fifo_usedw_o = use_word;
    assign fifo_avalwd_o = available_word;

/***********************************************************************************************************************/
/***********************************************************************************************************************/
/*******************************************            ASSERTION        ***********************************************/
/***********************************************************************************************************************/
/***********************************************************************************************************************/

    SVA_CHECK_SIZE_FIFO: assert property (
        @(posedge clk) disable iff(!reset_n)
        fifo_usedw_o + fifo_avalwd_o == SIZE
    ) else $error("SVA ERROR, FIFO: amount use + available word in fifo > SIZE fifo");

endmodule
