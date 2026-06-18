# invoice.awk - render an invoice (HTML) from postings tagged inv:<NUMBER>.
#
# Invoked by the `invoice` wrapper:
#   gawk -v inv=N -v cust_file=PATH -v comp_file=PATH -v tpl_file=PATH \
#        -f invoice.awk -
#
# stdin = normalized postings:  date amount [CUR:]account tags...
#   - selects postings whose tags include  inv:<N>
#   - AR postings (amount>0)  -> line items
#   - AR postings (amount<0)  -> payments
#
# Customer DB (cust_file) and seller/company DB (comp_file) are plain text:
#   blank-line separated records of  key: value  lines.  The customer record
#   is keyed by  id:  (matched against the  klient:<id>  tag, or the account
#   segment that follows the receivables keyword).  The company file holds a
#   single record (record boundaries are ignored).
#
# The HTML template (tpl_file) supports scalar placeholders  {{name}}  and an
# item loop  {{#items}} ... {{/items}}  with  {{item_label}} {{item_amount}}.
# If no template file is given, an embedded template is used.

# ---- environment / defaults -----------------------------------------------
BEGIN {
    AR   = ENVIRON["PTA_AR"];        if (!AR)   AR   = "receivable|pohladavky"
    CUR  = ENVIRON["PTA_CURRENCY"];  if (!CUR)  CUR  = "EUR"
    TAX  = (ENVIRON["PTA_TAX"] + 0)
    DUE  = (ENVIRON["PTA_DUE_DAYS"] + 0); if (!DUE) DUE = 14

    if (inv == "") {
        print "invoice: missing invoice number (usage: invoice 2024-001)" > "/dev/stderr"
        exit 2
    }

    load_clients(cust_file)
    load_seller(comp_file)
    tmpl = read_template(tpl_file)
}

# ---- main: one rule per normalized posting --------------------------------
$1 ~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ {
    d = $1; amt = +$2; acct = $3
    cur_this = CUR
    if (acct ~ /^[A-Z]{2,5}:/) {            # commodity prefix  EUR:account
        split(acct, ap, ":")
        cur_this = ap[1]
        sub(/^[A-Z]{2,5}:/, "", acct)
    }

    is_inv = 0; k = ""; desc = ""
    for (i = 4; i <= NF; i++) {
        t = $i
        if (t == ("inv:" inv))            { is_inv = 1; continue }
        if (t ~ /^klient:/)               { k = substr(t, 8); continue }
        if (t ~ /^[A-Za-z][A-Za-z0-9_]*:/) continue   # other key:val tag
        desc = desc (desc ? " " : "") t              # free-text -> description
    }
    if (!is_inv) next
    if (k != "") klient = k

    if (!currency) currency = cur_this

    if (acct ~ AR) {
        last_ar_acct = acct
        if (amt > 0) {
            n++
            item_label[n] = (desc != "") ? desc : last_seg(acct)
            item_amt[n]   = amt
            subtotal += amt
            if (!inv_date || d < inv_date) inv_date = d
        } else {
            paid += -amt
        }
    }
    if (!inv_date) inv_date = d
}

END {
    if (n == 0) {
        printf("invoice %s: no line items found (tag postings with inv:%s)\n", inv, inv) > "/dev/stderr"
        exit 1
    }
    if (!currency) currency = CUR

    due_date = add_days(inv_date, DUE)
    tax_amt  = subtotal * TAX / 100
    total    = subtotal + tax_amt
    balance  = total - paid

    cid = (klient != "") ? klient : client_from_acct(last_ar_acct)

    set_var("invoice_no", esc(inv))
    set_var("date",       esc(inv_date))
    set_var("due_date",   esc(due_date))
    set_var("currency",   esc(currency))
    set_var("status",     esc(status_text(balance, paid)))

    set_var("client_id",       esc(cid))
    set_var("client_name",     esc(client_val(cid, "name", cid)))
    set_var("client_address",  multiline(client_val(cid, "address", "")))
    set_var("client_ico",      esc(client_val(cid, "ico", "")))
    set_var("client_dic",      esc(client_val(cid, "dic", "")))
    set_var("client_icdph",    esc(client_val(cid, "icdph", "")))
    set_var("client_iban",     esc(client_val(cid, "iban", "")))
    set_var("client_swift",    esc(client_val(cid, "swift", "")))
    set_var("client_email",    esc(client_val(cid, "email", "")))
    set_var("client_note",     multiline(client_val(cid, "note", "")))

    set_var("seller_name",     esc(seller_val("name", "")))
    set_var("seller_address",  multiline(seller_val("address", "")))
    set_var("seller_ico",      esc(seller_val("ico", "")))
    set_var("seller_dic",      esc(seller_val("dic", "")))
    set_var("seller_icdph",    esc(seller_val("icdph", "")))
    set_var("seller_iban",     esc(seller_val("iban", "")))
    set_var("seller_swift",    esc(seller_val("swift", "")))
    set_var("seller_email",    esc(seller_val("email", "")))
    set_var("seller_phone",    esc(seller_val("phone", "")))
    set_var("seller_web",      esc(seller_val("web", "")))

    set_var("subtotal",    money(subtotal))
    set_var("tax_rate",    sprintf("%g", TAX))
    set_var("tax",         money(tax_amt))
    set_var("total",       money(total))
    set_var("paid",        money(paid))
    set_var("balance_due", money(balance))

    printf("%s", render(tmpl))
}

