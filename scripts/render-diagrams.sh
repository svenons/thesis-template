#!/usr/bin/env bash
# Render every diagram under assets/diagrams to a sibling .png.
#   *.mmd  -> rendered with Mermaid CLI (mmdc) at 3x for crisp text
#             in the LaTeX-scaled figure.
#   *.puml -> rendered with PlantUML for strict UML activity diagrams
#             and C4-PlantUML architecture diagrams. The Ubuntu-packaged
#             PlantUML 1.2020.02 cannot parse modern C4-PlantUML macros,
#             so the script downloads a recent PlantUML JAR into
#             scripts/.build/ on first use and caches it.
# Files under assets/diagrams/_lib/ (the C4-PlantUML stdlib) are never
# rendered directly; they exist only to satisfy `!include` in *.puml.
# Same script runs locally and in CI.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIAGRAMS_DIR="$ROOT/assets/diagrams"
BUILD_DIR="$ROOT/scripts/.build"
PLANTUML_VERSION="1.2024.8"
# Versioned filename so a cache restored under an older `restore-keys`
# fallback never gets reused as if it were the current version.
PLANTUML_JAR="$BUILD_DIR/plantuml-${PLANTUML_VERSION}.jar"
PLANTUML_URL="https://github.com/plantuml/plantuml/releases/download/v${PLANTUML_VERSION}/plantuml-${PLANTUML_VERSION}.jar"

if ! command -v npm >/dev/null 2>&1; then
  echo "npm not found; install Node 20+ first" >&2
  exit 1
fi

# Use the locally-installed mermaid-cli (pinned in package.json) so we
# don't re-fetch it on every CI run.
if [ ! -x "$ROOT/node_modules/.bin/mmdc" ]; then
  if [ -f "$ROOT/package.json" ]; then
    echo "Installing mermaid-cli via npm install..."
    (cd "$ROOT" && npm install --no-audit --no-fund)
  else
    echo "package.json not found and mermaid-cli not installed" >&2
    exit 1
  fi
fi
MMDC="$ROOT/node_modules/.bin/mmdc"

if ! command -v java >/dev/null 2>&1; then
  echo "java not found; install a JRE/JDK first (apt-get install default-jre-headless)" >&2
  exit 1
fi

if ! command -v dot >/dev/null 2>&1; then
  echo "dot not found; install graphviz (apt-get install graphviz)" >&2
  exit 1
fi

if [ ! -f "$PLANTUML_JAR" ]; then
  echo "Downloading PlantUML $PLANTUML_VERSION to $PLANTUML_JAR ..."
  mkdir -p "$BUILD_DIR"
  curl -fsSL -o "$PLANTUML_JAR" "$PLANTUML_URL"
fi

PUPPETEER_CFG="$(mktemp)"
trap 'rm -f "$PUPPETEER_CFG"' EXIT
cat > "$PUPPETEER_CFG" <<'JSON'
{
  "args": ["--no-sandbox", "--disable-setuid-sandbox"]
}
JSON

shopt -s globstar nullglob
mapfile -t MMD_SOURCES < <(find "$DIAGRAMS_DIR" -type f -name '*.mmd' -not -path '*/_lib/*' | sort)
mapfile -t PUML_SOURCES < <(find "$DIAGRAMS_DIR" -type f -name '*.puml' -not -path '*/_lib/*' | sort)

TOTAL=$(( ${#MMD_SOURCES[@]} + ${#PUML_SOURCES[@]} ))
if [ "$TOTAL" -eq 0 ]; then
  echo "No .mmd or .puml files found under $DIAGRAMS_DIR" >&2
  exit 1
fi

for src in "${MMD_SOURCES[@]}"; do
  out="${src%.mmd}.png"
  echo "Rendering $src -> $out"
  "$MMDC" \
    -i "$src" \
    -o "$out" \
    -b transparent \
    -s 3 \
    -p "$PUPPETEER_CFG" \
    --quiet
done

for src in "${PUML_SOURCES[@]}"; do
  out="${src%.puml}.png"
  echo "Rendering $src -> $out"
  # -SdpiResolution=216 matches the ~3x scaling we get from mmdc -s 3,
  # keeping line weights similar between the two engines.
  java -jar "$PLANTUML_JAR" \
    -tpng \
    -SdpiResolution=216 \
    -o "$(dirname "$src")" \
    "$src"
done

echo "Rendered $TOTAL diagram(s) (${#MMD_SOURCES[@]} mmd, ${#PUML_SOURCES[@]} puml)."
