#!/bin/bash
# shellcheck disable=SC2016

# Copyright (C) 2020-2021 Maddison Hellstrom <https://github.com/b0o>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <https://www.gnu.org/licenses/>.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -Eeuo pipefail
shopt -s inherit_errexit

declare -g basedir reporoot readme prog
basedir="$(realpath -e "$(dirname "$(readlink -e "${BASH_SOURCE[0]}")")")"
reporoot="$(realpath -e "$basedir/..")"
readme="$reporoot/README.md"
prog="${reporoot}/refind-genconf"

declare -gA sections=()

sections[USAGE]="$(printf '```\n%s\n```' "$("$prog" -h 2>&1)")"
sections[CONF]="$(printf '```bash\n%s\n```' "$("$prog" -X 2>&1)")"
sections[RESULT]="$(printf '```conf\n%s\n```' "$("$prog" -c <("$prog" -X 2>&1) | sed 's/\\/\\\\/g')")"
sections[LICENSE]="$(
  cat << EOF
&copy; 2020-$(date +%Y) Maddison Hellstrom

Released under the GNU General Public License, version 3.0 or later.
EOF
)"

function regen_section() {
  local section="$1"
  local content="$2"
  awk -v "section=$section" -v "content=$content" '
    BEGIN {
      d = 0
    }

    {
      if (match($0, "<!-- " section " -->")) {
        d = 1
        print $0
        print content
        next
      }
      if (match($0, "<!-- /" section " -->")) {
        d = 0
        print $0
        next
      }
    }

    d == 0 {
      print $0
    }
  ' "$readme"
}

for sec in "${!sections[@]}"; do
  regen_section "$sec" "${sections[$sec]}" > "${readme}_"
  mv "${readme}_" "$readme"
done
