--------------------------------------------------------------------------------
-- video_vga_test_pattern.vhd                                                 --
-- Video test pattern generator.                                              --
--------------------------------------------------------------------------------
-- (C) Copyright 2020 Adam Barnes <ambarnes@gmail.com>                        --
-- This file is part of The Tyto Project. The Tyto Project is free software:  --
-- you can redistribute it and/or modify it under the terms of the GNU Lesser --
-- General Public License as published by the Free Software Foundation,       --
-- either version 3 of the License, or (at your option) any later version.    --
-- The Tyto Project is distributed in the hope that it will be useful, but    --
-- WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public     --
-- License for more details. You should have received a copy of the GNU       --
-- Lesser General Public License along with The Tyto Project. If not, see     --
-- https://www.gnu.org/licenses/.                                             --
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity video_out_test_pattern is
    port (

        rst         : in    std_logic;                      -- sync reset
        clk         : in    std_logic;                      -- pixel clock

        v_act       : in    std_logic_vector(10 downto 0);  -- vertical active area (lines) *
        h_act       : in    std_logic_vector(10 downto 0);  -- horizontal active area (pixels) *

        raw_vs      : in    std_logic;                      -- vertical sync in
        raw_hs      : in    std_logic;                      -- horizontal sync in
        raw_vblank  : in    std_logic;                      --
        raw_hblank  : in    std_logic;                      --
        raw_ax      : in    std_logic_vector(11 downto 0);
        raw_ay      : in    std_logic_vector(11 downto 0);

        vga_vs      : out   std_logic;                      -- vertical sync out
        vga_hs      : out   std_logic;                      -- horizontal sync out
        vga_vblank  : out   std_logic;                      -- vertical blank out
        vga_hblank  : out   std_logic;                      -- horizontal blank out
        vga_r       : out   std_logic_vector(7 downto 0);   -- red output
        vga_g       : out   std_logic_vector(7 downto 0);   -- green output
        vga_b       : out   std_logic_vector(7 downto 0);   -- blue output
        vga_ax      : out   std_logic_vector(11 downto 0);
        vga_ay      : out   std_logic_vector(11 downto 0)

    );
end entity video_out_test_pattern;

----------------------------------------------------------------------

