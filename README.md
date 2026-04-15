# HeidiSQL Lazarus/FreePascal port
[![Build Status](https://github.com/acosonic/HeidiSQL/actions/workflows/lazarus.yaml/badge.svg?branch=lazarus)](https://github.com/acosonic/HeidiSQL/actions)
[![Supports Windows](https://img.shields.io/badge/support-Windows-blue?logo=Windows)](https://github.com/HeidiSQL/HeidiSQL/releases/latest)
[![Supports Linux](https://img.shields.io/badge/support-Linux-yellow?logo=Linux)](https://github.com/HeidiSQL/HeidiSQL/releases/latest)
[![Supports macOS](https://img.shields.io/badge/support-macOS-black?logo=macOS)](https://github.com/HeidiSQL/HeidiSQL/releases/latest)
[![License](https://img.shields.io/github/license/HeidiSQL/HeidiSQL?logo=github)](https://github.com/HeidiSQL/HeidiSQL/blob/main/LICENSE)
[![Latest Release](https://img.shields.io/github/v/release/HeidiSQL/HeidiSQL?label=latest%20release&logo=github)](https://github.com/HeidiSQL/HeidiSQL/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/HeidiSQL/HeidiSQL/total?logo=github)](https://github.com/HeidiSQL/HeidiSQL/releases)


This is the code base for compiling HeidiSQL on Linux and macOS. From v13 onwards, the Windows version
will be compiled from here.

Since February 2025 I am migrating the sources from the master branch, using Lazarus and FreePascal. I
left away some Windows-only stuff which won't ever work on other platforms, such as some Windows message
handlings, and ADO driver usage. Therefore, support for MS SQL is being redeveloped via FreeTDS
(formerly ADO), but is not yet fully mature.  

Ansgar

![HeidiSQL GTK2 running on Ubuntu Linux 22.04](https://www.heidisql.com/images/screenshots/linux_version_datagrid.png)

---

## acosonic/lazarus branch additions

This fork's `lazarus` branch extends the upstream with the following features:

### Oracle OCI support
Native Oracle connectivity via OCI (Oracle Call Interface) — no ODBC or third-party middleware required.

- Connects using Easy Connect string (`host:port/service_name`)
- Auto-detects `SYS` user and connects with `SYSDBA` privilege
- Schema browsing: all Oracle schemas (users) shown as "databases" in the tree
- `ALTER SESSION SET CURRENT_SCHEMA` issued on schema selection, so queries work without a schema prefix
- Data grid: uses `FETCH NEXT n ROWS ONLY` on Oracle 12c+, `ROWNUM` wrapper on older versions
- Table columns, keys, foreign keys, and CREATE code via `DBMS_METADATA.GET_DDL`
- Cyrillic and other non-ASCII text rendered correctly (`NLS_LANG=AMERICAN_AMERICA.AL32UTF8`)
- Lightweight keep-alive via `OCIPing` (no recursive query calls)

### AI SQL generation
Generate SQL queries from natural language using the Anthropic Claude API.

- API key and model configured in Preferences → AI
- Schema context (tables + columns) is automatically included in the prompt
- Column metadata is pre-cached in the background after connecting so generation is instant
- Robot icon on the AI tab; prompt strip positioned at the top of the query editor

### Other improvements
- `Ctrl+W` closes the active query tab (Ctrl+F4 kept as secondary shortcut)
- Row viewer dialog with inline editing support
- Wayland auto-detection on Linux
- Background DB structure cache warm-up after connection

---

### Building
Install Lazarus 4.4 and FreePascal. Then load the `.lpi` file in the root directory in the Lazarus IDE.
Alternatively, use `/usr/bin/lazbuild heidisql.lpi` on the command line.

### Icons8 copyright
Icons added in January 2019 are copyright by [Icons8](https://icons8.com). Used with a special permission
from Icons8 given to Ansgar for this project only. Do not copy them for anything else other than building
HeidiSQL.

[![Lazarus logo.](https://www.heidisql.com/images/powered-by-lazarus.png)](https://www.lazarus-ide.org/)

