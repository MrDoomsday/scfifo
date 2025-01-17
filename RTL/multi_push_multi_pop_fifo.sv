/*
    clk - тактовый сигнал
    reset_n - асинхронный сброс по заднему фронту 

    push - количество слов данных, которые мы хотим поместить в буфер
    push_data - данные, которые мы хотим поместить в буфер
    can_push - максимальное количество слов данных, которые можно поместить в буфер за одно обращение в данный момент


    pop - количество слов данных, которые мы хотим получить из буфера
    can_pop - максимальное количество слов данных, которые можно запросить из буфера за одно обращение в данный момент
    pop_data - возвращенные из буфера данные в ответ на запрос pop
    pop_resp - количество валидных слов данных в pop_data


    Как работает модуль.
    Процесс записи: 
    Выставляем на шину push_data требуемое для записи количество слов данных, одновременно выставляем на push количество этих слов. На следующем такте данные будут записаны в буфер.
    Порядок следующий [0]->[1]->[2]->e.t.c.
    !!! Если величина push будет превышать can_push, то операция записи будет проигнорирована целиком (ни будет записано ни одно из слов данных), так что нужно записывать только то количество, 
    которое позволено модулем.

    Процесс чтения: 
    Выставляем на шину pop количество слов данных, которые мы хотим прочитать.
    !!! Если величина pop превысит can_pop, то операция чтения будет проигнорирована целиком (по аналогии с операцией записи)
    Чтение из памяти занимает не один такт, однотактовое чтение в данном случае скорее всего нереализуемо, т.к. мультиплексирование всё равно потребуется, а мультиплексирование значений 
    сразу из памяти не позволит добиться высоких значений рабочих тактовых частот. 
    Спустя 5 тактов после запроса на выходе pop_data появится набор данных, а pop_resp укажет их количество (оно всегда равно ранее запрошенному). 
    Архитектура конвейерная, потому pop можно подавать друг за другом.
*/

