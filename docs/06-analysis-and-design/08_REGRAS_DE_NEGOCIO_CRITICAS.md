# Regras de Negócio Críticas

1. Toda demanda externa deve ser normalizada para o modelo canônico.
2. Todo job deve ter contexto de tenant e organização.
3. Todo sync mobile deve ser idempotente.
4. Um vistoriador só pode receber job se elegível.
5. Valuation só processa após intake válido.
6. Laudo só pode ser publicado após sign-off.
7. Settlement só pode ser calculado após resultado final do processo.
8. Toda mudança crítica deve gerar trilha de auditoria.
