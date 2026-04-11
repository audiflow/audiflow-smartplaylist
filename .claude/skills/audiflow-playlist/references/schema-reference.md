# Playlist Schema Reference (v4)

Complete reference for all three JSON schemas in the audiflow-smartplaylist system. Read this when you need precise field names, types, constraints, or behavioral details.

## Table of Contents

1. [Three-Level Hierarchy](#three-level-hierarchy)
2. [Pattern Index (patterns/meta.json)](#pattern-index)
3. [Pattern Meta ({patternId}/meta.json)](#pattern-meta)
4. [Playlist Definition ({patternId}/playlists/{id}.json)](#playlist-definition)
5. [Resolver Types](#resolver-types)
6. [Presentation Modes](#presentation-modes)
7. [Episode Filters](#episode-filters)
8. [TitleExtractor](#titleextractor)
9. [NumberingExtractor](#numberingextractor)
10. [GroupDef](#groupdef)
11. [Sort Rules](#sort-rules)
12. [YearBinding](#yearbinding)
13. [Pattern ID Derivation](#pattern-id-derivation)

---

## Three-Level Hierarchy

```
patterns/
  meta.json                         <- Pattern Index (one per repo)
  {patternId}/
    meta.json                       <- Pattern Meta (one per podcast)
    playlists/
      {playlistId}.json             <- Playlist Definition (one per playlist)
```

The app fetches `patterns/meta.json` first for discovery, then loads individual pattern files on demand.

---

## Pattern Index

**File**: `patterns/meta.json`
**Schema**: `pattern-index.schema.json`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `dataVersion` | integer (min 1) | yes | Bumped by CI when any pattern changes |
| `schemaVersion` | integer (min 1) | yes | Bumped on breaking structural changes |
| `patterns` | PatternIndexEntry[] | yes | Summary entries for all patterns |

### PatternIndexEntry

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | 12-char hex pattern ID |
| `dataVersion` | integer (min 1) | yes | Mirrors pattern's meta.json version |
| `displayName` | string | yes | Human-readable podcast name |
| `feedUrlHint` | string | yes | Substring of feed URL for pre-filtering |
| `playlistCount` | integer (min 1) | yes | Number of playlist definitions |

---

## Pattern Meta

**File**: `patterns/{patternId}/meta.json`
**Schema**: `pattern-meta.schema.json`

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `dataVersion` | integer (min 1) | yes | Bumped when any file in pattern changes |
| `id` | string | yes | Must match parent directory name |
| `podcastGuid` | string | no | Podcast GUID from RSS. Primary matcher when available |
| `feedUrls` | string[] (min 1) | yes | RSS feed URLs for matching |
| `yearGroupedEpisodes` | boolean | no | Show year headers in main episode list (default: false) |
| `playlists` | string[] (min 1) | yes | Ordered playlist IDs (controls display order) |

---

## Playlist Definition

**File**: `patterns/{patternId}/playlists/{playlistId}.json`
**Schema**: `playlist-definition.schema.json`

### Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Must match filename (without .json) |
| `displayName` | string | Name shown to users in the app |
| `resolverType` | enum | `seasonNumber`, `year`, `titleDiscovery`, `titleClassifier` |
| `presentation` | enum | `separate`, `combined` |

### Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `episodeFilters` | object | Include/exclude rules (see [Episode Filters](#episode-filters)) |
| `titleExtractor` | TitleExtractor | Generates group display names (not used with titleClassifier) |
| `prependSeasonNumber` | boolean | Prefix group titles with "S{n}" (default: false) |
| `groupList` | object | Combined-mode group display settings |
| `episodeList` | object | Episode display settings (defaults for all groups) |
| `numberingExtractor` | NumberingExtractor | Parse season/episode from titles |
| `groups` | GroupDef[] | Group definitions (required for titleClassifier) |

---

## Resolver Types

### `seasonNumber`

Groups episodes by season number. Season comes from numberingExtractor (parsing titles) or RSS metadata (itunes:season).

**Supports**: titleExtractor, numberingExtractor, prependSeasonNumber
**Best for**: podcasts with season tags or title patterns like `S01E01`, `[55-5]`

### `year`

Groups episodes by publication year.

**Supports**: titleExtractor
**Best for**: long-running podcasts where yearly grouping is natural

### `titleDiscovery`

Auto-detects recurring patterns in episode titles and groups by them, in feed order.

**Supports**: titleExtractor (primary), groups[0].pattern (fallback for discovery)
**Best for**: podcasts with titled story arcs or recurring series names

### `titleClassifier`

Matches episode titles against patterns you define in groups[]. First match wins.

**Requires**: groups array
**Does NOT use**: titleExtractor (group names come from GroupDef.displayName)
**Best for**: podcasts with naming conventions like brackets, prefixes, or category markers

---

## Presentation Modes

### `separate`

Each group becomes its own selectable playlist (dropdown UI). One definition produces many playlists.

### `combined`

All groups shown as cards inside a single playlist. Tapping a card shows episodes. Enables groupList settings (yearBinding, userSortable, showDateRange, sort).

---

## Episode Filters

```json
{
  "episodeFilters": {
    "require": [{ "title": "regex" }],
    "exclude": [{ "title": "regex" }]
  }
}
```

**Logic**:
- Within each rule: all fields must match (AND)
- Across `require` rules: ALL must match (AND)
- Across `exclude` rules: ANY match rejects (OR)
- Definitions with filters run before filter-less ones (filter-less get remaining episodes)

### EpisodeFilterEntry fields

| Field | Type | Description |
|-------|------|-------------|
| `title` | string | Case-insensitive regex against episode title |
| `description` | string | Case-insensitive regex against episode description |

At least one field must be specified per entry.

---

## TitleExtractor

Generates display names from episode data. Used for group titles (seasonNumber, year, titleDiscovery) and episode title transformation (episodeList.titleExtractor).

```json
{
  "source": "title",
  "pattern": "regex with (capture groups)",
  "group": 1,
  "template": "Season {value}",
  "fallback": { "source": "title", "pattern": "..." },
  "fallbackValue": "Specials"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `source` | enum | yes | `title`, `description`, `seasonNumber`, `episodeNumber` |
| `pattern` | string | no | Regex with capture groups. Omit to use raw source value |
| `group` | integer (min 0) | no | Which capture group (0=whole match, 1=first group). Default: 0 |
| `template` | string | no | Format with `{value}` placeholder |
| `fallback` | TitleExtractor | no | Tried when this step fails. Chainable |
| `fallbackValue` | string | no | Default for seasonNumber/episodeNumber when value is 0 or missing. Checked before pattern. No effect for title/description sources |

**Processing steps**: (1) read source -> (2) match pattern -> (3) extract group -> (4) apply template -> (5) on failure, try fallback

---

## NumberingExtractor

Parses season and episode numbers from episode text, overriding RSS metadata.

```json
{
  "source": "title",
  "pattern": "[(\\d+)-(\\d+)]",
  "seasonGroup": 1,
  "episodeGroup": 2,
  "fallbackSeasonNumber": 0,
  "fallbackEpisodePattern": "(\\d+)]",
  "fallbackEpisodeCaptureGroup": 1,
  "fallbackToRss": true
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `source` | enum | yes | `title` or `description` |
| `pattern` | string | yes | Primary regex with capture groups for season/episode |
| `seasonGroup` | integer or null | no | Capture group for season (default: 1). null = episode-only mode |
| `episodeGroup` | integer (min 1) | no | Capture group for episode (default: 2) |
| `fallbackSeasonNumber` | integer | no | Season number when only fallback pattern matches |
| `fallbackEpisodePattern` | string | no | Backup regex tried when primary doesn't match |
| `fallbackEpisodeCaptureGroup` | integer (min 1) | no | Capture group in fallback pattern (default: 1) |
| `fallbackToRss` | boolean | no | Use RSS episode number as last resort (default: false) |

**Three-tier approach**: (1) primary pattern -> (2) fallback pattern with fixed season -> (3) RSS data

---

## GroupDef

Used with titleClassifier (required) and optionally with titleDiscovery (groups[0].pattern as fallback).

```json
{
  "id": "unique_id",
  "displayName": "Display Name",
  "pattern": "regex pattern",
  "display": {
    "showDateRange": true,
    "yearBinding": "pinToYear"
  },
  "episodeList": {
    "showYearHeaders": false,
    "sort": { "field": "publishedAt", "order": "ascending" },
    "titleExtractor": { "source": "title", "pattern": "..." }
  },
  "numberingExtractor": { ... }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | yes | Unique within the playlist |
| `displayName` | string | yes | Name shown in the app |
| `pattern` | string | no | Regex for matching titles. Omit for catch-all (place last) |
| `display` | object | no | Per-group display overrides (showDateRange, yearBinding) |
| `episodeList` | object | no | Per-group episode list overrides |
| `numberingExtractor` | NumberingExtractor | no | Per-group numbering override |

**Evaluation order**: groups are evaluated in array order; first match wins.

---

## Sort Rules

### Group sort (groupList.sort)

| Field | Values |
|-------|--------|
| `field` | `playlistNumber`, `newestEpisodeDate`, `alphabetical` |
| `order` | `ascending`, `descending` |

### Episode sort (episodeList.sort)

| Field | Values |
|-------|--------|
| `field` | `publishedAt`, `episodeNumber`, `title` |
| `order` | `ascending`, `descending` |

Default episode sort when omitted: publishedAt ascending (oldest first).

---

## YearBinding

Controls how groups relate to year sections in combined presentation.

| Value | Behavior |
|-------|----------|
| `none` | Flat list, no year sections (default) |
| `pinToYear` | Each group appears once, under its earliest episode's year |
| `splitByYear` | Group repeated for each year it spans |

Can be set at playlist level (groupList.yearBinding) and overridden per-group (GroupDef.display.yearBinding).

---

## Pattern ID Derivation

The 12-character hex ID is computed deterministically:

```
if podcastGuid is available:
    id = md5(podcastGuid)[0:12]
else:
    id = md5(feedUrls[0])[0:12]
```

This ID becomes the directory name and must match the `id` field in pattern meta.json.
