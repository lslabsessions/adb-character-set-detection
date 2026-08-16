# Legacy Java GDK Approach

This document records the historical implementation that motivated the comparison with the new native PL/SQL API.

## Previous on-premises approach

The earlier solution used the Oracle Globalization Development Kit Java detector:

```java
oracle.i18n.lcsd.LCSDetector
```

A Java stored procedure exposed the detector to PL/SQL.

The specific implementation used this flow:

```text
character data
      |
      v
temporary BLOB
      |
      v
Java stored procedure
      |
      v
LCSDetector
      |
      v
detected Oracle character set
```

## Operational considerations

The solution worked, but the integration required additional components and lifecycle management:

- Java/GDK classes available in the database environment;
- a Java stored procedure;
- a PL/SQL-to-Java wrapper;
- temporary LOB creation in the particular implementation;
- temporary LOB cleanup and associated resource considerations.

The temporary BLOB was an implementation choice in that PL/SQL bridge. It should not be interpreted as a claim that the Java GDK detector itself only accepts BLOB input.

## Native 26ai approach

Oracle AI Database 26ai exposes detection directly through:

```plsql
utl_i18n.detect_charset(...)
```

The PL/SQL API supports `BFILE`, `BLOB`, `CLOB`, `VARCHAR2`, and `NVARCHAR2`, and returns ranked candidates with scores.

For this use case, the new API removes the need for the custom Java bridge.

## Separate historical mojibake heuristic

A custom PL/SQL scoring function was also previously used to identify suspicious mojibake patterns and accept a candidate repair only when it resulted in fewer suspicious mojibake patterns and therefore a better score.

That solves a different problem:

```text
DETECT_CHARSET
-> Which encoding most likely explains the current byte stream?

Custom mojibake score
-> Does already-decoded text look corrupted, and does a repair improve it?
```

The heuristic is therefore useful background but is intentionally not part of the main 26ai lab.

## Reference

- Oracle AI Database 26ai — `UTL_I18N`  
  https://docs.oracle.com/en/database/oracle/oracle-database/26/arpls/UTL_I18N.html
