`timescale 1ns / 1ps

module code_lock_tb;
    reg [4:0] keys;
    reg reset;
    wire lock_open;
    wire alarm;
    wire [4:0] stage_leds;
    
    // Instantiate code lock
    code_lock_system uut (
        .keys(keys),
        .reset(reset),
        .lock_open(lock_open),
        .alarm(alarm),
        .stage_leds(stage_leds)
    );

    // Task to press a key with realistic timing
    task press_key;
        input [2:0] key_num;  // 0=A, 1=B, 2=C, 3=D, 4=E
        begin
            $display("[%0t] Pressing Key %s", $time, 
                     key_num==0?"A":key_num==1?"B":key_num==2?"C":key_num==3?"D":"E");
            keys[key_num] = 1'b1;  // Press
            #100;                   // Hold for 100ns
            keys[key_num] = 1'b0;  // Release
            #100;                   // Wait before next press
        end
    endtask

    // Task to apply reset
    task apply_reset;
        begin
            $display("[%0t] Applying RESET", $time);
            reset = 1'b1;
            #50;
            reset = 1'b0;
            #50;
            $display("[%0t] Reset released", $time);
        end
    endtask

    initial begin
        // Initialize
        keys = 5'b00000;
        reset = 1'b0;
        
        $display("\n========================================");
        $display("Starting Code Lock Testbench");
        $display("Correct Code: A -> B -> B -> C -> D -> E");
        $display("========================================\n");
        
        // TEST 1: Correct sequence
        $display("\n--- TEST 1: Correct Sequence ---");
        apply_reset();
        press_key(0);  // A
        press_key(1);  // B
        press_key(1);  // B again
        press_key(2);  // C
        press_key(3);  // D
        press_key(4);  // E
        #100;
        if (lock_open && !alarm)
            $display("✓ TEST 1 PASSED: Lock opened successfully");
        else
            $display("✗ TEST 1 FAILED: lock_open=%b, alarm=%b", lock_open, alarm);
        
        // TEST 2: Wrong first key
        $display("\n--- TEST 2: Wrong First Key (B instead of A) ---");
        apply_reset();
        press_key(1);  // B (wrong!)
        #100;
        if (alarm && !lock_open)
            $display("✓ TEST 2 PASSED: Alarm triggered correctly");
        else
            $display("✗ TEST 2 FAILED: alarm=%b, lock_open=%b", alarm, lock_open);
        
        // TEST 3: Wrong key at stage 2
        $display("\n--- TEST 3: Wrong Key at Stage 2 ---");
        apply_reset();
        press_key(0);  // A (correct)
        press_key(2);  // C (wrong! should be B)
        #100;
        if (alarm && !lock_open)
            $display("✓ TEST 3 PASSED: Alarm triggered correctly");
        else
            $display("✗ TEST 3 FAILED: alarm=%b", alarm);
        
        // TEST 4: Skipping second B press
        $display("\n--- TEST 4: Skipping Second B Press ---");
        apply_reset();
        press_key(0);  // A
        press_key(1);  // B (first)
        press_key(2);  // C (skipped second B!)
        #100;
        if (alarm)
            $display("✓ TEST 4 PASSED: Detected skipped stage");
        else
            $display("✗ TEST 4 FAILED");
        
        // TEST 5: Pressing E too early
        $display("\n--- TEST 5: Pressing E Too Early ---");
        apply_reset();
        press_key(0);  // A
        press_key(1);  // B
        press_key(4);  // E (too early!)
        #100;
        if (alarm)
            $display("✓ TEST 5 PASSED: Early unlock prevented");
        else
            $display("✗ TEST 5 FAILED");
        
        // TEST 6: Reset mid-sequence and retry
        $display("\n--- TEST 6: Reset Mid-Sequence and Retry ---");
        apply_reset();
        press_key(0);  // A
        press_key(1);  // B
        $display("[%0t] Interrupting with reset...", $time);
        apply_reset();
        // Retry full sequence
        press_key(0);  // A
        press_key(1);  // B
        press_key(1);  // B
        press_key(2);  // C
        press_key(3);  // D
        press_key(4);  // E
        #100;
        if (lock_open && !alarm)
            $display("✓ TEST 6 PASSED: System recovered after reset");
        else
            $display("✗ TEST 6 FAILED");

        // TEST 7: Multiple Wrong Attempts
        $display("\n--- TEST 7: Multiple Wrong Attempts ---");
        apply_reset();
        press_key(0);  // A
        press_key(2);  // C (wrong)
        #100;
        if (alarm) $display("✓ Attempt 1 caught alarm");
        apply_reset();
        press_key(0);  // A
        press_key(1);  // B
        press_key(2);  // C (skipped B)
        #100;
        if (alarm) $display("✓ Attempt 2 caught alarm");
        apply_reset();
        press_key(0);  // A
        press_key(1);  // B
        press_key(1);  // B
        press_key(2);  // C
        press_key(3);  // D
        press_key(4);  // E
        #100;
        if (lock_open && !alarm)
            $display("✓ TEST 7 PASSED: System worked after multiple failures");
        else
            $display("✗ TEST 7 FAILED");
        
        $display("\n========================================");
        $display("All tests completed");
        $display("========================================\n");
        
        #500;
        $finish;
    end

    // Continuous monitoring
    initial begin
        $monitor("Time=%0t | Keys=%b | Stage LEDs=%b | Alarm=%b | Lock=%b", 
                 $time, keys, stage_leds, alarm, lock_open);
    end

    // Waveform dump for GTKWave/ModelSim
    initial begin
        $dumpfile("code_lock.vcd");
        $dumpvars(0, code_lock_tb);
        $dumpvars(0, uut.stage1);
        $dumpvars(0, uut.stage2);
        $dumpvars(0, uut.stage3);
        $dumpvars(0, uut.stage4);
        $dumpvars(0, uut.stage5);
    end

    // Display stage transitions
    always @(stage_leds) begin
        $display("[%0t] Stage LEDs changed: %b", $time, stage_leds);
    end

    always @(posedge alarm) begin
        $display("[%0t] ⚠️  ALARM TRIGGERED!", $time);
    end

    always @(posedge lock_open) begin
        $display("[%0t] 🔓 LOCK OPENED!", $time);
    end

endmodule
