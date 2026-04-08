<style>
  body { font-family: "Courier New", monospace; font-size: 9px; margin: 0.3in; line-height: 1.3; }
  h1 { font-size: 14px; text-align: center; margin: 0 0 6px; border-bottom: 2px solid #000; padding-bottom: 4px; }
  h2 { font-size: 10px; margin: 6px 0 2px; background: #000; color: #fff; padding: 1px 4px; }
  .cols { column-count: 3; column-gap: 12px; }
  .col-break { break-inside: avoid; }
  table { width: 100%; border-collapse: collapse; font-size: 9px; margin: 0; }
  td:first-child { font-weight: bold; white-space: nowrap; width: 38%; }
  td { padding: 0 2px; }
  code { background: #eee; padding: 0 2px; font-size: 8.5px; }
</style>

# Neovim Cheat Sheet — Leader = Space

<div class="cols">
<div class="col-break">

## Motion

| | |
|---|---|
| `C-d` / `C-u` | Half-page ↓/↑ (centered) |
| `n` / `N` | Next/prev match (centered) |
| `j` / `k` | Move (word-wrap aware) |
| `v J` / `v K` | Move selection ↓/↑ |

## Windows

| | |
|---|---|
| `⎵ h j k l` | Focus pane ←↓↑→ |
| `⎵ z` | Maximize toggle |
| `⎵ sb` | Scroll bind toggle |
| `⎵ rb` | Reference block toggle |

## Tabs

| | |
|---|---|
| `⎵ tn` / `⎵ tp` | Next / prev tab |
| `⎵ to` / `⎵ tc` | Only / close tab |

## Telescope

| | |
|---|---|
| `⎵ sf` | Search files |
| `⎵ sg` | Live grep |
| `⎵ sw` | Grep current word |
| `⎵ sd` | Search diagnostics |
| `⎵ sh` | Search help |
| `⎵ ?` | Recent files |
| `⎵ Space` | Open buffers |
| `⎵ /` | Fuzzy in buffer |

## Harpoon

| | |
|---|---|
| `⎵ ha` | Add file |
| `⎵ hh` | Quick menu |
| `⎵ 1-4` | Jump to file 1–4 |
| `C-S-P` / `C-S-N` | Prev / next file |

</div>
<div class="col-break">

## LSP

| | |
|---|---|
| `gd` / `gD` | Definition / declaration |
| `gr` / `gI` | References / implementation |
| `K` | Hover docs |
| `C-k` | Signature help |
| `⎵ rn` | Rename |
| `⎵ ca` | Code action |
| `⎵ D` | Type definition |
| `⎵ ds` | Document symbols |
| `⎵ ws` | Workspace symbols |
| `⎵ wa` / `⎵ wr` | Add/remove ws folder |
| `⎵ wl` | List ws folders |
| `⎵ gf` | Format |
| `⎵ td` | Toggle diagnostics |

## Debugging (DAP)

| | |
|---|---|
| `⎵ db` | Toggle breakpoint |
| `⎵ dc` | Continue / start |
| `⎵ do` / `⎵ di` | Step over / into |
| `⎵ dO` / `⎵ dq` | Step out / terminate |
| `⎵ du` | Toggle DAP UI |

## Git

| | |
|---|---|
| `⎵ gd` | Diff split (fugitive) |

</div>
<div class="col-break">

## Completion (Insert)

| | |
|---|---|
| `C-Space` | Trigger |
| `Tab` / `S-Tab` | Next / prev item |
| `CR` | Confirm |
| `C-e` | Abort |
| `C-b` / `C-f` | Scroll docs ↑/↓ |

## Terminal (Floaterm)

| | |
|---|---|
| `F7` | New terminal |
| `F8` / `F9` | Prev / next terminal |
| `F12` | Toggle terminal |
| `F5` | Run Python file |

## Neo-tree

| | |
|---|---|
| `⎵ nt` | Toggle tree |
| `⎵ bf` | Buffers float |

## Claude Code

| | |
|---|---|
| `⎵ ac` | Toggle Claude |
| `⎵ af` / `⎵ ar` | Focus / resume |
| `⎵ aC` / `⎵ am` | Continue / model |
| `⎵ ab` | Add buffer |
| `v ⎵ as` | Send selection |
| `⎵ aa` / `⎵ ad` | Accept / deny diff |

## Editing

| | |
|---|---|
| `gcc` | Toggle comment line |
| `gc` (visual) | Toggle comment |
| `cs"'` | Change surround |
| `ds"` | Delete surround |
| `ysiw"` | Add surround |

## Misc

| | |
|---|---|
| `⎵ kl` | Keystroke log toggle |

</div>
</div>
