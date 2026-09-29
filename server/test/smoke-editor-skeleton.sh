#!/bin/bash
# Esqueleto da linguagem no editor do contest (EDITOR_SKELETON) — opt-in e NUNCA em modo icpc:
#   • criação: editor_skeleton:true grava EDITOR_SKELETON=1 fora do icpc; no icpc não grava nada;
#   • settings: GET devolve o efetivo; POST liga/desliga fora do icpc e é IGNORADO no icpc;
#   • userinfo: editor_skeleton efetivo (conf editado à mão em contest icpc não liga);
#   • export/duplicar levam a opção;
#   • /contest/problems: function_langs = linguagens com scripts/<lang>/compile.sh no pacote.
set -u
ROOT="$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)"; ROUTER="$ROOT/api/v1/router.sh"
FIX="$(mktemp -d)"; SESS="$(mktemp -d)"; PROBS="$(mktemp -d)"; RUN="$(mktemp -d)"
trap 'rm -rf "$FIX" "$SESS" "$PROBS" "$RUN"' EXIT
export CONTESTSDIR="$FIX" SESSIONDIR="$SESS" MOJ_PROBLEMS_DIR="$PROBS" RUNDIR="$RUN"
source "$(dirname "$(readlink -f "$0")")/fixture.sh"
T="$FIX/treino"; mkdir -p "$T/var/jsons"
printf 'CONTEST_ID=treino\nCONTEST_TYPE=lista-publica\nUSER_STORE=v2\n' > "$T/conf"
fx_user "$T" regular s "Regular"
printf '{"threshold":0,"allow":["regular"],"deny":[]}' > "$T/var/contest-perms.json"
printf 'CONTEST=treino\nLOGIN=regular\nUSERFULLNAME=Regular\nLOGINAT=1\n' > "$SESS/reg"
printf '%s' '{"id":"lab#func","title":"Funcao","tags":[]}' > "$T/var/jsons/lab#func.json"
printf '%s' '{"id":"lab#comum","title":"Comum","tags":[]}' > "$T/var/jsons/lab#comum.json"
# índice de owners fresco (a criação confere privados por ele)
printf '%s' '{"problems":[{"id":"lab#func","title":"Funcao","owner":"x","collaborators":[],"public":true},{"id":"lab#comum","title":"Comum","owner":"x","collaborators":[],"public":true}]}' > "$T/var/problem-owners.json"
# pacotes: lab/func é de SUBMISSÃO DE FUNÇÃO em c e cpp (compile.sh próprio); lab/comum não
mkdir -p "$PROBS/lab/func/scripts/c" "$PROBS/lab/func/scripts/cpp" "$PROBS/lab/func/scripts/py" "$PROBS/lab/comum/scripts"
: > "$PROBS/lab/func/scripts/c/compile.sh"; : > "$PROBS/lab/func/scripts/cpp/compile.sh"; : > "$PROBS/lab/func/scripts/py/prep.sh"
NOW="$(date +%s)"; FUT=$(( NOW + 100000 ))
call(){ OUT="$(PATH_INFO="$1" REQUEST_METHOD="$2" QUERY_STRING="${5:-}" HTTP_AUTHORIZATION="Bearer ${4:-reg}" \
    bash "$ROUTER" <<<"${3:-}" 2>&1)"
  BODY="$(printf '%s' "$OUT" | awk 'f{print} /^\r?$/{f=1}')"; }
J(){ jq -r "$1" <<<"$BODY" 2>/dev/null; }
pass=0; fail=0; ck(){ if eval "$2"; then echo "  ok: $1"; ((pass++)); else echo "  FAIL: $1 :: ${BODY:0:240}"; ((fail++)); fi; }
mk(){ # mk <id> <mode> <editor_skeleton:true|false|omit>
  local esk=""; [[ "$3" != omit ]] && esk=",\"editor_skeleton\":$3"
  call /treino/contest-create/create POST "{\"id\":\"$1\",\"name\":\"$1\",\"mode\":\"$2\",\"start\":$((NOW-60)),\"end\":$FUT$esk,\"admin\":{\"login\":\"boss\",\"password\":\"sek\",\"fullname\":\"Boss\"},\"problems\":[{\"bank_id\":\"lab#func\",\"name\":\"F\",\"letter\":\"A\"},{\"bank_id\":\"lab#comum\",\"name\":\"C\",\"letter\":\"B\"}]}" reg
  [[ "$(J .admin_login)" == boss.admin ]] || { echo "SETUP FAIL ($1): $BODY"; exit 1; }
  printf 'CONTEST=%s\nLOGIN=boss.admin\nUSERFULLNAME=Boss\nLOGINAT=1\n' "$1" > "$SESS/adm-$1"
  fx_user "$FIX/$1" aluno a "Aluno"
  printf 'CONTEST=%s\nLOGIN=aluno\nUSERFULLNAME=Aluno\nLOGINAT=1\n' "$1" > "$SESS/usr-$1"
}

