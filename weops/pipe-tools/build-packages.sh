#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
MANIFEST_FILE="${SCRIPT_DIR}/packages.yaml"
GO_BIN="go"
GO_ROOT=""
PLATFORMS=(
  "linux:amd64:linux_amd64"
  "linux:arm64:linux_arm64"
  "windows:amd64:windows_amd64"
)

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "missing required command: $1" >&2
    exit 1
  }
}

resolve_go_toolchain() {
  local candidate_go=""
  local candidate_root=""

  if command -v go >/dev/null 2>&1; then
    if go version >/dev/null 2>&1; then
      GO_BIN="$(command -v go)"
      GO_ROOT="$(go env GOROOT 2>/dev/null || true)"
      return 0
    fi
  fi

  for candidate_go in \
    "/Users/fanzhongming/go/go1.24.3/bin/go" \
    "/usr/local/go/bin/go"; do
    if [[ -x "${candidate_go}" ]] && "${candidate_go}" version >/dev/null 2>&1; then
      GO_BIN="${candidate_go}"
      candidate_root="$(${candidate_go} env GOROOT 2>/dev/null || true)"
      GO_ROOT="${candidate_root}"
      return 0
    fi
  done

  echo "unable to find a working Go toolchain" >&2
  exit 1
}

run_go() {
  GOROOT="${GO_ROOT}" PATH="$(dirname "${GO_BIN}"):${PATH}" "${GO_BIN}" "$@"
}

run_make() {
  GOROOT="${GO_ROOT}" PATH="$(dirname "${GO_BIN}"):${PATH}" make "$@"
}

resolve_version() {
  local tag
  tag="$(git -C "${REPO_ROOT}" describe --tags --exact-match 2>/dev/null || true)"
  if [[ -n "${tag}" ]]; then
    printf '%s' "${tag#v}"
    return 0
  fi

  git -C "${REPO_ROOT}" rev-parse --short HEAD
}

build_ldflags() {
  local version="$1"
  local revision branch build_user build_date

  revision="$(git -C "${REPO_ROOT}" rev-parse HEAD)"
  branch="$(git -C "${REPO_ROOT}" rev-parse --abbrev-ref HEAD)"
  build_user="$(id -un 2>/dev/null || echo unknown)@$(hostname 2>/dev/null || echo unknown)"
  build_date="$(date +%Y%m%d-%H:%M:%S)"

  printf '%s' "-X github.com/prometheus/common/version.Version=${version} -X github.com/prometheus/common/version.Revision=${revision} -X github.com/prometheus/common/version.Branch=${branch} -X github.com/prometheus/common/version.BuildUser=${build_user} -X github.com/prometheus/common/version.BuildDate=${build_date} -s -w"
}

list_packages() {
  awk '
    $1 == "-" && $2 == "name:" { print $3 }
  ' "${MANIFEST_FILE}"
}

resolve_package_name() {
  local target="$1"

  if awk -v pkg="${target}" '
    $1 == "-" && $2 == "name:" && $3 == pkg { found = 1 }
    END { exit(found ? 0 : 1) }
  ' "${MANIFEST_FILE}"; then
    printf '%s' "${target}"
    return 0
  fi

  awk -v db="${target}" '
    $1 == "-" && $2 == "name:" { current = $3; next }
    $1 == "db:" && $2 == db { print current; exit }
  ' "${MANIFEST_FILE}"
}

load_package() {
  local pkg_name="$1"
  awk -v pkg="${pkg_name}" '
    $1 == "-" && $2 == "name:" {
      in_pkg = ($3 == pkg)
      next
    }
    in_pkg && $1 == "db:" { print "db=" $2 }
    in_pkg && $1 == "driver_profile:" { print "driver_profile=" $2 }
    in_pkg && $1 == "bk_pkg_dir:" { print "bk_pkg_dir=" $2 }
    in_pkg && $1 == "plugin_id:" { print "plugin_id=" $2 }
    in_pkg && $1 == "display_name:" {
      sub(/^display_name:[[:space:]]*/, "")
      print "display_name=" $0
    }
    in_pkg && $1 == "readme:" { print "readme=" $2 }
  ' "${MANIFEST_FILE}"
}

