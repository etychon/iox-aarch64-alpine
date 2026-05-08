#!/bin/sh

# Show banner only for interactive terminal sessions.
if [ -z "${PS1:-}" ] || [ ! -t 1 ]; then
  return 0 2>/dev/null || exit 0
fi

# Avoid duplicate output in nested interactive shells.
if [ "${IOX_BANNER_SHOWN:-0}" = "1" ]; then
  return 0 2>/dev/null || exit 0
fi
export IOX_BANNER_SHOWN=1

APP_NAME="${IOX_APP_NAME:-iox-aarch64-alpine}"
APP_VERSION="${IOX_APP_VERSION:-unknown}"
APP_AUTHOR="${IOX_APP_AUTHOR:-Emmanuel Tychon}"

printf '\n'
printf '============================================================\n'
printf ' Cisco IOx App Console\n'
printf '------------------------------------------------------------\n'
printf ' App     : %s\n' "${APP_NAME}"
printf ' Version : %s\n' "${APP_VERSION}"
printf ' Author  : %s\n' "${APP_AUTHOR}"
printf '------------------------------------------------------------\n'
printf ' NOTICE: Authorized users only.\n'
printf ' NOTICE: Commands executed here may impact router/switch behavior.\n'
printf ' NOTICE: Validate serial/USB/DIO operations in a controlled environment.\n'
printf '============================================================\n'
printf '\n'
