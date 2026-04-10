#!/bin/sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
TARGET_FILE="index.html"
LIST_PAGE="$ROOT_DIR/history.html"
DETAIL_DIR="$ROOT_DIR/history"
SNAPSHOT_DIR="$DETAIL_DIR/snapshots"

html_escape() {
    printf '%s' "$1" | sed \
        -e 's/&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g'
}

COMMITS=$(git -C "$ROOT_DIR" log --follow --reverse --format='%H' -- "$TARGET_FILE")

if [ -z "$COMMITS" ]; then
    echo "No commits found for $TARGET_FILE" >&2
    exit 1
fi

rm -rf "$DETAIL_DIR"
rm -f "$LIST_PAGE"
mkdir -p "$DETAIL_DIR" "$SNAPSHOT_DIR"

set -- $COMMITS
TOTAL=$#
LATEST_NO=$(printf '%03d' "$TOTAL")
CARDS=''

INDEX=1
for HASH in "$@"; do
    NO=$(printf '%03d' "$INDEX")
    SHORT_HASH=$(git -C "$ROOT_DIR" show -s --format='%h' "$HASH")
    SUBJECT=$(git -C "$ROOT_DIR" show -s --format='%s' "$HASH")
    AUTHOR=$(git -C "$ROOT_DIR" show -s --format='%an' "$HASH")
    COMMIT_DATE=$(git -C "$ROOT_DIR" show -s --date='format:%Y-%m-%d %H:%M:%S' --format='%cd' "$HASH")

    SUBJECT_HTML=$(html_escape "$SUBJECT")
    AUTHOR_HTML=$(html_escape "$AUTHOR")

    SNAPSHOT_NAME="commit-$NO.html"
    DETAIL_NAME="commit-$NO.html"
    SNAPSHOT_PATH="$SNAPSHOT_DIR/$SNAPSHOT_NAME"
    DETAIL_PATH="$DETAIL_DIR/$DETAIL_NAME"

    git -C "$ROOT_DIR" show "$HASH:$TARGET_FILE" > "$SNAPSHOT_PATH"

    NEWER_LINK='<span class="nav-button disabled">← 新しいコミット</span>'
    OLDER_LINK='<span class="nav-button disabled">古いコミット →</span>'

    if [ "$INDEX" -lt "$TOTAL" ]; then
        NEWER_NO=$(printf '%03d' "$((INDEX + 1))")
        NEWER_LINK="<a class=\"nav-button\" href=\"commit-$NEWER_NO.html\">← 新しいコミット</a>"
    fi

    if [ "$INDEX" -gt 1 ]; then
        OLDER_NO=$(printf '%03d' "$((INDEX - 1))")
        OLDER_LINK="<a class=\"nav-button\" href=\"commit-$OLDER_NO.html\">古いコミット →</a>"
    fi

    LATEST_BADGE=''
    if [ "$INDEX" -eq "$TOTAL" ]; then
        LATEST_BADGE='<span class="latest-badge">LATEST</span>'
    fi

    cat > "$DETAIL_PATH" <<EOF
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Commit No.$NO | index.html history</title>
    <style>
        :root {
            --bg: #f4efe8;
            --panel: #fffaf4;
            --panel-strong: #ffffff;
            --text: #2e2721;
            --sub: #6f6458;
            --line: #dfd2c2;
            --accent: #9a3d1a;
            --accent-soft: #f6dfd5;
            --shadow: 0 12px 30px rgba(70, 44, 18, 0.08);
            --radius: 18px;
        }

        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            background:
                radial-gradient(circle at top left, #fff7ee 0, #f4efe8 40%, #efe6dc 100%);
            color: var(--text);
            font-family: "Hiragino Sans", "Yu Gothic", "Noto Sans JP", sans-serif;
        }

        .page {
            max-width: 1480px;
            margin: 0 auto;
            padding: 24px;
        }

        .hero,
        .preview {
            background: rgba(255, 250, 244, 0.88);
            border: 1px solid rgba(223, 210, 194, 0.9);
            border-radius: var(--radius);
            box-shadow: var(--shadow);
            backdrop-filter: blur(10px);
        }

        .hero {
            padding: 24px;
        }

        .eyebrow {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 6px 12px;
            border-radius: 999px;
            background: var(--accent-soft);
            color: var(--accent);
            font-size: 12px;
            font-weight: 900;
            letter-spacing: 0.08em;
        }

        .latest-badge {
            display: inline-flex;
            align-items: center;
            padding: 5px 10px;
            border-radius: 999px;
            background: #2f5f4b;
            color: #ffffff;
            font-size: 11px;
            font-weight: 900;
        }

        h1 {
            margin: 16px 0 8px;
            font-size: clamp(28px, 5vw, 44px);
            line-height: 1.1;
        }

        .lede {
            margin: 0;
            color: var(--sub);
            font-size: 15px;
            line-height: 1.7;
        }

        .meta {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 12px;
            margin-top: 20px;
        }

        .meta-card {
            padding: 14px 16px;
            background: var(--panel-strong);
            border: 1px solid var(--line);
            border-radius: 14px;
        }

        .meta-label {
            display: block;
            margin-bottom: 6px;
            color: var(--sub);
            font-size: 12px;
            font-weight: 800;
            letter-spacing: 0.06em;
        }

        .meta-value {
            font-size: 16px;
            font-weight: 900;
            line-height: 1.45;
            word-break: break-word;
        }

        .actions {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            margin-top: 20px;
        }

        .nav-button {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-height: 44px;
            padding: 0 16px;
            border-radius: 999px;
            border: 1px solid var(--line);
            background: #ffffff;
            color: var(--text);
            text-decoration: none;
            font-weight: 800;
        }

        .nav-button.disabled {
            background: #f3ebe2;
            color: #a09182;
            pointer-events: none;
        }

        .preview {
            margin-top: 18px;
            padding: 14px;
        }

        .preview-head {
            display: flex;
            flex-wrap: wrap;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            margin-bottom: 12px;
        }

        .preview-title {
            margin: 0;
            font-size: 20px;
            font-weight: 900;
        }

        .preview-note {
            margin: 0;
            color: var(--sub);
            font-size: 13px;
        }

        iframe {
            width: 100%;
            height: 720px;
            border: 1px solid var(--line);
            border-radius: 14px;
            background: #ffffff;
        }

        @media (max-width: 720px) {
            .page {
                padding: 16px;
            }

            .hero {
                padding: 18px;
            }

            iframe {
                height: 560px;
            }
        }
    </style>
