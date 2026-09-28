# MOJ no IFSul Sapucaia

Branch `ifsul` = `local/treino-empty-fix` (correções que rodam no MOJ do câmpus,
candidatas a PR upstream — ver FIXES-UPSTREAM.md no workspace) + o workflow
`.github/workflows/imagem-ifsul.yml`, que só serve à implantação local.
PRs para o upstream saem de branches próprias, sem esta pasta nem o workflow.

A imagem é a de `deploy/Containerfile`, montada como o `make image` faz, com o
`mojtools` da branch `local/moj-vm` do fork `alexorozco-ifsul/mojtools` e o
`moj-cli` do upstream no commit fixado no workflow. Publicada em
`ghcr.io/alexorozco-ifsul/moj-server:ifsul-<commit>`; o job do Nomad fica no
repositório do cluster (`servicos/moj/`).
