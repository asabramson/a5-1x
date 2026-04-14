module A51_EXT_V2_STREAM (
    input wire clk,
    input wire enable_setkey,
    input wire data_in,
    output wire sig_out
);

    wire sr1_feedback;
    wire sr2_feedback;
    wire sr3_feedback;

    // -----------------------------------------------------------------
    // Circuit SR1
    // Polynomial: x^19+x^18+x^17+x^14+1
    // -----------------------------------------------------------------

    parameter SR1_WIDTH = 19;
    reg [SR1_WIDTH-1:0] sr1 = 0; // Fibonacci

    wire sr1_tap18;
    wire sr1_tap17; wire sr1_17_to_16;
    wire sr1_tap16; wire sr1_16_to_13;
    wire sr1_tap13;

    assign sr1_tap18 = sr1[18];
    assign sr1_tap17 = sr1[17];
    assign sr1_tap16 = sr1[16];
    assign sr1_tap13 = sr1[13];

    assign sr1_17_to_16 = sr1_tap18 ^ sr1_tap17;
    assign sr1_16_to_13 = sr1_tap16 ^ sr1_17_to_16;
    assign sr1_feedback = sr1_tap13 ^ sr1_16_to_13;

    // -----------------------------------------------------------------
    // Circuit SR2
    // Polynomial: x^22+x^21+1
    // -----------------------------------------------------------------

    parameter SR2_WIDTH = 22;
    reg [SR2_WIDTH-1:0] sr2 = 0;

    wire sr2_tap21;
    wire sr2_tap20;

    assign sr2_tap21 = sr2[21];
    assign sr2_tap20 = sr2[20];

    assign sr2_feedback = sr2_tap21 ^ sr2_tap20;

    // -----------------------------------------------------------------
    // Circuit SR3
    // Polynomial: x^23+x^22+x^21+x^8+1
    // -----------------------------------------------------------------

    parameter SR3_WIDTH = 23;
    reg [SR3_WIDTH-1:0] sr3 = 0;

    wire sr3_tap22;
    wire sr3_tap21; wire sr3_21_to_20;
    wire sr3_tap20; wire sr3_20_to_7;
    wire sr3_tap7;

    assign sr3_tap22 = sr3[22];
    assign sr3_tap21 = sr3[21];
    assign sr3_tap20 = sr3[20];
    assign sr3_tap7 = sr3[7];

    assign sr3_21_to_20 = sr3_tap22 ^ sr3_tap21;
    assign sr3_20_to_7 = sr3_tap20 ^ sr3_21_to_20;
    assign sr3_feedback = (sr3_tap7 ^ sr3_20_to_7)^(sr1_feedback&sr2_feedback);

    // -----------------------------------------------------------------
    // Circuit SR4
    // Polynomial: x^27+x^5+x^2+x^1+1
    // -----------------------------------------------------------------

    parameter SR4_WIDTH = 27;
    reg [SR4_WIDTH-1:0] sr4 = 0;

    wire sr4_tap26;
    wire sr4_tap4; wire sr4_4_to_1;
    wire sr4_tap1; wire sr4_1_to_0;
    wire sr4_tap0;

    assign sr4_tap26 = sr4[26];
    assign sr4_tap4 = sr4[4];
    assign sr4_tap1 = sr4[1];
    assign sr4_tap0 = sr4[0];

    assign sr4_4_to_1 = sr4_tap26 ^ sr4_tap4;
    assign sr4_1_to_0 = sr4_tap1 ^ sr4_4_to_1;
    assign sr4_feedback = (sr4_tap0 ^ sr4_1_to_0);

    // -----------------------------------------------------------------
    // Clock Pulse Shifting
    // -----------------------------------------------------------------

    reg [7:0] key_counter = 0;

    wire clock_maj;
    assign clock_maj = (sr1[8] & sr2[10]) ^ (sr1[8] & sr3[10]) ^ (sr2[10] & sr3[10]);

    always @(posedge clk) begin
        if (enable_setkey) begin
            // Build up initial key register state
            if (key_counter < 19) begin
                sr1 <= {sr1[SR1_WIDTH-2:0], data_in};
            end else if (key_counter < 41) begin
                sr2 <= {sr2[SR2_WIDTH-2:0], data_in};
            end else if (key_counter < 64) begin
                sr3 <= {sr3[SR3_WIDTH-2:0], data_in};
            end else begin
                sr4 <= {sr4[SR4_WIDTH-2:0], data_in};
            end
            key_counter <= key_counter + 1'b1;
        end else begin
            // Wait for signals to settle.
            #30
            if (clock_maj==sr1[8]) begin
                sr1 <= {sr1[SR1_WIDTH-2:0], sr1_feedback};
            end
            if (clock_maj==sr2[10]) begin
                sr2 <= {sr2[SR2_WIDTH-2:0], sr2_feedback};
            end
            if (clock_maj==sr3[10]) begin
                sr3 <= {sr3[SR3_WIDTH-2:0], sr3_feedback};
            end
            // Always clock SR4
            sr4 <= {sr4[SR4_WIDTH-2:0], sr4_feedback};
        end
    end

    assign sig_out = sr1[SR1_WIDTH-1] ^ sr2[SR2_WIDTH-1] ^ sr3[SR3_WIDTH-1] ^ sr4[SR4_WIDTH-1];
endmodule

