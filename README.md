# seal-key-server

Contingency container image of the upstream [MystenLabs/seal](https://github.com/MystenLabs/seal)
key server, built from a pinned release for Permissioned mode. It is **not deployed**: production
Sealed Storage uses independent key servers (see the workspace ADR-0002). The image build and the
runbook arrive with the contingency kit.