module multi_push_multi_pop_fifo #(
    parameter   WIDTH_DATA = 32,        // ширина шины данных
                SIZE_FIFO = 19,         // сколько слов должно поместиться в фифошке
                AMOUNT_PUSH_POP = 13,   // max number of pushes or pops

    localparam  WIDTH_CAN = $clog2(AMOUNT_PUSH_POP + 1), // ширина шин can_push и can_pop
    localparam  WIDTH_SIZE_FIFO = $clog2(SIZE_FIFO + 1)  // ширина шины, которая сможет адресовать SIZE_FIFO слов в FIFO
)(
    input   logic                                           clk,
    input   logic                                           reset_n,

    input   logic [WIDTH_CAN-1:0]                           push,
    input   logic [AMOUNT_PUSH_POP-1:0][WIDTH_DATA-1:0]     push_data,
    output  logic [WIDTH_CAN-1:0]                           can_push,  // how many items can I push

    input   logic [WIDTH_CAN-1:0]                           pop,
    output  logic [AMOUNT_PUSH_POP-1:0][WIDTH_DATA-1:0]     pop_data,
    output  logic [WIDTH_CAN-1:0]                           pop_resp, // т.к. данные из памяти читаются не сразу
    output  logic [WIDTH_CAN-1:0]                           can_pop
);

    // common
    localparam AMOUNT_RAM_BLOCKS = AMOUNT_PUSH_POP; // количество блоков RAM для записи
    localparam SIZE_RAM_BLOCKS = (SIZE_FIFO + (SIZE_FIFO % AMOUNT_PUSH_POP > 0 ? AMOUNT_PUSH_POP - (SIZE_FIFO % AMOUNT_PUSH_POP) : 0)) / AMOUNT_PUSH_POP; // объем одного блока RAM в словах
    localparam DEPTH_RAM_BLOCK = $clog2(SIZE_RAM_BLOCKS); // ширина шины, которая позволяет адресовать весь набор слов в RAM
    localparam WIDTH_PTR_RAM_BLOCK = WIDTH_CAN; // ширина указателя на текущий активный блок RAM, в который будет первым идит запись или чтение

    // write side
    logic [WIDTH_SIZE_FIFO-1:0]                                 wrside_available_words, wrside_available_words_next; // сколько слов еще доступно для записи
    logic                                                       write;
    logic                                                       full;

    logic                                                       write_r, write_rr, write_rrr;
    logic [AMOUNT_PUSH_POP-1:0]                                 wrmask_r, wrmask_rr, wrmask_rrr; // маскирует блоки памяти, в которые идет запись в соответствии с указателем
    logic [2**WIDTH_CAN-1:0][AMOUNT_PUSH_POP-1:0]               wrmask_rr_next;
    logic [2**WIDTH_PTR_RAM_BLOCK-1:0][AMOUNT_PUSH_POP-1:0]     wrmask_rrr_next;
    logic [AMOUNT_PUSH_POP*WIDTH_DATA-1:0]                      wdata_r, wdata_rr, wdata_rrr;
    logic [AMOUNT_PUSH_POP*WIDTH_DATA-1:0]                      wdata_rrr_next [2**WIDTH_PTR_RAM_BLOCK-1:0];
    logic [WIDTH_CAN-1:0]                                       push_r, push_rr, push_rrr;
    logic [WIDTH_PTR_RAM_BLOCK-1:0]                             wr_ptr_ram_block, wr_ptr_ram_block_next; // указатель на текущий блок RAM, с которого начнется запись следующего слова
    
    /*
        зачем делать два счетчика? Если использовать один, то возникают трудности с его ведением, т.к. запись идет не один такт, аналогичная ситуация с чтением
        Если будет один счетчик, то мы можем начать чтение еще до того как в память лягут значения и их оттуда можно будет читать.
    */
    // read side
    logic [WIDTH_SIZE_FIFO-1:0]                                 rdside_used_words, rdside_used_words_next; // сколько слов лежит в буфере на стороне чтения
    logic                                                       read;
    logic                                                       empty;

    logic                                                       read_r, read_rr, read_rrr;
    logic [AMOUNT_PUSH_POP*WIDTH_DATA-1:0]                      rdata, rdata_rrrr, rdata_rrrrr;
    logic [AMOUNT_PUSH_POP*WIDTH_DATA-1:0]                      pop_data_next [2**WIDTH_PTR_RAM_BLOCK-1:0];
    logic [WIDTH_CAN-1:0]                                       pop_r, pop_rr, pop_rrr, pop_rrrr, pop_rrrrr;
    logic [AMOUNT_PUSH_POP-1:0]                                 rdmask_r, rdmask_rr, rdmask_rrr; // маскирует блоки памяти, в которые идет запись в соответствии с указателем
    logic [2**WIDTH_CAN-1:0][AMOUNT_PUSH_POP-1:0]               rdmask_rr_next;
    logic [2**WIDTH_PTR_RAM_BLOCK-1:0][AMOUNT_PUSH_POP-1:0]     rdmask_rrr_next;
    logic [WIDTH_PTR_RAM_BLOCK-1:0]                             rd_ptr_ram_block, rd_ptr_ram_block_next; // указатель на текущий блок RAM, с которого начнется запись следующего слова
    logic [WIDTH_PTR_RAM_BLOCK-1:0]                             rd_ptr_ram_block_rrr, rd_ptr_ram_block_rrrr, rd_ptr_ram_block_rrrrr;

    /******************************************************** Stage 0 ********************************************************/ 
    // WRITE - контроль за переполнением буферов + запись в регистры входных сигналов
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            wrside_available_words  <= SIZE_FIFO;
            write_r                 <= '0;
            push_r                  <= '0;
        end else begin
            wrside_available_words  <= wrside_available_words_next;
            write_r                 <= write;
            push_r                  <= push;
        end
    end

    always_ff @(posedge clk) begin
        wdata_r <= push_data;
    end

    always_comb begin
        case({read_rrr, write})
            2'b00: begin
                wrside_available_words_next = wrside_available_words;
            end
            2'b01: begin
                wrside_available_words_next = wrside_available_words - push;
            end
            2'b10: begin
                wrside_available_words_next = wrside_available_words + pop_rrr;
            end
            2'b11: begin
                wrside_available_words_next = wrside_available_words - push + pop_rrr;
            end
        endcase
    end


    assign full = (wrside_available_words == 0) | (push > wrside_available_words); // либо когда заполнено полностью, либо когда хотим записать больше доступного
    assign write = (push > 'h0) & (push <= AMOUNT_PUSH_POP) & ~full; // если число записываемых элементов отлично от нуля и фифошка при этом не переполнена + число записываемых слов не превышает разрешенное количество


    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            can_push <= 'h0;
        end else begin
            if(wrside_available_words_next >= AMOUNT_PUSH_POP) begin
                can_push <= AMOUNT_PUSH_POP;
            end else begin
                can_push <= wrside_available_words_next[WIDTH_CAN-1:0];
            end
        end
    end

    // READ - контроль за переполнением буферов + запись в регистры входных сигналов
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            rdside_used_words       <= '0;
            pop_r                   <= '0;
            read_r                  <= '0;
        end else begin
            rdside_used_words       <= rdside_used_words_next;
            pop_r                   <= pop;
            read_r                  <= read;
        end
    end


    always_comb begin
        case({read, write_rrr})
            2'b00: begin
                rdside_used_words_next  = rdside_used_words;
            end
            2'b01: begin
                rdside_used_words_next  = rdside_used_words + push_rrr;
            end
            2'b10: begin
                rdside_used_words_next  = rdside_used_words - pop;
            end
            2'b11: begin
                rdside_used_words_next  = rdside_used_words + push_rrr - pop;
            end
        endcase
    end


    assign empty = (rdside_used_words == 0) & (pop > rdside_used_words); // когда нечего читать или запрос прочитать больше фактически находящихся в fifo слов
    assign read = (pop > 0) & (pop <= AMOUNT_PUSH_POP) & ~empty;

    

    /******************************************************** Stage 1 ********************************************************/
    // WRITE - преобразование push в битовую маску, которая в дальнейшем будет маскировать буферы для записи
    generate
        for(genvar i = 0; i < 2**WIDTH_CAN; i++) begin: gen_write_next_mask_rr
            if(i == 0 || i > AMOUNT_PUSH_POP) begin
                assign wrmask_rr_next[i] = '0;
            end else begin
                assign wrmask_rr_next[i] = {{(AMOUNT_PUSH_POP-i){1'b0}}, {i{1'b1}}};
            end
        end
    endgenerate


    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            write_rr                <= '0;
            wrmask_rr               <= '0;
            push_rr                 <= '0;
        end else begin
            write_rr                <= write_r;
            wrmask_rr               <= wrmask_rr_next[push_r];
            push_rr                 <= push_r;
        end
    end

    always_ff @(posedge clk) begin
        wdata_rr <= wdata_r;
    end

    // READ - преобразование pop в битовую маску, которая в дальнейшем будет маскировать буферы для чтения
    generate
        for(genvar i = 0; i < 2**WIDTH_CAN; i++) begin: gen_read_next_mask_rr
            if(i == 0 || i > AMOUNT_PUSH_POP) begin
                assign rdmask_rr_next[i] = '0;
            end else begin
                assign rdmask_rr_next[i] = {{(AMOUNT_PUSH_POP-i){1'b0}}, {i{1'b1}}};
            end
        end
    endgenerate

    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            pop_rr          <= '0;
            read_rr         <= '0;
            rdmask_rr       <= '0;
        end else begin
            pop_rr          <= pop_r;
            read_rr         <= read_r;
            rdmask_rr       <= rdmask_rr_next[pop_r];
        end
    end

    /******************************************************** Stage 2 ********************************************************/
    // WRITE - циклический сдвиг маски в соответствии с величиной указателя на текущую ячейку, параллельно таким же алгоритмом сдвигаются и данные
    generate
        for(genvar i = 0; i < 2**WIDTH_PTR_RAM_BLOCK; i++) begin: gen_write_next_mask_rrr
            if(i == 0 || i > AMOUNT_PUSH_POP-1) begin
                assign wrmask_rrr_next[i] = wrmask_rr;
                assign wdata_rrr_next[i] = wdata_rr;
            end else begin
                assign wrmask_rrr_next[i] = {wrmask_rr[AMOUNT_PUSH_POP-1-i:0], wrmask_rr[AMOUNT_PUSH_POP-1:AMOUNT_PUSH_POP-i]};
                assign wdata_rrr_next[i] = {wdata_rr[(WIDTH_DATA*AMOUNT_PUSH_POP-1-WIDTH_DATA*i):0], wdata_rr[WIDTH_DATA*AMOUNT_PUSH_POP-1:WIDTH_DATA*AMOUNT_PUSH_POP-WIDTH_DATA*i]}; // сдвиг влево
            end
        end
    endgenerate

    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            write_rrr               <= '0;
            wrmask_rrr              <= '0;
            push_rrr                <= '0;
            wr_ptr_ram_block        <= '0;
        end else begin
            write_rrr               <= write_rr;
            wrmask_rrr              <= wrmask_rrr_next[wr_ptr_ram_block];
            push_rrr                <= push_rr;
            wr_ptr_ram_block        <= write_rr ? wr_ptr_ram_block_next : wr_ptr_ram_block;
        end
    end

    always_ff @(posedge clk) begin
        wdata_rrr <= wdata_rrr_next[wr_ptr_ram_block];
    end


    always_comb begin
        if(wr_ptr_ram_block + push_rr > AMOUNT_RAM_BLOCKS) begin
            wr_ptr_ram_block_next = wr_ptr_ram_block + push_rr - AMOUNT_RAM_BLOCKS;
        end else begin
            wr_ptr_ram_block_next = wr_ptr_ram_block + push_rr;
        end
    end

    // READ - циклический сдвиг маски в соответствии с величиной указателя на текущую ячейку для чтения
    generate
        for(genvar i = 0; i < 2**WIDTH_PTR_RAM_BLOCK; i++) begin: gen_read_next_mask_rrr
            if(i == 0 || i > AMOUNT_PUSH_POP-1) begin
                assign rdmask_rrr_next[i] = rdmask_rr;
            end else begin
                assign rdmask_rrr_next[i] = {rdmask_rr[AMOUNT_PUSH_POP-1-i:0], rdmask_rr[AMOUNT_PUSH_POP-1:AMOUNT_PUSH_POP-i]};
            end
        end
    endgenerate

    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            pop_rrr             <= '0;
            read_rrr            <= '0;
            rdmask_rrr          <= '0;
            rd_ptr_ram_block    <= '0;
        end else begin
            pop_rrr             <= pop_rr;
            read_rrr            <= read_rr;
            rdmask_rrr          <= rdmask_rrr_next[rd_ptr_ram_block];
            rd_ptr_ram_block    <= read_rr ? rd_ptr_ram_block_next : rd_ptr_ram_block;
            rd_ptr_ram_block_rrr<= rd_ptr_ram_block; // с текущими данными используется предыдущее значение счетчика, нам он понадобится для восстановления порядка прочитанных из памяти слов
        end
    end


    always_comb begin
        if(rd_ptr_ram_block + pop_rr > AMOUNT_RAM_BLOCKS) begin
            rd_ptr_ram_block_next = rd_ptr_ram_block + pop_rr - AMOUNT_RAM_BLOCKS;
        end else begin
            rd_ptr_ram_block_next = rd_ptr_ram_block + pop_rr;
        end
    end

    /******************************************************** Stage 3 ********************************************************/
    generate 
        for(genvar i = 0; i < AMOUNT_RAM_BLOCKS; i++) begin: gen_ram_instance

            mpmp_ram # (
                .DATA_WIDTH ( WIDTH_DATA        ),
                .RAM_SIZE   ( SIZE_RAM_BLOCKS   ),
                .ADDR_WIDTH ( DEPTH_RAM_BLOCK   )
            ) mpmp_ram_inst (
                .clk        ( clk                                       ),
                .reset_n    ( reset_n                                   ),

                .write      ( wrmask_rrr[i]                             ),
                .wdata      ( wdata_rrr[WIDTH_DATA*(i+1)-1:WIDTH_DATA*i]),
                
                .read       ( rdmask_rrr[i]                             ),
                .rdata      ( rdata[WIDTH_DATA*i+:WIDTH_DATA]           )
            );
        end
    endgenerate

    // задержка чтения на памяти составляет один такт
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            pop_rrrr                <= '0;
            rd_ptr_ram_block_rrrr   <= '0;
        end else begin
            pop_rrrr                <= pop_rrr;
            rd_ptr_ram_block_rrrr   <= rd_ptr_ram_block_rrr; // понадобится для упорядочивания прочитанных данных
        end
    end

    assign rdata_rrrr = rdata;

    /******************************************************** Stage 4 ********************************************************/
    // READ - загрузка данных в буферные регистры перед дальнейшем мультиплексированием
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            pop_rrrrr               <= '0;
            rd_ptr_ram_block_rrrrr  <= '0;
        end else begin
            pop_rrrrr               <= pop_rrrr;
            rd_ptr_ram_block_rrrrr  <= rd_ptr_ram_block_rrrr; // понадобится для упорядочивания прочитанных данных
        end
    end

    always_ff @(posedge clk) begin
        rdata_rrrrr <= rdata_rrrr;
    end

    /******************************************************** Stage 5 ********************************************************/
    // READ - приводим данные в порядок в соответствии с указателем на первую прочитанную ячейку и отправляем на выход
    generate
        for(genvar i = 0; i < 2**WIDTH_PTR_RAM_BLOCK; i++) begin: gen_read_next_pop_data
            if(i == 0 || i > AMOUNT_PUSH_POP-1) begin
                assign pop_data_next[i] = rdata_rrrrr;
            end else begin
                assign pop_data_next[i] = {rdata_rrrrr[WIDTH_DATA*i-1:0], rdata_rrrrr[WIDTH_DATA*AMOUNT_PUSH_POP-1:WIDTH_DATA*i]}; // сдвиг вправо
            end
        end
    endgenerate


    always_ff @(posedge clk) begin
        pop_data <= pop_data_next[rd_ptr_ram_block_rrrrr];
    end
    
    always_ff @(posedge clk or negedge reset_n) begin
        if(!reset_n) begin
            can_pop     <= '0;
            pop_resp    <= '0;
        end else begin
            pop_resp <= pop_rrrrr;
            if(rdside_used_words_next >= AMOUNT_PUSH_POP) begin
                can_pop <= AMOUNT_PUSH_POP;
            end else begin
                can_pop <= rdside_used_words_next[WIDTH_CAN-1:0];
            end
        end
    end

    /******************************************************** Assertion ********************************************************/
    // проверка является ли запись или чтение данного количества слов допустимой
    SVA_CHECK_REQUEST_PUSH: assert property (
        @(posedge clk) disable iff(!reset_n)
        push <= can_push | push <= AMOUNT_PUSH_POP
    ) else $error("SVA_ERROR: The number of words being recorded exceeds one of the limits");


    SVA_CHECK_REQUEST_POP: assert property (
        @(posedge clk) disable iff(!reset_n)
        pop <= can_pop | pop <= AMOUNT_PUSH_POP
    ) else $error("SVA_ERROR: Attempt to read an invalid number of words out of range");

    // проверка превышения счетчиками контроля переполнения заданных лимитов
    SVA_CHECK_OVERFLOW_WRCOUNTER: assert property (
        @(posedge clk) disable iff(!reset_n)
        wrside_available_words <= SIZE_FIFO
    ) else $error("SVA_ERROR: The number of words in the buffer on the write side has exceeded the limit");

    SVA_CHECK_OVERFLOW_RDCOUNTER: assert property (
        @(posedge clk) disable iff(!reset_n)
        rdside_used_words <= SIZE_FIFO
    ) else $error("SVA_ERROR: The number of words in the buffer on the read side has exceeded the limit");
    
    

endmodule