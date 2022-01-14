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

  ;; State offsets for XXH32 state structs
  (global $SO_32_TOTAL_LEN i32 (i32.const 0))
  (global $SO_32_LARGE_LEN i32 (i32.const 4))
  (global $SO_32_V1 i32 (i32.const 8))
  (global $SO_32_V2 i32 (i32.const 12))
  (global $SO_32_V3 i32 (i32.const 16))
  (global $SO_32_V4 i32 (i32.const 20))
  (global $SO_32_MEM32 i32 (i32.const 24))
  (global $SO_32_MEMSIZE i32 (i32.const 40))

  ;; State offsets for XXH64 state structs
  (global $SO_64_TOTAL_LEN i32 (i32.const 0))
  (global $SO_64_V1 i32 (i32.const 8))
  (global $SO_64_V2 i32 (i32.const 16))
  (global $SO_64_V3 i32 (i32.const 24))
  (global $SO_64_V4 i32 (i32.const 32))
  (global $SO_64_MEM64 i32 (i32.const 40))
  (global $SO_64_MEMSIZE i32 (i32.const 72))

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
        (call $finalize32 (local.get $h32) (local.get $ptr) (i32.and (local.get $len) (i32.const 15))))

  (func $finalize32 (param $h32 i32) (param $ptr i32) (param $len i32) (result i32)
        (local $end i32)
        (local.set $end (i32.add (local.get $ptr) (local.get $len)))
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

  ;; Initialize a XXH32 state struct
  (func (export "init32") (param $statePtr i32) (param $seed i32)
        (i32.store 
          (i32.add (local.get $statePtr) (global.get $SO_32_V1))
          (i32.add (i32.add (local.get $seed) (global.get $PRIME32_1)) (global.get $PRIME32_2)))
        (i32.store 
          (i32.add (local.get $statePtr) (global.get $SO_32_V2))
          (i32.add (local.get $seed) (global.get $PRIME32_2)))
        (i32.store
          (i32.add (local.get $statePtr) (global.get $SO_32_V3))
          (local.get $seed))
        (i32.store 
          (i32.add (local.get $statePtr) (global.get $SO_32_V4))
          (i32.sub (local.get $seed) (global.get $PRIME32_1))))

  ;; Update a XXH32 State struct with the provided input bytes
  (func (export "update32") (param $statePtr i32) (param $inputPtr i32) (param $len i32)
        (local $end i32)
        (local $limit i32)
        (local $mem32Ptr i32)
        (local $initial-memsize i32)
        (local $largeLenPtr i32)
        (local $totalLenPtr i32)
        (local $v1 i32)
        (local $v2 i32)
        (local $v3 i32)
        (local $v4 i32)
        (local.set $end (i32.add (local.get $inputPtr) (local.get $len)))
        (local.set $mem32Ptr (i32.add (local.get $statePtr) (global.get $SO_32_MEM32)))
        (local.set $largeLenPtr (i32.add (local.get $statePtr) (global.get $SO_32_LARGE_LEN)))
        (local.set $totalLenPtr (i32.add (local.get $statePtr) (global.get $SO_32_TOTAL_LEN)))
        (local.set $initial-memsize (i32.load (i32.add (local.get $statePtr) (global.get $SO_32_MEMSIZE))))
        (i32.store (local.get $totalLenPtr) (i32.add (i32.load (local.get $totalLenPtr)) (local.get $len)))
        (i32.store 
          (local.get $largeLenPtr)
          (i32.or 
            (i32.load (local.get $largeLenPtr))
            (i32.or 
              (i32.ge_u (local.get $len) (i32.const 16)) 
              (i32.ge_u (i32.load (local.get $totalLenPtr)) (i32.const 16)))))
        (if (i32.lt_u
          (i32.add (local.get $len) (local.get $initial-memsize))
          (i32.const 16))
          (block
            (memory.copy
              (i32.add (local.get $mem32Ptr) (local.get $initial-memsize))
              (local.get $inputPtr)
              (local.get $len))
            (i32.store 
              (i32.add (local.get $statePtr) (global.get $SO_32_MEMSIZE))
              (i32.add (local.get $initial-memsize) (local.get $len)))
            (return)))
        (if (i32.ne (local.get $initial-memsize) (i32.const 0))
          (block
            (memory.copy
              (i32.add (local.get $mem32Ptr) (local.get $initial-memsize))
              (local.get $inputPtr)
              (i32.sub (i32.const 16) (local.get $initial-memsize)))
            (i32.store 
              (i32.add (local.get $statePtr) (global.get $SO_32_V1))
              (call $round32
                (i32.load (i32.add (local.get $statePtr) (global.get $SO_32_V1)))
                (i32.load (local.get $mem32Ptr))))
            (i32.store 
              (i32.add (local.get $statePtr) (global.get $SO_32_V2))
              (call $round32
                (i32.load (i32.add (local.get $statePtr) (global.get $SO_32_V2)))
                (i32.load (i32.add (local.get $mem32Ptr) (i32.const 4)))))
            (i32.store 
              (i32.add (local.get $statePtr) (global.get $SO_32_V3))
              (call $round32
                (i32.load (i32.add (local.get $statePtr) (global.get $SO_32_V3)))
                (i32.load (i32.add (local.get $mem32Ptr) (i32.const 8)))))
            (i32.store 
              (i32.add (local.get $statePtr) (global.get $SO_32_V4))
              (call $round32
                (i32.load (i32.add (local.get $statePtr) (global.get $SO_32_V4)))
                (i32.load (i32.add (local.get $mem32Ptr) (i32.const 12)))))
            (local.set $inputPtr (i32.add (local.get $inputPtr) (i32.sub (i32.const 16) (local.get $initial-memsize))))
            (i32.store (i32.add (local.get $statePtr) (global.get $SO_32_MEMSIZE)) (i32.const 0))))
        (if (i32.le_u (local.get $inputPtr) (i32.sub (local.get $end) (i32.const 16)))
          (block
            (local.set $limit (i32.sub (local.get $end) (i32.const 16)))
            (local.set $v1 (i32.load (i32.add (local.get $statePtr) (global.get $SO_32_V1))))
            (local.set $v2 (i32.load (i32.add (local.get $statePtr) (global.get $SO_32_V2))))
            (local.set $v3 (i32.load (i32.add (local.get $statePtr) (global.get $SO_32_V3))))
            (local.set $v4 (i32.load (i32.add (local.get $statePtr) (global.get $SO_32_V4))))
            (loop $update-loop
              (local.set $v1 (call $round32 (local.get $v1) (i32.load (local.get $inputPtr))))
              (local.set $inputPtr (i32.add (local.get $inputPtr) (i32.const 4)))
              (local.set $v2 (call $round32 (local.get $v2) (i32.load (local.get $inputPtr))))
              (local.set $inputPtr (i32.add (local.get $inputPtr) (i32.const 4)))
              (local.set $v3 (call $round32 (local.get $v3) (i32.load (local.get $inputPtr))))
              (local.set $inputPtr (i32.add (local.get $inputPtr) (i32.const 4)))
              (local.set $v4 (call $round32 (local.get $v4) (i32.load (local.get $inputPtr))))
              (local.set $inputPtr (i32.add (local.get $inputPtr) (i32.const 4)))
              (br_if $update-loop (i32.le_u (local.get $inputPtr) (local.get $limit))))
            (i32.store (i32.add (local.get $statePtr) (global.get $SO_32_V1)) (local.get $v1))
            (i32.store (i32.add (local.get $statePtr) (global.get $SO_32_V2)) (local.get $v2))
            (i32.store (i32.add (local.get $statePtr) (global.get $SO_32_V3)) (local.get $v3))
            (i32.store (i32.add (local.get $statePtr) (global.get $SO_32_V4)) (local.get $v4))))
        (if (i32.lt_u (local.get $inputPtr) (local.get $end))
          (block
            (memory.copy
              (local.get $mem32Ptr)
              (local.get $inputPtr)
              (i32.sub (local.get $end) (local.get $inputPtr)))
            (i32.store (i32.add (local.get $statePtr) (global.get $SO_32_MEMSIZE))
              (i32.sub (local.get $end) (local.get $inputPtr))))))

  ;; Digest an XXH32 State struct into a hash value
  (func (export "digest32") (param $ptr i32) (result i32)
        (local $h32 i32)
        (local $v1 i32)
        (local $v2 i32)
        (local $v3 i32)
        (local $v4 i32)
        (local.set $v3 (i32.load (i32.add (local.get $ptr) (global.get $SO_32_V3))))
        (if (i32.ne (i32.load (i32.add (local.get $ptr) (global.get $SO_32_LARGE_LEN))) (i32.const 0))
          (block 
            (local.set $v1 (i32.load (i32.add (local.get $ptr) (global.get $SO_32_V1))))
            (local.set $v2 (i32.load (i32.add (local.get $ptr) (global.get $SO_32_V2))))
            (local.set $v4 (i32.load (i32.add (local.get $ptr) (global.get $SO_32_V4))))
            (local.set $h32 (i32.add
                              (i32.rotl (local.get $v1) (i32.const 1))
                              (i32.add
                                (i32.rotl (local.get $v2) (i32.const 7))
                                  (i32.add
                                    (i32.rotl (local.get $v3) (i32.const 12))
                                    (i32.rotl (local.get $v4) (i32.const 18)))))))
          (local.set $h32 (i32.add (local.get $v3) (global.get $PRIME32_5))))
        (local.set $h32 (i32.add 
          (local.get $h32) 
          (i32.load (i32.add (local.get $ptr) (global.get $SO_32_TOTAL_LEN)))))
        (call $finalize32
          (local.get $h32)
          (i32.add (local.get $ptr) (global.get $SO_32_MEM32))
          (i32.load (i32.add (local.get $ptr) (global.get $SO_32_MEMSIZE)))))

  ;; This is the actual WebAssembly implementation for one-shot XXH64.
  ;; $ptr indicates the beginning of the memory where the to-be-hashed data is stored.
  ;; $len is the length of the data.
  ;; $seed is the seed to be used in the hash invocation
  (func (export "xxh64") (param $ptr i32) (param $len i32) (param $seed i64) (result i64)
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
        (call $finalize64 (local.get $h64) (local.get $ptr) (i32.and (local.get $len) (i32.const 31))))

  (func $finalize64 (param $h64 i64) (param $ptr i32) (param $len i32) (result i64)
        (local $end i32)
        (local.set $end (i32.add (local.get $ptr) (local.get $len)))
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

  ;; Initialize an XXH64 State Struct
  (func (export "init64") (param $statePtr i32) (param $seed i64)
        (i64.store 
          (i32.add (local.get $statePtr) (global.get $SO_64_V1))
          (i64.add (i64.add (local.get $seed) (global.get $PRIME64_1)) (global.get $PRIME64_2)))
        (i64.store 
          (i32.add (local.get $statePtr) (global.get $SO_64_V2))
          (i64.add (local.get $seed) (global.get $PRIME64_2)))
        (i64.store
          (i32.add (local.get $statePtr) (global.get $SO_64_V3))
          (local.get $seed))
        (i64.store 
          (i32.add (local.get $statePtr) (global.get $SO_64_V4))
          (i64.sub (local.get $seed) (global.get $PRIME64_1))))

  ;; Update an XXH64 State Struct with an array of input bytes
  (func (export "update64") (param $statePtr i32) (param $inputPtr i32) (param $len i32)
        (local $end i32)
        (local $limit i32)
        (local $mem64Ptr i32)
        (local $initial-memsize i32)
        (local $v1 i64)
        (local $v2 i64)
        (local $v3 i64)
        (local $v4 i64)
        (local.set $end (i32.add (local.get $inputPtr) (local.get $len)))
        (local.set $mem64Ptr (i32.add (local.get $statePtr) (global.get $SO_64_MEM64)))
        (local.set $initial-memsize (i32.load (i32.add (local.get $statePtr) (global.get $SO_64_MEMSIZE))))
        (i64.store (i32.add (local.get $statePtr) (global.get $SO_64_TOTAL_LEN))
          (i64.add 
            (i64.load (i32.add (local.get $statePtr) (global.get $SO_64_TOTAL_LEN)))
            (i64.extend_i32_u (local.get $len))))
        (if (i32.lt_u
          (i32.add (local.get $len) (local.get $initial-memsize))
          (i32.const 32))
          (block
            (memory.copy
              (i32.add (local.get $mem64Ptr) (local.get $initial-memsize))
              (local.get $inputPtr)
              (local.get $len))
            (i32.store 
              (i32.add (local.get $statePtr) (global.get $SO_64_MEMSIZE))
              (i32.add (local.get $initial-memsize) (local.get $len)))
            (return)))
        (if (i32.ne (local.get $initial-memsize) (i32.const 0))
          (block
            (memory.copy
              (i32.add (local.get $mem64Ptr) (local.get $initial-memsize))
              (local.get $inputPtr)
              (i32.sub (i32.const 32) (local.get $initial-memsize)))
            (i64.store 
              (i32.add (local.get $statePtr) (global.get $SO_64_V1))
              (call $round64 
                (i64.load (i32.add (local.get $statePtr) (global.get $SO_64_V1)))
                (i64.load (local.get $mem64Ptr))))
            (i64.store 
              (i32.add (local.get $statePtr) (global.get $SO_64_V2))
              (call $round64 
                (i64.load (i32.add (local.get $statePtr) (global.get $SO_64_V2)))
                (i64.load (i32.add (local.get $mem64Ptr) (i32.const 8)))))
            (i64.store 
              (i32.add (local.get $statePtr) (global.get $SO_64_V3))
              (call $round64 
                (i64.load (i32.add (local.get $statePtr) (global.get $SO_64_V3)))
                (i64.load (i32.add (local.get $mem64Ptr) (i32.const 16)))))
            (i64.store 
              (i32.add (local.get $statePtr) (global.get $SO_64_V4))
              (call $round64 
                (i64.load (i32.add (local.get $statePtr) (global.get $SO_64_V4)))
                (i64.load (i32.add (local.get $mem64Ptr) (i32.const 24)))))
            (local.set $inputPtr (i32.add (local.get $inputPtr) (i32.sub (i32.const 32) (local.get $initial-memsize))))
            (i32.store (i32.add (local.get $statePtr) (global.get $SO_64_MEMSIZE)) (i32.const 0))))
        (if (i32.le_u (i32.add (local.get $inputPtr) (i32.const 32)) (local.get $end))
          (block
            (local.set $limit (i32.sub (local.get $end) (i32.const 32)))
            (local.set $v1 (i64.load (i32.add (local.get $statePtr) (global.get $SO_64_V1))))
            (local.set $v2 (i64.load (i32.add (local.get $statePtr) (global.get $SO_64_V2))))
            (local.set $v3 (i64.load (i32.add (local.get $statePtr) (global.get $SO_64_V3))))
            (local.set $v4 (i64.load (i32.add (local.get $statePtr) (global.get $SO_64_V4))))
            (loop $update-loop
              (local.set $v1 (call $round64 (local.get $v1) (i64.load (local.get $inputPtr))))
              (local.set $inputPtr (i32.add (local.get $inputPtr) (i32.const 8)))
              (local.set $v2 (call $round64 (local.get $v2) (i64.load (local.get $inputPtr))))
              (local.set $inputPtr (i32.add (local.get $inputPtr) (i32.const 8)))
              (local.set $v3 (call $round64 (local.get $v3) (i64.load (local.get $inputPtr))))
              (local.set $inputPtr (i32.add (local.get $inputPtr) (i32.const 8)))
              (local.set $v4 (call $round64 (local.get $v4) (i64.load (local.get $inputPtr))))
              (local.set $inputPtr (i32.add (local.get $inputPtr) (i32.const 8)))
              (br_if $update-loop (i32.le_u (local.get $inputPtr) (local.get $limit))))
            (i64.store (i32.add (local.get $statePtr) (global.get $SO_64_V1)) (local.get $v1))
            (i64.store (i32.add (local.get $statePtr) (global.get $SO_64_V2)) (local.get $v2))
            (i64.store (i32.add (local.get $statePtr) (global.get $SO_64_V3)) (local.get $v3))
            (i64.store (i32.add (local.get $statePtr) (global.get $SO_64_V4)) (local.get $v4))))
        (if (i32.lt_u (local.get $inputPtr) (local.get $end))
          (block
            (memory.copy
              (local.get $mem64Ptr)
              (local.get $inputPtr)
              (i32.sub (local.get $end) (local.get $inputPtr)))
            (i32.store 
              (i32.add (local.get $statePtr) (global.get $SO_64_MEMSIZE))
              (i32.sub (local.get $end) (local.get $inputPtr))))))

  ;; Digest an XXH64 State struct into a hash value
  (func (export "digest64") (param $ptr i32) (result i64)
        (local $h64 i64)
        (local $v1 i64)
        (local $v2 i64)
        (local $v3 i64)
        (local $v4 i64)
        (local $total_len i64)
        (local.set $total_len (i64.load (i32.add (local.get $ptr) (global.get $SO_64_TOTAL_LEN))))
        (local.set $v3 (i64.load (i32.add (local.get $ptr) (global.get $SO_64_V3))))
        (if (i64.ge_u (local.get $total_len) (i64.const 32))
          (block 
            (local.set $v1 (i64.load (i32.add (local.get $ptr) (global.get $SO_64_V1))))
            (local.set $v2 (i64.load (i32.add (local.get $ptr) (global.get $SO_64_V2))))
            (local.set $v4 (i64.load (i32.add (local.get $ptr) (global.get $SO_64_V4))))
            (local.set $h64 (i64.add
                              (i64.add 
                                (i64.rotl (local.get $v1) (i64.const 1))
                                (i64.rotl (local.get $v2) (i64.const 7)))
                              (i64.add
                                (i64.rotl (local.get $v3) (i64.const 12))
                                (i64.rotl (local.get $v4) (i64.const 18)))))
            (local.set $h64 (call $merge-round64 (local.get $h64) (local.get $v1)))
            (local.set $h64 (call $merge-round64 (local.get $h64) (local.get $v2)))
            (local.set $h64 (call $merge-round64 (local.get $h64) (local.get $v3)))
            (local.set $h64 (call $merge-round64 (local.get $h64) (local.get $v4))))
          (local.set $h64 (i64.add (local.get $v3) (global.get $PRIME64_5))))
        (local.set $h64 (i64.add (local.get $h64) (local.get $total_len)))
        (call $finalize64 
          (local.get $h64)
          (i32.add (local.get $ptr) (global.get $SO_64_MEM64))
          (i32.wrap_i64 (i64.and (local.get $total_len) (i64.const 31))))))