</head>
<body>
    <main class="page">
        <section class="hero">
            <div class="eyebrow">INDEX VERSION VIEWER</div>
            <h1>Commit No.$NO $LATEST_BADGE</h1>
            <p class="lede">index.html のこの時点の状態を、コミット情報と一緒に確認できます。</p>

            <div class="meta">
                <article class="meta-card">
                    <span class="meta-label">COMMIT NO</span>
                    <div class="meta-value">$NO / $LATEST_NO</div>
                </article>
                <article class="meta-card">
                    <span class="meta-label">HASH</span>
                    <div class="meta-value">$SHORT_HASH</div>
                </article>
                <article class="meta-card">
                    <span class="meta-label">DATE</span>
                    <div class="meta-value">$COMMIT_DATE</div>
                </article>
                <article class="meta-card">
                    <span class="meta-label">AUTHOR</span>
                    <div class="meta-value">$AUTHOR_HTML</div>
                </article>
                <article class="meta-card">
                    <span class="meta-label">MESSAGE</span>
                    <div class="meta-value">$SUBJECT_HTML</div>
                </article>
            </div>

            <div class="actions">
                $NEWER_LINK
                <a class="nav-button" href="../history.html">一覧へ戻る</a>
                <a class="nav-button" href="snapshots/$SNAPSHOT_NAME">この版を単体で開く</a>
                $OLDER_LINK
            </div>
        </section>

        <section class="preview">
            <div class="preview-head">
                <h2 class="preview-title">Preview</h2>
                <p class="preview-note">下のフレームに、そのコミット時点の index.html を表示しています。</p>
            </div>
            <iframe src="snapshots/$SNAPSHOT_NAME" title="Commit No.$NO preview"></iframe>
        </section>
    </main>
</body>
</html>
EOF

    CARD_BADGE=''
    if [ "$INDEX" -eq "$TOTAL" ]; then
        CARD_BADGE='<span class="card-badge">LATEST</span>'
    fi

    CARDS="
        <a class=\"commit-card\" href=\"history/$DETAIL_NAME\">
            <div class=\"card-top\">
                <span class=\"card-no\">Commit No.$NO</span>
                $CARD_BADGE
            </div>
            <h2>$SUBJECT_HTML</h2>
            <dl class=\"card-meta\">
                <div>
                    <dt>Hash</dt>
                    <dd>$SHORT_HASH</dd>
                </div>
                <div>
                    <dt>Date</dt>
                    <dd>$COMMIT_DATE</dd>
                </div>
                <div>
                    <dt>Author</dt>
                    <dd>$AUTHOR_HTML</dd>
                </div>
            </dl>
        </a>$CARDS"

    INDEX=$((INDEX + 1))
done