echo "== criação =="
mk sk-obi obi true
ck "obi + editor_skeleton:true grava EDITOR_SKELETON=1"   'grep -q "^EDITOR_SKELETON=1" "$FIX/sk-obi/conf"'
mk sk-icpc icpc true
ck "icpc + editor_skeleton:true NÃO grava"                '! grep -q "^EDITOR_SKELETON" "$FIX/sk-icpc/conf"'
mk sk-treino treino omit
ck "sem a chave: não grava (opt-in)"                       '! grep -q "^EDITOR_SKELETON" "$FIX/sk-treino/conf"'

echo "== userinfo =="
call /contest/userinfo GET '' usr-sk-obi 'contest=sk-obi'
ck "obi ligado: editor_skeleton true"                      '[[ "$(J .editor_skeleton)" == true ]]'
call /contest/userinfo GET '' usr-sk-treino 'contest=sk-treino'
ck "treino sem a opção: false"                             '[[ "$(J .editor_skeleton)" == false ]]'
echo 'EDITOR_SKELETON=1' >> "$FIX/sk-icpc/conf"
call /contest/userinfo GET '' usr-sk-icpc 'contest=sk-icpc'
ck "icpc com o conf editado à mão: continua false"         '[[ "$(J .editor_skeleton)" == false ]]'
sed -i '/^EDITOR_SKELETON/d' "$FIX/sk-icpc/conf"

echo "== settings =="
call /contest/admin/settings GET '' adm-sk-obi 'contest=sk-obi'
ck "GET obi: true"                                         '[[ "$(J .editor_skeleton)" == true && "$(J .mode)" == obi ]]'
call /contest/admin/settings POST '{"editor_skeleton":false}' adm-sk-obi 'contest=sk-obi'
ck "POST false desliga (sai do conf)"                      '[[ "$OUT" == *"Status: 200"* ]] && ! grep -q "^EDITOR_SKELETON" "$FIX/sk-obi/conf"'
call /contest/admin/settings POST '{"editor_skeleton":true}' adm-sk-obi 'contest=sk-obi'
ck "POST true religa"                                      'grep -q "^EDITOR_SKELETON=1" "$FIX/sk-obi/conf"'
call /contest/admin/settings POST '{"show_log":true}' adm-sk-obi 'contest=sk-obi'
ck "POST sem a chave não mexe"                             'grep -q "^EDITOR_SKELETON=1" "$FIX/sk-obi/conf"'
call /contest/admin/settings POST '{"editor_skeleton":true}' adm-sk-icpc 'contest=sk-icpc'
ck "POST true no icpc: 200 e ignorado"                     '[[ "$OUT" == *"Status: 200"* ]] && ! grep -q "^EDITOR_SKELETON" "$FIX/sk-icpc/conf"'
call /contest/admin/settings GET '' adm-sk-icpc 'contest=sk-icpc'
ck "GET icpc: false"                                       '[[ "$(J .editor_skeleton)" == false ]]'
call /contest/admin/settings POST '{"editor_skeleton":true}' usr-sk-obi 'contest=sk-obi'
ck "competidor não muda (403)"                             '[[ "$OUT" == *"Status: 403"* ]]'

echo "== export / duplicar =="
call /treino/contest-create/export GET '' reg 'id=sk-obi'
ck "export leva editor_skeleton:true"                      '[[ "$(J "(.spec // .).editor_skeleton")" == true ]]'
call /treino/contest-create/export GET '' reg 'id=sk-treino'
ck "export sem a opção não inventa a chave"                '[[ "$(J "(.spec // .) | has(\"editor_skeleton\")")" == false ]]'
call /treino/contest-create/duplicate POST '{"from":"sk-obi","id":"sk-obi2","name":"copia"}' reg
ck "duplicar mantém a opção"                               'grep -q "^EDITOR_SKELETON=1" "$FIX/sk-obi2/conf"'

echo "== /contest/problems: function_langs =="
call /contest/problems GET '' usr-sk-obi 'contest=sk-obi'
ck "problema de função: function_langs = [c,cpp]"          '[[ "$(J "[.problems[]|select(.short_name==\"A\")][0].function_langs|join(\",\")")" == "c,cpp" ]]'
ck "problema comum: sem function_langs"                    '[[ "$(J "[.problems[]|select(.short_name==\"B\")][0]|has(\"function_langs\")")" == false ]]'

echo
echo "RESULT: $pass passed, $fail failed"
[[ $fail -eq 0 ]]
