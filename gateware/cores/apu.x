// Copyright 2023 The XLS Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import std


const DUTY_WAVES = [u8:0b1000_0000, u8:0b1100_0000, u8:0b1111_0000, u8:0b0011_1111];

enum DutySel: u2 {
  p12_5 = 0,
  p25   = 1,
  p50   = 2,
  p75   = 3,
}

struct ApuPulseState {
  timer: u11,
  period: u11,
  duty: DutySel,
  pos: u3,
}

proc apu_pulse {
  period_r: chan<u11> in;
  duty_r: chan<DutySel> in;
  output_s: chan<u1> out;

  init {
    ApuPulseState{ period: u11:0, timer: u11:0, duty: DutySel::p12_5, pos: u3:0 }
  }

  config(period_r: chan<u11> in, duty_r: chan<DutySel> in, output_s: chan<u1> out) {
    (period_r, duty_r, output_s)
  }

  next(tok: token, state: ApuPulseState) {
    let (tok', period', period'_vld) = recv_non_blocking(tok, period_r, state.period);
    let (tok'', duty', duty'_vld) = recv_non_blocking(tok, duty_r, state.duty);
    let tok = join(tok', tok'');
    let (timer', pos') = if (state.timer == u11:0) {
      let sig = DUTY_WAVES[duty' as u2][state.pos+:u1];
      let tok = send(tok, output_s, sig);
      (period', state.pos - u3:1)
    } else {
      (state.timer - u11:1, state.pos)
    };
    let _ = trace!(timer');
    ApuPulseState{ period: period', timer: timer', duty: duty', pos: pos' }
  }
}

#[test_proc]
proc apu_pulse_test {
  terminator: chan<bool> out;
  period_s: chan<u11> out;
  period_r: chan<u11> in;
  duty_s: chan<DutySel> out;
  duty_r: chan<DutySel> in;
  output_s: chan<u1> out;
  output_r: chan<u1> in;

  init {
    ()
  }

  config(t: chan<bool> out) {
    let (period_s, period_r) = chan<u11>;
    let (duty_s, duty_r) = chan<DutySel>;
    let (output_s, output_r) = chan<u1>;
    spawn apu_pulse(period_r, duty_r, output_s);
    (t, period_s, period_r, duty_s, duty_r, output_s, output_r)
  }

  next(tok: token, state: ()) {
    let tok' = send(tok, period_s, u11:4);
    let tok'' = send(tok, duty_s, DutySel::p12_5);
    let tok = join(tok', tok'');
    let (wave, tok) = for (i, (wave, tok)) in u32:0..u32:8 {
      let (tok, sig) = recv(tok, output_r);
      (wave | ((sig as u8) << (u32:7 - i)), tok)
    }((u8:0, tok));
    let _ = assert_eq(wave, u8:0b0100_0000);

    let tok = send(tok, duty_s, DutySel::p25);
    let (wave, tok) = for (i, (wave, tok)) in u32:0..u32:8 {
      let (tok, sig) = recv(tok, output_r);
      (wave | ((sig as u8) << (u32:7 - i)), tok)
    }((u8:0, tok));
    let _ = assert_eq(wave, u8:0b0110_0000);

    let tok = send(tok, duty_s, DutySel::p50);
    let (wave, tok) = for (i, (wave, tok)) in u32:0..u32:4 {
      let (tok, sig) = recv(tok, output_r);
      (wave | ((sig as u8) << (u32:7 - i)), tok)
    }((u8:0, tok));
    let tok = send(tok, duty_s, DutySel::p75);
    let (wave, tok) = for (i, (wave, tok)) in u32:4..u32:8 {
      let (tok, sig) = recv(tok, output_r);
      (wave | ((sig as u8) << (u32:7 - i)), tok)
    }((wave, tok));
    let _ = assert_eq(wave, u8:0b0111_1111);

    let tok = send(tok, terminator, true);
    ()
  }
}