cat > "$LIST_PAGE" <<EOF
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>index.html Commit History</title>
    <style>
        :root {
            --bg: #f2ece4;
            --panel: rgba(255, 249, 242, 0.92);
            --panel-strong: #ffffff;
            --text: #2f2721;
            --sub: #706457;
            --line: #decebb;
            --accent: #9a3d1a;
            --accent-soft: #f5dfd4;
            --shadow: 0 18px 40px rgba(65, 38, 14, 0.08);
            --radius-xl: 28px;
            --radius-lg: 20px;
        }

        * {
            box-sizing: border-box;
        }

        body {
            margin: 0;
            color: var(--text);
            font-family: "Hiragino Sans", "Yu Gothic", "Noto Sans JP", sans-serif;
            background:
                radial-gradient(circle at top left, #fff7ee 0, #f6efe6 28%, #efe7dd 64%, #eadfce 100%);
        }

        .page {
            max-width: 1280px;
            margin: 0 auto;
            padding: 24px;
        }

        .hero {
            padding: 28px;
            background: var(--panel);
            border: 1px solid rgba(222, 206, 187, 0.92);
            border-radius: var(--radius-xl);
            box-shadow: var(--shadow);
            backdrop-filter: blur(10px);
        }

        .eyebrow {
            display: inline-flex;
            align-items: center;
            padding: 6px 12px;
            border-radius: 999px;
            background: var(--accent-soft);
            color: var(--accent);
            font-size: 12px;
            font-weight: 900;
            letter-spacing: 0.08em;
        }

        h1 {
            margin: 18px 0 10px;
            font-size: clamp(30px, 5vw, 52px);
            line-height: 1.05;
        }

        .lede {
            max-width: 760px;
            margin: 0;
            color: var(--sub);
            font-size: 15px;
            line-height: 1.8;
        }

        .hero-actions {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            margin-top: 22px;
        }

        .hero-link {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            min-height: 46px;
            padding: 0 18px;
            border-radius: 999px;
            border: 1px solid var(--line);
            background: var(--panel-strong);
            color: var(--text);
            text-decoration: none;
            font-weight: 800;
        }

        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
            gap: 12px;
            margin-top: 18px;
        }

        .summary-card {
            padding: 16px;
            background: var(--panel-strong);
            border: 1px solid var(--line);
            border-radius: 16px;
        }

        .summary-label {
            display: block;
            margin-bottom: 8px;
            color: var(--sub);
            font-size: 12px;
            font-weight: 800;
            letter-spacing: 0.06em;
        }

        .summary-value {
            font-size: 24px;
            line-height: 1.2;
            font-weight: 900;
        }

        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
            gap: 16px;
            margin-top: 22px;
        }

        .commit-card {
            display: block;
            padding: 20px;
            color: inherit;
            text-decoration: none;
            background: var(--panel);
            border: 1px solid rgba(222, 206, 187, 0.92);
            border-radius: var(--radius-lg);
            box-shadow: var(--shadow);
            transition: transform 160ms ease, border-color 160ms ease;
        }

        .commit-card:hover {
            transform: translateY(-2px);
            border-color: #caa27d;
        }

        .card-top {
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 8px;
        }

        .card-no,
        .card-badge {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            border-radius: 999px;
            font-size: 11px;
            font-weight: 900;
            letter-spacing: 0.06em;
        }

        .card-no {
            padding: 6px 10px;
            background: var(--accent-soft);
            color: var(--accent);
        }

        .card-badge {
            padding: 5px 10px;
            background: #2f5f4b;
            color: #ffffff;
        }

        .commit-card h2 {
            margin: 14px 0 16px;
            font-size: 23px;
            line-height: 1.2;
        }

        .card-meta {
            display: grid;
            gap: 10px;
            margin: 0;
        }

        .card-meta div {
            display: grid;
            gap: 4px;
        }

        .card-meta dt {
            color: var(--sub);
            font-size: 12px;
            font-weight: 800;
            letter-spacing: 0.05em;
        }

        .card-meta dd {
            margin: 0;
            font-size: 15px;
            font-weight: 800;
            word-break: break-word;
        }

        @media (max-width: 720px) {
            .page {
                padding: 16px;
            }

            .hero {
                padding: 20px;
            }

            .commit-card {
                padding: 18px;
            }
        }
    </style>
</head>
<body>
    <main class="page">
        <section class="hero">
            <div class="eyebrow">INDEX VERSION HISTORY</div>
            <h1>コミットごとに index.html を見比べる</h1>
            <p class="lede">このページは Git 履歴から index.html の各バージョンを静的に書き出した一覧です。Commit No. を押すと、その時点のプレビューとコミット情報を確認できます。</p>

            <div class="hero-actions">
                <a class="hero-link" href="index.html">現在の index.html を開く</a>
                <a class="hero-link" href="history/commit-$LATEST_NO.html">最新コミットを開く</a>
            </div>

            <div class="summary">
                <article class="summary-card">
                    <span class="summary-label">TOTAL COMMITS</span>
                    <div class="summary-value">$TOTAL</div>
                </article>
                <article class="summary-card">
                    <span class="summary-label">LATEST COMMIT NO</span>
                    <div class="summary-value">$LATEST_NO</div>
                </article>
                <article class="summary-card">
                    <span class="summary-label">ORDER</span>
                    <div class="summary-value">新しい順 → 古い順</div>
                </article>
            </div>
        </section>

        <section class="grid">
$CARDS
        </section>
    </main>
</body>
</html>
EOF

printf 'Generated %s commits into %s\n' "$TOTAL" "$DETAIL_DIR"
