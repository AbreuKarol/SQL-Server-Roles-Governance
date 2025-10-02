
# SQL Server Roles Governance

Guia prático para **padronizar, versionar e auditar** permissões em bancos SQL Server usando *database roles* idempotentes.

---

## Visão Geral

Este projeto centraliza a criação e manutenção de **roles** no SQL Server aplicando princípios de **segurança**, **governança** e **reutilização**. O foco é substituir *grants* diretos a usuários por **concessões via roles**, simplificando auditoria e manutenção ao longo dos ambientes (**DEV**, **HML**, **PRD**).

---

## Objetivos

* Padronizar concessões de acesso em SQL Server.
* Evitar a complexidade e os riscos de *grants* diretos.
* Estabelecer convenções de nomenclatura claras e consistentes.
* Disponibilizar **scripts idempotentes** (executáveis repetidas vezes sem erro).
* Servir como base didática para devs, DBAs e estudantes.

---

## Arquitetura & Conceitos

* **Role**: agrupador lógico de permissões; usuários são adicionados/removidos das roles.
* **Idempotência**: cada script verifica existência antes de criar/alterar objetos.
* **Menor Privilégio**: cada role concede apenas o necessário ao caso de uso.
* **Separação de Ambientes**: mesmos nomes de roles em DEV/HML/PRD facilitam *promotions* e políticas.

---

## Convenção de Nomes

Use prefixo curto e semântico **DBR_** (*DataBase Role*):

| Role          | Significado                                           |
| ------------- | ----------------------------------------------------- |
| `DBR_READER`  | Leitura (`SELECT`) em tabelas/views do schema alvo.   |
| `DBR_WRITER`  | DML completo: `SELECT`, `INSERT`, `UPDATE`, `DELETE`. |
| `DBR_DDL`     | `CREATE`/`ALTER`/`DROP` em objetos do schema.         |
| `DBR_ADMIN`   | Administração ampla do banco (uso criterioso).        |
| `DBR_AUDITOR` | Acesso a metadados e consultas de auditoria.          |

> **Dica:** adapte se necessário, mantendo **consistência** e **clareza**.

---

## Matriz de Permissões

| Role          | Objetos/Âmbito        | Permissões Principais                                                      |
| ------------- | --------------------- | -------------------------------------------------------------------------- |
| `DBR_READER`  | `SCHEMA::dbo`         | `SELECT`                                                                   |
| `DBR_WRITER`  | `SCHEMA::dbo`         | `SELECT`, `INSERT`, `UPDATE`, `DELETE`                                     |
| `DBR_DDL`     | `DATABASE` / `SCHEMA` | `CREATE TABLE/VIEW/PROC`, `ALTER`, `DROP`                                  |
| `DBR_ADMIN`   | `DATABASE`            | `CONTROL`, `ALTER ANY SCHEMA`, `ALTER ANY USER` (ajuste conforme política) |
| `DBR_AUDITOR` | `DATABASE`            | `VIEW DEFINITION`, consultas em `sys.*`, DMVs                              |

> Ajuste o **escopo** (por `SCHEMA` ou `DATABASE`) conforme sua política de segurança.

---

## Estrutura do Repositório

```text
sqlserver-roles-gov/
├─ roles.sql      # Criação e concessão de roles (idempotente)
├─ README.md      # Este documento
```

---

## Pré‑requisitos

* SQL Server 2016+ (recomendado) e permissões para `CREATE ROLE`/`GRANT`.
* Acesso ao banco alvo e ao(s) schema(s) onde as permissões serão aplicadas.
* Ferramenta de execução (SSMS / Azure Data Studio / sqlcmd).

---

## Instalação & Execução

1. Abra o `roles.sql` no seu cliente SQL.
2. Se necessário, ajuste o schema alvo (ex.: `dbo`) e o escopo das permissões.
3. Execute o script. Ele é **idempotente** e pode ser reaplicado com segurança.

---

## Exemplos de Uso

### 1) Criação de roles (idempotente)

