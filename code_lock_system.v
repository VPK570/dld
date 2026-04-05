module code_lock_system(
    input [4:0] keys,        // keys[0]=A, keys[1]=B, keys[2]=C, keys[3]=D, keys[4]=E
    input reset,             // Master reset (active HIGH)
    output lock_open,        // HIGH when correct sequence completed
    output alarm,            // HIGH when wrong key pressed
    output [4:0] stage_leds  // stage_leds[i] = stage i is active
);

    wire [9:0] q1, q2, q3, q4, q5;
    wire system_reset;
    reg lock_open_reg;
    reg alarm_reg;

    // Combined reset: Master reset or Alarm
    assign system_reset = reset || alarm_reg;

    // CD4017 Stage Instantiations
    // Stage 1: always enabled
    cd4017_top stage1 (
        .clk(keys[0]),
        .reset(system_reset),
        .clk_inhibit(1'b0),
        .Q(q1),
        .carry_out()
    );

    // Stage 2: enabled only when stage1 complete
    cd4017_top stage2 (
        .clk(keys[1]),
        .reset(system_reset),
        .clk_inhibit(~q1[1]),
        .Q(q2),
        .carry_out()
    );

    // Stage 3: enabled only when stage2 complete AND key B is released (prevents ripple)
    cd4017_top stage3 (
        .clk(keys[1]),
        .reset(system_reset),
        .clk_inhibit(~q2[1] | keys[1]), // Interlock on keys[1] to prevent same-cycle ripple
        .Q(q3),
        .carry_out()
    );

    // Stage 4: enabled only when stage3 complete
    cd4017_top stage4 (
        .clk(keys[2]),
        .reset(system_reset),
        .clk_inhibit(~q3[1]),
        .Q(q4),
        .carry_out()
    );

    // Stage 5: enabled only when stage4 complete
    cd4017_top stage5 (
        .clk(keys[3]),
        .reset(system_reset),
        .clk_inhibit(~q4[1]),
        .Q(q5),
        .carry_out()
    );

    // Stage active detection signals
    wire stage1_active, stage2_active, stage3_active, stage4_active, stage5_active;

    // A stage is active when previous stage completed but current stage hasn't 
    assign stage1_active = (q1[0] == 1'b1);                                     // Stage 1 at reset position
    assign stage2_active = (q1[1] == 1'b1) && (q2[1] == 1'b0);                  // Stage1 done, stage2 not done
    assign stage3_active = (q2[1] == 1'b1) && (q3[1] == 1'b0);                  // Stage2 done, stage3 not done  
    assign stage4_active = (q3[1] == 1'b1) && (q4[1] == 1'b0);                  // Stage3 done, stage4 not done
    assign stage5_active = (q4[1] == 1'b1) && (q5[1] == 1'b0);                  // Stage4 done, stage5 not done

    // Alarm logic (Registered to avoid race conditions with stage transitions)
    // We sample the "active" status on the positive edge of the keys.
    // This ensures we see the state BEFORE the current key press advances the counter.
    always @(posedge keys[0] or posedge keys[1] or posedge keys[2] or 
             posedge keys[3] or posedge keys[4] or posedge reset) begin
        if (reset) begin
            alarm_reg <= 1'b0;
        end else if (!alarm_reg) begin
            // Check if the pressed key is valid for any currently active stage
            if (keys[0] && !stage1_active) 
                alarm_reg <= 1'b1;
            else if (keys[1] && !(stage2_active || stage3_active)) 
                alarm_reg <= 1'b1;
            else if (keys[2] && !stage4_active) 
                alarm_reg <= 1'b1;
            else if (keys[3] && !stage5_active) 
                alarm_reg <= 1'b1;
            else if (keys[4] && (q5[1] == 1'b0)) 
                alarm_reg <= 1'b1;
        end
    end
    assign alarm = alarm_reg;

    // Stage Active Indicators
    assign stage_leds[0] = stage1_active;
    assign stage_leds[1] = stage2_active;
    assign stage_leds[2] = stage3_active;
    assign stage_leds[3] = stage4_active;
    assign stage_leds[4] = stage5_active;

    // Success Detection (Key E)
    always @(posedge keys[4] or posedge reset) begin
        if (reset)
            lock_open_reg <= 1'b0;
        else if (q5[1] == 1'b1 && !alarm_reg)
            lock_open_reg <= 1'b1;
    end
    assign lock_open = lock_open_reg;

endmodule