build_package() {
  local pkg_name="$1"
  local version="$2"
  local db=""
  local driver_profile=""
  local bk_pkg_dir=""
  local plugin_id=""
  local display_name=""
  local readme=""

  while IFS='=' read -r key value; do
    case "${key}" in
      db) db="${value}" ;;
      driver_profile) driver_profile="${value}" ;;
      bk_pkg_dir) bk_pkg_dir="${value}" ;;
      plugin_id) plugin_id="${value}" ;;
      display_name) display_name="${value}" ;;
      readme) readme="${value}" ;;
    esac
  done < <(load_package "${pkg_name}")

  if [[ -z "${driver_profile}" || -z "${bk_pkg_dir}" || -z "${plugin_id}" || -z "${display_name}" || -z "${readme}" ]]; then
    echo "invalid package definition for ${pkg_name}" >&2
    exit 1
  fi

  local source_bk_pkg_dir="${SCRIPT_DIR}/${bk_pkg_dir}"
  local source_bin_dir="${source_bk_pkg_dir}/bin"

  echo ">> building ${pkg_name} (db=${db}, driver=${driver_profile}, version=${version})"
  run_make -C "${REPO_ROOT}" "drivers-${driver_profile}"

  rm -rf "${source_bin_dir}"
  mkdir -p "${source_bin_dir}"
  build_platform_binaries "${source_bin_dir}" "${pkg_name}" "${version}"
  echo ">> binaries staged in ${source_bin_dir}"
}

build_platform_binaries() {
  local target_bin_dir="$1"
  local pkg_name="$2"
  local version="$3"
  local platform_spec=""
  local goos=""
  local goarch=""
  local output_name=""
  local packaged_binary_name=""
  local output_path=""
  local ldflags=""
  local output_suffix=""

  ldflags="$(build_ldflags "${version}")"

  for platform_spec in "${PLATFORMS[@]}"; do
    IFS=':' read -r goos goarch output_name <<< "${platform_spec}"

    output_suffix=""
    if [[ "${goos}" == "windows" ]]; then
      output_suffix=".exe"
    fi

    packaged_binary_name="${pkg_name}_${output_name}${output_suffix}"
    output_path="${target_bin_dir}/${packaged_binary_name}"
    GOROOT="${GO_ROOT}" PATH="$(dirname "${GO_BIN}"):${PATH}" GOOS="${goos}" GOARCH="${goarch}" CGO_ENABLED=0 "${GO_BIN}" -C "${REPO_ROOT}" build -trimpath -ldflags "${ldflags}" -o "${output_path}" ./cmd/sql_exporter
  done
}

main() {
  require_cmd git
  require_cmd make
  resolve_go_toolchain

  local version
  version="$(resolve_version)"

  local targets=()
  local resolved_pkg=""
  if [[ $# -eq 0 || "$1" == "all-packages" ]]; then
    while IFS= read -r pkg; do
      targets+=("${pkg}")
    done < <(list_packages)
  else
    for pkg in "$@"; do
      resolved_pkg="$(resolve_package_name "${pkg}")"
      if [[ -z "${resolved_pkg}" ]]; then
        echo "unknown package or db: ${pkg}" >&2
        exit 1
      fi
      targets+=("${resolved_pkg}")
    done
  fi

  if git -C "${REPO_ROOT}" describe --tags --exact-match >/dev/null 2>&1; then
    echo ">> release tag: v${version}"
  else
    echo ">> release version (untagged): ${version}"
  fi
  echo ">> go toolchain: $("${GO_BIN}" version)"
  echo ">> targets: ${targets[*]}"

  for pkg in "${targets[@]}"; do
    build_package "${pkg}" "${version}"
  done

  echo ">> done, binaries are under each bk_pkg/<db>/bin directory"
}

main "$@"