```sql
-- Leitura
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'DBR_READER')
    CREATE ROLE DBR_READER;
GRANT SELECT ON SCHEMA::dbo TO DBR_READER;

-- Escrita
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'DBR_WRITER')
    CREATE ROLE DBR_WRITER;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO DBR_WRITER;

-- DDL
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'DBR_DDL')
    CREATE ROLE DBR_DDL;
GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE TO DBR_DDL;
GRANT ALTER, CONTROL ON SCHEMA::dbo TO DBR_DDL;

-- Auditoria
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'DBR_AUDITOR')
    CREATE ROLE DBR_AUDITOR;
GRANT VIEW DEFINITION TO DBR_AUDITOR;
```

### 2) Atribuir usuário às roles

```sql
-- Usuário existente no banco
EXEC sp_addrolemember @rolename = 'DBR_READER', @membername = 'usuario_app';
EXEC sp_addrolemember @rolename = 'DBR_WRITER', @membername = 'usuario_app';
```

> Em versões recentes, prefira `ALTER ROLE ... ADD MEMBER`:

```sql
ALTER ROLE DBR_READER ADD MEMBER [usuario_app];
ALTER ROLE DBR_WRITER ADD MEMBER [usuario_app];
```

### 3) Verificar membros de uma role

```sql
SELECT r.name AS role_name, m.name AS member_name
FROM sys.database_role_members drm
JOIN sys.database_principals r ON r.principal_id = drm.role_principal_id
JOIN sys.database_principals m ON m.principal_id = drm.member_principal_id
WHERE r.name IN ('DBR_READER','DBR_WRITER','DBR_DDL','DBR_ADMIN','DBR_AUDITOR')
ORDER BY r.name, m.name;
```

---

## Boas Práticas de Governança

* **Menor privilégio** sempre; evite conceder `CONTROL`/`db_owner` sem justificativa.
* **Sem grants diretos a usuários**: use apenas via roles.
* **Versione** os scripts (Git) e aplique *code review* para mudanças de permissão.
* **Segregue deveres**: quem define não é quem aprova/aplica em PRD.
* **Padronize** nomes e escopos (schema vs database) por política.

---

## Auditoria & Observabilidade

* Habilite *auditing* ou *Extended Events* para registrar `GRANT`, `REVOKE`, `ALTER ROLE`.
* Periodicamente, gere inventário de membros por role e compare com o estado esperado.
* Mantenha um **catálogo de sistemas** com mapeamento *Sistema → Banco → Roles*.

---

## Teste & Validação

* **Smoke test**: após aplicar, rode consultas simples de leitura/escrita com uma conta de teste.
* **DMVs**: valide membros de roles e permissões efetivas.
* **Idempotência**: reexecute o script e confirme ausência de erros/efeitos colaterais.

---

## Rollback & Remoção Segura

```sql
-- Remover membro de uma role
ALTER ROLE DBR_WRITER DROP MEMBER [usuario_app];

-- Revogar permissões (se necessário)
REVOKE SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo FROM DBR_WRITER;

-- Dropar a role (após esvaziá-la)
DROP ROLE IF EXISTS DBR_WRITER;
```

> **Importante:** confirme dependências antes de remover roles em produção.

---

## FAQ

**1) Posso usar um schema que não seja `dbo`?**
Sim. Substitua `SCHEMA::dbo` pelo schema alvo (ex.: `SCHEMA::app`).

**2) Como restringir `DBR_DDL` a somente `CREATE VIEW`?**
Conceda permissões específicas e evite `CONTROL`/`ALTER` amplos, ex.: `GRANT CREATE VIEW ON DATABASE TO DBR_DDL;`.

**3) Posso ter `DBR_READER` por schema e `DBR_WRITER` por tabela?**
Sim, mas priorize **simplicidade** por schema. Concessões por tabela aumentam manutenção.

---

> **Resumo:** este repositório entrega uma base sólida e idempotente para governança de permissões no SQL Server, com nomes padronizados, matriz de acesso clara e exemplos práticos para adoção imediata.

