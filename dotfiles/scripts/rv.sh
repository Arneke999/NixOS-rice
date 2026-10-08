# rv: build, run and debug RISC-V assembly on this laptop (no RISC-V board needed;
# QEMU runs the program). Installed as the `rv` command by home/home.nix (Nix wraps
# this file with the toolchain on PATH, and shellchecks it at build time).
#
#   rv run   prog.s [args…]   assemble + link + run; prints the exit code (a0 at exit)
#   rv build prog.s           just build → ./prog (a RISC-V ELF)
#   rv debug prog.s           run paused under gdb: registers + source, step with `si`
#   rv dump  prog.s           disassemble: the machine code (hex) of every instruction
#
# RV32 by default; put -64 before the command for RV64:  rv -64 run prog.s
#
# Entry point: `_start:` for a bare program (exit with ecall 93), or `main:` to link
# the C library (printf etc.; return from main to exit).
# Syscalls are LINUX ones here: a7=64 write, a7=63 read, a7=93 exit. RARS uses its
# own numbers (a7=1 print int, a7=4 print string, a7=10 exit): open those in RARS.

usage() {
  cat <<'EOF'
rv: build, run and debug RISC-V assembly (QEMU)

  rv run   prog.s [args…]   assemble + link + run; prints the exit code (a0 at exit)
  rv build prog.s           just build → ./prog
  rv debug prog.s           run paused under gdb (registers + source); si = step
  rv dump  prog.s           disassemble: machine code (hex) of every instruction

  RV32 by default; -64 before the command for RV64:  rv -64 run prog.s
  Entry: _start: (bare, exit via ecall a7=93) or main: (C library, return to exit).
  Linux syscalls: a7=64 write, 63 read, 93 exit. (RARS numbering differs.)
EOF
}
die()   { echo "rv: $*" >&2; exit 1; }

xlen=32
while [[ ${1:-} == -* ]]; do
  case $1 in
    -32) xlen=32 ;;
    -64) xlen=64 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option: $1 (try rv --help)" ;;
  esac
  shift
done

cmd=${1:-}; src=${2:-}
if [[ -z $cmd || -z $src ]]; then usage; exit 1; fi
shift 2
[[ -f $src ]] || die "no such file: $src"

tri=riscv$xlen-unknown-linux-gnu
out=${src%.*}
[[ $out != "$src" ]] || out=$src.out
exe=$out; [[ $exe == */* ]] || exe=./$exe   # path to run: keep dir/abs paths, else ./prog
has_main() { grep -qE '^[[:space:]]*main:' "$src"; }

build() {
  # gcc drives the assembler + linker (and preprocesses .S files). -g keeps the
  # source line info, so gdb and `rv dump` can show your code next to each instruction.
  # -march=rv32g/rv64g: no "C" (compressed) extension, so every instruction is the
  # 32-bit encoding from the course/reference card (the toolchain default rv32gc turns
  # e.g. `li a0,1` into 16-bit 4505). Same ABI, so linking the C library still works.
  local flags=(-g "-march=rv${xlen}g")
  has_main || flags+=(-nostdlib)
  "$tri-gcc" "${flags[@]}" -o "$out" "$src"
}

case $cmd in
  build)
    build && echo "built $exe (RV$xlen)"
    ;;
  run)
    build
    set +e
    "qemu-riscv$xlen" "$exe" "$@"
    rc=$?
    set -e
    printf '\n\033[2m[exit code %d]\033[0m\n' "$rc" >&2
    exit "$rc"
    ;;
  debug)
    build
    port=$(( 20000 + RANDOM % 20000 ))
    "qemu-riscv$xlen" -g "$port" "$exe" "$@" &
    qpid=$!
    trap 'kill "$qpid" 2>/dev/null || true' EXIT
    stop=()
    if has_main; then stop=(-ex "break main" -ex "continue"); fi
    # Stopped at the first instruction. si = step one instruction, ni = step over a
    # call, c = continue, info registers / p $a0 / x/4wx &label, q = quit.
    gdb -q "$exe" \
      -ex "target remote :$port" \
      "${stop[@]}" \
      -ex "layout src" -ex "layout regs" -ex "focus cmd"
    ;;
  dump)
    build
    "$tri-objdump" -d -S "$out"
    ;;
  *)
    die "unknown command: $cmd (run | build | debug | dump)"
    ;;
esac
