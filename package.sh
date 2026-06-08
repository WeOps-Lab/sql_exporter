#!/usr/bin/env bash
#
# package.sh — 构建 WeOps sql_exporter 各数据库监控探针安装包。
#
# 每个包针对一种数据库类型，打包：
#   - 仅编入该数据库驱动的 sql_exporter 跨平台二进制（linux/amd64, linux/arm64, windows/amd64）
#   - 该数据库的 collector YAML 与 README
# 并压缩为 dist/<plugin_id>_<version>.zip。
#
# 用法：
#   ./package.sh <db> [<db> ...]   构建一个或多个数据库的包
#   ./package.sh all-packages      构建注册表中全部包
#   ./package.sh -l | --list       列出可用数据库
#   ./package.sh -h | --help       显示帮助
#
# 示例：
#   ./package.sh polardb_pg              # 单个
#   ./package.sh polardb_pg dm mssql     # 多个
#   ./package.sh all-packages            # 全部
#
# 环境变量（可选）：
#   GO=/path/to/go      指定 Go 工具链（默认自动探测）
#   PLATFORMS=...       目标平台，逗号分隔（默认 linux/amd64,linux/arm64,windows/amd64）
#   OUTPUT_DIR=...      产物目录（默认 ./dist）

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BK_PKG_DIR="${ROOT_DIR}/weops/pipe-tools/bk_pkg"
OUTPUT_DIR="${OUTPUT_DIR:-${ROOT_DIR}/dist}"
IFS=',' read -r -a PLATFORMS <<< "${PLATFORMS:-linux/amd64,linux/arm64,windows/amd64}"

# 包注册表：  db_type  driver_profile  plugin_id  display_name(最后一列，可含空格)
# 注：driver_profile 必须是 drivers_gen.go 中已定义的 profile（构建前会校验）。
#     PostgreSQL 系（vastbase / polardb_pg）使用 postgres profile（仅 github.com/lib/pq）；
#     若 drivers_gen.go 尚未定义该 profile，需先补上（一行）再打包这两个库。
read -r -d '' REGISTRY <<'EOF' || true
minimal     minimal    weops_minimal_exporter     通用数据库监控探针(基础版)
all         all        weops_all_exporter         通用数据库监控探针(全量版)
dm          dm         weops_dm_exporter          达梦数据库监控探针
mssql       mssql      weops_mssql_exporter       SQL Server数据库监控探针
kingbase    kingbase   weops_kingbase_exporter    人大金仓数据库监控探针
opengauss   opengauss  weops_opengauss_exporter   openGauss数据库监控探针
gbase8a     gbase8a    weops_gbase8a_exporter     GBase8a数据库监控探针
oceanbase   oceanbase  weops_oceanbase_exporter   OceanBase数据库监控探针
sybase      sybase     weops_sybase_exporter      Sybase数据库监控探针
vastbase    postgres   weops_vastbase_exporter    海量数据库监控探针
polardb_pg  postgres   weops_polardb_pg_exporter  PolarDB(PG)数据库监控探针
EOF

