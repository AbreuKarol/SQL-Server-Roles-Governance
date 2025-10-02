USE [NOME_DO_BANCO];
GO

/* ============================================================
   SQL Server Roles Governance
   Seção 1: Roles criadas e associadas às roles internas
   ============================================================ */

-- DBR_READER -> herda db_datareader
CREATE ROLE DBR_READER;
GO
ALTER ROLE db_datareader ADD MEMBER DBR_READER;
GO

-- DBR_WRITER -> herda db_datawriter
CREATE ROLE DBR_WRITER;
GO
ALTER ROLE db_datawriter ADD MEMBER DBR_WRITER;
GO

-- DBR_DDL -> herda db_ddladmin
CREATE ROLE DBR_DDL;
GO
ALTER ROLE db_ddladmin ADD MEMBER DBR_DDL;
GO

-- DBR_ADMIN -> herda db_owner
CREATE ROLE DBR_ADMIN;
GO
ALTER ROLE db_owner ADD MEMBER DBR_ADMIN;
GO

-- DBR_AUDITOR -> sem equivalente interno
CREATE ROLE DBR_AUDITOR;
GO
GRANT VIEW DEFINITION TO DBR_AUDITOR;
GO


/* ============================================================
   SQL Server Roles Governance
   Seção 2: Roles criadas com permissões via GRANT direto
   ============================================================ */

-- DBR_READER
CREATE ROLE DBR_READER_GRANT;
GO
GRANT SELECT ON SCHEMA::dbo TO DBR_READER_GRANT;
GO

-- DBR_WRITER
CREATE ROLE DBR_WRITER_GRANT;
GO
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO DBR_WRITER_GRANT;
GRANT EXECUTE ON SCHEMA::dbo TO DBR_WRITER_GRANT;
GO

-- DBR_DDL
CREATE ROLE DBR_DDL_GRANT;
GO
GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE FUNCTION, CREATE TYPE, CREATE SYNONYM TO DBR_DDL_GRANT;
GRANT ALTER ON SCHEMA::dbo TO DBR_DDL_GRANT;
GO

-- DBR_ADMIN
CREATE ROLE DBR_ADMIN_GRANT;
GO
GRANT CONTROL ON DATABASE::[NOME_DO_BANCO] TO DBR_ADMIN_GRANT;
GO

-- DBR_AUDITOR
CREATE ROLE DBR_AUDITOR_GRANT;
GO
GRANT VIEW DEFINITION TO DBR_AUDITOR_GRANT;
GRANT VIEW DATABASE STATE TO DBR_AUDITOR_GRANT;
GO