# ---- DB loaders -----------------------------------------------------------
function load_clients(file,    line, m, key, val, cur, idx) {
    if (file == "") return
    while ((getline line < file) > 0) {
        sub(/\r$/, "", line)
        if (line ~ /^[[:space:]]*$/) { cur = ""; continue }
        if (line ~ /^[[:space:]]*#/) continue
        if (match(line, /^[[:space:]]*([A-Za-z0-9_]+):[[:space:]]*(.*)$/, m)) {
            key = tolower(m[1]); val = m[2]; sub(/[[:space:]]+$/, "", val)
            if (key == "id") { cur = val; continue }
            if (cur == "") continue
            idx = cur SUBSEP key
            client[idx] = (idx in client) ? client[idx] "\n" val : val
        }
    }
    close(file)
}

function load_seller(file,    line, m, key, val) {
    if (file == "") return
    while ((getline line < file) > 0) {
        sub(/\r$/, "", line)
        if (line ~ /^[[:space:]]*#/) continue
        if (match(line, /^[[:space:]]*([A-Za-z0-9_]+):[[:space:]]*(.*)$/, m)) {
            key = tolower(m[1]); val = m[2]; sub(/[[:space:]]+$/, "", val)
            seller[key] = (key in seller) ? seller[key] "\n" val : val
        }
    }
    close(file)
}

function client_val(id, key, dflt,    idx) {
    idx = id SUBSEP key
    return (idx in client) ? client[idx] : dflt
}
function seller_val(key, dflt) { return (key in seller) ? seller[key] : dflt }

# ---- template reading / rendering ----------------------------------------
function read_template(file,    t, line) {
    if (file == "" || (getline t < file) <= 0) { close(file); return default_template() }
    t = t "\n"
    while ((getline line < file) > 0) t = t line "\n"
    close(file)
    return t
}

# Replace the {{#items}}...{{/items}} block, then all scalar {{name}}.
function render(t,    p1, p2, pre, body, post, rows, i, row) {
    p1 = index(t, "{{#items}}")
    p2 = index(t, "{{/items}}")
    if (p1 && p2 && p2 > p1) {
        pre  = substr(t, 1, p1 - 1)
        body = substr(t, p1 + length("{{#items}}"), p2 - (p1 + length("{{#items}}")))
        post = substr(t, p2 + length("{{/items}}"))
        rows = ""
        for (i = 1; i <= n; i++) {
            row = body
            row = replace_all(row, "{{item_label}}",  esc(item_label[i]))
            row = replace_all(row, "{{item_amount}}", money(item_amt[i]))
            row = replace_all(row, "{{item_idx}}",    i)
            rows = rows row
        }
        t = pre rows post
    }
    return apply_vars(t)
}

# Generic {{name}} replacement (manual, so '&' in values is safe).
function apply_vars(s,    out, name) {
    out = ""
    while (match(s, /\{\{[A-Za-z0-9_]+\}\}/)) {
        out = out substr(s, 1, RSTART - 1)
        name = substr(s, RSTART + 2, RLENGTH - 4)
        out = out ((name in vars) ? vars[name] : "")
        s = substr(s, RSTART + RLENGTH)
    }
    return out s
}

function replace_all(s, marker, val,    out, p) {
    out = ""
    while ((p = index(s, marker)) > 0) {
        out = out substr(s, 1, p - 1) val
        s = substr(s, p + length(marker))
    }
    return out s
}

# ---- helpers --------------------------------------------------------------
function set_var(name, val) { vars[name] = val }

function esc(s,    r) {
    r = s
    gsub(/&/, "\\&amp;", r)
    gsub(/</, "\\&lt;",  r)
    gsub(/>/, "\\&gt;",  r)
    gsub(/"/, "\\&quot;", r)
    return r
}

# newline-separated raw value -> escaped lines joined with <br>
function multiline(s,    n, a, i, out) {
    n = split(s, a, "\n")
    out = ""
    for (i = 1; i <= n; i++)
        out = out (i > 1 ? "<br>\n" : "") esc(a[i])
    return out
}

function money(x) { return sprintf("%.2f", x) }

function last_seg(acct,    n, a) { n = split(acct, a, ":"); return a[n] }

# client id = account segment right after the receivables keyword
function client_from_acct(acct,    n, a, i) {
    n = split(acct, a, ":")
    for (i = 1; i <= n; i++)
        if (a[i] ~ AR && i < n) return a[i + 1]
    return ""
}

function add_days(date, days,    a, ts) {
    split(date, a, "-")
    ts = mktime(a[1] " " a[2] " " a[3] " 12 0 0")
    return strftime("%Y-%m-%d", ts + days * 86400)
}

function status_text(balance, paid) {
    if (paid <= 0)        return "Unpaid"
    if (balance <= 0.005) return "Paid"
    return "Partially paid"
}

# ---- embedded fallback template ------------------------------------------
function default_template(    t) {
    t = "<!doctype html>\n"
    t = t "<html lang=\"en\"><head><meta charset=\"utf-8\">\n"
    t = t "<title>Invoice {{invoice_no}}</title>\n"
    t = t "<style>\n"
    t = t "body{font:14px/1.5 -apple-system,Segoe UI,Roboto,sans-serif;"
    t = t "color:#1f2937;max-width:780px;margin:2em auto;padding:0 1em}\n"
    t = t "h1{font-size:1.6em;margin:0}\n"
    t = t ".muted{color:#6b7280}\n"
    t = t "table{width:100%;border-collapse:collapse;margin:1em 0}\n"
    t = t "th,td{padding:.5em .6em;text-align:left;border-bottom:1px solid #e5e7eb}\n"
    t = t "th{background:#f9fafb}\n"
    t = t ".amt{text-align:right;white-space:nowrap}\n"
    t = t ".totals{margin-left:auto;width:280px}\n"
    t = t ".totals td{border:none;padding:.25em .6em}\n"
    t = t ".due{font-weight:700;font-size:1.1em}\n"
    t = t "header{display:flex;justify-content:space-between;gap:2em}\n"
    t = t "hr{border:none;border-top:1px solid #e5e7eb;margin:1.5em 0}\n"
    t = t "@media print{body{margin:0}}\n"
    t = t "</style></head><body>\n"
    t = t "<header><div>\n"
    t = t "<h1>Invoice</h1>\n"
    t = t "<div class=\"muted\">no. {{invoice_no}}</div>\n"
    t = t "<div>Date: {{date}}</div>\n"
    t = t "<div>Due: {{due_date}}</div>\n"
    t = t "</div><div>\n"
    t = t "<strong>{{seller_name}}</strong><br>\n{{seller_address}}<br>\n"
    t = t "ICO: {{seller_ico}} &middot; DIC: {{seller_dic}}<br>\n"
    t = t "IBAN: {{seller_iban}}\n"
    t = t "</div></header>\n<hr>\n"
    t = t "<div><strong>Bill to:</strong> {{client_name}}<br>\n"
    t = t "{{client_address}}<br>\n"
    t = t "ICO: {{client_ico}} &middot; DIC: {{client_dic}}</div>\n"
    t = t "<table>\n<thead><tr><th>Description</th><th class=\"amt\">Amount</th></tr></thead>\n<tbody>\n"
    t = t "{{#items}}<tr><td>{{item_label}}</td><td class=\"amt\">{{item_amount}}</td></tr>\n{{/items}}"
    t = t "</tbody>\n</table>\n"
    t = t "<table class=\"totals\">\n"
    t = t "<tr><td>Subtotal ({{currency}})</td><td class=\"amt\">{{subtotal}}</td></tr>\n"
    t = t "<tr><td>VAT {{tax_rate}}%</td><td class=\"amt\">{{tax}}</td></tr>\n"
    t = t "<tr><td>Total</td><td class=\"amt\">{{total}}</td></tr>\n"
    t = t "<tr><td>Paid</td><td class=\"amt\">{{paid}}</td></tr>\n"
    t = t "<tr class=\"due\"><td>Balance due</td><td class=\"amt\">{{balance_due}}</td></tr>\n"
    t = t "</table>\n"
    t = t "<div class=\"muted\">Status: {{status}}</div>\n"
    t = t "</body></html>\n"
    return t
}
