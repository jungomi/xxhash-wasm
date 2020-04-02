(module
  (memory (export "mem") 1)

  (global $PRIME32_1 i32 (i32.const 2654435761))
  (global $PRIME32_2 i32 (i32.const 2246822519))
  (global $PRIME32_3 i32 (i32.const 3266489917))
  (global $PRIME32_4 i32 (i32.const 668265263))
  (global $PRIME32_5 i32 (i32.const 374761393))

  (global $PRIME64_1 i64 (i64.const 11400714785074694791))
  (global $PRIME64_2 i64 (i64.const 14029467366897019727))
  (global $PRIME64_3 i64 (i64.const  1609587929392839161))
  (global $PRIME64_4 i64 (i64.const  9650029242287828579))
  (global $PRIME64_5 i64 (i64.const  2870177450012600261))

  (func (export "xxh32") (param $ptr i32) (param $len i32) (param $seed i32) (result i32)
        (local $h32 i32)
        (local $end i32)
        (local $limit i32)
        (local $v1 i32)
        (local $v2 i32)
        (local $v3 i32)
        (local $v4 i32)
        (local.set $end (i32.add (local.get $ptr) (local.get $len)))
        (if
          (i32.ge_u (local.get $len) (i32.const 16))
          (block
            (local.set $limit (i32.sub (local.get $end) (i32.const 16)))
            (local.set $v1 (i32.add (i32.add (local.get $seed) (global.get $PRIME32_1)) (global.get $PRIME32_2)))
            (local.set $v2 (i32.add (local.get $seed) (global.get $PRIME32_2)))
            (local.set $v3 (i32.add (local.get $seed) (i32.const 0)))
            (local.set $v4 (i32.sub (local.get $seed) (global.get $PRIME32_1)))
            ;; For every chunk of 4 words, so 4 * 32bits = 16 bytes
            (loop $4words-loop
                  (local.set $v1 (call $round32 (local.get $v1) (i32.load (local.get $ptr))))
                  (local.set $ptr (i32.add (local.get $ptr) (i32.const 4)))
                  (local.set $v2 (call $round32 (local.get $v2) (i32.load (local.get $ptr))))
                  (local.set $ptr (i32.add (local.get $ptr) (i32.const 4)))
                  (local.set $v3 (call $round32 (local.get $v3) (i32.load (local.get $ptr))))
                  (local.set $ptr (i32.add (local.get $ptr) (i32.const 4)))
                  (local.set $v4 (call $round32 (local.get $v4) (i32.load (local.get $ptr))))
                  (local.set $ptr (i32.add (local.get $ptr) (i32.const 4)))
                  (br_if $4words-loop (i32.le_u (local.get $ptr) (local.get $limit))))
            (local.set $h32 (i32.add
                              (i32.rotl (local.get $v1) (i32.const 1))
                              (i32.add
                                (i32.rotl (local.get $v2) (i32.const 7))
                                (i32.add
                                  (i32.rotl (local.get $v3) (i32.const 12))
                                  (i32.rotl (local.get $v4) (i32.const 18)))))))
          ;; else block, when input is smaller than 16 bytes
          (local.set $h32 (i32.add (local.get $seed) (global.get $PRIME32_5))))
        (local.set $h32 (i32.add (local.get $h32) (local.get $len)))
        ;; For the remaining words not covered above, either 0, 1, 2 or 3
        (block $exit-remaining-words
               (loop $remaining-words-loop
                     (br_if $exit-remaining-words (i32.gt_u (i32.add (local.get $ptr) (i32.const 4)) (local.get $end)))
                     (local.set $h32 (i32.add (local.get $h32) (i32.mul (i32.load (local.get $ptr)) (global.get $PRIME32_3))))
                     (local.set $h32 (i32.mul (i32.rotl (local.get $h32) (i32.const 17)) (global.get $PRIME32_4)))
                     (local.set $ptr (i32.add (local.get $ptr) (i32.const 4)))
                     (br $remaining-words-loop)))
        ;; For the remaining bytes that didn't make a whole word,
        ;; either 0, 1, 2 or 3 bytes, as 4bytes = 32bits = 1 word.
        (block $exit-remaining-bytes
               (loop $remaining-bytes-loop
                     (br_if $exit-remaining-bytes (i32.ge_u (local.get $ptr) (local.get $end)))
                     (local.set $h32 (i32.add (local.get $h32) (i32.mul (i32.load8_u (local.get $ptr)) (global.get $PRIME32_5))))
                     (local.set $h32 (i32.mul (i32.rotl (local.get $h32) (i32.const 11)) (global.get $PRIME32_1)))
                     (local.set $ptr (i32.add (local.get $ptr) (i32.const 1)))
                     (br $remaining-bytes-loop)))
        ;; Finalise
        (local.set $h32 (i32.xor (local.get $h32) (i32.shr_u (local.get $h32) (i32.const 15))))
        (local.set $h32 (i32.mul (local.get $h32) (global.get $PRIME32_2)))
        (local.set $h32 (i32.xor (local.get $h32) (i32.shr_u (local.get $h32) (i32.const 13))))
        (local.set $h32 (i32.mul (local.get $h32) (global.get $PRIME32_3)))
        (local.set $h32 (i32.xor (local.get $h32) (i32.shr_u (local.get $h32) (i32.const 16))))
        (local.get $h32))

  (func $round32 (param $seed i32) (param $value i32) (result i32)
        (local.set $seed (i32.add  (local.get $seed) (i32.mul (local.get $value) (global.get $PRIME32_2))))
        (local.set $seed (i32.rotl (local.get $seed) (i32.const 13)))
        (local.set $seed (i32.mul (local.get $seed) (global.get $PRIME32_1)))
        (local.get $seed))

  ;; This is the actual WebAssembly implementation.
  ;; It cannot be used directly from JavaScript because of the lack of support
  ;; for i64.
  (func $xxh64 (param $ptr i32) (param $len i32) (param $seed i64) (result i64)
        (local $h64 i64)
        (local $end i32)
        (local $limit i32)
        (local $v1 i64)
        (local $v2 i64)
        (local $v3 i64)
        (local $v4 i64)
        (local.set $end (i32.add (local.get $ptr) (local.get $len)))
        (if
          (i32.ge_u (local.get $len) (i32.const 32))
          (block
            (local.set $limit (i32.sub (local.get $end) (i32.const 32)))
            (local.set $v1 (i64.add (i64.add (local.get $seed) (global.get $PRIME64_1)) (global.get $PRIME64_2)))
            (local.set $v2 (i64.add (local.get $seed) (global.get $PRIME64_2)))
            (local.set $v3 (i64.add (local.get $seed) (i64.const 0)))
            (local.set $v4 (i64.sub (local.get $seed) (global.get $PRIME64_1)))
            ;; For every chunk of 4 words, so 4 * 64bits = 32 bytes
            (loop $4words-loop
                  (local.set $v1 (call $round64 (local.get $v1) (i64.load (local.get $ptr))))
                  (local.set $ptr (i32.add (local.get $ptr) (i32.const 8)))
                  (local.set $v2 (call $round64 (local.get $v2) (i64.load (local.get $ptr))))
                  (local.set $ptr (i32.add (local.get $ptr) (i32.const 8)))
                  (local.set $v3 (call $round64 (local.get $v3) (i64.load (local.get $ptr))))
                  (local.set $ptr (i32.add (local.get $ptr) (i32.const 8)))
                  (local.set $v4 (call $round64 (local.get $v4) (i64.load (local.get $ptr))))
                  (local.set $ptr (i32.add (local.get $ptr) (i32.const 8)))
                  (br_if $4words-loop (i32.le_u (local.get $ptr) (local.get $limit))))
            (local.set $h64 (i64.add
                              (i64.rotl (local.get $v1) (i64.const 1))
                              (i64.add
                                (i64.rotl (local.get $v2) (i64.const 7))
                                (i64.add
                                  (i64.rotl (local.get $v3) (i64.const 12))
                                  (i64.rotl (local.get $v4) (i64.const 18))))))
            (local.set $h64 (call $merge-round64 (local.get $h64) (local.get $v1)))
            (local.set $h64 (call $merge-round64 (local.get $h64) (local.get $v2)))
            (local.set $h64 (call $merge-round64 (local.get $h64) (local.get $v3)))
            (local.set $h64 (call $merge-round64 (local.get $h64) (local.get $v4))))
          ;; else block, when input is smaller than 32 bytes
          (local.set $h64 (i64.add (local.get $seed) (global.get $PRIME64_5))))
        (local.set $h64 (i64.add (local.get $h64) (i64.extend_i32_u (local.get $len))))
        ;; For the remaining words not covered above, either 0, 1, 2 or 3
        (block $exit-remaining-words
               (loop $remaining-words-loop
                     (br_if $exit-remaining-words (i32.gt_u (i32.add (local.get $ptr) (i32.const 8)) (local.get $end)))
                     (local.set $h64 (i64.xor (local.get $h64) (call $round64 (i64.const 0) (i64.load (local.get $ptr)))))
                     (local.set $h64 (i64.add
                                       (i64.mul
                                         (i64.rotl (local.get $h64) (i64.const 27))
                                         (global.get $PRIME64_1))
                                       (global.get $PRIME64_4)))
                     (local.set $ptr (i32.add (local.get $ptr) (i32.const 8)))
                     (br $remaining-words-loop)))
        ;; For the remaining half word. That is when there are more than 32bits
        ;; remaining which didn't make a whole word.
        (if
          (i32.le_u (i32.add (local.get $ptr) (i32.const 4)) (local.get $end))
          (block
            (local.set $h64 (i64.xor (local.get $h64) (i64.mul (i64.load32_u (local.get $ptr)) (global.get $PRIME64_1))))
            (local.set $h64 (i64.add
                              (i64.mul
                                (i64.rotl (local.get $h64) (i64.const 23))
                                (global.get $PRIME64_2))
                              (global.get $PRIME64_3)))
            (local.set $ptr (i32.add (local.get $ptr) (i32.const 4)))))
        ;; For the remaining bytes that didn't make a half a word (32bits),
        ;; either 0, 1, 2 or 3 bytes, as 4bytes = 32bits = 1/2 word.
        (block $exit-remaining-bytes
               (loop $remaining-bytes-loop
                     (br_if $exit-remaining-bytes (i32.ge_u (local.get $ptr) (local.get $end)))
                     (local.set $h64 (i64.xor (local.get $h64) (i64.mul (i64.load8_u (local.get $ptr)) (global.get $PRIME64_5))))
                     (local.set $h64 (i64.mul (i64.rotl (local.get $h64) (i64.const 11)) (global.get $PRIME64_1)))
                     (local.set $ptr (i32.add (local.get $ptr) (i32.const 1)))
                     (br $remaining-bytes-loop)))
        ;; Finalise
        (local.set $h64 (i64.xor (local.get $h64) (i64.shr_u (local.get $h64) (i64.const 33))))
        (local.set $h64 (i64.mul (local.get $h64) (global.get $PRIME64_2)))
        (local.set $h64 (i64.xor (local.get $h64) (i64.shr_u (local.get $h64) (i64.const 29))))
        (local.set $h64 (i64.mul (local.get $h64) (global.get $PRIME64_3)))
        (local.set $h64 (i64.xor (local.get $h64) (i64.shr_u (local.get $h64) (i64.const 32))))
        (local.get $h64))

  (func $round64 (param $acc i64) (param $value i64) (result i64)
        (local.set $acc (i64.add  (local.get $acc) (i64.mul (local.get $value) (global.get $PRIME64_2))))
        (local.set $acc (i64.rotl (local.get $acc) (i64.const 31)))
        (local.set $acc (i64.mul (local.get $acc) (global.get $PRIME64_1)))
        (local.get $acc))

  (func $merge-round64 (param $acc i64) (param $value i64) (result i64)
        (local.set $value (call $round64 (i64.const 0) (local.get $value)))
        (local.set $acc (i64.xor (local.get $acc) (local.get $value)))
        (local.set $acc (i64.add (i64.mul (local.get $acc) (global.get $PRIME64_1)) (global.get $PRIME64_4)))
        (local.get $acc))

  ;; This function can be called from JavaScript and it expects that the
  ;; first word in the memory is the u64 seed, which is followed by the actual
  ;; data that is being hashed.
  ;; $ptr indicates the beginning of the memory where it's stored (with seed).
  ;; $len is the length of the actual data (without the 8bytes for the seed).
  ;; The function itself doesn't return anything, since the u64 wouldn't work
  ;; in JavaScript, so instead it is stored in place of the seed.
  (func (export "xxh64") (param $ptr i32) (param $len i32)
        (local $seed i64)
        (local $initial-ptr i32)
        (local $h64 i64)
        (local.set $initial-ptr (i32.add (local.get $ptr) (i32.const 0)))
        ;; Assemble the u64 seed from two u32 that were stored from JavaScript.
        ;; I would have thought it would be okay to just load an i64 directly,
        ;; but apparently that is not the case.
        (local.set $seed (i64.or
                           (i64.shl
                             (i64.load32_u (local.get $ptr))
                             (i64.const 32))
                           (i64.load32_u (i32.add (local.get $ptr) (i32.const 4)))))
        (local.set $ptr (i32.add (local.get $ptr) (i32.const 8)))
        (local.set $h64 (call $xxh64 (local.get $ptr) (local.get $len) (local.get $seed)))
        ;; Disassemble the u64 hash result to two u32 that can be read from
        ;; JavaScript. Again, I would have thought just storing the i64 would be
        ;; good enough.
        (i32.store (local.get $initial-ptr) (i32.wrap_i64 (i64.shr_u (local.get $h64) (i64.const 32))))
        (i32.store (i32.add (local.get $initial-ptr) (i32.const 4)) (i32.wrap_i64 (local.get $h64)))))
