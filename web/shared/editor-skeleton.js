// shared/editor-skeleton.js — o ESQUELETO da linguagem no editor do CONTEST (opção
// `editor_skeleton`, que o servidor só liga fora do modo icpc — editor_skeleton_effective).
// Funções PURAS (sem DOM): o contest.js decide com elas e o smoke-editor-skeleton.gjs.sh as
// exercita. O esqueleto é o MESMO `template` do treino (shared/languages.js).
//   • problema de SUBMISSÃO DE FUNÇÃO (`function_langs` do /contest/problems: linguagens com
//     scripts/<lang>/compile.sh, que injeta o main): nessas o editor começa VAZIO — o main do
//     esqueleto daria CE por main duplicado;
//   • trocar de linguagem só troca o texto se ainda é esqueleto (ou vazio): código digitado fica;
//   • enviar o esqueleto intacto é recusado (ele burlaria a trava de "editor vazio").
import { LANGUAGES, langById } from './languages.js';

const norm = (t) => (t || '').trim();

// o esqueleto que o editor mostra para `langId` ('' = começa vazio)
export function skeletonFor(on, langId, functionLangs) {
  if (!on || (functionLangs || []).includes(langId)) return '';
  return (langById(langId) || {}).template || '';
}

// o texto é o esqueleto (intacto) de ALGUMA linguagem?
export function isSkeleton(txt) {
  const t = norm(txt);
  return t !== '' && LANGUAGES.some((l) => l.template && norm(l.template) === t);
}

// o que o editor passa a mostrar ao trocar para `langId`
export function docOnLangChange(cur, on, langId, functionLangs) {
  if (!on) return cur;
  return (!norm(cur) || isSkeleton(cur)) ? skeletonFor(on, langId, functionLangs) : cur;
}
