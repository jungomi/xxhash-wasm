(module
  (import "data" "memory" (memory 1))

  (global $PRIME32_1 i32 (i32.const 2654435761))
  (global $PRIME32_2 i32 (i32.const 2246822519))
  (global $PRIME32_3 i32 (i32.const 3266489917))
  (global $PRIME32_4 i32 (i32.const 668265263))
  (global $PRIME32_5 i32 (i32.const 374761393))

  (func (export "xxh32") (param $ptr i32) (param $len i32) (param $seed i32) (result i32)
        (local $h32 i32)
        (local $end i32)
        (local $limit i32)
        (local $v1 i32)
        (local $v2 i32)
        (local $v3 i32)
        (local $v4 i32)
        (set_local $end (i32.add (get_local $ptr) (get_local $len)))
        (if
          (i32.ge_u (get_local $len) (i32.const 16))
          (block
            (set_local $limit (i32.sub (get_local $end) (i32.const 16)))
            (set_local $v1 (i32.add (i32.add (get_local $seed) (get_global $PRIME32_1)) (get_global $PRIME32_2)))
            (set_local $v2 (i32.add (get_local $seed) (get_global $PRIME32_2)))
            (set_local $v3 (i32.add (get_local $seed) (i32.const 0)))
            (set_local $v4 (i32.sub (get_local $seed) (get_global $PRIME32_1)))
            ;; For every chunk of 4 words, so 4 * 32bits = 16 bytes
            (loop $4words-loop
                  (set_local $v1 (call $round32 (get_local $v1) (i32.load (get_local $ptr))))
                  (set_local $ptr (i32.add (get_local $ptr) (i32.const 4)))
                  (set_local $v2 (call $round32 (get_local $v2) (i32.load (get_local $ptr))))
                  (set_local $ptr (i32.add (get_local $ptr) (i32.const 4)))
                  (set_local $v3 (call $round32 (get_local $v3) (i32.load (get_local $ptr))))
                  (set_local $ptr (i32.add (get_local $ptr) (i32.const 4)))
                  (set_local $v4 (call $round32 (get_local $v4) (i32.load (get_local $ptr))))
                  (set_local $ptr (i32.add (get_local $ptr) (i32.const 4)))
                  (br_if $4words-loop (i32.le_u (get_local $ptr) (get_local $limit))))
            (set_local $h32 (i32.add
                              (i32.rotl (get_local $v1) (i32.const 1))
                              (i32.add
                                (i32.rotl (get_local $v2) (i32.const 7))
                                (i32.add
                                  (i32.rotl (get_local $v3) (i32.const 12))
                                  (i32.rotl (get_local $v4) (i32.const 18)))))))
          ;; else block, when input is smaller than 16 bytes
          (set_local $h32 (i32.add (get_local $seed) (get_global $PRIME32_5))))
        (set_local $h32 (i32.add (get_local $h32) (get_local $len)))
        ;; For the remaining words not covered above, either 0, 1, 2 or 3
        (block $exit-remaining-words
               (loop $remaining-words-loop
                     (br_if $exit-remaining-words (i32.gt_u (i32.add (get_local $ptr) (i32.const 4)) (get_local $end)))
                     (set_local $h32 (i32.add (get_local $h32) (i32.mul (i32.load (get_local $ptr)) (get_global $PRIME32_3))))
                     (set_local $h32 (i32.mul (i32.rotl (get_local $h32) (i32.const 17)) (get_global $PRIME32_4)))
                     (set_local $ptr (i32.add (get_local $ptr) (i32.const 4)))
                     (br $remaining-words-loop)))
        ;; For the remaining bytes that didn't make a whole word,
        ;; either 0, 1, 2 or 3 bytes, as 4bytes = 32bits = 1 word.
        (block $exit-remaining-bytes
               (loop $remaining-bytes-loop
                     (br_if $exit-remaining-bytes (i32.ge_u (get_local $ptr) (get_local $end)))
                     (set_local $h32 (i32.add (get_local $h32) (i32.mul (i32.load8_u (get_local $ptr)) (get_global $PRIME32_5))))
                     (set_local $h32 (i32.mul (i32.rotl (get_local $h32) (i32.const 11)) (get_global $PRIME32_1)))
                     (set_local $ptr (i32.add (get_local $ptr) (i32.const 1)))
                     (br $remaining-bytes-loop)))
        ;; Finalise
        (set_local $h32 (i32.xor (get_local $h32) (i32.shr_u (get_local $h32) (i32.const 15))))
        (set_local $h32 (i32.mul (get_local $h32) (get_global $PRIME32_2)))
        (set_local $h32 (i32.xor (get_local $h32) (i32.shr_u (get_local $h32) (i32.const 13))))
        (set_local $h32 (i32.mul (get_local $h32) (get_global $PRIME32_3)))
        (set_local $h32 (i32.xor (get_local $h32) (i32.shr_u (get_local $h32) (i32.const 16))))
        (get_local $h32))

  (func $round32 (param $seed i32) (param $value i32) (result i32)
        (set_local $seed (i32.add  (get_local $seed) (i32.mul (get_local $value) (get_global $PRIME32_2))))
        (set_local $seed (i32.rotl (get_local $seed) (i32.const 13)))
        (set_local $seed (i32.mul (get_local $seed) (get_global $PRIME32_1)))
        (get_local $seed)))