# ---------- 日志 ----------
log()  { printf '\033[1;34m>>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }
require_cmd() { command -v "$1" >/dev/null 2>&1 || die "缺少命令: $1"; }

usage() { sed -n '2,40p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; }

registry_rows() { printf '%s\n' "${REGISTRY}" | sed '/^[[:space:]]*$/d'; }

list_dbs() {
  printf '%-12s %-10s %-26s %s\n' "DB" "PROFILE" "PLUGIN_ID" "名称"
  registry_rows | while read -r db profile plugin display; do
    printf '%-12s %-10s %-26s %s\n' "${db}" "${profile}" "${plugin}" "${display}"
  done
}

# 在注册表中查 db；命中则设置 DB/PROFILE/PLUGIN/DISPLAY 并返回 0
lookup() {
  local want="$1" db profile plugin display
  while read -r db profile plugin display; do
    [ "${db}" = "${want}" ] || continue
    DB="${db}"; PROFILE="${profile}"; PLUGIN="${plugin}"; DISPLAY="${display}"
    return 0
  done < <(registry_rows)
  return 1
}

# ---------- Go 工具链 ----------
resolve_go() {
  export GOTOOLCHAIN="${GOTOOLCHAIN:-local}"
  local c bindir root candidates=()
  [ -n "${GO:-}" ] && candidates+=("${GO}")
  candidates+=("go")
  for c in "${HOME}"/sdk/go*/bin/go "${HOME}"/go/go*/bin/go /usr/local/go/bin/go /opt/homebrew/bin/go; do
    [ -x "${c}" ] && candidates+=("${c}")
  done
  for c in "${candidates[@]}"; do
    { command -v "${c}" >/dev/null 2>&1 || [ -x "${c}" ]; } || continue
    # 由二进制位置反推 GOROOT（上两级），覆盖持久化/环境里可能写错的 GOROOT
    bindir="$(cd "$(dirname "$(command -v "${c}")")" 2>/dev/null && pwd || true)"
    [ -n "${bindir}" ] || continue
    root="$(cd "${bindir}/.." && pwd)"
    if GOROOT="${root}" "${c}" version >/dev/null 2>&1; then
      GO="${c}"; export GOROOT="${root}"; return 0
    fi
    # 退路：若环境/持久化里的 GOROOT 本就正确，直接用
    if "${c}" version >/dev/null 2>&1; then GO="${c}"; return 0; fi
  done
  die "找不到可用的 Go 工具链，请用 GO=/path/to/go 指定（或修正 go env -w GOROOT）"
}

resolve_version() {
  local tag
  tag="$(git -C "${ROOT_DIR}" describe --tags --exact-match 2>/dev/null || true)"
  if [ -n "${tag}" ]; then printf '%s' "${tag#v}"; return; fi
  git -C "${ROOT_DIR}" rev-parse --short HEAD 2>/dev/null || printf 'dev'
}

build_ldflags() {
  local v="$1" rev branch user date p="github.com/prometheus/common/version"
  rev="$(git -C "${ROOT_DIR}" rev-parse HEAD 2>/dev/null || echo unknown)"
  branch="$(git -C "${ROOT_DIR}" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  user="$(id -un 2>/dev/null || echo unknown)@$(hostname -s 2>/dev/null || echo unknown)"
  date="$(date +%Y%m%d-%H:%M:%S)"
  printf -- '-X %s.Version=%s -X %s.Revision=%s -X %s.Branch=%s -X %s.BuildUser=%s -X %s.BuildDate=%s -s -w' \
    "${p}" "${v}" "${p}" "${rev}" "${p}" "${branch}" "${p}" "${user}" "${p}" "${date}"
}

# ---------- 构建 ----------
# 校验 driver profile 是否在 drivers_gen.go 中定义，避免 drivers_gen.go 对未知
# profile 静默“Nonexistent key. Do nothing.”后用错误的 drivers.go 继续构建。
ensure_profile() {
  local profile="$1"
  grep -qE "^[[:space:]]*\"${profile}\":[[:space:]]*\{" "${ROOT_DIR}/drivers_gen.go" \
    || die "driver profile '${profile}' 未在 drivers_gen.go 中定义；请先补充该 profile 再打包"
}

generate_drivers() {
  local profile="$1"
  ensure_profile "${profile}"
  log "生成 drivers.go (profile=${profile})"
  ( cd "${ROOT_DIR}"
    "${GO}" get github.com/dave/jennifer/jen        # drivers_gen.go 的代码生成依赖
    "${GO}" run drivers_gen.go -- "${profile}"
    "${GO}" mod tidy                                # 按新 drivers.go 整理依赖
  )
}

build_binaries() {
  local plugin="$1" version="$2" bindir="$3"
  local ldflags spec os arch ext out
  ldflags="$(build_ldflags "${version}")"
  rm -rf "${bindir}"; mkdir -p "${bindir}"
  for spec in "${PLATFORMS[@]}"; do
    IFS='/' read -r os arch <<< "${spec}"
    ext=""; [ "${os}" = windows ] && ext=".exe"
    out="${bindir}/${plugin}_${os}_${arch}${ext}"
    log "构建 ${os}/${arch} -> $(basename "${out}")"
    ( cd "${ROOT_DIR}"
      GOOS="${os}" GOARCH="${arch}" CGO_ENABLED=0 \
        "${GO}" build -trimpath -ldflags "${ldflags}" -o "${out}" ./cmd/sql_exporter )
  done
}

make_zip() {
  local db="$1" plugin="$2" version="$3"
  local src="${BK_PKG_DIR}/${db}" stage="${OUTPUT_DIR}/.stage/${plugin}"
  require_cmd zip
  rm -rf "${stage}"; mkdir -p "${stage}"
  cp "${src}"/*.collector*.yml "${stage}"/ 2>/dev/null || warn "${db}: 未找到 collector yml"
  [ -f "${src}/README.md" ] && cp "${src}/README.md" "${stage}"/
  cp -R "${src}/bin" "${stage}/bin"
  local zipfile="${OUTPUT_DIR}/${plugin}_${version}.zip"
  rm -f "${zipfile}"
  ( cd "${OUTPUT_DIR}/.stage" && zip -rq "${zipfile}" "${plugin}" -x '*.DS_Store' )
  rm -rf "${OUTPUT_DIR}/.stage"
  printf '%s' "${zipfile}"
}

build_package() {
  local db="$1" version="$2"
  lookup "${db}" || die "未知数据库: ${db}（用 --list 查看）"
  [ -d "${BK_PKG_DIR}/${DB}" ] || die "缺少包目录: weops/pipe-tools/bk_pkg/${DB}"
  log "打包 ${DISPLAY}  [db=${DB} profile=${PROFILE} plugin=${PLUGIN}]"
  generate_drivers "${PROFILE}"
  build_binaries "${PLUGIN}" "${version}" "${BK_PKG_DIR}/${DB}/bin"
  local zipfile; zipfile="$(make_zip "${DB}" "${PLUGIN}" "${version}")"
  log "完成: ${zipfile}"
  BUILT+=("${zipfile}")
}

main() {
  local args=() a
  for a in "$@"; do
    case "${a}" in
      -h|--help) usage; exit 0 ;;
      -l|--list) list_dbs; exit 0 ;;
      -*) die "未知选项: ${a}（用 --help 查看）" ;;
      *) args+=("${a}") ;;
    esac
  done

  require_cmd git
  resolve_go

  local version; version="$(resolve_version)"

  local targets=() db
  if [ "${#args[@]}" -eq 0 ] || { [ "${#args[@]}" -eq 1 ] && [ "${args[0]}" = all-packages ]; }; then
    while read -r db _; do targets+=("${db}"); done < <(registry_rows)
  else
    targets=("${args[@]}")
  fi

  mkdir -p "${OUTPUT_DIR}"
  log "go: $("${GO}" version)"
  log "version: ${version}"
  log "targets: ${targets[*]}"

  BUILT=()
  for db in "${targets[@]}"; do build_package "${db}" "${version}"; done

  log "全部完成，产物："
  local z
  for z in "${BUILT[@]}"; do printf '   %s\n' "${z}"; done
}

main "$@"