architecture synth of video_out_test_pattern is

    signal cbs         : unsigned(15 downto 0);             -- colour bar scale coefficient

    signal s0_cbx      : signed(raw_ax'range);   -- x position within colour bar region
    signal s0_cby      : signed(raw_ay'range);   -- y position within colour bar region

    signal s1_vs       : std_logic;
    signal s1_hs       : std_logic;
    signal s1_vblank   : std_logic;
    signal s1_hblank   : std_logic;
    signal s1_border   : std_logic;
    signal s1_cbe_x    : std_logic;
    signal s1_cbe_y    : std_logic;
    signal s1_cbs      : unsigned(1 downto 0);                  -- colour bar select (1 of 4)
    signal s1_cbv      : unsigned(25 downto 0);
    signal s1_ax       : std_logic_vector(raw_ax'range);
    signal s1_ay       : std_logic_vector(raw_ay'range);

begin

    s0_cbx <= signed(raw_ax) - resize(signed('0' & h_act(h_act'length-1 downto 2)),raw_ax'length); -- colour bar region x pos
    s0_cby <= signed(raw_ay) - resize(signed('0' & v_act(v_act'length-1 downto 2)),raw_ay'length); -- colour bar region y pos

    process(rst,clk)

        -- use to infer 1k x 16 synchronous ROM
        function cbscale(h_act  : unsigned) return unsigned is
        variable q: unsigned(15 downto 0);
        begin
            case to_integer(h_act) is
                when 257 => q := to_unsigned(65280,16);
                when 258 => q := to_unsigned(65026,16);
                when 259 => q := to_unsigned(64774,16);
                when 260 => q := to_unsigned(64524,16);
                when 261 => q := to_unsigned(64276,16);
                when 262 => q := to_unsigned(64029,16);
                when 263 => q := to_unsigned(63785,16);
                when 264 => q := to_unsigned(63543,16);
                when 265 => q := to_unsigned(63302,16);
                when 266 => q := to_unsigned(63063,16);
                when 267 => q := to_unsigned(62826,16);
                when 268 => q := to_unsigned(62591,16);
                when 269 => q := to_unsigned(62357,16);
                when 270 => q := to_unsigned(62125,16);
                when 271 => q := to_unsigned(61895,16);
                when 272 => q := to_unsigned(61667,16);
                when 273 => q := to_unsigned(61440,16);
                when 274 => q := to_unsigned(61215,16);
                when 275 => q := to_unsigned(60992,16);
                when 276 => q := to_unsigned(60770,16);
                when 277 => q := to_unsigned(60550,16);
                when 278 => q := to_unsigned(60331,16);
                when 279 => q := to_unsigned(60114,16);
                when 280 => q := to_unsigned(59898,16);
                when 281 => q := to_unsigned(59685,16);
                when 282 => q := to_unsigned(59472,16);
                when 283 => q := to_unsigned(59261,16);
                when 284 => q := to_unsigned(59052,16);
                when 285 => q := to_unsigned(58844,16);
                when 286 => q := to_unsigned(58637,16);
                when 287 => q := to_unsigned(58432,16);
                when 288 => q := to_unsigned(58229,16);
                when 289 => q := to_unsigned(58027,16);
                when 290 => q := to_unsigned(57826,16);
                when 291 => q := to_unsigned(57626,16);
                when 292 => q := to_unsigned(57428,16);
                when 293 => q := to_unsigned(57232,16);
                when 294 => q := to_unsigned(57036,16);
                when 295 => q := to_unsigned(56842,16);
                when 296 => q := to_unsigned(56650,16);
                when 297 => q := to_unsigned(56458,16);
                when 298 => q := to_unsigned(56268,16);
                when 299 => q := to_unsigned(56079,16);
                when 300 => q := to_unsigned(55892,16);
                when 301 => q := to_unsigned(55706,16);
                when 302 => q := to_unsigned(55521,16);
                when 303 => q := to_unsigned(55337,16);
                when 304 => q := to_unsigned(55154,16);
                when 305 => q := to_unsigned(54973,16);
                when 306 => q := to_unsigned(54792,16);
                when 307 => q := to_unsigned(54613,16);
                when 308 => q := to_unsigned(54435,16);
                when 309 => q := to_unsigned(54259,16);
                when 310 => q := to_unsigned(54083,16);
                when 311 => q := to_unsigned(53909,16);
                when 312 => q := to_unsigned(53735,16);
                when 313 => q := to_unsigned(53563,16);
                when 314 => q := to_unsigned(53392,16);
                when 315 => q := to_unsigned(53222,16);
                when 316 => q := to_unsigned(53053,16);
                when 317 => q := to_unsigned(52885,16);
                when 318 => q := to_unsigned(52718,16);
                when 319 => q := to_unsigned(52552,16);
                when 320 => q := to_unsigned(52388,16);
                when 321 => q := to_unsigned(52224,16);
                when 322 => q := to_unsigned(52061,16);
                when 323 => q := to_unsigned(51900,16);
                when 324 => q := to_unsigned(51739,16);
                when 325 => q := to_unsigned(51579,16);
                when 326 => q := to_unsigned(51421,16);
                when 327 => q := to_unsigned(51263,16);
                when 328 => q := to_unsigned(51106,16);
                when 329 => q := to_unsigned(50950,16);
                when 330 => q := to_unsigned(50795,16);
                when 331 => q := to_unsigned(50641,16);
                when 332 => q := to_unsigned(50488,16);
                when 333 => q := to_unsigned(50336,16);
                when 334 => q := to_unsigned(50185,16);
                when 335 => q := to_unsigned(50035,16);
                when 336 => q := to_unsigned(49886,16);
                when 337 => q := to_unsigned(49737,16);
                when 338 => q := to_unsigned(49590,16);
                when 339 => q := to_unsigned(49443,16);
                when 340 => q := to_unsigned(49297,16);
                when 341 => q := to_unsigned(49152,16);
                when 342 => q := to_unsigned(49008,16);
                when 343 => q := to_unsigned(48865,16);
                when 344 => q := to_unsigned(48722,16);
                when 345 => q := to_unsigned(48580,16);
                when 346 => q := to_unsigned(48440,16);
                when 347 => q := to_unsigned(48300,16);
                when 348 => q := to_unsigned(48160,16);
                when 349 => q := to_unsigned(48022,16);
                when 350 => q := to_unsigned(47884,16);
                when 351 => q := to_unsigned(47748,16);
                when 352 => q := to_unsigned(47612,16);
                when 353 => q := to_unsigned(47476,16);
                when 354 => q := to_unsigned(47342,16);
                when 355 => q := to_unsigned(47208,16);
                when 356 => q := to_unsigned(47075,16);
                when 357 => q := to_unsigned(46943,16);
                when 358 => q := to_unsigned(46811,16);
                when 359 => q := to_unsigned(46681,16);
                when 360 => q := to_unsigned(46551,16);
                when 361 => q := to_unsigned(46421,16);
                when 362 => q := to_unsigned(46293,16);
                when 363 => q := to_unsigned(46165,16);
                when 364 => q := to_unsigned(46038,16);
                when 365 => q := to_unsigned(45911,16);
                when 366 => q := to_unsigned(45785,16);
                when 367 => q := to_unsigned(45660,16);
                when 368 => q := to_unsigned(45536,16);
                when 369 => q := to_unsigned(45412,16);
                when 370 => q := to_unsigned(45289,16);
                when 371 => q := to_unsigned(45167,16);
                when 372 => q := to_unsigned(45045,16);
                when 373 => q := to_unsigned(44924,16);
                when 374 => q := to_unsigned(44803,16);
                when 375 => q := to_unsigned(44684,16);
                when 376 => q := to_unsigned(44564,16);
                when 377 => q := to_unsigned(44446,16);
                when 378 => q := to_unsigned(44328,16);
                when 379 => q := to_unsigned(44211,16);
                when 380 => q := to_unsigned(44094,16);
                when 381 => q := to_unsigned(43978,16);
                when 382 => q := to_unsigned(43863,16);
                when 383 => q := to_unsigned(43748,16);
                when 384 => q := to_unsigned(43634,16);
                when 385 => q := to_unsigned(43520,16);
                when 386 => q := to_unsigned(43407,16);
                when 387 => q := to_unsigned(43295,16);
                when 388 => q := to_unsigned(43183,16);
                when 389 => q := to_unsigned(43071,16);
                when 390 => q := to_unsigned(42961,16);
                when 391 => q := to_unsigned(42850,16);
                when 392 => q := to_unsigned(42741,16);
                when 393 => q := to_unsigned(42632,16);
                when 394 => q := to_unsigned(42523,16);
                when 395 => q := to_unsigned(42415,16);
                when 396 => q := to_unsigned(42308,16);
                when 397 => q := to_unsigned(42201,16);
                when 398 => q := to_unsigned(42095,16);
                when 399 => q := to_unsigned(41989,16);
                when 400 => q := to_unsigned(41884,16);
                when 401 => q := to_unsigned(41779,16);
                when 402 => q := to_unsigned(41675,16);
                when 403 => q := to_unsigned(41571,16);
                when 404 => q := to_unsigned(41468,16);
                when 405 => q := to_unsigned(41366,16);
                when 406 => q := to_unsigned(41263,16);
                when 407 => q := to_unsigned(41162,16);
                when 408 => q := to_unsigned(41061,16);
                when 409 => q := to_unsigned(40960,16);
                when 410 => q := to_unsigned(40860,16);
                when 411 => q := to_unsigned(40760,16);
                when 412 => q := to_unsigned(40661,16);
                when 413 => q := to_unsigned(40562,16);
                when 414 => q := to_unsigned(40464,16);
                when 415 => q := to_unsigned(40366,16);
                when 416 => q := to_unsigned(40269,16);
                when 417 => q := to_unsigned(40172,16);
                when 418 => q := to_unsigned(40076,16);
                when 419 => q := to_unsigned(39980,16);
                when 420 => q := to_unsigned(39885,16);
                when 421 => q := to_unsigned(39790,16);
                when 422 => q := to_unsigned(39695,16);
                when 423 => q := to_unsigned(39601,16);
                when 424 => q := to_unsigned(39508,16);
                when 425 => q := to_unsigned(39414,16);
                when 426 => q := to_unsigned(39322,16);
                when 427 => q := to_unsigned(39229,16);
                when 428 => q := to_unsigned(39137,16);
                when 429 => q := to_unsigned(39046,16);
                when 430 => q := to_unsigned(38955,16);
                when 431 => q := to_unsigned(38864,16);
                when 432 => q := to_unsigned(38774,16);
                when 433 => q := to_unsigned(38684,16);
                when 434 => q := to_unsigned(38595,16);
                when 435 => q := to_unsigned(38506,16);
                when 436 => q := to_unsigned(38418,16);
                when 437 => q := to_unsigned(38330,16);
                when 438 => q := to_unsigned(38242,16);
                when 439 => q := to_unsigned(38155,16);
                when 440 => q := to_unsigned(38068,16);
                when 441 => q := to_unsigned(37981,16);
                when 442 => q := to_unsigned(37895,16);
                when 443 => q := to_unsigned(37809,16);
                when 444 => q := to_unsigned(37724,16);
                when 445 => q := to_unsigned(37639,16);
                when 446 => q := to_unsigned(37554,16);
                when 447 => q := to_unsigned(37470,16);
                when 448 => q := to_unsigned(37386,16);
                when 449 => q := to_unsigned(37303,16);
                when 450 => q := to_unsigned(37220,16);
                when 451 => q := to_unsigned(37137,16);
                when 452 => q := to_unsigned(37055,16);
                when 453 => q := to_unsigned(36973,16);
                when 454 => q := to_unsigned(36891,16);
                when 455 => q := to_unsigned(36810,16);
                when 456 => q := to_unsigned(36729,16);
                when 457 => q := to_unsigned(36648,16);
                when 458 => q := to_unsigned(36568,16);
                when 459 => q := to_unsigned(36488,16);
                when 460 => q := to_unsigned(36409,16);
                when 461 => q := to_unsigned(36330,16);
                when 462 => q := to_unsigned(36251,16);
                when 463 => q := to_unsigned(36172,16);
                when 464 => q := to_unsigned(36094,16);
                when 465 => q := to_unsigned(36017,16);
                when 466 => q := to_unsigned(35939,16);
                when 467 => q := to_unsigned(35862,16);
                when 468 => q := to_unsigned(35785,16);
                when 469 => q := to_unsigned(35709,16);
                when 470 => q := to_unsigned(35633,16);
                when 471 => q := to_unsigned(35557,16);
                when 472 => q := to_unsigned(35481,16);
                when 473 => q := to_unsigned(35406,16);
                when 474 => q := to_unsigned(35331,16);
                when 475 => q := to_unsigned(35257,16);
                when 476 => q := to_unsigned(35182,16);
                when 477 => q := to_unsigned(35109,16);
                when 478 => q := to_unsigned(35035,16);
                when 479 => q := to_unsigned(34962,16);
                when 480 => q := to_unsigned(34889,16);
                when 481 => q := to_unsigned(34816,16);
                when 482 => q := to_unsigned(34744,16);
                when 483 => q := to_unsigned(34672,16);
                when 484 => q := to_unsigned(34600,16);
                when 485 => q := to_unsigned(34528,16);
                when 486 => q := to_unsigned(34457,16);
                when 487 => q := to_unsigned(34386,16);
                when 488 => q := to_unsigned(34316,16);
                when 489 => q := to_unsigned(34245,16);
                when 490 => q := to_unsigned(34175,16);
                when 491 => q := to_unsigned(34105,16);
                when 492 => q := to_unsigned(34036,16);
                when 493 => q := to_unsigned(33967,16);
                when 494 => q := to_unsigned(33898,16);
                when 495 => q := to_unsigned(33829,16);
                when 496 => q := to_unsigned(33761,16);
                when 497 => q := to_unsigned(33693,16);
                when 498 => q := to_unsigned(33625,16);
                when 499 => q := to_unsigned(33558,16);
                when 500 => q := to_unsigned(33490,16);
                when 501 => q := to_unsigned(33423,16);
                when 502 => q := to_unsigned(33357,16);
                when 503 => q := to_unsigned(33290,16);
                when 504 => q := to_unsigned(33224,16);
                when 505 => q := to_unsigned(33158,16);
                when 506 => q := to_unsigned(33092,16);
                when 507 => q := to_unsigned(33027,16);
                when 508 => q := to_unsigned(32962,16);
                when 509 => q := to_unsigned(32897,16);
                when 510 => q := to_unsigned(32832,16);
                when 511 => q := to_unsigned(32768,16);
                when 512 => q := to_unsigned(32704,16);
                when 513 => q := to_unsigned(32640,16);
                when 514 => q := to_unsigned(32576,16);
                when 515 => q := to_unsigned(32513,16);
                when 516 => q := to_unsigned(32450,16);
                when 517 => q := to_unsigned(32387,16);
                when 518 => q := to_unsigned(32324,16);
                when 519 => q := to_unsigned(32262,16);
                when 520 => q := to_unsigned(32200,16);
                when 521 => q := to_unsigned(32138,16);
                when 522 => q := to_unsigned(32076,16);
                when 523 => q := to_unsigned(32015,16);
                when 524 => q := to_unsigned(31953,16);
                when 525 => q := to_unsigned(31893,16);
                when 526 => q := to_unsigned(31832,16);
                when 527 => q := to_unsigned(31771,16);
                when 528 => q := to_unsigned(31711,16);
                when 529 => q := to_unsigned(31651,16);
                when 530 => q := to_unsigned(31591,16);
                when 531 => q := to_unsigned(31531,16);
                when 532 => q := to_unsigned(31472,16);
                when 533 => q := to_unsigned(31413,16);
                when 534 => q := to_unsigned(31354,16);
                when 535 => q := to_unsigned(31295,16);
                when 536 => q := to_unsigned(31237,16);
                when 537 => q := to_unsigned(31179,16);
                when 538 => q := to_unsigned(31120,16);
                when 539 => q := to_unsigned(31063,16);
                when 540 => q := to_unsigned(31005,16);
                when 541 => q := to_unsigned(30948,16);
                when 542 => q := to_unsigned(30890,16);
                when 543 => q := to_unsigned(30833,16);
                when 544 => q := to_unsigned(30777,16);
                when 545 => q := to_unsigned(30720,16);
                when 546 => q := to_unsigned(30664,16);
                when 547 => q := to_unsigned(30607,16);
                when 548 => q := to_unsigned(30552,16);
                when 549 => q := to_unsigned(30496,16);
                when 550 => q := to_unsigned(30440,16);
                when 551 => q := to_unsigned(30385,16);
                when 552 => q := to_unsigned(30330,16);
                when 553 => q := to_unsigned(30275,16);
                when 554 => q := to_unsigned(30220,16);
                when 555 => q := to_unsigned(30165,16);
                when 556 => q := to_unsigned(30111,16);
                when 557 => q := to_unsigned(30057,16);
                when 558 => q := to_unsigned(30003,16);
                when 559 => q := to_unsigned(29949,16);
                when 560 => q := to_unsigned(29896,16);
                when 561 => q := to_unsigned(29842,16);
                when 562 => q := to_unsigned(29789,16);
                when 563 => q := to_unsigned(29736,16);
                when 564 => q := to_unsigned(29683,16);
                when 565 => q := to_unsigned(29631,16);
                when 566 => q := to_unsigned(29578,16);
                when 567 => q := to_unsigned(29526,16);
                when 568 => q := to_unsigned(29474,16);
                when 569 => q := to_unsigned(29422,16);
                when 570 => q := to_unsigned(29370,16);
                when 571 => q := to_unsigned(29319,16);
                when 572 => q := to_unsigned(29267,16);
                when 573 => q := to_unsigned(29216,16);
                when 574 => q := to_unsigned(29165,16);
                when 575 => q := to_unsigned(29114,16);
                when 576 => q := to_unsigned(29064,16);
                when 577 => q := to_unsigned(29013,16);
                when 578 => q := to_unsigned(28963,16);
                when 579 => q := to_unsigned(28913,16);
                when 580 => q := to_unsigned(28863,16);
                when 581 => q := to_unsigned(28813,16);
                when 582 => q := to_unsigned(28764,16);
                when 583 => q := to_unsigned(28714,16);
                when 584 => q := to_unsigned(28665,16);
                when 585 => q := to_unsigned(28616,16);
                when 586 => q := to_unsigned(28567,16);
                when 587 => q := to_unsigned(28518,16);
                when 588 => q := to_unsigned(28470,16);
                when 589 => q := to_unsigned(28421,16);
                when 590 => q := to_unsigned(28373,16);
                when 591 => q := to_unsigned(28325,16);
                when 592 => q := to_unsigned(28277,16);
                when 593 => q := to_unsigned(28229,16);
                when 594 => q := to_unsigned(28182,16);
                when 595 => q := to_unsigned(28134,16);
                when 596 => q := to_unsigned(28087,16);
                when 597 => q := to_unsigned(28040,16);
                when 598 => q := to_unsigned(27993,16);
                when 599 => q := to_unsigned(27946,16);
                when 600 => q := to_unsigned(27899,16);
                when 601 => q := to_unsigned(27853,16);
                when 602 => q := to_unsigned(27806,16);
                when 603 => q := to_unsigned(27760,16);
                when 604 => q := to_unsigned(27714,16);
                when 605 => q := to_unsigned(27668,16);
                when 606 => q := to_unsigned(27623,16);
                when 607 => q := to_unsigned(27577,16);
                when 608 => q := to_unsigned(27532,16);
                when 609 => q := to_unsigned(27486,16);
                when 610 => q := to_unsigned(27441,16);
                when 611 => q := to_unsigned(27396,16);
                when 612 => q := to_unsigned(27351,16);
                when 613 => q := to_unsigned(27307,16);
                when 614 => q := to_unsigned(27262,16);
                when 615 => q := to_unsigned(27218,16);
                when 616 => q := to_unsigned(27173,16);
                when 617 => q := to_unsigned(27129,16);
                when 618 => q := to_unsigned(27085,16);
                when 619 => q := to_unsigned(27042,16);
                when 620 => q := to_unsigned(26998,16);
                when 621 => q := to_unsigned(26954,16);
                when 622 => q := to_unsigned(26911,16);
                when 623 => q := to_unsigned(26868,16);
                when 624 => q := to_unsigned(26825,16);
                when 625 => q := to_unsigned(26782,16);
                when 626 => q := to_unsigned(26739,16);
                when 627 => q := to_unsigned(26696,16);
                when 628 => q := to_unsigned(26653,16);
                when 629 => q := to_unsigned(26611,16);
                when 630 => q := to_unsigned(26569,16);
                when 631 => q := to_unsigned(26526,16);
                when 632 => q := to_unsigned(26484,16);
                when 633 => q := to_unsigned(26443,16);
                when 634 => q := to_unsigned(26401,16);
                when 635 => q := to_unsigned(26359,16);
                when 636 => q := to_unsigned(26318,16);
                when 637 => q := to_unsigned(26276,16);
                when 638 => q := to_unsigned(26235,16);
                when 639 => q := to_unsigned(26194,16);
                when 640 => q := to_unsigned(26153,16);
                when 641 => q := to_unsigned(26112,16);
                when 642 => q := to_unsigned(26071,16);
                when 643 => q := to_unsigned(26031,16);
                when 644 => q := to_unsigned(25990,16);
                when 645 => q := to_unsigned(25950,16);
                when 646 => q := to_unsigned(25910,16);
                when 647 => q := to_unsigned(25869,16);
                when 648 => q := to_unsigned(25829,16);
                when 649 => q := to_unsigned(25790,16);
                when 650 => q := to_unsigned(25750,16);
                when 651 => q := to_unsigned(25710,16);
                when 652 => q := to_unsigned(25671,16);
                when 653 => q := to_unsigned(25631,16);
                when 654 => q := to_unsigned(25592,16);
                when 655 => q := to_unsigned(25553,16);
                when 656 => q := to_unsigned(25514,16);
                when 657 => q := to_unsigned(25475,16);
                when 658 => q := to_unsigned(25436,16);
                when 659 => q := to_unsigned(25398,16);
                when 660 => q := to_unsigned(25359,16);
                when 661 => q := to_unsigned(25321,16);
                when 662 => q := to_unsigned(25282,16);
                when 663 => q := to_unsigned(25244,16);
                when 664 => q := to_unsigned(25206,16);
                when 665 => q := to_unsigned(25168,16);
                when 666 => q := to_unsigned(25130,16);
                when 667 => q := to_unsigned(25093,16);
                when 668 => q := to_unsigned(25055,16);
                when 669 => q := to_unsigned(25017,16);
                when 670 => q := to_unsigned(24980,16);
                when 671 => q := to_unsigned(24943,16);
                when 672 => q := to_unsigned(24906,16);
                when 673 => q := to_unsigned(24869,16);
                when 674 => q := to_unsigned(24832,16);
                when 675 => q := to_unsigned(24795,16);
                when 676 => q := to_unsigned(24758,16);
                when 677 => q := to_unsigned(24721,16);
                when 678 => q := to_unsigned(24685,16);
                when 679 => q := to_unsigned(24648,16);
                when 680 => q := to_unsigned(24612,16);
                when 681 => q := to_unsigned(24576,16);
                when 682 => q := to_unsigned(24540,16);
                when 683 => q := to_unsigned(24504,16);
                when 684 => q := to_unsigned(24468,16);
                when 685 => q := to_unsigned(24432,16);
                when 686 => q := to_unsigned(24397,16);
                when 687 => q := to_unsigned(24361,16);
                when 688 => q := to_unsigned(24326,16);
                when 689 => q := to_unsigned(24290,16);
                when 690 => q := to_unsigned(24255,16);
                when 691 => q := to_unsigned(24220,16);
                when 692 => q := to_unsigned(24185,16);
                when 693 => q := to_unsigned(24150,16);
                when 694 => q := to_unsigned(24115,16);
                when 695 => q := to_unsigned(24080,16);
                when 696 => q := to_unsigned(24046,16);
                when 697 => q := to_unsigned(24011,16);
                when 698 => q := to_unsigned(23977,16);
                when 699 => q := to_unsigned(23942,16);
                when 700 => q := to_unsigned(23908,16);
                when 701 => q := to_unsigned(23874,16);
                when 702 => q := to_unsigned(23840,16);
                when 703 => q := to_unsigned(23806,16);
                when 704 => q := to_unsigned(23772,16);
                when 705 => q := to_unsigned(23738,16);
                when 706 => q := to_unsigned(23705,16);
                when 707 => q := to_unsigned(23671,16);
                when 708 => q := to_unsigned(23637,16);
                when 709 => q := to_unsigned(23604,16);
                when 710 => q := to_unsigned(23571,16);
                when 711 => q := to_unsigned(23538,16);
                when 712 => q := to_unsigned(23504,16);
                when 713 => q := to_unsigned(23471,16);
                when 714 => q := to_unsigned(23439,16);
                when 715 => q := to_unsigned(23406,16);
                when 716 => q := to_unsigned(23373,16);
                when 717 => q := to_unsigned(23340,16);
                when 718 => q := to_unsigned(23308,16);
                when 719 => q := to_unsigned(23275,16);
                when 720 => q := to_unsigned(23243,16);
                when 721 => q := to_unsigned(23211,16);
                when 722 => q := to_unsigned(23178,16);
                when 723 => q := to_unsigned(23146,16);
                when 724 => q := to_unsigned(23114,16);
                when 725 => q := to_unsigned(23082,16);
                when 726 => q := to_unsigned(23051,16);
                when 727 => q := to_unsigned(23019,16);
                when 728 => q := to_unsigned(22987,16);
                when 729 => q := to_unsigned(22956,16);
                when 730 => q := to_unsigned(22924,16);
                when 731 => q := to_unsigned(22893,16);
                when 732 => q := to_unsigned(22861,16);
                when 733 => q := to_unsigned(22830,16);
                when 734 => q := to_unsigned(22799,16);
                when 735 => q := to_unsigned(22768,16);
                when 736 => q := to_unsigned(22737,16);
                when 737 => q := to_unsigned(22706,16);
                when 738 => q := to_unsigned(22675,16);
                when 739 => q := to_unsigned(22645,16);
                when 740 => q := to_unsigned(22614,16);
                when 741 => q := to_unsigned(22583,16);
                when 742 => q := to_unsigned(22553,16);
                when 743 => q := to_unsigned(22522,16);
                when 744 => q := to_unsigned(22492,16);
                when 745 => q := to_unsigned(22462,16);
                when 746 => q := to_unsigned(22432,16);
                when 747 => q := to_unsigned(22402,16);
                when 748 => q := to_unsigned(22372,16);
                when 749 => q := to_unsigned(22342,16);
                when 750 => q := to_unsigned(22312,16);
                when 751 => q := to_unsigned(22282,16);
                when 752 => q := to_unsigned(22253,16);
                when 753 => q := to_unsigned(22223,16);
                when 754 => q := to_unsigned(22193,16);
                when 755 => q := to_unsigned(22164,16);
                when 756 => q := to_unsigned(22135,16);
                when 757 => q := to_unsigned(22105,16);
                when 758 => q := to_unsigned(22076,16);
                when 759 => q := to_unsigned(22047,16);
                when 760 => q := to_unsigned(22018,16);
                when 761 => q := to_unsigned(21989,16);
                when 762 => q := to_unsigned(21960,16);
                when 763 => q := to_unsigned(21931,16);
                when 764 => q := to_unsigned(21903,16);
                when 765 => q := to_unsigned(21874,16);
                when 766 => q := to_unsigned(21845,16);
                when 767 => q := to_unsigned(21817,16);
                when 768 => q := to_unsigned(21788,16);
                when 769 => q := to_unsigned(21760,16);
                when 770 => q := to_unsigned(21732,16);
                when 771 => q := to_unsigned(21703,16);
                when 772 => q := to_unsigned(21675,16);
                when 773 => q := to_unsigned(21647,16);
                when 774 => q := to_unsigned(21619,16);
                when 775 => q := to_unsigned(21591,16);
                when 776 => q := to_unsigned(21563,16);
                when 777 => q := to_unsigned(21536,16);
                when 778 => q := to_unsigned(21508,16);
                when 779 => q := to_unsigned(21480,16);
                when 780 => q := to_unsigned(21453,16);
                when 781 => q := to_unsigned(21425,16);
                when 782 => q := to_unsigned(21398,16);
                when 783 => q := to_unsigned(21370,16);
                when 784 => q := to_unsigned(21343,16);
                when 785 => q := to_unsigned(21316,16);
                when 786 => q := to_unsigned(21289,16);
                when 787 => q := to_unsigned(21262,16);
                when 788 => q := to_unsigned(21235,16);
                when 789 => q := to_unsigned(21208,16);
                when 790 => q := to_unsigned(21181,16);
                when 791 => q := to_unsigned(21154,16);
                when 792 => q := to_unsigned(21127,16);
                when 793 => q := to_unsigned(21101,16);
                when 794 => q := to_unsigned(21074,16);
                when 795 => q := to_unsigned(21047,16);
                when 796 => q := to_unsigned(21021,16);
                when 797 => q := to_unsigned(20995,16);
                when 798 => q := to_unsigned(20968,16);
                when 799 => q := to_unsigned(20942,16);
                when 800 => q := to_unsigned(20916,16);
                when 801 => q := to_unsigned(20890,16);
                when 802 => q := to_unsigned(20864,16);
                when 803 => q := to_unsigned(20838,16);
                when 804 => q := to_unsigned(20812,16);
                when 805 => q := to_unsigned(20786,16);
                when 806 => q := to_unsigned(20760,16);
                when 807 => q := to_unsigned(20734,16);
                when 808 => q := to_unsigned(20708,16);
                when 809 => q := to_unsigned(20683,16);
                when 810 => q := to_unsigned(20657,16);
                when 811 => q := to_unsigned(20632,16);
                when 812 => q := to_unsigned(20606,16);
                when 813 => q := to_unsigned(20581,16);
                when 814 => q := to_unsigned(20556,16);
                when 815 => q := to_unsigned(20530,16);
                when 816 => q := to_unsigned(20505,16);
                when 817 => q := to_unsigned(20480,16);
                when 818 => q := to_unsigned(20455,16);
                when 819 => q := to_unsigned(20430,16);
                when 820 => q := to_unsigned(20405,16);
                when 821 => q := to_unsigned(20380,16);
                when 822 => q := to_unsigned(20355,16);
                when 823 => q := to_unsigned(20331,16);
                when 824 => q := to_unsigned(20306,16);
                when 825 => q := to_unsigned(20281,16);
                when 826 => q := to_unsigned(20257,16);
                when 827 => q := to_unsigned(20232,16);
                when 828 => q := to_unsigned(20208,16);
                when 829 => q := to_unsigned(20183,16);
                when 830 => q := to_unsigned(20159,16);
                when 831 => q := to_unsigned(20135,16);
                when 832 => q := to_unsigned(20110,16);
                when 833 => q := to_unsigned(20086,16);
                when 834 => q := to_unsigned(20062,16);
                when 835 => q := to_unsigned(20038,16);
                when 836 => q := to_unsigned(20014,16);
                when 837 => q := to_unsigned(19990,16);
                when 838 => q := to_unsigned(19966,16);
                when 839 => q := to_unsigned(19942,16);
                when 840 => q := to_unsigned(19919,16);
                when 841 => q := to_unsigned(19895,16);
                when 842 => q := to_unsigned(19871,16);
                when 843 => q := to_unsigned(19848,16);
                when 844 => q := to_unsigned(19824,16);
                when 845 => q := to_unsigned(19801,16);
                when 846 => q := to_unsigned(19777,16);
                when 847 => q := to_unsigned(19754,16);
                when 848 => q := to_unsigned(19730,16);
                when 849 => q := to_unsigned(19707,16);
                when 850 => q := to_unsigned(19684,16);
                when 851 => q := to_unsigned(19661,16);
                when 852 => q := to_unsigned(19638,16);
                when 853 => q := to_unsigned(19615,16);
                when 854 => q := to_unsigned(19592,16);
                when 855 => q := to_unsigned(19569,16);
                when 856 => q := to_unsigned(19546,16);
                when 857 => q := to_unsigned(19523,16);
                when 858 => q := to_unsigned(19500,16);
                when 859 => q := to_unsigned(19477,16);
                when 860 => q := to_unsigned(19455,16);
                when 861 => q := to_unsigned(19432,16);
                when 862 => q := to_unsigned(19410,16);
                when 863 => q := to_unsigned(19387,16);
                when 864 => q := to_unsigned(19365,16);
                when 865 => q := to_unsigned(19342,16);
                when 866 => q := to_unsigned(19320,16);
                when 867 => q := to_unsigned(19298,16);
                when 868 => q := to_unsigned(19275,16);
                when 869 => q := to_unsigned(19253,16);
                when 870 => q := to_unsigned(19231,16);
                when 871 => q := to_unsigned(19209,16);
                when 872 => q := to_unsigned(19187,16);
                when 873 => q := to_unsigned(19165,16);
                when 874 => q := to_unsigned(19143,16);
                when 875 => q := to_unsigned(19121,16);
                when 876 => q := to_unsigned(19099,16);
                when 877 => q := to_unsigned(19077,16);
                when 878 => q := to_unsigned(19056,16);
                when 879 => q := to_unsigned(19034,16);
                when 880 => q := to_unsigned(19012,16);
                when 881 => q := to_unsigned(18991,16);
                when 882 => q := to_unsigned(18969,16);
                when 883 => q := to_unsigned(18947,16);
                when 884 => q := to_unsigned(18926,16);
                when 885 => q := to_unsigned(18905,16);
                when 886 => q := to_unsigned(18883,16);
                when 887 => q := to_unsigned(18862,16);
                when 888 => q := to_unsigned(18841,16);
                when 889 => q := to_unsigned(18819,16);
                when 890 => q := to_unsigned(18798,16);
                when 891 => q := to_unsigned(18777,16);
                when 892 => q := to_unsigned(18756,16);
                when 893 => q := to_unsigned(18735,16);
                when 894 => q := to_unsigned(18714,16);
                when 895 => q := to_unsigned(18693,16);
                when 896 => q := to_unsigned(18672,16);
                when 897 => q := to_unsigned(18651,16);
                when 898 => q := to_unsigned(18631,16);
                when 899 => q := to_unsigned(18610,16);
                when 900 => q := to_unsigned(18589,16);
                when 901 => q := to_unsigned(18569,16);
                when 902 => q := to_unsigned(18548,16);
                when 903 => q := to_unsigned(18527,16);
                when 904 => q := to_unsigned(18507,16);
                when 905 => q := to_unsigned(18486,16);
                when 906 => q := to_unsigned(18466,16);
                when 907 => q := to_unsigned(18446,16);
                when 908 => q := to_unsigned(18425,16);
                when 909 => q := to_unsigned(18405,16);
                when 910 => q := to_unsigned(18385,16);
                when 911 => q := to_unsigned(18364,16);
                when 912 => q := to_unsigned(18344,16);
                when 913 => q := to_unsigned(18324,16);
                when 914 => q := to_unsigned(18304,16);
                when 915 => q := to_unsigned(18284,16);
                when 916 => q := to_unsigned(18264,16);
                when 917 => q := to_unsigned(18244,16);
                when 918 => q := to_unsigned(18224,16);
                when 919 => q := to_unsigned(18204,16);
                when 920 => q := to_unsigned(18185,16);
                when 921 => q := to_unsigned(18165,16);
                when 922 => q := to_unsigned(18145,16);
                when 923 => q := to_unsigned(18125,16);
                when 924 => q := to_unsigned(18106,16);
                when 925 => q := to_unsigned(18086,16);
                when 926 => q := to_unsigned(18067,16);
                when 927 => q := to_unsigned(18047,16);
                when 928 => q := to_unsigned(18028,16);
                when 929 => q := to_unsigned(18008,16);
                when 930 => q := to_unsigned(17989,16);
                when 931 => q := to_unsigned(17970,16);
                when 932 => q := to_unsigned(17950,16);
                when 933 => q := to_unsigned(17931,16);
                when 934 => q := to_unsigned(17912,16);
                when 935 => q := to_unsigned(17893,16);
                when 936 => q := to_unsigned(17873,16);
                when 937 => q := to_unsigned(17854,16);
                when 938 => q := to_unsigned(17835,16);
                when 939 => q := to_unsigned(17816,16);
                when 940 => q := to_unsigned(17797,16);
                when 941 => q := to_unsigned(17778,16);
                when 942 => q := to_unsigned(17759,16);
                when 943 => q := to_unsigned(17741,16);
                when 944 => q := to_unsigned(17722,16);
                when 945 => q := to_unsigned(17703,16);
                when 946 => q := to_unsigned(17684,16);
                when 947 => q := to_unsigned(17666,16);
                when 948 => q := to_unsigned(17647,16);
                when 949 => q := to_unsigned(17628,16);
                when 950 => q := to_unsigned(17610,16);
                when 951 => q := to_unsigned(17591,16);
                when 952 => q := to_unsigned(17573,16);
                when 953 => q := to_unsigned(17554,16);
                when 954 => q := to_unsigned(17536,16);
                when 955 => q := to_unsigned(17517,16);
                when 956 => q := to_unsigned(17499,16);
                when 957 => q := to_unsigned(17481,16);
                when 958 => q := to_unsigned(17463,16);
                when 959 => q := to_unsigned(17444,16);
                when 960 => q := to_unsigned(17426,16);
                when 961 => q := to_unsigned(17408,16);
                when 962 => q := to_unsigned(17390,16);
                when 963 => q := to_unsigned(17372,16);
                when 964 => q := to_unsigned(17354,16);
                when 965 => q := to_unsigned(17336,16);
                when 966 => q := to_unsigned(17318,16);
                when 967 => q := to_unsigned(17300,16);
                when 968 => q := to_unsigned(17282,16);
                when 969 => q := to_unsigned(17264,16);
                when 970 => q := to_unsigned(17246,16);
                when 971 => q := to_unsigned(17229,16);
                when 972 => q := to_unsigned(17211,16);
                when 973 => q := to_unsigned(17193,16);
                when 974 => q := to_unsigned(17175,16);
                when 975 => q := to_unsigned(17158,16);
                when 976 => q := to_unsigned(17140,16);
                when 977 => q := to_unsigned(17123,16);
                when 978 => q := to_unsigned(17105,16);
                when 979 => q := to_unsigned(17088,16);
                when 980 => q := to_unsigned(17070,16);
                when 981 => q := to_unsigned(17053,16);
                when 982 => q := to_unsigned(17035,16);
                when 983 => q := to_unsigned(17018,16);
                when 984 => q := to_unsigned(17001,16);
                when 985 => q := to_unsigned(16983,16);
                when 986 => q := to_unsigned(16966,16);
                when 987 => q := to_unsigned(16949,16);
                when 988 => q := to_unsigned(16932,16);
                when 989 => q := to_unsigned(16915,16);
                when 990 => q := to_unsigned(16898,16);
                when 991 => q := to_unsigned(16880,16);
                when 992 => q := to_unsigned(16863,16);
                when 993 => q := to_unsigned(16846,16);
                when 994 => q := to_unsigned(16829,16);
                when 995 => q := to_unsigned(16813,16);
                when 996 => q := to_unsigned(16796,16);
                when 997 => q := to_unsigned(16779,16);
                when 998 => q := to_unsigned(16762,16);
                when 999 => q := to_unsigned(16745,16);
                when 1000 => q := to_unsigned(16728,16);
                when 1001 => q := to_unsigned(16712,16);
                when 1002 => q := to_unsigned(16695,16);
                when 1003 => q := to_unsigned(16678,16);
                when 1004 => q := to_unsigned(16662,16);
                when 1005 => q := to_unsigned(16645,16);
                when 1006 => q := to_unsigned(16629,16);
                when 1007 => q := to_unsigned(16612,16);
                when 1008 => q := to_unsigned(16596,16);
                when 1009 => q := to_unsigned(16579,16);
                when 1010 => q := to_unsigned(16563,16);
                when 1011 => q := to_unsigned(16546,16);
                when 1012 => q := to_unsigned(16530,16);
                when 1013 => q := to_unsigned(16514,16);
                when 1014 => q := to_unsigned(16497,16);
                when 1015 => q := to_unsigned(16481,16);
                when 1016 => q := to_unsigned(16465,16);
                when 1017 => q := to_unsigned(16449,16);
                when 1018 => q := to_unsigned(16432,16);
                when 1019 => q := to_unsigned(16416,16);
                when 1020 => q := to_unsigned(16400,16);
                when 1021 => q := to_unsigned(16384,16);
                when 1022 => q := to_unsigned(16368,16);
                when 1023 => q := to_unsigned(16352,16);
                when others => q := to_unsigned(0,16);
            end case;
            return q;
        end function cbscale;

    begin

        if rst = '1' then

            cbs         <= (others => '0');
            s1_vs       <= '0';
            s1_hs       <= '0';
            s1_vblank   <= '1';
            s1_hblank   <= '1';
            s1_border   <= '0';
            s1_cbe_x    <= '0';
            s1_cbe_y    <= '0';
            s1_cbv      <= (others => '0');
            s1_cbs      <= (others => '0');

            vga_vs      <= '0';
            vga_hs      <= '0';
            vga_vblank  <= '1';
            vga_hblank  <= '1';
            vga_r       <= (others => '0');
            vga_g       <= (others => '0');
            vga_b       <= (others => '0');

        elsif rising_edge(clk) then

            -- infer synchronous 1k x 16 ROM
            cbs <= cbscale(unsigned(h_act(h_act'length-1 downto 1)));

            -- pipeline stage 1
            s1_vs <= raw_vs;
            s1_hs <= raw_hs;
            s1_vblank <= raw_vblank;
            s1_hblank <= raw_hblank;
            s1_border <= '0';
            if
                (shift_right(signed(raw_ax),1) = 0) or   -- left
                (shift_right(signed(raw_ay),1) = 0) or   -- top
                (signed(raw_ax) = resize(signed('0' & h_act),raw_ax'length)-2) or  -- right
                (signed(raw_ax) = resize(signed('0' & h_act),raw_ax'length)-1) or  -- right
                (signed(raw_ay) = resize(signed('0' & v_act),raw_ay'length)-2) or  -- bottom
                (signed(raw_ay) = resize(signed('0' & v_act),raw_ay'length)-1)     -- bottom
            then
                s1_border <= '1';
            end if;
            if s0_cbx = 0 then
                s1_cbe_x <= '1';
            end if;
            if s0_cbx = shift_right(resize(signed('0' & h_act),s0_cbx'length),1) then
                s1_cbe_x <= '0';
            end if;
            if s0_cby >= signed(shift_right(unsigned(v_act),1)) then
                s1_cbe_y <= '0';
                s1_cbs <= "00";
            elsif s0_cby >= signed(shift_right(unsigned(v_act),2)+shift_right(unsigned(v_act),3)) then
                s1_cbe_y <= '1';
                s1_cbs <= "11";
            elsif s0_cby >= signed(shift_right(unsigned(v_act),2)) then
                s1_cbe_y <= '1';
                s1_cbs <= "10";
            elsif s0_cby >= signed(shift_right(unsigned(v_act),3)) then
                s1_cbe_y <= '1';
                s1_cbs <= "01";
            elsif s0_cby >= 0 then
                s1_cbe_y <= '1';
                s1_cbs <= "00";
            end if;
            s1_cbv <= cbs * unsigned(s0_cbx(9 downto 0));
            s1_ax <= raw_ax;
            s1_ay <= raw_ay;

            -- pipeline stage 2 (output)
            vga_vs <= s1_vs;
            vga_hs <= s1_hs;
            vga_vblank <= s1_vblank;
            vga_hblank <= s1_hblank;
            (vga_r,vga_g,vga_b) <= std_logic_vector'(x"000000");
            vga_ax <= s1_ax;
            vga_ay <= s1_ay;
            if s1_vblank = '0' and s1_hblank = '0' then
                -- borders
                if (s1_border = '1') then
                    vga_r <= x"FF"; vga_b <= x"FF"; vga_g <= x"FF";
                -- grid
                elsif
                    (s0_cbx(s0_cbx'length-1 downto 1) = 0) or                                                                                   -- 1/4 h
                    (s0_cbx(s0_cbx'length-1 downto 1) = shift_right(resize(signed('0' & h_act(h_act'length-1 downto 1)),s0_cbx'length),2)) or   -- 1/2 h
                    (s0_cbx(s0_cbx'length-1 downto 1) = shift_right(resize(signed('0' & h_act(h_act'length-1 downto 1)),s0_cbx'length),1)) or   -- 3/4 h
                    (s0_cby(s0_cby'length-1 downto 1) = 0) or                                                                                   -- 1/4 v
                    (s0_cby(s0_cby'length-1 downto 1) = shift_right(resize(signed('0' & v_act(v_act'length-1 downto 1)),s0_cby'length),2)) or   -- 1/2 v
                    (s0_cby(s0_cby'length-1 downto 1) = shift_right(resize(signed('0' & v_act(v_act'length-1 downto 1)),s0_cby'length),1))      -- 3/4 v
                then
                    vga_r <= x"80"; vga_b <= x"80"; vga_g <= x"80";
                -- colour bars
                elsif s1_cbe_x = '1' and s1_cbe_y = '1' then
                    case s1_cbs is
                        when "00" => vga_r <= std_logic_vector(s1_cbv(23 downto 16));
                        when "01" => vga_g <= std_logic_vector(s1_cbv(23 downto 16));
                        when "10" => vga_b <= std_logic_vector(s1_cbv(23 downto 16));
                        when others =>
                            vga_r <= std_logic_vector(s1_cbv(23 downto 16));
                            vga_g <= std_logic_vector(s1_cbv(23 downto 16));
                            vga_b <= std_logic_vector(s1_cbv(23 downto 16));
                    end case;
                end if;
            end if;

        end if;

    end process;

end architecture synth;
