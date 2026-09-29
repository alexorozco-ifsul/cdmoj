#!/bin/bash
# smoke-editor-skeleton.gjs.sh — web/shared/editor-skeleton.js, o que o editor do contest faz com a
# opção `editor_skeleton` (ver smoke-editor-skeleton.sh p/ o lado do servidor):
#   • desligada: nada muda (começa vazio; trocar de linguagem mantém o texto);
#   • ligada: começa com o template de shared/languages.js; problema de FUNÇÃO (function_langs)
#     começa vazio naquela linguagem;
#   • trocar de linguagem só troca o texto se ele ainda é esqueleto (ou vazio);
#   • isSkeleton reconhece o esqueleto intacto (com espaço sobrando) e não o código editado.
set -u
command -v gjs >/dev/null 2>&1 || { echo "editor-skeleton: gjs ausente — pulando"; exit 0; }
WEB="$(cd "$(dirname "$(readlink -f "$0")")/../../web" && pwd)"
strip(){ sed -E '/^import /d; s/^export (async )?(function|const|let|class) /\1\2 /; /^export \{/d' "$1"; }
JS="$(mktemp --suffix=.js)"; trap 'rm -f "$JS"' EXIT
{ echo "function T(pt){ return pt; }"
  strip "$WEB/shared/languages.js"; strip "$WEB/shared/editor-skeleton.js"
  cat <<'EOF'
let pass=0, fail=0; const ck=(m,ok,d)=>{ if (ok) { print('  ok: '+m); pass++; } else { print('  FAIL: '+m+' :: '+(d||'')); fail++; } };
const C=langById('c').template, PY=langById('py').template, JAVA=langById('java').template;
ck('templates existem (c, py, java)', !!C && !!PY && !!JAVA);
ck('desligada: começa vazio', skeletonFor(false,'c',[])==='');
ck('ligada: começa com o esqueleto da linguagem', skeletonFor(true,'c',[])===C);
ck('ligada + problema de função em c: começa vazio', skeletonFor(true,'c',['c','cpp'])==='');
ck('…mas não nas outras linguagens do mesmo problema', skeletonFor(true,'py',['c','cpp'])===PY);
ck('isSkeleton: esqueleto intacto', isSkeleton(C) && isSkeleton(JAVA));
ck('isSkeleton: tolera espaço/linha sobrando', isSkeleton('\n  '+C+'\n\n'));
ck('isSkeleton: código editado não é esqueleto', !isSkeleton(C.replace('return 0;', 'printf("oi");\n    return 0;')));
ck('isSkeleton: vazio não é esqueleto (a trava de vazio é outra)', !isSkeleton('') && !isSkeleton('   '));
ck('troca de linguagem, desligada: mantém o texto (inclusive vazio)', docOnLangChange(C,false,'py',[])===C && docOnLangChange('',false,'py',[])==='');
ck('troca, ligada: esqueleto vira o da nova linguagem', docOnLangChange(C,true,'py',[])===PY);
ck('troca, ligada: vazio vira o esqueleto novo', docOnLangChange('  ',true,'java',[])===JAVA);
const meu=C.replace('    \n    return 0;', '    int n; scanf("%d",&n);\n    return 0;');
ck('troca, ligada: código digitado fica', docOnLangChange(meu,true,'py',[])===meu);
ck('troca p/ linguagem de função: esqueleto some', docOnLangChange(PY,true,'c',['c'])==='');
print(''); print('RESULT: '+pass+' passed, '+fail+' failed');
imports.system.exit(fail>0?1:0);
EOF
} > "$JS"
gjs "$JS"
